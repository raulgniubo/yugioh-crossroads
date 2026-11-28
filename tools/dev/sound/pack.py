# Runs in the ElevenLabs sandbox: joins the short sounds in /workspace/all/<kind>/ into one wav with fixed slots.
# python3 pack.py sounds "$OUT/pack_sfx.wav" "draw:1,card:0.9,..."   (name:slot seconds = spec seconds + 0.4)
import sys, subprocess, numpy as np, soundfile as sf, glob, os
kind, out, spec = sys.argv[1], sys.argv[2], sys.argv[3]
SR = 44100
def dec(p):
    raw = subprocess.run(["ffmpeg","-v","error","-i",p,"-f","f32le","-ac","2","-ar",str(SR),"-"],capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1,2)
t = np.arange(int(0.1*SR))/SR
beep = (0.5*np.sin(2*np.pi*1000*t)).astype(np.float32)
sync = np.zeros((int(0.5*SR),2),np.float32); sync[:len(beep),0]=beep; sync[:len(beep),1]=beep
parts=[sync]; miss=[]; over=[]
for item in spec.split(","):
    name, slot = item.split(":"); n = int(round(float(slot)*SR))
    fs = glob.glob("/workspace/all/%s/%s.*" % (kind, name))
    buf = np.zeros((n,2),np.float32)
    if not fs: miss.append(name)
    else:
        a = dec(fs[0])
        if len(a) > n: over.append("%s %.2f>%s" % (name, len(a)/SR, slot)); a = a[:n]
        buf[:len(a)] = a
    parts.append(buf)
x = np.concatenate(parts)
sf.write(out, x, SR, subtype="PCM_16")
print("len %.2f s  missing %s  over %s  size %.1f MB" % (len(x)/SR, miss, over, os.path.getsize(out)/1e6))
