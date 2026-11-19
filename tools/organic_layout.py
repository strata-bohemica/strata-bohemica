#!/usr/bin/env python3
"""Organic village layout on uneven terrain (fictional heightfield, seeded). Output: village-organic.png + farms.json.
Run: python organic_plan.py [seed]
Coordinates: metres, x east, y north, origin at the middle of the diorama disc (radius 70 m)."""
import sys, json, math
import numpy as np
from scipy.ndimage import gaussian_filter, gaussian_filter1d
from scipy.optimize import linear_sum_assignment
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra, minimum_spanning_tree
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
from matplotlib.colors import LinearSegmentedColormap, LightSource
from matplotlib.patches import Polygon, Circle, PathPatch, Rectangle
from matplotlib.path import Path

SEED = int(sys.argv[1]) if len(sys.argv) > 1 else 11
rng = np.random.default_rng(SEED)
SOIL, BONE, STRAW, HUMUS, HUMUSL, CLAY, BRONZE, PATINA = '#1E1914', '#F3EBDD', '#E6D5A8', '#6B5238', '#8A6B4B', '#C46A3F', '#D1A24B', '#5E9C8A'
DISC = 70.0
HW, HL = 7.4, 11.4          # house footprint, ridge along its long side
YARD = 4.2                  # work-yard radius

# ---------------------------------------------------------------- terrain
n = 161
xs = np.arange(-80, 80.01, 1.0)
X, Y = np.meshgrid(xs, xs)  # rows = y

def noise(sigma, amp):
    z = gaussian_filter(rng.standard_normal((n, n)), sigma, mode='reflect')
    return z / z.std() * amp

H = 0.045 * (X + 80) + 0.02 * (Y + 80)
H += 6.0 * np.exp(-(((X - 18) / 34) ** 2 + ((Y - 22) / 26) ** 2))
H += 4.0 * np.exp(-(((X + 6) / 24) ** 2 + ((Y + 46) / 20) ** 2))
H += 3.0 * np.exp(-(((X - 58) / 18) ** 2 + ((Y + 12) / 26) ** 2))
H += noise(12, 1.3) + noise(5, 0.18)
stream_x = lambda y: -49 + 7 * np.sin(y / 16 + 0.6) + 3 * np.sin(y / 7 + 1.2)
D = np.abs(X - stream_x(Y))                      # distance to stream (east-west approximation)
H += -5.0 * np.exp(-(D / 10) ** 2)
Hs = np.array([H[i, np.argmin(np.abs(xs - stream_x(xs[i])))] for i in range(n)])[:, None] * np.ones((1, n))
above = H - Hs                                    # height above the stream bed
gy, gx = np.gradient(H, 1.0)
slope = np.degrees(np.arctan(np.hypot(gx, gy)))
R = np.hypot(X, Y)
water = D < 2.0
idx = lambda v: int(round(v + 80))
at = lambda arr, x, y: arr[idx(y), idx(x)]

# ---------------------------------------------------------------- houses
def house_poly(cx, cy, yaw, w=HW, h=HL):
    c, s = math.cos(yaw), math.sin(yaw)
    pts = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
    return [(cx + px * c - py * s, cy + px * s + py * c) for px, py in pts]


