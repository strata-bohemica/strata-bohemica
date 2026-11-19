#!/usr/bin/env python3
"""Strata Bohemica brand asset generator.

Usage: build_brand.py FONT_DIR OUT_DIR
FONT_DIR holds Fraunces.ttf (variable), PlexSans.ttf (variable), PlexMono.ttf (all SIL OFL).
Text is converted to outlines so the SVGs need no installed fonts.
Needs: uharfbuzz, fonttools. PNG/ICO export is done afterwards by export.sh
(same directory; needs rsvg-convert and ImageMagick).
"""
import os
import sys

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONT_DIR, OUT = sys.argv[1], sys.argv[2]


def num(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


class Face:
    def __init__(self, path, variations=None):
        self.face = hb.Face(open(path, "rb").read())
        self.font = hb.Font(self.face)
        if variations:
            self.font.set_variations(variations)
        self.upem = self.face.upem

    def text(self, s, size, x, y, anchor="start", tracking=0.0):
        buf = hb.Buffer()
        buf.add_str(s)
        buf.guess_segment_properties()
        hb.shape(self.font, buf, {"kern": True, "liga": True})
        k = size / self.upem
        advs = [p.x_advance * k + tracking * size for p in buf.glyph_positions]
        total = sum(advs) - tracking * size
        x0 = x - (total if anchor == "end" else total / 2 if anchor == "middle" else 0)
        parts, px = [], x0
        for info, pos, adv in zip(buf.glyph_infos, buf.glyph_positions, advs):
            sp = SVGPathPen(None, ntos=num)
            tp = TransformPen(sp, (k, 0, 0, -k, px + pos.x_offset * k, y - pos.y_offset * k))
            self.font.draw_glyph_with_pen(info.codepoint, tp)
            parts.append(sp.getCommands())
            px += adv
        return " ".join(p for p in parts if p), total


FRAUNCES = Face(os.path.join(FONT_DIR, "Fraunces.ttf"), {"wght": 600, "opsz": 72, "SOFT": 0, "WONK": 0})
SANS = Face(os.path.join(FONT_DIR, "PlexSans.ttf"), {"wght": 400, "wdth": 100})
MONO = Face(os.path.join(FONT_DIR, "PlexMono.ttf"))

# Palette
SOIL, HUMUS, HUMUS_LT, CLAY, BRONZE, BRONZE_DK = "#1E1914", "#6B5238", "#8A6B4B", "#C46A3F", "#D1A24B", "#B8862F"
PATINA, STRAW, BONE, HUMUS_DK, INK = "#5E9C8A", "#E6D5A8", "#F3EBDD", "#5A4635", "#2A211A"

# Contour geometry (120 x 120 design box, bbox centre = 62.6, 61.8)
OUTER = "M107.4 58.0 C108.1 63.4 105.9 70.0 102.8 74.9 C99.6 79.8 93.9 84.1 88.5 87.3 C83.0 90.5 76.4 92.8 70.0 94.0 C63.6 95.1 56.2 95.3 50.0 94.1 C43.7 92.8 37.2 89.9 32.4 86.4 C27.6 83.0 23.9 78.0 21.4 73.3 C19.0 68.5 17.7 63.1 17.8 58.0 C17.9 52.9 19.1 47.3 21.9 42.9 C24.7 38.6 29.6 34.3 34.6 31.9 C39.6 29.4 46.2 28.6 51.7 28.3 C57.3 28.0 62.5 29.0 67.8 30.0 C73.1 30.9 78.2 31.8 83.4 33.9 C88.6 36.0 95.1 38.5 99.1 42.6 C103.1 46.6 106.8 52.6 107.4 58.0 Z"
CLAY_P = "M93.1 60.0 C93.2 64.0 91.2 68.7 88.7 72.2 C86.3 75.6 82.2 78.7 78.3 80.9 C74.4 83.2 69.8 85.0 65.2 85.8 C60.6 86.6 55.3 86.8 50.8 85.8 C46.4 84.9 41.8 82.7 38.4 80.2 C35.0 77.7 32.3 74.2 30.6 70.9 C28.8 67.5 27.8 63.6 27.8 60.0 C27.9 56.4 28.9 52.4 31.0 49.3 C33.0 46.3 36.7 43.4 40.3 41.7 C43.8 40.0 48.3 39.5 52.2 39.0 C56.1 38.6 59.8 38.9 63.8 39.2 C67.8 39.6 72.1 39.9 76.1 41.3 C80.1 42.8 85.1 45.0 88.0 48.2 C90.8 51.3 93.0 56.0 93.1 60.0 Z"
BRONZE_P = "M78.4 62.0 C78.3 64.6 76.8 67.4 75.2 69.6 C73.6 71.8 71.2 73.7 68.8 75.1 C66.3 76.6 63.4 77.8 60.5 78.3 C57.7 78.8 54.3 78.8 51.5 78.2 C48.7 77.6 45.9 76.1 43.8 74.6 C41.7 73.0 40.0 70.9 38.8 68.8 C37.7 66.7 36.9 64.2 37.0 62.0 C37.0 59.8 37.8 57.2 39.2 55.3 C40.5 53.5 42.9 51.8 45.1 50.8 C47.3 49.7 49.9 49.2 52.3 48.8 C54.8 48.4 57.2 48.1 59.8 48.2 C62.5 48.2 65.7 48.2 68.4 49.2 C71.1 50.2 74.3 52.0 75.9 54.1 C77.6 56.2 78.5 59.4 78.4 62.0 Z"
CENTER = "M64.7 63.0 C64.6 64.3 63.9 65.6 63.1 66.6 C62.3 67.7 61.3 68.6 60.1 69.3 C59.0 70.0 57.6 70.6 56.2 70.9 C54.8 71.1 53.2 71.0 51.9 70.7 C50.5 70.4 49.2 69.7 48.2 69.0 C47.2 68.2 46.3 67.3 45.8 66.3 C45.2 65.3 44.8 64.1 44.9 63.0 C44.9 61.9 45.3 60.7 46.0 59.8 C46.7 59.0 47.8 58.2 48.8 57.7 C49.9 57.1 51.0 56.8 52.2 56.5 C53.4 56.2 54.6 55.8 56.0 55.8 C57.4 55.8 59.1 55.8 60.4 56.4 C61.7 56.9 63.2 58.0 63.9 59.1 C64.7 60.2 64.9 61.7 64.7 63.0 Z"
BX, BY = 62.6, 61.8

SCHEMES = {
    "dark": (HUMUS_LT, CLAY, BRONZE, PATINA),
    "light": (HUMUS_DK, CLAY, BRONZE_DK, PATINA),
    "mono": ("currentColor",) * 4,
}


def mark(scheme, cx, cy, s, sw=5.5):
    o, c, b, m = SCHEMES[scheme]
    return (
        f'<g transform="translate({num(cx - BX * s)} {num(cy - BY * s)}) scale({num(s)})">'
        f'<g fill="none" stroke-width="{num(sw)}" stroke-linejoin="round">'
        f'<path d="{OUTER}" stroke="{o}"/><path d="{CLAY_P}" stroke="{c}"/><path d="{BRONZE_P}" stroke="{b}"/></g>'
        f'<path d="{CENTER}" fill="{m}"/></g>'
    )


def mark_small(cx, cy, s, rings, sw):
    """Simplified mark for favicons: rings = [(path, colour)]."""
    body = "".join(f'<path d="{p}" stroke="{c}"/>' for p, c in rings)
    return (
        f'<g transform="translate({num(cx - BX * s)} {num(cy - BY * s)}) scale({num(s)})">'
        f'<g fill="none" stroke-width="{num(sw)}" stroke-linejoin="round">{body}</g>'
        f'<path d="{CENTER}" fill="{PATINA}"/></g>'
    )


def svg(w, h, body, title, extra=""):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-label="{title}"{extra}>'
        f"<title>{title}</title>{body}</svg>\n"
    )


