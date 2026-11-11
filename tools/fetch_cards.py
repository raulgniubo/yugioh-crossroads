#!/usr/bin/env python3
"""
Download Yu-Gi-Oh! card data and card images from the YGOPRODeck API
into a local folder for a private project.

Usage:
  python3 fetch_cards.py --set "Legend of Blue Eyes White Dragon"
  python3 fetch_cards.py --set "Metal Raiders" --set "Starter Deck: Yugi"
  python3 fetch_cards.py --all            # every card (13k+, takes a while)
  python3 fetch_cards.py --all --no-art   # skip the cropped artwork images

Output (default ./assets):
  assets/cards.json            card data (name, type, atk, def, level, text...)
  assets/cards/<id>.jpg        full card image
  assets/art/<id>.jpg          cropped artwork only (good for 3D summon effects)

Safe to re-run: files that already exist are skipped.
Stays well under the API limit (20 requests/second) and stores images
locally, which is what the API guide asks for.
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

API = "https://db.ygoprodeck.com/api/v7/cardinfo.php"
HEADERS = {"User-Agent": "private-ygo-project/1.0"}
DELAY = 0.2  # seconds between downloads (5 per second)


USE_CURL = False


def _curl(url):
    out = subprocess.run(
        ["curl", "-sSfL", "-A", HEADERS["User-Agent"], "--max-time", "60", url],
        capture_output=True,
    )
    if out.returncode != 0:
        raise RuntimeError(out.stderr.decode(errors="replace").strip() or "curl failed")
    return out.stdout


def get(url, retries=3):
    global USE_CURL
    for attempt in range(retries):
        try:
            if USE_CURL:
                return _curl(url)
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except Exception as e:
            # Python from python.org on macOS often has no SSL certificates installed.
            # The system curl does, so switch to it for the rest of the run.
            if not USE_CURL and isinstance(getattr(e, "reason", e), ssl.SSLError) and shutil.which("curl"):
                print("  Python SSL certificates missing, using curl instead")
                USE_CURL = True
                continue
            if attempt == retries - 1:
                raise
            print(f"  retrying ({e})")
            time.sleep(2 * (attempt + 1))


def fetch_cards(sets):
    if not sets:
        return json.loads(get(API))["data"]
    cards = {}
    for s in sets:
        url = API + "?" + urllib.parse.urlencode({"cardset": s})
        print(f"Fetching card list for set: {s}")
        for c in json.loads(get(url))["data"]:
            cards[c["id"]] = c
        time.sleep(DELAY)
    return list(cards.values())


def download(url, dest):
    if dest.exists() and dest.stat().st_size > 0:
        return False
    dest.write_bytes(get(url))
    time.sleep(DELAY)
    return True


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--set", action="append", default=[], help="card set name (repeatable)")
    p.add_argument("--all", action="store_true", help="download every card")
    p.add_argument("--no-art", action="store_true", help="skip cropped artwork")
    p.add_argument("--out", default="assets", help="output folder")
    a = p.parse_args()

    if not a.set and not a.all:
        p.error('pick a set with --set "Set Name" or use --all')

    out = Path(a.out)
    (out / "cards").mkdir(parents=True, exist_ok=True)
    (out / "art").mkdir(parents=True, exist_ok=True)

    cards = fetch_cards([] if a.all else a.set)
    (out / "cards.json").write_text(json.dumps(cards, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"Saved data for {len(cards)} cards to {out / 'cards.json'}")

    failed = 0
    for i, c in enumerate(cards, 1):
        img = c["card_images"][0]  # default artwork
        cid = img["id"]
        try:
            download(img["image_url"], out / "cards" / f"{cid}.jpg")
            if not a.no_art and img.get("image_url_cropped"):
                download(img["image_url_cropped"], out / "art" / f"{cid}.jpg")
        except Exception as e:
            failed += 1
            print(f"  failed: {c['name']} ({e})")
        if i % 25 == 0 or i == len(cards):
            print(f"  {i}/{len(cards)} cards")

    print(f"Done. {failed} failed." if failed else "Done.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
