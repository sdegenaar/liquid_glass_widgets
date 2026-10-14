#!/usr/bin/env python3
"""Measure card extents and divider positions in parity captures.

Usage: measure_rows.py <capture.png> [<capture.png> ...] [--x PX]

Scans one pixel column (default x=1000, inside the card but right of the
avatar/text on the 1206px-wide iPhone 18 Pro captures) and reports, in points
(captures are 3x):

  * cards: vertical extent of a run of the card fill colour (#FFFFFF /
    #1C1C1E) once short interruptions are bridged
  * dividers: short interruptions inside a card, with their (antialiased)
    thickness and the most deviating colour

Row pitch = distance between consecutive dividers. Needs Pillow
(`pip install pillow`). This is a measuring aid for PARITY_AUDIT.md, not a
test. A column can also cross text or icons; check any odd value by eye.
"""
import sys
from PIL import Image

SCALE = 3.0
FILLS = {(255, 255, 255), (0x1C, 0x1C, 0x1E)}
MAX_GAP_PX = 12  # interruptions shorter than this are dividers, not gaps


def deviation(c, fill):
    return sum(abs(c[i] - fill[i]) for i in range(3))


def measure(path, x):
    im = Image.open(path).convert("RGB")
    h = im.size[1]
    col = [im.getpixel((x, y)) for y in range(h)]
    is_fill = [c in FILLS for c in col]

    # Maximal runs of fill / non-fill.
    segs, s = [], 0
    for y in range(1, h + 1):
        if y == h or is_fill[y] != is_fill[s]:
            segs.append((s, y, is_fill[s]))
            s = y

    cards, dividers = [], []
    cur = None  # [top, bottom]
    for i, (a, b, fill) in enumerate(segs):
        if fill and b - a > 6:
            if cur is None:
                cur = [a, b]
            else:
                cur[1] = b
        elif not fill and cur is not None and b - a < MAX_GAP_PX and i + 1 < len(segs) and segs[i + 1][2]:
            base = col[cur[0]]
            worst = max(col[a:b], key=lambda c: deviation(c, base))
            dividers.append((a, b, worst))
            cur[1] = b
        else:
            if cur is not None:
                cards.append(tuple(cur))
                cur = None
    if cur is not None:
        cards.append(tuple(cur))
    return im.size, cards, dividers


def main():
    args = sys.argv[1:]
    x = 1000
    if "--x" in args:
        k = args.index("--x")
        x = int(args[k + 1])
        del args[k:k + 2]
    for p in args:
        size, cards, dividers = measure(p, x)
        print(f"{p}  ({size[0]}x{size[1]}, x={x})")
        for s, e in cards:
            if e - s > 30:
                print(f"  card  top {s / SCALE:7.2f}pt  height {(e - s) / SCALE:7.2f}pt")
        prev = None
        for s, e, c in dividers:
            pitch = "" if prev is None else f"  pitch {(s - prev) / SCALE:6.2f}pt"
            print(
                f"  divider at {s / SCALE:7.2f}pt  {(e - s) / SCALE:4.2f}pt thick"
                f"  #{c[0]:02X}{c[1]:02X}{c[2]:02X}{pitch}"
            )
            prev = s


if __name__ == "__main__":
    main()