def write(rel, content):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w", encoding="utf-8").write(content)


def path(d, fill):
    return f'<path d="{d}" fill="{fill}"/>'


def bars(x, y, w, h):
    cols = [PATINA, HUMUS, CLAY, BRONZE]
    return "".join(f'<rect x="{num(x + i * w / 4)}" y="{y}" width="{num(w / 4)}" height="{h}" fill="{c}"/>' for i, c in enumerate(cols))


# ---- logo: mark only
for sch in ("dark", "light"):
    write(f"logo/mark-{sch}.svg", svg(120, 120, mark(sch, 60, 60, 1.0), "Strata Bohemica mark"))
write("logo/mark-mono.svg", svg(120, 120, mark("mono", 60, 60, 1.0), "Strata Bohemica mark (one colour)", ' color="#000000"'))

# ---- logo: horizontal + stacked
for sch, ink, sub in (("dark", BONE, BRONZE), ("light", INK, HUMUS)):
    d, tw = FRAUNCES.text("Strata Bohemica", 72, 164, 100)
    w = int(164 + tw + 28)
    write(f"logo/logo-horizontal-{sch}.svg", svg(w, 150, mark(sch, 78, 75, 1.2) + path(d, ink), "Strata Bohemica"))
    d, tw = FRAUNCES.text("Strata Bohemica", 84, 360, 392, "middle")
    t, _ = MONO.text("DIGITAL OPEN-AIR MUSEUM · BOHEMIA", 15, 360, 440, "middle", 0.18)
    write(f"logo/logo-stacked-{sch}.svg", svg(720, 500, mark(sch, 360, 170, 2.3) + path(d, ink) + path(t, sub), "Strata Bohemica"))