def place(rng):
    global houses, seeds, fields
    ok_seed = (slope < 4.5) & (D > 22) & (above > 2.5) & (R < 46)
    cand = np.argwhere(ok_seed)
    seeds = []
    for _ in range(4000):
        j, i = cand[rng.integers(len(cand))]
        x, y = xs[i], xs[j]
        if all(math.hypot(x - sx, y - sy) > 40 for sx, sy in seeds):
            seeds.append((x, y))
        if len(seeds) == 4:
            break
    sizes = [3, 3, 3, 3]
    houses = []
    def house_poly(cx, cy, yaw, w=HW, h=HL):
        c, s = math.cos(yaw), math.sin(yaw)
        pts = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
        return [(cx + px * c - py * s, cy + px * s + py * c) for px, py in pts]
    def too_close(cx, cy):
        return any(math.hypot(cx - h['x'], cy - h['y']) < 15 for h in houses)
    for (sx, sy), k in zip(seeds, sizes):
        placed, tries = 0, 0
        while placed < k and tries < 4000:
            tries += 1
            a, r = rng.uniform(0, 2 * math.pi), rng.uniform(9, 26)
            x, y = sx + r * math.cos(a), sy + r * math.sin(a)
            if not (abs(x) < 60 and abs(y) < 60 and math.hypot(x, y) < 56):
                continue
            if at(slope, x, y) > 6.5 or at(D, x, y) < 17 or at(above, x, y) < 2.0 or too_close(x, y):
                continue
            yaw = math.radians(float(np.clip(rng.normal(0, 8), -14, 14)))   # long axis north-south (long pits N-S, E)
            houses.append(dict(x=x, y=y, yaw=yaw, cluster=len(set(h['cluster'] for h in houses if h['cluster'] is not None and h['cluster'] < 10)) if False else None, seed=(sx, sy)))
            placed += 1
    for h in houses:
        h['cluster'] = 'ABCD'[seeds.index(h['seed'])]
    # door side: yard on the side facing away from the cluster centre, must have flat ground
    for h in houses:
        c, s = math.cos(h['yaw']), math.sin(h['yaw'])
        cx = np.mean([q['x'] for q in houses if q['cluster'] == h['cluster']]); cy = np.mean([q['y'] for q in houses if q['cluster'] == h['cluster']])
        best = None
        for side in (1, -1):
            off = side * (HW / 2 + 5.0)
            yx, yy = h['x'] + off * c, h['y'] + off * s
            sc = math.hypot(yx - cx, yy - cy) - 0.35 * at(slope, yx, yy) - (50 if at(D, yx, yy) < 6 else 0)
            for q in houses:
                if q is not h and math.hypot(yx - q['x'], yy - q['y']) < 9.5:
                    sc -= 30
            if best is None or sc > best[0]:
                best = (sc, side, yx, yy)
        h['side'], h['yard'] = best[1], (best[2], best[3])

    # ---------------------------------------------------------------- fields (outside the village, gentle slopes)
    fields = []
    cand2 = np.argwhere((slope < 5.0) & (D > 20) & (above > 1.2) & (R > 34) & (R < 60))
    print('houses placed', len(houses), 'field candidates', len(cand2))
    rng.shuffle(cand2)
    for j, i in cand2:
        x, y = xs[i], xs[j]
        if all(math.hypot(x - f['x'], y - f['y']) > 26 for f in fields) and all(math.hypot(x - h['x'], y - h['y']) > 20 for h in houses):
            ang = np.linspace(0, 2 * math.pi, 28, endpoint=False)
            rad = rng.uniform(9, 13) * (1 + 0.12 * np.sin(ang * 3 + rng.uniform(0, 6)) + 0.07 * np.sin(ang * 5))
            rot = rng.uniform(0, math.pi)
            poly = [(x + r * math.cos(t) * 1.25 * math.cos(rot) - r * math.sin(t) * 0.8 * math.sin(rot),
                     y + r * math.cos(t) * 1.25 * math.sin(rot) + r * math.sin(t) * 0.8 * math.cos(rot)) for t, r in zip(ang, rad)]
            if all(math.hypot(px, py) < DISC - 1 and at(D, px, py) > 6 for px, py in poly):
                fields.append(dict(x=x, y=y, poly=poly))
        if len(fields) == 3:
            break


    return houses, seeds, fields

for attempt in range(400):
    prng = np.random.default_rng(SEED * 1000 + attempt)
    houses, seeds, fields = [], [], []
    place(prng)
    if len(houses) == 12 and len(fields) == 3:
        break
