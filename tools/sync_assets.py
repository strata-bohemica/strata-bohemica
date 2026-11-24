#!/usr/bin/env python3
"""Copy the museum's factory assets into assets/ and write museum/data/assets.json.

usage: tools/sync_assets.py FACTORY_RETURNS_DIR [--dry-run | --check-anchors] [--allow-anchor-errors]
  --dry-run        copy nothing, write nothing (exit status 0 even when anchors are in error: read the "anchor error" lines)
  --allow-anchor-errors  write assets.json although anchors are in error (they are left out); exit status 0
  --check-anchors  only normalise the anchors of every asset.json under FACTORY_RETURNS_DIR (all revisions, no models
                   or manifest needed) and print the anchors that could not be converted

Reads museum/data/asset_manifest.json. For each "pack/ID" the newest revision is copied to assets/<ID>/<rev>/
(models, asset.json, PROVENANCE.md, Godot .import files with paths rewritten); a manifest entry may list the models to copy. The generated assets.json holds,
per model, the GLB path, animation names with durations and the anchors listed in the asset's own asset.json,
normalised by tools/anchors.py to translation + yaw_deg_about_plusY. Every anchor that is not converted (or only
partly: attached to a bone, borrowed, guessed key, world position on an anchor with a parent, no heading) is logged as
"anchor <level> ASSET/rev/model/anchor: text"; an anchor with neither position nor parent is an error: it is left out,
assets.json is NOT written and the exit status is 1 (the assets already copied stay; see --allow-anchor-errors, --dry-run).
"""
import glob, json, os, re, shutil, struct, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import anchors as anc

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = [a for a in sys.argv[1:] if not a.startswith('--')]
DRY = '--dry-run' in sys.argv
ALLOW_ERRORS = '--allow-anchor-errors' in sys.argv
CHECK = '--check-anchors' in sys.argv
if not args:
    sys.exit(__doc__)
SRC = os.path.abspath(args[0])
ERRORS = []


def log_anchors(label, entries):
    for level, name, text in entries:
        print('anchor %-13s %s/%s: %s' % (level, label, name, text))
        if level == 'error':
            ERRORS.append('%s/%s' % (label, name))


def borrow_person(aid):
    """Raw top-level anchors of the epoch's PERSON-001 (HILL-INTERVAL-001 takes its carry_anchor from HILL-PERSON-001), newest revision."""
    prefix = aid.split('-')[0]
    if aid == prefix + '-PERSON-001':
        return None
    hits = sorted(glob.glob(os.path.join(SRC, '*', prefix + '-PERSON-001', 'r*', 'asset.json')))
    return anc.person_anchors_of(json.load(open(hits[-1]))) if hits else None


def check_anchors():
    files = sorted(glob.glob(os.path.join(SRC, '**', 'asset.json'), recursive=True))
    n_models = n_anchors = 0
    for f in files:
        d = json.load(open(f))
        parts = os.path.relpath(f, SRC).split(os.sep)
        aid, rev = parts[-3], parts[-2]
        borrow = borrow_person(aid)
        for m in anc.models_of(d):
            out, log = anc.normalize_model_anchors(d, m, borrow)
            n_models += 1
            n_anchors += len(out)
            log_anchors('%s/%s/%s' % (aid, rev, anc.model_stem(m)), log)
    print('%d asset.json, %d models, %d anchors converted, %d errors' % (len(files), n_models, n_anchors, len(ERRORS)))


if CHECK:
    check_anchors()
    sys.exit(0)
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
for entry in manifest['assets']:
    rel = entry if isinstance(entry, str) else entry['id']
    only_models = None if isinstance(entry, str) else set(entry['models'])
    aid = rel.split('/')[-1]
    src_rev_dir = os.path.join(SRC, rel, newest(os.path.join(SRC, rel)))
    rev = os.path.basename(src_rev_dir)
    dst = os.path.join(ROOT, 'assets', aid, rev)
    old_prefix = 'res://art/returns/%s/%s/' % (rel, rev)
    new_prefix = 'res://assets/%s/%s/' % (aid, rev)
    asset_json = json.load(open(os.path.join(src_rev_dir, 'asset.json')))
    borrow = borrow_person(aid)
    anchors_by_stem = {}
    for m in anc.models_of(asset_json):
        anchors_by_stem[anc.model_stem(m)], log = anc.normalize_model_anchors(asset_json, m, borrow)
        log_anchors('%s/%s/%s' % (aid, rev, anc.model_stem(m)), log)
    models = {}
    for dirpath, dirs, files in os.walk(src_rev_dir):
        dirs[:] = [d for d in dirs if d not in ('source', 'checks', 'previews', 'inputs', 'fixtures', 'review', 'renders', 'tmp', 'hosts')]
        for f in sorted(files):
            p = os.path.join(dirpath, f)
            r = os.path.relpath(p, src_rev_dir)
            keep = f in ('asset.json', 'PROVENANCE.md', 'CHANGELOG.md') and dirpath == src_rev_dir
            stem = f.split('.glb')[0] if '.glb' in f else None
            keep = keep or (stem is not None and (only_models is None or stem in only_models))
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
                                      anchors=anchors_by_stem.get(f[:-4], {}))
    catalogue[aid] = dict(source=rel, rev=rev, models=models)
    print('%-12s %s  %2d models' % (aid, rev, len(models)))
if ERRORS and not DRY and not ALLOW_ERRORS:
    sys.exit("%d anchors with neither position nor parent (see \"anchor error\" lines): museum/data/assets.json not written" % len(ERRORS))
if not DRY:
    tmp = os.path.join(ROOT, 'museum/data/assets.json.tmp')
    json.dump(catalogue, open(tmp, 'w'), indent=1, ensure_ascii=False)
    os.replace(tmp, os.path.join(ROOT, 'museum/data/assets.json'))
    print('wrote museum/data/assets.json')
