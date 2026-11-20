#!/usr/bin/env python3
"""Builds the table of every line a voice speaks in a duel.

  python3 tools/voices/build_lines.py <lines_src.json> <names_out.json>

lines_src.json comes from dump_lines.gd and names_out.json from dump_names.tscn (see HANDOFF).
Writes tools/voices/lines.json: one entry per (voice, language, line) with the text to speak.
A line's file is voices/<lang>/<voice>/<key>.ogg, where key = the first 12 hex digits of the md5 of
its English text (or of "call:<card id>" for a monster call-out). The game looks files up the same way.
`todo` (printed) is what has no file yet or whose spoken text changed since it was made.
"""
import hashlib, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
VOICES = json.load(open(os.path.join(HERE, "voices.json")))
NEW = json.load(open(os.path.join(HERE, "new_lines.json")))
FEMALE = set(NEW["female"])
HAS_F = {"kind", "cocky", "cool"}
PLAYER_KINDS = ["intro", "ace", "ace_lost", "chain", "negate", "fusion", "synchro", "xyz", "ritual", "trap", "big_hit", "comeback", "win", "lose"]


def key_of(s):
    return hashlib.md5(s.encode("utf-8")).hexdigest()[:12]


def voice_of(char, pers):
    return "%s_%s" % (pers, "f" if char in FEMALE and pers in HAS_F else "m")


def spoken(text, lang):
    t = text
    for a, b in NEW["say"][lang]:
        t = t.replace(a, b)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def card_say(name, lang):
    t = name.replace("HERO", "Hero").replace("HÉROE", "Héroe").replace(" - ", ", ")
    t = re.sub(r"\bLV(\d+)", (r"Level \1" if lang == "en" else r"Nivel \1"), t)
    return t


def main():
    src = json.load(open(sys.argv[1]))
    names = json.load(open(sys.argv[2]))
    es_names = json.load(open(os.path.join(ROOT, "data", "card_names_es.json")))
    es = dict(src["es"])
    es.update(NEW["es"])
    lines = {}      # (voice, lang, key) -> entry

    def add(voice, en, kind):
        if not en:
            return
        for lang in ("en", "es"):
            shown = en if lang == "en" else es.get(en)
            if shown is None:
                raise SystemExit("no Spanish for: " + en)
            lines[(voice, lang, key_of(en))] = {"voice": voice, "lang": lang, "key": key_of(en), "kind": kind, "en": en, "text": shown, "tts": spoken(shown, lang)}

    def add_call(voice, card_id, en_name, tpl_en, tpl_es, what="call"):
        k = key_of("%s:%d" % (what, card_id))
        es_name = es_names.get(str(card_id)) or en_name
        for lang, nm, tpl in (("en", en_name, tpl_en), ("es", es_name, tpl_es)):
            lines[(voice, lang, k)] = {"voice": voice, "lang": lang, "key": k, "kind": what, "en": "%s:%d" % (what, card_id),
                "text": tpl.replace("{n}", nm), "tts": spoken(tpl.replace("{n}", card_say(nm, lang)), lang)}

    # Opponents (and you, when you play as one of them): their own lines, then their personality's.
    for ck, c in sorted(src["chars"].items()):
        p = c["personality"]
        if not p:
            continue
        v = voice_of(ck, p)
        for kind, arr in c["lines"].items():
            for en in arr:
                add(v, en, kind)
        for kind, arr in src["personality"][p].items():
            for en in arr:
                add(v, en, kind)
        # The face-off: a line for a duelist who remembers the last duel, and the shout as it starts.
        for en in NEW["rematch"][p]:
            add(v, en, "rematch")
        add(v, NEW["duel"], "duel")
        ace = int(c["ace"] or names.get(c["ace_name"], 0) or 0)
        if ace:
            en_name = c["ace_name"] or names[str(ace)]
            add_call(v, ace, en_name, NEW["calls"][p][0], NEW["calls"][p][1])
    # Your own duelist: the big moments, the intro and win lines you can pick, and the famous monsters.
    for v in ("player_m", "player_f", "player_m2", "player_f2"):
        for kind, arr in src["player"].items():
            for en in arr:
                add(v, en, kind)
        for en in src["intros"] + src["wins"]:
            add(v, en, "pick")
        add(v, NEW["duel"], "duel")
        for nm in NEW["player_calls"]:
            add_call(v, int(names[nm]), nm, "{n}!", "¡{n}!")
            add_call(v, int(names[nm]), nm, NEW["player_atk"][0], NEW["player_atk"][1], "atk")
    # Lumen: what she already says, and the new lines.
    # (three voices to pick from: lumen = bright, lumen_b = warm, lumen_c = calm)
    for lv in ("lumen", "lumen_b", "lumen_c"):
        for kind, arr in src["lumen"].items():
            for en in arr:
                add(lv, en, kind)
        for kind, arr in NEW["lumen"].items():
            for en in arr:
                add(lv, en, kind)
        # Outside duels: her greeting when the game opens, and the very first start.
        for en in NEW["hello"]:
            add(lv, en, "hello")
        for en in NEW["first"]:
            add(lv, en, "first")

    out = sorted(lines.values(), key=lambda e: (e["lang"], e["voice"], e["kind"], e["key"]))
    json.dump(out, open(os.path.join(HERE, "lines.json"), "w"), ensure_ascii=False, indent=0)
    done = {}
    mp = os.path.join(HERE, "made.json")
    if os.path.exists(mp):
        done = json.load(open(mp))
    todo = [e for e in out if done.get("%s/%s/%s" % (e["lang"], e["voice"], e["key"])) != key_of(e["tts"])]
    json.dump(todo, open(os.path.join(HERE, "todo.json"), "w"), ensure_ascii=False, indent=0)
    by = {}
    for e in out:
        by[(e["lang"], e["voice"])] = by.get((e["lang"], e["voice"]), 0) + 1
    print("lines", len(out), "characters", sum(len(e["tts"]) for e in out), "todo", len(todo), "todo characters", sum(len(e["tts"]) for e in todo))
    print(" ".join("%s/%s:%d" % (k[0], k[1], n) for k, n in sorted(by.items())))


if __name__ == "__main__":
    main()
