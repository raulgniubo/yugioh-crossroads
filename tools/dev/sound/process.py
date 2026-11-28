# Cuts, cleans and levels the ElevenLabs downloads into the game's audio folders.
# python3 -I process.py <in dir> <repo> <listen dir>
import sys, os, json, subprocess, numpy as np, soundfile as sf
IN, REPO, LISTEN = sys.argv[1], sys.argv[2], sys.argv[3]
SR = 44100
spec = json.load(open(os.path.join(REPO, "tools/dev/sound/sounds.json")))
TONE = {}
for part in open("/tmp/audit.txt", errors="ignore"):
    if part.startswith("SOUND"):
        w = part.split(); TONE[w[1]] = float(w[3])
def dec(p):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", p, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"], capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).astype(np.float64)
def db(v): return 20 * np.log10(max(v, 1e-9))
def rms(x): return float(np.sqrt(np.mean(np.square(x)))) if len(x) else 0.0
def loud100(x):
    m = x.mean(axis=1); w = int(0.1 * SR)
    if len(m) <= w: return rms(m)
    c = np.cumsum(np.concatenate([[0.0], m * m])); e = (c[w:] - c[:-w]) / w
    return float(np.sqrt(e.max()))
def fade(x, n_in, n_out):
    x = x.copy()
    if n_in > 0: x[:n_in] *= np.linspace(0, 1, n_in)[:, None]
    if n_out > 0: x[-n_out:] *= np.linspace(1, 0, n_out)[:, None]
    return x
def trim(x, thr_db=-50.0, pre=0.004, post=0.05):
    env = np.abs(x).max(axis=1); thr = 10 ** (thr_db / 20)
    idx = np.nonzero(env > thr)[0]
    if len(idx) == 0: return x[:0]
    a = max(0, idx[0] - int(pre * SR)); b = min(len(x), idx[-1] + int(post * SR))
    return x[a:b]
def soft(x, T):
    # peaks over 0.7 T are eased toward T; everything under is untouched
    a = np.abs(x); k = 0.7 * T
    over = a > k
    y = x.copy()
    y[over] = np.sign(x[over]) * (k + (T - k) * np.tanh((a[over] - k) / (T - k)))
    return y
