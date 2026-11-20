#!/usr/bin/env python3
"""Build the village data the museum loads: terrain with flat platforms under the houses, paths, fields, stream.

usage: python tools/build_village.py          (needs numpy and scipy)

Input : museum/data/villages/breznice-layout.json  (house positions chosen by tools/organic_layout.py, seed 11)
Output: museum/data/villages/breznice.json         (houses, paths, fields, stream; world coordinates, x east, z south)
        museum/data/villages/breznice-terrain.json (heights in centimetres on a 1 m grid)

The raw terrain is the same fictional height field as in organic_layout.py (same seed, same noise). It is F/R: no real
Březnice terrain model exists in the project. Under every house and its work yard the ground is levelled.
"""
import json, math, os
import numpy as np
from scipy.ndimage import gaussian_filter, gaussian_filter1d, distance_transform_edt
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra, minimum_spanning_tree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'museum/data/villages')
layout = json.load(open(os.path.join(DATA, 'breznice-layout.json')))
SEED = layout['seed']
DISC = layout['disc_radius_m']
# house envelope (roof included) per type, from the model bounds the factory measured (asset.json export_bounds_m);
# the type of every house comes from layout['house_types'] (odd ids A, even ids B)
catalogue = json.load(open(os.path.join(ROOT, 'museum/data/assets.json')))
def asset_meta(asset_id):
    entry = catalogue[asset_id]
    return json.load(open(os.path.join(ROOT, 'assets', asset_id, entry['rev'], 'asset.json')))
def envelope(asset_id):
    """(across the ridge = house z, along the ridge = house x) in metres, symmetric about the house origin."""
    meta = asset_meta(asset_id)
    sizes = {(round(2 * max(abs(m['export_bounds_m']['min'][2]), m['export_bounds_m']['max'][2]), 2),
              round(2 * max(abs(m['export_bounds_m']['min'][0]), m['export_bounds_m']['max'][0]), 2)) for m in meta['models']}
    assert len(sizes) == 1, (asset_id, sizes)    # every finish has the same geometry
    return sizes.pop()
def wall_half(asset_id):
    """(along the ridge, across) half size of the walls in metres, from asset.json construction_measured.wall_outer_m."""
    w = asset_meta(asset_id)['construction_measured']['wall_outer_m']
    return (w['length_x'] / 2, w['width_z'] / 2)
HOUSE_TYPES = layout['house_types']
ENVELOPE = {t: envelope(a) for t, a in HOUSE_TYPES['assets'].items()}     # A about 6.4 x 15.9 m, B about 5.9 x 9.4 m
WALL_HALF = {t: wall_half(a) for t, a in HOUSE_TYPES['assets'].items()}   # (along the ridge, across), from asset.json
ROUTE_MARGIN_M = 1.5                    # the router keeps this far off the walls: grid steps cut corners and the smoothing pulls the line inward
HUB_CLEAR_M = 2.5                       # a hub (meeting point of a cluster's paths) stays this far off any wall: the roof overhangs 0.9 m
BLOCKED_COST = 1e4                      # added to a step into a blocked cell (not infinite: a hub or yard must stay reachable)
HOUSE002_HALF_LEN = 5.4                 # the tree clearances below were tuned around HOUSE-002 (10.8 m long)
YARD_LOCAL_Z = 6.0                      # work place, in the house frame, along the door normal
YARD_R = 4.2
FALLOFF_M = 7.0                         # width of the bank around a platform

# ---- raw terrain: identical to organic_layout.py -------------------------------------------------
rng = np.random.default_rng(SEED)
n = 161
xs = np.arange(-80, 80.01, 1.0)
X, Y = np.meshgrid(xs, xs)
def noise(sigma, amp):
    z = gaussian_filter(rng.standard_normal((n, n)), sigma, mode='reflect')
    return z / z.std() * amp
H = 0.045 * (X + 80) + 0.02 * (Y + 80)
H += 6.0 * np.exp(-(((X - 18) / 34) ** 2 + ((Y - 22) / 26) ** 2))
H += 4.0 * np.exp(-(((X + 6) / 24) ** 2 + ((Y + 46) / 20) ** 2))
H += 3.0 * np.exp(-(((X - 58) / 18) ** 2 + ((Y + 12) / 26) ** 2))
H += noise(12, 1.3) + noise(5, 0.18)
stream_x = lambda y: -49 + 7 * np.sin(y / 16 + 0.6) + 3 * np.sin(y / 7 + 1.2)
D = np.abs(X - stream_x(Y))
H += -5.0 * np.exp(-(D / 10) ** 2)
H0 = H.copy()

