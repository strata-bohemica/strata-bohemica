#!/usr/bin/env python3
"""Writes museum/data/villages/breznice-furrows.json: how the furrows on each field are drawn (SB-008). Standard library only.

The dimensions come from experiments with a replica of Walle-type ards from Opava (Kováčik, Pavelka, Hořínková 2022); their ranges are in the file
as `source_ranges` and every field's value must lie inside them (checks/museum_village/test_data.gd). Nothing here says that
an ard was used at Březnice: the card says the opposite. Which furrow each field gets, and the direction, are F choices:
the direction runs along the contour (the same rule the plough site uses), the dimension is drawn from the range with a fixed seed.

usage: python3 tools/build_furrows.py
"""
import json, math, os, random

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, '..', 'museum', 'data', 'villages')
village = json.load(open(os.path.join(DATA, 'breznice.json')))
terrain = json.load(open(os.path.join(DATA, 'breznice-terrain.json')))
n, step, x0, z0 = terrain['size'], terrain['step_m'], terrain['x0'], terrain['z0']
H = terrain['heights_cm']

def height(x, z):
    c = min(max(int(round((x - x0) / step)), 0), n - 1)
    r = min(max(int(round((z0 - z) / step)), 0), n - 1)
    return H[r * n + c] / 100.0

RANGES = {'depth_m': [0.08, 0.12], 'width_m': [0.04, 0.06], 'spacing_m': [0.18, 0.35]}
rng = random.Random(8)
fields = []
for poly in village['fields']:
    cx = sum(p[0] for p in poly) / len(poly)
    cz = sum(p[1] for p in poly) / len(poly)
    gx = (height(cx + 3, cz) - height(cx - 3, cz)) / 6.0
    gz = (height(cx, cz + 3) - height(cx, cz - 3)) / 6.0
    d = (-gz, gx) if math.hypot(gx, gz) > 1e-6 else (1.0, 0.0)     # along the contour
    norm = math.hypot(*d)
    f = {'dir': [round(d[0] / norm, 4), round(d[1] / norm, 4)]}
    for k, (lo, hi) in RANGES.items():
        f[k] = round(rng.uniform(lo, hi), 3)
    fields.append(f)

out = {
    'schema': 1,
    'evidence': 'R',
    'source': 'Kováčik, Pavelka, Hořínková 2022, Archeologické rozhledy 74(2): 155–179 (replica of Walle-type ards from Opava, Silesia, Lusatian Urnfield culture)',
    'note': 'Dimensions are those of the experiment, a regional analogy (R). No ard, furrow or tillage trace is attested at Březnice. The choice per field and the direction along the contour are F.',
    'source_ranges': RANGES,
    'fields': fields,
}
with open(os.path.join(DATA, 'breznice-furrows.json'), 'w', encoding='utf-8') as fh:
    json.dump(out, fh, ensure_ascii=False, indent=1)
    fh.write('\n')
print(len(fields), 'fields')