def write(x, path, q, mp3_too=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mono = np.max(np.abs(x[:, 0] - x[:, 1])) < 1e-3
    tmp = path + ".wav"
    sf.write(tmp, x[:, 0] if mono else x, SR, subtype="PCM_16")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q), path], check=True)
    if mp3_too:
        os.makedirs(os.path.dirname(mp3_too), exist_ok=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-c:a", "libmp3lame", "-q:a", "2", mp3_too], check=True)
    os.remove(tmp)
    return mono
report = {"sounds": {}, "ambience": {}, "music": {}, "flags": []}
NEW = {"sig_": -11.0, "st_": -12.0, "gone_": -14.0}
ONE = {"ace_enter": -11.0, "boss_enter": -9.5, "fate_draw": -13.0, "attack_stopped": -13.0, "notify": -22.0, "purchase": -17.0,
       "deck_save": -19.0, "star_chip": -19.0, "unlock": -17.0, "hit": -14.0}
# ---- short sounds
x = dec(os.path.join(IN, "pack_sfx.mp3"))
on = int(np.nonzero(np.abs(x[:, 0]) > 0.1)[0][0])
pos = on + int(0.5 * SR)
for name, secs, _p in spec["sounds"]:
    n = int(round((secs + 0.4) * SR)); seg = x[pos:pos + n].copy(); pos += n
    seg[-int(0.07 * SR):] = 0.0      # the pack's mp3 smears the next sound's attack a few ms back into this slot
    raw_peak = float(np.abs(seg).max())
    t = trim(seg, min(-50.0, db(raw_peak) - 38.0))
    if len(t) < int(0.05 * SR) or raw_peak < 0.01:
        report["flags"].append("%s: silent or empty (peak %.1f dB, %.2f s)" % (name, db(raw_peak), len(t) / SR)); continue
    t = fade(t, int(0.002 * SR), min(len(t) // 3, int(0.03 * SR)))
    if name in ONE: target = ONE[name]
    elif name in TONE: target = min(-10.0, max(-24.0, TONE[name] + 3.0))
    else:
        target = -15.0
        for k, v in NEW.items():
            if name.startswith(k): target = v
    # still loud where the file ends: it was cut, not finished. A longer fade hides it.
    tail = rms(t[-int(0.08 * SR):].mean(axis=1))
    cut = tail > loud100(t) * 10 ** (-12 / 20)
    if cut: t = fade(t, 0, min(len(t) // 2, int(0.14 * SR)))
    # a duel plays its sounds 4 dB up, several at once: no single one may sit near full scale
    T = min(0.63, 10 ** ((target + 12.0) / 20))
    for _i in range(5):
        t = t * (10 ** (target / 20) / max(loud100(t), 1e-6))
        t = soft(t, T)
    pk = float(np.abs(t).max())
    if pk > 0.63: t = t * (0.63 / pk)
    mono = write(t, os.path.join(REPO, "audio/sounds", name + ".ogg"), 4, os.path.join(LISTEN, "sounds", name + ".mp3"))
    report["sounds"][name] = {"s": round(len(t) / SR, 2), "loud": round(db(loud100(t)), 1), "peak": round(db(np.abs(t).max()), 1), "raw_peak": round(db(raw_peak), 1), "mono": bool(mono), "target": target, "cut": bool(cut)}
    if len(t) / SR < 0.12: report["flags"].append("%s: very short (%.2f s)" % (name, len(t) / SR))
# ---- ambience loops
for name, secs, _p in spec["ambience"]:
    a = dec(os.path.join(IN, "amb_%s.mp3" % name)); a = trim(a, -60.0, 0.0, 0.0)
    X = int(1.5 * SR); N = len(a)
    th = np.linspace(0, np.pi / 2, X)[:, None]
    cross = a[N - X:] * np.cos(th) + a[:X] * np.sin(th)
    y = np.concatenate([a[X:N - X], cross])
    target = TONE.get("amb_" + name, -26.0)
    T = min(0.89, 10 ** ((target + 17.0) / 20))
    for _i in range(4):
        y = y * (10 ** (target / 20) / max(rms(y.mean(axis=1)), 1e-6))
        y = soft(y, T)
    # the seam: last sample to first sample must be as smooth as any neighbour pair
    seam = float(np.abs(y[0] - y[-1]).max()); typical = float(np.percentile(np.abs(np.diff(y[:, 0])), 99))
    write(y, os.path.join(REPO, "audio/ambience", name + ".ogg"), 3, os.path.join(LISTEN, "ambience", name + ".mp3"))
    report["ambience"][name] = {"s": round(len(y) / SR, 1), "rms": round(db(rms(y.mean(axis=1))), 1), "peak": round(db(np.abs(y).max()), 1), "seam": round(seam, 4), "p99step": round(typical, 4)}
    # dull or empty loops: how much the level moves over the loop
    blocks = [db(rms(y[i:i + SR].mean(axis=1))) for i in range(0, len(y) - SR, SR)]
    report["ambience"][name]["range_db"] = round(max(blocks) - min(blocks), 1)
# ---- music
MT = {"menu": -23.0, "shop": -24.0, "duel": -20.5, "duel_tense": -20.5, "duel_rival": -20.5, "duel_dark": -21.0, "duel_wild": -20.5, "turbo": -20.5,
      "finale": -20.5, "victory": -20.5, "defeat": -24.0, "city": -23.5, "academy": -23.5, "satellite": -23.5, "newdomino": -23.5, "heartland": -23.5,
      "memory": -24.5, "museum": -25.0}
for name, secs, _p in spec["music"]:
    m = dec(os.path.join(IN, "music_%s.mp3" % name)); full = len(m) / SR
    m = trim(m, -55.0, 0.01, 0.3)
    once = name in ("victory", "defeat")
    m = fade(m, int(0.05 * SR), int((1.2 if once else 3.0) * SR))
    g = 10 ** (MT[name] / 20) / max(rms(m.mean(axis=1)), 1e-6)
    pk = float(np.abs(m).max()) * g
    limited = False
    if pk > 0.94:
        # a few peaks over the ceiling: soft-limit them instead of turning the whole track down
        m = m * g; m = np.tanh(m / 0.94 * 1.0) * 0.94 if pk > 1.5 else np.clip(m, -0.94, 0.94) ; limited = True
    else:
        m = m * g
    write(m, os.path.join(REPO, "audio/music", name + ".ogg"), 4, os.path.join(LISTEN, "music", name + ".mp3"))
    blocks = [db(rms(m[i:i + 5 * SR].mean(axis=1))) for i in range(0, len(m) - 5 * SR, 5 * SR)]
    quiet = sum(1 for b in blocks if b < MT[name] - 18)
    report["music"][name] = {"asked": secs, "got": round(full, 1), "kept": round(len(m) / SR, 1), "rms": round(db(rms(m.mean(axis=1))), 1), "peak": round(db(np.abs(m).max()), 1),
                             "pre_gain_peak": round(db(pk), 1), "limited": limited, "quiet_5s_blocks": quiet, "blocks": len(blocks)}
    if abs(full - secs) > 8: report["flags"].append("music %s: asked %d s, got %.0f s" % (name, secs, full))
json.dump(report, open(os.path.join(os.path.dirname(LISTEN.rstrip("/")), "sound_report.json"), "w"), indent=1)
print("sounds %d  ambience %d  music %d  flags %d" % (len(report["sounds"]), len(report["ambience"]), len(report["music"]), len(report["flags"])))
for f in report["flags"]: print("FLAG", f)
