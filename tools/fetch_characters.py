#!/usr/bin/env python3
"""
Download character pictures from Yugipedia for a private project.

Usage:
  python3 fetch_characters.py --out ~/Documents/Crossroads/assets

Saves <out>/characters/<key>.<ext>, which the game picks up automatically.
To use your own picture for someone (or yourself), drop a PNG/JPG named
<key>.png into that folder. Keys: yugi, kaiba, joey, jaden, yusei, yuma, player.
Re-running skips characters you already have. Use --force to re-download.
"""
import argparse
import json
import shutil
import ssl
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://yugipedia.com/api.php"
HEADERS = {"User-Agent": "private-ygo-project/1.0 (personal use)"}

CHARACTERS = {
    "yugi": "Yugi Muto", "kaiba": "Seto Kaiba", "joey": "Joey Wheeler", "mai": "Mai Valentine",
    "bakura": "Bakura Ryou", "marik": "Marik Ishtar", "pegasus": "Maximillion J. Pegasus",
    "weevil": "Weevil Underwood", "rex": "Rex Raptor",
    "jaden": "Jaden Yuki", "chazz": "Chazz Princeton", "zane": "Zane Truesdale", "alexis": "Alexis Rhodes",
    "syrus": "Syrus Truesdale", "aster": "Aster Phoenix",
    "yusei": "Yusei Fudo", "jack": "Jack Atlas", "crow": "Crow Hogan", "akiza": "Akiza Izinski", "kalin": "Kalin Kessler",
    "yuma": "Yuma Tsukumo", "shark": "Reginald Kastle", "kite": "Kite Tenjo", "vector": "Vector",
}

USE_CURL = False


def _curl(url):
    out = subprocess.run(["curl", "-sSfL", "-A", HEADERS["User-Agent"], "--max-time", "60", url], capture_output=True)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.decode(errors="replace").strip() or "curl failed")
    return out.stdout


def get(url):
    global USE_CURL
    for attempt in range(3):
        try:
            if USE_CURL:
                return _curl(url)
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except Exception as e:
            if not USE_CURL and isinstance(getattr(e, "reason", e), ssl.SSLError) and shutil.which("curl"):
                print("  Python SSL certificates missing, using curl instead")
                USE_CURL = True
                continue
            if attempt == 2:
                raise
            time.sleep(2 * (attempt + 1))


def api(**params):
    params.update({"format": "json", "redirects": 1})
    return json.loads(get(API + "?" + urllib.parse.urlencode(params)))


def page_image(title):
    """Main image of a wiki page, or None."""
    data = api(action="query", titles=title, prop="pageimages", piprop="original")
    for page in data.get("query", {}).get("pages", {}).values():
        src = page.get("original", {}).get("source")
        if src:
            return src
    # Fallback: first picture file on the page whose name mentions the character.
    data = api(action="parse", page=title, prop="images")
    first = title.split()[0].lower()
    files = [f for f in data.get("parse", {}).get("images", [])
             if first in f.lower() and f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))]
    for f in files:
        info = api(action="query", titles="File:" + f, prop="imageinfo", iiprop="url")
        for page in info.get("query", {}).get("pages", {}).values():
            ii = page.get("imageinfo")
            if ii:
                return ii[0]["url"]
    return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="assets", help="the game's card folder")
    p.add_argument("--force", action="store_true")
    a = p.parse_args()
    folder = Path(a.out).expanduser() / "characters"
    folder.mkdir(parents=True, exist_ok=True)
    failed = 0
    for key, title in CHARACTERS.items():
        existing = [f for f in folder.glob(key + ".*")]
        if existing and not a.force:
            print(f"{title}: already have it")
            continue
        try:
            url = page_image(title)
            if not url:
                print(f"{title}: no picture found")
                failed += 1
                continue
            ext = Path(urllib.parse.urlparse(url).path).suffix.lower() or ".png"
            if ext == ".jpeg":
                ext = ".jpg"
            (folder / f"{key}{ext}").write_bytes(get(url))
            print(f"{title}: saved {key}{ext}")
        except Exception as e:
            print(f"{title}: failed ({e})")
            failed += 1
        time.sleep(0.5)
    print(f"Done. Pictures are in {folder}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