# ---- levelled platforms under houses and yards --------------------------------------------------
houses = layout['houses']
for h in houses:
    h['depth'], h['length'] = ENVELOPE[HOUSE_TYPES['by_house'][str(h['id'])]]
mask_all = np.zeros_like(H, dtype=bool)
weights, targets, rects = [], [], []
for h in houses:
    j = math.radians(h['yaw_deg']); side = 1 if h['door'] == 'E' else -1
    u = np.array([math.cos(j), math.sin(j)]); v = np.array([-math.sin(j), math.cos(j)])
    nrm = side * u
    rel_x, rel_y = X - h['x'], Y - h['y']
    a = rel_x * u[0] + rel_y * u[1]; b = rel_x * v[0] + rel_y * v[1]
    rect = (np.abs(a) <= h['depth'] / 2 + 1.0) & (np.abs(b) <= h['length'] / 2 + 1.0)
    cx, cy = h['x'] + nrm[0] * YARD_LOCAL_Z, h['y'] + nrm[1] * YARD_LOCAL_Z
    circ = np.hypot(X - cx, Y - cy) <= YARD_R
    region = rect | circ
    h['platform_z'] = float(H0[region].mean())
    w = np.clip(1.0 - distance_transform_edt(~region) / FALLOFF_M, 0.0, 1.0)
    w = w * w * w * (w * (w * 6 - 15) + 10)   # smootherstep: flat on the platform, gentle bank outside
    weights.append(w); targets.append(h['platform_z']); rects.append(rect); mask_all |= region
# all platforms at once; weights squared so the nearer platform dominates but heights blend smoothly between houses (no cliffs)
Wsum = np.maximum.reduce(weights)
num = sum(w ** 3 * t for w, t in zip(weights, targets)); den = sum(w ** 3 for w in weights) + 1e-12
T = num / den
for rect, t in zip(rects, targets):    # a house's own floor wins over a neighbour's bank or yard (long type A houses come close)
    T[rect] = t
H = H0 * (1 - Wsum) + T * Wsum
for h in houses:
    h['platform_z'] = round(h['platform_z'], 2)

# ---- height helpers ---------------------------------------------------------------------------------
def at(arr, x, y):
    return arr[int(round(y + 80)), int(round(x + 80))]
water = np.abs(X - stream_x(Y)) < 2.0
gy, gx = np.gradient(H, 1.0)

# ---- least-cost paths on the levelled terrain -----------------------------------------------------
# cells inside any house's walls (plus the routing margin) are almost closed: footpaths go round the houses, never through them
blocked = np.zeros((n, n), dtype=bool)
for h in houses:
    ridge, across = WALL_HALF[HOUSE_TYPES['by_house'][str(h['id'])]]
    j = math.radians(h['yaw_deg']); u = np.array([math.cos(j), math.sin(j)]); v = np.array([-math.sin(j), math.cos(j)])
    rel_x, rel_y = X - h['x'], Y - h['y']
    blocked |= (np.abs(rel_x * u[0] + rel_y * u[1]) <= across + ROUTE_MARGIN_M) & (np.abs(rel_x * v[0] + rel_y * v[1]) <= ridge + ROUTE_MARGIN_M)
ids = np.arange(n * n).reshape(n, n)
rows, cols, vals = [], [], []
for dj, di in [(0, 1), (1, 0), (1, 1), (1, -1)]:
    j0, j1 = 0, n - dj
    i0, i1 = (0, n - di) if di >= 0 else (-di, n)
    a = ids[j0:j1, i0:i1]; b = ids[j0 + dj:j1 + dj, i0 + di:i1 + di]
    ha = H[j0:j1, i0:i1]; hb = H[j0 + dj:j1 + dj, i0 + di:i1 + di]
    length = math.hypot(dj, di)
    w = length * (1 + 60 * ((hb - ha) / length) ** 2)
    wa = water[j0:j1, i0:i1] | water[j0 + dj:j1 + dj, i0 + di:i1 + di]
    w = w + np.where(wa, 80, 0)
    w = w + np.where(blocked[j0:j1, i0:i1] | blocked[j0 + dj:j1 + dj, i0 + di:i1 + di], BLOCKED_COST * length, 0)
    rows += [a.ravel(), b.ravel()]; cols += [b.ravel(), a.ravel()]; vals += [w.ravel(), w.ravel()]