# ---- avatar + icons
write("icons/avatar.svg", svg(512, 512, f'<rect width="512" height="512" fill="{SOIL}"/>' + mark("dark", 256, 256, 3.6), "Strata Bohemica avatar"))
write("icons/apple-touch-icon.svg", svg(180, 180, f'<rect width="180" height="180" fill="{SOIL}"/>' + mark("dark", 90, 90, 1.3), "Strata Bohemica icon"))
write("icons/favicon.svg", svg(64, 64, f'<rect width="64" height="64" rx="14" fill="{SOIL}"/>' + mark_small(32, 32, 0.5, [(OUTER, HUMUS_LT), (CLAY_P, CLAY), (BRONZE_P, BRONZE)], 7), "Strata Bohemica favicon"))
write("icons/favicon-32.svg", svg(32, 32, f'<rect width="32" height="32" rx="7" fill="{SOIL}"/>' + mark_small(16, 16, 0.25, [(OUTER, HUMUS_LT), (CLAY_P, CLAY)], 12), "Strata Bohemica favicon 32"))
write("icons/favicon-16.svg", svg(16, 16, f'<rect width="16" height="16" rx="3" fill="{SOIL}"/>' + mark_small(8, 8, 0.125, [(OUTER, CLAY)], 20), "Strata Bohemica favicon 16"))

# ---- social preview 1280x640
chip, _ = MONO.text("OPEN SOURCE · GODOT 4", 18, 80, 118, "start", 0.18)
t1, _ = FRAUNCES.text("Strata", 124, 80, 252, "start", -0.02)
t2, _ = FRAUNCES.text("Bohemica", 124, 80, 366, "start", -0.02)
g1, _ = SANS.text("A digital open-air museum of Bohemian prehistory.", 30, 80, 430)
g2, _ = SANS.text("Watch a village live, season by season.", 30, 80, 471)
bands = (
    f'<path d="M0 532 L170 524 L350 536 L540 526 L720 534 L930 522 L1110 532 L1280 524 V640 H0Z" fill="{PATINA}"/>'
    f'<path d="M0 556 L200 550 L380 560 L600 552 L800 562 L1000 550 L1280 558 V640 H0Z" fill="{HUMUS}"/>'
    f'<path d="M0 580 L140 588 L330 578 L520 586 L760 576 L980 586 L1280 578 V640 H0Z" fill="{CLAY}"/>'
    f'<path d="M0 608 L220 600 L420 610 L650 602 L880 610 L1090 600 L1280 608 V640 H0Z" fill="{BRONZE}"/>'
)
write(
    "social/social-preview.svg",
    svg(1280, 640, f'<rect width="1280" height="640" fill="{SOIL}"/>' + path(chip, BRONZE) + path(t1, BONE) + path(t2, BONE) + path(g1, STRAW) + path(g2, STRAW) + mark("dark", 1030, 268, 3.1) + bands, "Strata Bohemica social preview"),
)

# ---- README banners 1280x320
for sch, bg, ink, sub in (("dark", SOIL, BONE, STRAW), ("light", BONE, INK, HUMUS)):
    t, _ = FRAUNCES.text("Strata Bohemica", 92, 322, 158)
    g, _ = SANS.text("A digital open-air museum of Bohemian prehistory.", 26, 324, 208)
    body = f'<rect width="1280" height="320" fill="{bg}"/>' + mark(sch, 175, 149, 1.62) + path(t, ink) + path(g, sub) + bars(0, 298, 1280, 22)
    write(f"readme/banner-{sch}.svg", svg(1280, 320, body, "Strata Bohemica"))

# ---- README section divider
write("readme/divider.svg", svg(1280, 8, bars(0, 0, 1280, 8), "Strata Bohemica divider"))
print("svg done")
