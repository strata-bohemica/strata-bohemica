#!/usr/bin/env python3
"""Copy the museum's factory assets into assets/ and write museum/data/assets.json.

usage: tools/sync_assets.py FACTORY_RETURNS_DIR [--dry-run]

Reads museum/data/asset_manifest.json. For each "pack/ID" the newest revision is copied to assets/<ID>/<rev>/
(models, asset.json, PROVENANCE.md, Godot .import files with paths rewritten). The generated assets.json holds,
per model, the GLB path, animation names with durations and the anchors listed in the asset's own asset.json.
"""
import json, os, re, shutil, struct, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = [a for a in sys.argv[1:] if not a.startswith('--')]
DRY = '--dry-run' in sys.argv
if not args:
    sys.exit(__doc__)
SRC = os.path.abspath(args[0])
manifest = json.load(open(os.path.join(ROOT, 'museum/data/asset_manifest.json')))


def glb_json(path):
    b = open(path, 'rb').read()
    n = struct.unpack('<I', b[12:16])[0]
    return json.loads(b[20:20 + n])


def clip_lengths(j):
    out = {}
    for a in j.get('animations', []):
        out[a['name']] = round(max(j['accessors'][s['input']]['max'][0] for s in a['samplers']), 4)
    return out


def newest(d):
    revs = sorted(x for x in os.listdir(d) if re.fullmatch(r'r\d+', x))
    return revs[-1]


catalogue = {}
for rel in manifest['assets']:
    aid = rel.split('/')[-1]
    src_rev_dir = os.path.join(SRC, rel, newest(os.path.join(SRC, rel)))
    rev = os.path.basename(src_rev_dir)
    dst = os.path.join(ROOT, 'assets', aid, rev)
    old_prefix = 'res://art/returns/%s/%s/' % (rel, rev)
    new_prefix = 'res://assets/%s/%s/' % (aid, rev)
    asset_json = json.load(open(os.path.join(src_rev_dir, 'asset.json')))
    anchors_by_file = {os.path.basename(m['file']): m.get('anchors', {}) for m in asset_json.get('models', [])}
    models = {}
    for dirpath, dirs, files in os.walk(src_rev_dir):
        dirs[:] = [d for d in dirs if d not in ('source', 'checks', 'previews', 'inputs', 'fixtures', 'review', 'renders', 'tmp', 'hosts')]
        for f in sorted(files):
            p = os.path.join(dirpath, f)
            r = os.path.relpath(p, src_rev_dir)
            keep = f in ('asset.json', 'PROVENANCE.md', 'CHANGELOG.md') and dirpath == src_rev_dir
            keep = keep or f.endswith('.glb') or f.endswith('.glb.import')
            keep = keep or (f.endswith('.png') and os.path.basename(dirpath) in ('models', 'textures'))
            keep = keep or (f.endswith('.png.import') and os.path.basename(dirpath) in ('models', 'textures'))
            if not keep:
                continue
            if not DRY:
                os.makedirs(os.path.dirname(os.path.join(dst, r)), exist_ok=True)
                if f.endswith('.import'):
                    text = open(p, errors='ignore').read().replace(old_prefix, new_prefix)
                    open(os.path.join(dst, r), 'w').write(text)
                else:
                    shutil.copy2(p, os.path.join(dst, r))
            if f.endswith('.glb'):
                j = glb_json(p)
                models[f[:-4]] = dict(file='%s/%s/%s' % (aid, rev, r.replace(os.sep, '/')), animations=clip_lengths(j),
                                      anchors={k: dict(translation=v.get('translation'), yaw_deg=v.get('yaw_deg_about_plusY', 0.0)) for k, v in anchors_by_file.get(f, {}).items()})
    catalogue[aid] = dict(source=rel, rev=rev, models=models)
    print('%-12s %s  %2d models' % (aid, rev, len(models)))
if not DRY:
    json.dump(catalogue, open(os.path.join(ROOT, 'museum/data/assets.json'), 'w'), indent=1, ensure_ascii=False)
    print('wrote museum/data/assets.json')