G = coo_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(n * n, n * n)).tocsr()
node = lambda x, y: int(round(y + 80)) * n + int(round(x + 80))
def route(src, dst):
    dist, pred = dijkstra(G, directed=False, indices=src, return_predecessors=True)
    path, cur = [], dst
    while cur != src and cur >= 0:
        path.append(cur); cur = pred[cur]
    path.append(src)
    pts = np.array([(xs[p % n], xs[p // n]) for p in path[::-1]], float)
    if len(pts) > 6:
        pts[:, 0] = gaussian_filter1d(pts[:, 0], 2.5, mode='nearest'); pts[:, 1] = gaussian_filter1d(pts[:, 1], 2.5, mode='nearest')
    return pts
hubs = {}
for k in 'ABCD':
    mem = [h for h in houses if h['cluster'] == k]
    hubs[k] = (float(np.mean([q['x'] for q in mem])), float(np.mean([q['y'] for q in mem])))
def wall_dist(h, x, y):
    """Distance from (x, y) to the walls of house h (0 inside)."""
    ridge, across = WALL_HALF[HOUSE_TYPES['by_house'][str(h['id'])]]
    j = math.radians(h['yaw_deg']); rx, ry = x - h['x'], y - h['y']
    return math.hypot(max(abs(rx * math.cos(j) + ry * math.sin(j)) - across, 0.0), max(abs(-rx * math.sin(j) + ry * math.cos(j)) - ridge, 0.0))
for k, (hx, hy) in list(hubs.items()):       # a centroid can fall beside a house: take the nearest grid point that clears every wall
    if min(wall_dist(h, hx, hy) for h in houses) < HUB_CLEAR_M:
        hubs[k] = min(((float(x), float(y)) for x in xs for y in xs if min(wall_dist(h, x, y) for h in houses) >= HUB_CLEAR_M),
                      key=lambda c: math.hypot(c[0] - hx, c[1] - hy))
        print('hub', k, 'moved', round(math.hypot(hubs[k][0] - hx, hubs[k][1] - hy), 2), 'm off', round(min(wall_dist(h, hx, hy) for h in houses), 2), 'm from a wall')
paths = []
for h in houses:
    paths.append(route(node(*h['yard']), node(*hubs[h['cluster']])))
keys = list('ABCD')
full = np.zeros((4, 4))
for a_ in range(4):
    dist = dijkstra(G, directed=False, indices=node(*hubs[keys[a_]]))
    for b_ in range(4):
        full[a_, b_] = dist[node(*hubs[keys[b_]])]
mst = minimum_spanning_tree(full + 1e-6).tocoo()
for a_, b_ in zip(mst.row, mst.col):
    paths.append(route(node(*hubs[keys[a_]]), node(*hubs[keys[b_]])))
fields = []
frng = np.random.default_rng(SEED + 7)
for f in layout['fields']:
    ang = np.linspace(0, 2 * math.pi, 28, endpoint=False)
    rad = frng.uniform(9, 13) * (1 + 0.12 * np.sin(ang * 3 + frng.uniform(0, 6)) + 0.07 * np.sin(ang * 5))
    rot = frng.uniform(0, math.pi)
    poly = [(f['x'] + r * math.cos(t) * 1.25 * math.cos(rot) - r * math.sin(t) * 0.8 * math.sin(rot),
             f['y'] + r * math.cos(t) * 1.25 * math.sin(rot) + r * math.sin(t) * 0.8 * math.cos(rot)) for t, r in zip(ang, rad)]
    # keep every field inside the disc (the rim is the edge of the diorama)
    poly = [(x * min(1.0, (DISC - 4.0) / math.hypot(x, y)), y * min(1.0, (DISC - 4.0) / math.hypot(x, y))) for x, y in poly]
    fields.append(poly)
paths = [p for p in paths if len(p) > 3]
wa = layout['water_access']
kw = min(keys, key=lambda q: math.hypot(hubs[q][0] - wa[0], hubs[q][1] - wa[1]))
paths.append(route(node(*hubs[kw]), node(*wa)))

# ---- trees: oaks (spaced) and hazel scrub, kept off houses, yards, fields, paths and the stream --------------------
def min_seg_dist(px, py, pts):
    """Smallest distance from (px, py) to the polyline through pts."""
    best = 1e9
    for (x1, y1), (x2, y2) in zip(pts[:-1], pts[1:]):
        vx, vy = x2 - x1, y2 - y1
        length2 = vx * vx + vy * vy
        t = 0.0 if length2 == 0 else max(0.0, min(1.0, ((px - x1) * vx + (py - y1) * vy) / length2))
        best = min(best, math.hypot(px - (x1 + t * vx), py - (y1 + t * vy)))
    return best
def inside(poly, x, y):
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c
trng = np.random.default_rng(SEED + 11)
yard_pts = []
for h in houses:
    jj = math.radians(h['yaw_deg']); sd = 1 if h['door'] == 'E' else -1
    yard_pts.append((h['x'] + sd * math.cos(jj) * YARD_LOCAL_Z, h['y'] + sd * math.sin(jj) * YARD_LOCAL_Z))
def roof_dist(h, x, y):
    """Distance from (x, y) to the house's envelope rectangle (0 inside)."""
    j = math.radians(h['yaw_deg'])
    rx, ry = x - h['x'], y - h['y']
    a = abs(rx * math.cos(j) + ry * math.sin(j)) - h['depth'] / 2
    b = abs(-rx * math.sin(j) + ry * math.cos(j)) - h['length'] / 2
    return math.hypot(max(a, 0.0), max(b, 0.0))
stream_poly = [(float(stream_x(y)), float(y)) for y in range(-80, 81, 4)]   # full course: keeps the tree placement unchanged

# the water ends at the slab: keep the 4 m ribbon inside the disc, end points found on the same stream_x course
STREAM_W = 4.0
def stream_ends():
    lim = DISC - STREAM_W / 2
    f = lambda y: math.hypot(float(stream_x(y)), y) - lim
    ys = [float(y) for y in range(-80, 81, 4)]
    keep = [y for y in ys if f(y) <= 0]
    lo, hi = keep[0], keep[-1]
    def edge(inside, outside):
        for _ in range(60):
            mid = (inside + outside) / 2
            if f(mid) <= 0: inside = mid
            else: outside = mid
        return inside
    out = [edge(lo, lo - 4.0)] if f(lo - 4.0) > 0 or lo > -80 else []
    out += keep
    if hi < 80:
        out.append(edge(hi, hi + 4.0))
    return out
stream_ys = stream_ends()
gslope = np.degrees(np.arctan(np.hypot(gx, gy)))
trees = []
def try_place(kind, min_gap, house_gap, count, rim_bias):
    placed = 0
    for _ in range(40000):
        if placed >= count:
            break
        r = DISC - 3.0 - (DISC - 8.0) * (trng.random() ** rim_bias)
        a = trng.uniform(0, 2 * math.pi)
        x, y = r * math.cos(a), r * math.sin(a)
        if any(math.hypot(x - h['x'], y - h['y']) < house_gap for h in houses):
            continue
        if any(roof_dist(h, x, y) < house_gap - HOUSE002_HALF_LEN for h in houses):   # the same room off the ends of a long house
            continue
        if any(math.hypot(x - yx, y - yy) < 7.0 for yx, yy in yard_pts):
            continue
        if any(inside(poly, x, y) or min_seg_dist(x, y, poly + poly[:1]) < 2.5 for poly in fields):
            continue
        if any(min_seg_dist(x, y, [tuple(q) for q in pth]) < 3.5 for pth in paths):
            continue
        if min_seg_dist(x, y, stream_poly) < 6.0:
            continue
        if at(gslope, x, y) > 22:
            continue
        if any(math.hypot(x - t['x'], y - t['y']) < (min_gap if t['kind'] == kind else 4.0) for t in trees):
            continue
        trees.append(dict(kind=kind, x=x, y=y, yaw=float(trng.uniform(0, 360)), scale=float(trng.uniform(0.85, 1.25))))
        placed += 1
try_place('oak_summer', 13.0, 13.0, 14, 0.55)
try_place('hazel_leafed', 4.5, 10.0, 34, 0.5)

W = lambda x, y: [round(float(x), 2), round(float(-y), 2)]

# ---- field sites: a worker who moves (the plough) works in a field, reached by the path network ---------------------------
SITE_LENGTH = 14.0
sites = {}
for h in houses:
    if h['craft'] != 'plough':
        continue
    jj = math.radians(h['yaw_deg']); sd = 1 if h['door'] == 'E' else -1
    yard = (h['x'] + sd * math.cos(jj) * YARD_LOCAL_Z, h['y'] + sd * math.sin(jj) * YARD_LOCAL_Z)
    centres = [(sum(px for px, _ in poly) / len(poly), sum(py for _, py in poly) / len(poly)) for poly in fields]
    cx, cy = min(centres, key=lambda c: math.hypot(c[0] - yard[0], c[1] - yard[1]))
    # plough across the slope, along the contour
    g = np.array([at(gx, cx, cy), at(gy, cx, cy)])
    d = np.array([-g[1], g[0]])
    d = d / (np.linalg.norm(d) or 1.0)
    start = (cx - d[0] * SITE_LENGTH / 2, cy - d[1] * SITE_LENGTH / 2)
    commute = route(node(*yard), node(*start))
    paths.append(commute)                      # the way to the field is a visible path too
    sites[str(h['id'])] = dict(start=W(*start), dir=[round(float(d[0]), 4), round(float(-d[1]), 4)], length=SITE_LENGTH,
                               commute=[W(x, y) for x, y in commute[::2]] + [W(*start)])

# ---- export (world coordinates: x east, z south = -y) -----------------------------------------------
W = lambda x, y: [round(float(x), 2), round(float(-y), 2)]
out_houses = []
for h in houses:
    side = 1 if h['door'] == 'E' else -1
    out_houses.append(dict(id=h['id'], cluster=h['cluster'], craft=h['craft'], label=h['label'],
        pos=W(h['x'], h['y']), y=round(h['platform_z'], 2),
        yaw_deg=round((90 + h['yaw_deg']) if side > 0 else (-90 + h['yaw_deg']), 1), door=h['door']))
village = dict(id='breznice', schema=1, disc_radius_m=DISC, note='Layout and terrain are F/R: no house plan or terrain model of Březnice exists. World coordinates, x east, z south.',
    houses=out_houses, paths=[[W(x, y) for x, y in p] for p in paths], fields=[[W(x, y) for x, y in poly] for poly in fields],
    stream=dict(points=[W(float(stream_x(y)), y) for y in stream_ys], width_m=STREAM_W),
    clay_pit=W(*layout['clay_pit']), water_access=W(*layout['water_access']), sites=sites,
    trees=[dict(kind=t['kind'], pos=W(t['x'], t['y']), yaw_deg=round(t['yaw'], 1), scale=round(t['scale'], 2)) for t in trees])
json.dump(village, open(os.path.join(DATA, 'breznice.json'), 'w'), separators=(',', ':'))
heights_cm = np.round(H * 100).astype(int)
heights_cm -= int(heights_cm.min())   # lowest point is 0 cm
json.dump(dict(schema=1, size=n, step_m=1.0, x0=-80.0, z0=80.0, note='heights_cm[row*size+col]: world x = x0 + col*step, world z = z0 - row*step (rows run north); lowest point is 0',
               heights_cm=heights_cm.flatten().tolist()),
          open(os.path.join(DATA, 'breznice-terrain.json'), 'w'), separators=(',', ':'))
foot = np.zeros_like(H, dtype=bool)
for h in houses:
    j = math.radians(h['yaw_deg']); u = np.array([math.cos(j), math.sin(j)]); v = np.array([-math.sin(j), math.cos(j)])
    rx, ry = X - h['x'], Y - h['y']
    foot |= (np.abs(rx * u[0] + ry * u[1]) <= h['depth'] / 2) & (np.abs(rx * v[0] + ry * v[1]) <= h['length'] / 2)
slope_deg = np.degrees(np.arctan(np.hypot(gx, gy)))
bank = (~mask_all) & (distance_transform_edt(~mask_all) < FALLOFF_M)
print('slope under house footprints max', round(float(slope_deg[foot].max()), 2), 'deg; bank around platforms: mean', round(float(slope_deg[bank].mean()), 1), 'p95', round(float(np.percentile(slope_deg[bank], 95)), 1), 'max', round(float(slope_deg[bank].max()), 1))
print('houses', len(out_houses), 'paths', len(paths), 'fields', len(fields), 'height range m', round(float(H.max() - H.min()), 1),
      'max slope under houses (deg)', round(max(float(np.degrees(np.arctan(np.hypot(gx, gy)))[mask_all].max()), 0), 1))