print('placement attempt', attempt, 'houses', len(houses), 'fields', len(fields))
# ---------------------------------------------------------------- crafts
crafts = [('Koželuh', 'hide', lambda h: at(D, *h['yard'])),
          ('Hrnčířka', 'pot', lambda h: 0.9 * at(D, *h['yard'])),
          ('Omítač', 'clay', lambda h: 0.8 * at(D, *h['yard'])),
          ('Pastýřka', 'milk', lambda h: -math.hypot(*h['yard']) * 1.0),
          ('Oráč', 'plough', lambda h: min(math.hypot(h['x'] - f['x'], h['y'] - f['y']) for f in fields)),
          ('Mlatec', 'thresh', lambda h: 0.9 * min(math.hypot(h['x'] - f['x'], h['y'] - f['y']) for f in fields)),
          ('Pražič prosa', 'parch', lambda h: 0.7 * min(math.hypot(h['x'] - f['x'], h['y'] - f['y']) for f in fields) + 0.3 * math.hypot(h['x'], h['y'])),
          ('Tesař', 'wood', lambda h: -0.8 * math.hypot(*h['yard'])),
          ('Mlynářka', 'grind', lambda h: math.hypot(*h['yard'])),
          ('Kuchařka', 'cook', lambda h: math.hypot(*h['yard']) + 3),
          ('Tkadlena', 'weave', lambda h: math.hypot(*h['yard']) + 6),
          ('Předoucí', 'spin', lambda h: math.hypot(*h['yard']) + 9)]
m = min(len(crafts), len(houses))
cost = np.array([[c[2](h) for h in houses] for c in crafts])
ri, ci = linear_sum_assignment(cost)
for r_, c_ in zip(ri, ci):
    houses[c_]['label'], houses[c_]['craft'] = crafts[r_][0], crafts[r_][1]
houses.sort(key=lambda h: (h['cluster'], math.atan2(h['y'], h['x'])))
for i, h in enumerate(houses, 1):
    h['id'] = i
    h['z'] = round(float(at(H, h['x'], h['y'])), 2)
    h['slope'] = round(float(at(slope, h['x'], h['y'])), 1)

# ---------------------------------------------------------------- paths (least cost over the terrain)
def build_graph():
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
        rows += [a.ravel(), b.ravel()]; cols += [b.ravel(), a.ravel()]; vals += [w.ravel(), w.ravel()]
    return coo_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(n * n, n * n)).tocsr()
