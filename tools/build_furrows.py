#!/usr/bin/env python3
"""Writes museum/data/villages/breznice-furrows.json: how the furrows on each field are drawn (SB-008). Standard library only.

The dimensions come from experiments with a replica of Walle-type ards from Opava (Kováčik, Pavelka, Hořínková 2022); their ranges are in the file
as `source_ranges` and every field's value must lie inside them (checks/museum_village/test_data.gd). Nothing here says that
an ard was used at Březnice: the card says the opposite. Which furrow each field gets, and the direction, are F choices:
the direction runs along the contour (the same rule the plough site uses), the dimension is drawn from the range with a fixed seed.

SB-037: the furrows are not ruler-straight. The model of the research note E-furrow-irregularity.md (stationary wander around a shared arc, clamped
gaps, depth/width/profile noise, deep patches, gaps, uneven ends, clods) lives in museum/core/furrow_field.gd; this script draws each field's
parameters from a per-field seed, inside the ranges of the note. Class F, our choice: the source gives dimensions, not how irregular a field was.

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
# SB-037, research note E-furrow-irregularity.md section 3.2 (every value class F, ours; drawn per field from its seed within the note's range).
# The model itself (stationary wander, shared arc, clamps) is museum/core/furrow_field.gd; here only the per-field parameters are drawn.
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
    ts = [(p[0] * f['dir'][0] + p[1] * f['dir'][1]) for p in poly]
    length = max(ts) - min(ts)
    seed = 37000 + len(fields)                       # per field, so the fields differ and a rebuild gives the same file
    r = random.Random(seed)
    f['seed'] = seed
    f['spacing_m'] = round(r.uniform(0.24, 0.28), 3)                       # P
    f['depth_m'] = round(r.uniform(0.095, 0.105), 4)                       # D0, dry field
    f['width_m'] = round(0.05 + 0.25 * (f['depth_m'] - 0.10), 5)           # 5 + 0.25 (D - 10) cm
    f['wet'] = round(r.uniform(0.3, 1.0), 2) if r.random() < 0.34 else 0.0  # wet share: deeper, wider
    f['rho'] = round(r.uniform(0.70, 0.85), 3)
    f['wander_lambda_m'] = round(r.uniform(10, 16), 2)
    f['arc'] = round(r.choice([-1, 1]) * r.uniform(0.010, 0.025), 4)       # signed kappa, fraction of the furrow length
    f['turn_deg'] = round(r.uniform(3, 7), 2)
    f['turn_len_m'] = round(min(r.uniform(2, 5), length / 4), 2)
    f['lambda_m'] = round(r.uniform(4, 12), 2)                             # depth and width noise
    f['u_share'] = round(r.uniform(0.3, 0.7), 2)
    f['patch_p'] = round(r.uniform(0.0, 0.3), 3)                           # deep patch per furrow
    f['interrupt_per_10m'] = round(r.uniform(0.0, 1.0), 2)
    f['interrupt_gap_m'] = round(r.uniform(0.2, 0.8), 2)
    f['clods'] = {'cover': round(r.uniform(0.02, 0.08), 3), 'size_m': round(r.uniform(0.10, 0.25), 3)}
    fields.append(f)

out = {
    'schema': 1,
    'evidence': 'R',
    'source': 'Kováčik, Pavelka, Hořínková 2022, Archeologické rozhledy 74(2): 155–179 (replica of Walle-type ards from Opava, Silesia, Lusatian Urnfield culture)',
    'note': 'Dimensions are those of the experiment, a regional analogy (R). No ard, furrow or tillage trace is attested at Březnice. The choice per field and the direction along the contour are F.',
    'source_ranges': RANGES,
    'irregularity': 'F: stationary wander of each furrow, a shared gentle arc and end turn-in, depth, width, U/V profile, deep patches, lifted gaps, uneven ends and clods follow research note E-furrow-irregularity (SB-037); every amplitude and share is our choice, nothing about the irregularity of a field is attested, nor any ard at Březnice',
    'deep_patch': {'depth_m': [0.12, 0.18], 'width_max_m': 0.08, 'max_share': 0.02, 'length_m': [0.3, 1.0]},
    'gap_clamp_m': [0.187, 0.35],
    'heading_tan_max': 0.28,
    'fields': fields,
}
with open(os.path.join(DATA, 'breznice-furrows.json'), 'w', encoding='utf-8') as fh:
    json.dump(out, fh, ensure_ascii=False, indent=1)
    fh.write('\n')
print(len(fields), 'fields')
