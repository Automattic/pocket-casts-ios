"""WCAG contrast of text/icons in a screenshot.

usage: python3 contrast.py <screenshot.png> name:x0:y0:x1:y1 [name:x0:y0:x1:y1 ...]

Regions are in screenshot *pixels* (points x 3 on current iPhones). In each region the
most common colour is taken as the background and the colour with the highest contrast
against it as the foreground. Normal text needs 4.5:1, large text and icons 3:1.
"""
import sys
from collections import Counter

from PIL import Image


def lum(c):
    def ch(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = c[:3]
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def ratio(a, b):
    la, lb = sorted([lum(a), lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


img = Image.open(sys.argv[1]).convert("RGB")
for spec in sys.argv[2:]:
    name, x0, y0, x1, y1 = spec.split(":")
    x0, y0, x1, y1 = map(int, (x0, y0, x1, y1))
    px = [img.getpixel((x, y)) for x in range(x0, x1) for y in range(y0, y1)]
    bg = Counter(px).most_common(1)[0][0]
    fg = max(px, key=lambda p: ratio(p, bg))
    print(f"{name}: fg={'#%02x%02x%02x' % fg} bg={'#%02x%02x%02x' % bg} ratio={ratio(fg, bg):.2f}")