G = build_graph()
node = lambda x, y: idx(y) * n + idx(x)
def route(src, dst):
    dist, pred = dijkstra(G, directed=False, indices=src, return_predecessors=True)
    path, cur = [], dst
    while cur != src and cur >= 0:
        path.append(cur); cur = pred[cur]
    path.append(src)
    pts = np.array([(xs[p % n], xs[p // n]) for p in path[::-1]], float)
    if len(pts) > 6:
        pts[:, 0] = gaussian_filter1d(pts[:, 0], 2.5, mode='nearest'); pts[:, 1] = gaussian_filter1d(pts[:, 1], 2.5, mode='nearest')
    return pts, dist[dst]
hubs = {}
for k in 'ABCD':
    mem = [h for h in houses if h['cluster'] == k]
    hubs[k] = (np.mean([q['x'] for q in mem]), np.mean([q['y'] for q in mem]))
paths = []
for h in houses:
    p, _ = route(node(*h['yard']), node(*hubs[h['cluster']]))
    paths.append(p)
keys = list('ABCD')
full = np.zeros((4, 4))
for a in range(4):
    dist = dijkstra(G, directed=False, indices=node(*hubs[keys[a]]))
    for b in range(4):
        full[a, b] = dist[node(*hubs[keys[b]])]
mst = minimum_spanning_tree(full + 1e-6).tocoo()
for a, b in zip(mst.row, mst.col):
    p, _ = route(node(*hubs[keys[a]]), node(*hubs[keys[b]])); paths.append(p)
for f in fields:                                  # each field joins the nearest hub
    k = min(keys, key=lambda q: math.hypot(f['x'] - hubs[q][0], f['y'] - hubs[q][1]))
    p, _ = route(node(f['x'], f['y']), node(*hubs[k])); paths.append(p)
# a path to the water: nearest bank point from the hub closest to the stream
ford = None
kw = min(keys, key=lambda q: at(D, *hubs[q]))
by = hubs[kw][1]
fx = float(stream_x(by)) + 4.0
ford = (fx, by)
p, _ = route(node(*hubs[kw]), node(fx, by)); paths.append(p)
# clay pit on the bank near the Omitac
om = next(h for h in houses if h['craft'] == 'clay')
cy_ = om['y']; clay_pit = (float(stream_x(cy_)) + 11.0, cy_)

# ---------------------------------------------------------------- render
fig, ax = plt.subplots(figsize=(13, 13.8), dpi=100)
fig.subplots_adjust(left=0.01, right=0.99, top=0.9, bottom=0.14)
fig.patch.set_facecolor(SOIL); ax.set_facecolor(SOIL)
cmap = LinearSegmentedColormap.from_list('earth', ['#2f261d', '#4a3a2b', HUMUS, HUMUSL, '#b39569'])
ls = LightSource(azdeg=305, altdeg=38)
rgb = ls.shade(H, cmap=cmap, blend_mode='soft', vert_exag=1.4, dx=1, dy=1, vmin=float(np.percentile(H, 2)), vmax=float(np.percentile(H, 98)))
ax.imshow(rgb, extent=(-80.5, 80.5, -80.5, 80.5), origin='lower', zorder=1, interpolation='bicubic')
cs = ax.contour(X, Y, H, levels=np.arange(np.floor(H.min()), np.ceil(H.max()) + 1, 1.0), colors=[BONE], linewidths=0.35, alpha=0.22, zorder=2)
cs5 = ax.contour(X, Y, H, levels=np.arange(np.floor(H.min() / 5) * 5, np.ceil(H.max()) + 1, 5.0), colors=[BONE], linewidths=0.9, alpha=0.5, zorder=2)
yy = np.linspace(-80, 80, 400); cx_ = stream_x(yy)
ax.fill_betweenx(yy, cx_ - 14, cx_ + 14, color=PATINA, alpha=0.13, lw=0, zorder=2)      # flood plain (R)
ax.fill_betweenx(yy, cx_ - 1.9 - 0.7 * np.sin(yy / 5), cx_ + 1.9 + 0.7 * np.sin(yy / 5), color=PATINA, alpha=0.92, lw=0, zorder=3)  # stream
for f in fields:
    ax.add_patch(Polygon(f['poly'], closed=True, facecolor=STRAW, alpha=0.28, edgecolor=STRAW, lw=1.2, ls='--', zorder=4))
    ax.text(f['x'], f['y'], 'pole', color=STRAW, fontsize=10, ha='center', va='center', zorder=5, path_effects=[pe.withStroke(linewidth=2.5, foreground=SOIL)])
for p in paths:
    ax.plot(p[:, 0], p[:, 1], color=BONE, lw=2.4, alpha=0.72, ls=(0, (1.2, 2.6)), solid_capstyle='round', zorder=5)
ax.add_patch(Circle(clay_pit, 3.0, facecolor=CLAY, alpha=0.75, edgecolor=BONE, lw=1, zorder=5))
ax.text(clay_pit[0], clay_pit[1] - 5.2, 'jáma na hlínu', color=BONE, fontsize=8.5, ha='center', zorder=6, path_effects=[pe.withStroke(linewidth=2.5, foreground=SOIL)])
ax.plot(*ford, marker='D', ms=7, color=PATINA, mec=BONE, zorder=6)
for h in houses:
    ax.add_patch(Polygon(house_poly(h['x'], h['y'], h['yaw']), closed=True, facecolor=CLAY, edgecolor=BONE, lw=1.6, alpha=0.95, zorder=7))
    c, s = math.cos(h['yaw']), math.sin(h['yaw'])
    dxm, dym = h['side'] * HW / 2 * c, h['side'] * HW / 2 * s
    ax.plot([h['x'] + dxm - 0.9 * (-s), h['x'] + dxm + 0.9 * (-s)], [h['y'] + dym - 0.9 * c, h['y'] + dym + 0.9 * c], color=BONE, lw=4.5, zorder=8)
    ax.add_patch(Circle(h['yard'], YARD, facecolor=BRONZE, alpha=0.3, edgecolor=BRONZE, lw=1.4, zorder=6))
    ax.plot(*h['yard'], 'o', color=BRONZE, ms=5, zorder=8)
    ax.text(h['x'], h['y'], str(h['id']), color=BONE, fontsize=13, fontweight='bold', ha='center', va='center', zorder=9, path_effects=[pe.withStroke(linewidth=2.5, foreground=CLAY)])
    low = (h['yard'][1] - YARD - 3.4)
    inside = math.hypot(h['yard'][0], low) < DISC - 5
    ax.text(h['yard'][0], h['yard'][1] - YARD - 1.4 if inside else h['yard'][1] + YARD + 1.4, h['label'], color=BONE, fontsize=10, ha='center', va='top' if inside else 'bottom', zorder=9, path_effects=[pe.withStroke(linewidth=3, foreground=SOIL)])
# diorama boundary
th = np.linspace(0, 2 * math.pi, 361)
outer = [(-90, -90), (90, -90), (90, 90), (-90, 90), (-90, -90)]
verts = outer + [(DISC * math.cos(t), DISC * math.sin(t)) for t in th[::-1]]
codes = [Path.MOVETO] + [Path.LINETO] * 4 + [Path.MOVETO] + [Path.LINETO] * 360
ax.add_patch(PathPatch(Path(verts, codes), facecolor=SOIL, edgecolor='none', zorder=10))
ax.add_patch(Circle((0, 0), DISC, fill=False, edgecolor=HUMUSL, lw=3, zorder=11))
ax.set_xlim(-76, 76); ax.set_ylim(-80, 74); ax.set_aspect('equal'); ax.axis('off')
fig.text(0.04, 0.975, 'Ves podle Březnice, pozdní doba bronzová: organické rozložení na nerovném terénu', color=BONE, fontsize=19, fontweight='bold', family='serif', va='top')
fig.text(0.04, 0.945, f'Schéma M0 (varianta {SEED}). Výškopis i rozmístění jsou fikce/rekonstrukce (F/R): z Březnice se nedochoval půdorys domu ani vsi. Vrstevnice po 1 m, tučně po 5 m.', color=STRAW, fontsize=10.5, va='top')
leg = [('dům, osa sever–jih, dveře k pracovišti', CLAY), ('pracoviště před domem', BRONZE), ('stezka podle terénu (F)', BONE), ('potok a záplavová niva (R), kosočtverec = přístup k vodě', PATINA), ('pole (R)', STRAW)]
for i, (t, c) in enumerate(leg):
    fig.patches.append(Rectangle((0.04, 0.115 - i * 0.0205), 0.012, 0.012, transform=fig.transFigure, facecolor=c, edgecolor='none'))
    fig.text(0.06, 0.12 - i * 0.0205 + 0.0015, t, color=BONE, fontsize=10, va='center')
ax.plot([-20, 0], [-77, -77], color=BONE, lw=3, zorder=12); ax.text(-10, -79.6, '20 m', color=BONE, fontsize=10, ha='center', zorder=12)
ax.annotate('', xy=(70, 70), xytext=(70, 60), arrowprops=dict(arrowstyle='-|>', color=BONE, lw=2), zorder=12); ax.text(70, 71.5, 'N', color=BONE, fontsize=14, ha='center', zorder=12)
fig.savefig('village-organic.png', facecolor=SOIL, bbox_inches='tight', pad_inches=0.25)

# ---------------------------------------------------------------- data + stats
out = [dict(id=h['id'], cluster=h['cluster'], craft=h['craft'], label=h['label'], x=round(h['x'], 1), y=round(h['y'], 1), z=h['z'], yaw_deg=round(math.degrees(h['yaw']), 1),
            door='E' if h['side'] > 0 else 'W', yard=[round(h['yard'][0], 1), round(h['yard'][1], 1)], slope_deg=h['slope']) for h in houses]
json.dump(dict(seed=SEED, disc_radius_m=DISC, houses=out, fields=[dict(x=round(f['x'], 1), y=round(f['y'], 1)) for f in fields],
               clay_pit=[round(clay_pit[0], 1), round(clay_pit[1], 1)], water_access=[round(ford[0], 1), round(ford[1], 1)]), open('farms.json', 'w'), ensure_ascii=False, indent=1)
d = [math.hypot(a['x'] - b['x'], a['y'] - b['y']) for i, a in enumerate(houses) for b in houses[i + 1:]]
print('houses', len(houses), 'fields', len(fields), 'min house distance', round(min(d), 1), 'slope at houses', min(h['slope'] for h in houses), '-', max(h['slope'] for h in houses),
      'height range', round(float(H.min()), 1), round(float(H.max()), 1), 'relief at houses', round(min(h['z'] for h in houses), 1), '-', round(max(h['z'] for h in houses), 1))
print({k: sum(1 for h in houses if h['cluster'] == k) for k in 'ABCD'})
