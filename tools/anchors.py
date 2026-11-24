"""Normalise the anchors of a factory asset.json to {translation, yaw_deg_about_plusY}.

The factory returns spell anchors in many shapes (see museum/README.md, "Assets"). This module is pure
(no file access) so tools/sync_assets.py and checks/sync_assets can share it.

normalize_model_anchors(asset_json, model, borrow=None) -> (anchors, log)
  anchors: {name: {"translation": [x,y,z], "yaw_deg_about_plusY": float, "yaw_deg": float, "frame": str, "source_key": str,
                   ["parent": str], ["bone_attached": True]}}
           "yaw_deg" repeats the yaw for museum/assets/catalogue.gd, which still reads that key.
           "frame" is what the translation is relative to: "local" (parent-relative), "model" (the GLB's own space) or
           "world" (a world/rest-pose key); "source_key" is the asset.json key it came from.
  log:     list of (level, anchor name, text); level is "bone_attached", "borrowed", "heuristic", "world_with_parent",
           "degenerate_yaw" or "error". One anchor can have several lines.
           An anchor with neither a position nor a parent is an "error" and is left out of `anchors`.
"""
import math
import re

# Position keys by frame. Which group is tried first depends on whether the anchor has a parent (_frame_order):
#   with a parent    local_* keys, then the generic keys (read as parent-relative), then rest_* (model space), then world keys
#   without a parent generic keys (model space), then local_*, then rest_*, then world keys
# so "translation"/"position" can never beat "local_translation" on an anchor that hangs on a bone, and a world key is
# only used when nothing else exists.
LOCAL_POSITION_KEYS = ('local_translation', 'local_translation_m', 'local_translation_m_gltf')
GENERIC_POSITION_KEYS = ('translation', 'translation_m', 'position', 'position_m', 'pos', 'pos_m', 'xyz')
REST_POSITION_KEYS = (
    'rest_position_m', 'rest_position', 'rest_translation_m', 'rest_translation', 'rest_pose_position_m',
    'rest_position_m_gltf', 'rest_model_position', 'model_position_m', 'position_m_rest', 'translation_rest_m',
    'pos_rest_m',
)
WORLD_POSITION_KEYS = (
    'rest_world_position', 'rest_world_position_m', 'rest_world_translation', 'rest_world_translation_m',
    'rest_world_m', 'world_position', 'world_position_m', 'world_translation', 'world_translation_m',
    'world_rest_translation', 'world_rest_translation_m', 'world_rest_position', 'translation_world',
    'translation_world_rest_m', 'translation_rest_world', 'pos_world', 'rest_scene_origin_m_godot',
)
POSITION_KEYS = GENERIC_POSITION_KEYS + LOCAL_POSITION_KEYS + REST_POSITION_KEYS + WORLD_POSITION_KEYS
# Unknown key names that still look like a position (flagged "heuristic" in the log).
_POSITION_LIKE = re.compile(r'(translation|position|^pos(_|$)|^xyz$)')
_NOT_POSITION = re.compile(r'(gap|clearance|offset|rotation|axis|surface|nearest|snap|height|scale|tile|landing|drop)')

YAW_KEYS = ('yaw_deg_about_plusY', 'godot_yaw_deg_about_plusY', 'yaw_deg', 'yaw_deg_of_plus_z',
            'yaw_deg_local_plusZ', 'yaw_deg_local_+Z')
# Rotation keys follow the same frame order as the position keys (a scalar yaw key is frame-less and always first).
LOCAL_QUAT_KEYS = ('local_rotation_xyzw', 'local_rotation_xyzw_gltf')
GENERIC_QUAT_KEYS = ('rotation_xyzw',)
REST_QUAT_KEYS = ('rest_rotation_xyzw',)
WORLD_QUAT_KEYS = ('world_rotation_xyzw', 'rot_world_xyzw', 'godot_global_quat_xyzw')
QUAT_KEYS = GENERIC_QUAT_KEYS + LOCAL_QUAT_KEYS + REST_QUAT_KEYS + WORLD_QUAT_KEYS
# Where the anchor's +Z (facing) is given as a vector instead of an angle.
FORWARD_KEYS = ('forward_plusZ', 'forward_+Z', 'forward', 'forward_z', 'forward_plusZ_world', 'facing_local_plus_z_world',
                'facing_plus_z', 'facing_plusZ_world', 'plus_z_world', 'plus_z_direction', 'local_+Z_dir',
                'z_axis', 'axis_z', 'axis_z_front', 'rest_z_axis')
# A key that only says what the anchor hangs on. An anchor with one of these and no position is "bone_attached".
PARENT_KEYS = ('parent', 'parent_bone', 'parent_bone_or_node', 'parent_node', 'parent_joint', 'parent_anchor',
               'host', 'attach_to', 'attaches_to', 'attach_to_hal_person_node', 'godot_parent')
LIST_ANCHOR_FLAG = 'bone_attached'


def _vec3(v):
    if isinstance(v, (list, tuple)) and len(v) == 3 and all(isinstance(x, (int, float)) and not isinstance(x, bool) for x in v):
        return [float(x) for x in v]
    return None


def _num(v):
    return float(v) if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def _yaw_of_forward(x, z):
    """Heading of a +Z-like vector about +Y; None if it points (nearly) straight up or down."""
    if math.hypot(x, z) < 1e-3:
        return None
    return round(math.degrees(math.atan2(x, z)), 4)


def yaw_from_quat_xyzw(q):
    if not (isinstance(q, (list, tuple)) and len(q) == 4 and all(_num(c) is not None for c in q)):
        return None
    x, y, z, w = (float(c) for c in q)
    return _yaw_of_forward(2 * (x * z + w * y), 1 - 2 * (x * x + y * y))


def yaw_from_basis_columns(cols):
    """basis_columns = [X column, Y column, Z column]; the facing is the Z column."""
    if isinstance(cols, (list, tuple)) and len(cols) == 3 and _vec3(cols[2]) is not None:
        z = _vec3(cols[2])
        return _yaw_of_forward(z[0], z[2])
    return None


def _yaw_from_euler_string(s):
    """'(x, y, z)' degrees as Godot prints them (bind_pose_rotation_deg_godot); yaw is y."""
    if isinstance(s, str):
        parts = re.findall(r'-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?', s)
        if len(parts) == 3:
            return round(float(parts[1]), 4)
    return None


def _frame_order(parent, local, generic, rest, world):
    """The key groups in the order they are tried (see the table of position keys)."""
    return (local, generic, rest, world) if parent else (generic, local, rest, world)


def find_yaw(a, parent=None):
    """-> (yaw_deg_about_plusY, found, degenerate). `degenerate`: an orientation was given but its +Z points straight
    up or down, so it has no heading (the yaw then stays 0 unless another key gives one)."""
    degenerate = False
    for k in YAW_KEYS:
        y = _num(a.get(k))
        if y is not None:
            return y, True, False
    quat_keys = [k for group in _frame_order(parent, LOCAL_QUAT_KEYS, GENERIC_QUAT_KEYS, REST_QUAT_KEYS, WORLD_QUAT_KEYS) for k in group]
    for k in quat_keys:
        if a.get(k) is None:
            continue
        y = yaw_from_quat_xyzw(a.get(k))
        if y is not None:
            return y, True, False
        degenerate = degenerate or _is_quat(a.get(k))
    y = yaw_from_basis_columns(a.get('basis_columns'))
    if y is not None:
        return y, True, False
    degenerate = degenerate or _is_basis(a.get('basis_columns'))
    y = _yaw_from_euler_string(a.get('bind_pose_rotation_deg_godot'))
    if y is not None:
        return y, True, False
    for k in FORWARD_KEYS:
        v = _vec3(a.get(k))
        if v is not None:
            y = _yaw_of_forward(v[0], v[2])
            if y is not None:
                return y, True, False
            degenerate = True
    return 0.0, False, degenerate


def _is_quat(q):
    return isinstance(q, (list, tuple)) and len(q) == 4 and all(_num(c) is not None for c in q)


def _is_basis(cols):
    return isinstance(cols, (list, tuple)) and len(cols) == 3 and _vec3(cols[2]) is not None


def find_position(a, parent=None):
    """-> (translation or None, key used, heuristic?). The order of the keys depends on `parent` (see POSITION_KEYS)."""
    groups = _frame_order(parent, LOCAL_POSITION_KEYS, GENERIC_POSITION_KEYS, REST_POSITION_KEYS, WORLD_POSITION_KEYS)
    for k in [k for g in groups for k in g]:
        v = _vec3(a.get(k))
        if v is not None:
            return v, k, False
    for k, raw in a.items():
        if _POSITION_LIKE.search(k) and not _NOT_POSITION.search(k) and _vec3(raw) is not None:
            return _vec3(raw), k, True
    return None, None, False


def frame_of(key, parent=None):
    """What the position under `key` is relative to: "local" (parent-relative), "model" or "world".
    A generic key ("translation", "position", ...) is read as parent-relative when the anchor has a parent."""
    if key in LOCAL_POSITION_KEYS:
        return 'local'
    if key in WORLD_POSITION_KEYS or 'world' in key:
        return 'world'
    if key in REST_POSITION_KEYS:
        return 'model'
    if 'local' in key:
        return 'local'
    return 'local' if parent else 'model'


def _parent_of(a):
    for k in PARENT_KEYS:
        v = a.get(k)
        if isinstance(v, str) and v:
            return v
        if isinstance(v, list) and v and isinstance(v[0], str):
            return v[0]
    return None


def silhouette_letters(model, models):
    """The silhouette letters a model may use in a shared anchor's `silhouette_<x>` entries: its own letter (the end of
    the file stem) first, then the letters of the models with the same `silhouette` text, in file order. The returns say
    "silhouette a and b; c/d use the a/b positions", and c/d carry the same text as a/b (person_lt_d = long dress = _b)."""
    own = model_stem(model).split('_')[-1]
    text = model.get('silhouette')
    out = [own]
    if isinstance(text, str) and text:
        for m in models:
            letter = model_stem(m).split('_')[-1]
            if m.get('silhouette') == text and letter not in out:
                out.append(letter)
    return tuple(out)


def _variant_for(a, stem, letters=()):
    """The per-model sub-entry of a shared anchor -> (entry or None, note or None): per_model[stem], a[stem],
    a['all_models'], a['silhouette_<x>'] for the first x of `letters` (silhouette_letters), the entry whose key is the
    longest prefix of the stem (person_mig_f for person_mig_f_b). Without a silhouette text, as a last resort, the
    silhouette entries are used by position (c -> a, d -> b); that is a guess and comes back with a note."""
    if stem is None:
        return None, None
    per = a.get('per_model')
    pools = [per] if isinstance(per, dict) else []
    pools.append(a)
    for pool in pools:
        v = pool.get(stem)
        if isinstance(v, dict):
            return v, None
    v = a.get('all_models')
    if isinstance(v, dict):
        return v, None
    for x in letters or (stem.split('_')[-1],):
        v = a.get('silhouette_' + x)
        if isinstance(v, dict):
            return v, None
    for pool in pools:
        keys = [k for k, x in pool.items() if isinstance(x, dict) and stem.startswith(k + '_')]
        if keys:
            return pool[max(keys, key=len)], None
    sil = sorted(k for k, x in a.items() if k.startswith('silhouette_') and isinstance(x, dict))
    own = stem.split('_')[-1]
    if sil and len(own) == 1 and own.isalpha():
        k = sil[(ord(own.lower()) - ord('a')) % len(sil)]
        return a[k], 'no silhouette text to match: entry %r by the rule "c/d use the a/b positions"' % k
    return None, None


def _any_variant(a):
    """Last resort for a shared anchor with per-model entries but none for this stem: the first entry with a position."""
    for k, x in a.items():
        if isinstance(x, dict) and find_position(x)[0] is not None:
            return k, x
    per = a.get('per_model')
    for k, x in (per.items() if isinstance(per, dict) else ()):
        if isinstance(x, dict) and find_position(x)[0] is not None:
            return k, x
    return None, None


_BONE = re.compile(r'^(hand|foot|head|neck|pelvis|spine\d*|chest|clavicle|upperarm|forearm|thigh|shin|calf|toe)([._][LR])?$')
_IDENTITY_TRS = re.compile(r'identity\s+TRS', re.I)
_CHILD_OF = re.compile(r'child of (?!the\b)([A-Za-z_][\w.]*)')
_UNCHANGED = re.compile(r'unchanged', re.I)


def _text_of(raw):
    return ' '.join(raw[k] for k in ('note', 'type', 'meaning') if isinstance(raw.get(k), str))


def says_unchanged(raw):
    """An anchor whose only content is a note that it is the same as in the epoch's PERSON-001."""
    return isinstance(raw, dict) and find_position(raw)[0] is None and _parent_of(raw) is None and bool(_UNCHANGED.search(_text_of(raw)))


def normalize_anchor_notes(raw, stem=None, letters=(), name=None):
    """One raw anchor -> (anchor dict | None, [(level, text), ...]). No notes means a clean conversion."""
    if _vec3(raw) is not None:
        t = _vec3(raw)
        return dict(translation=t, yaw_deg_about_plusY=0.0, yaw_deg=0.0, frame='model', source_key='[x,y,z]'), []
    if isinstance(raw, list) and name and _BONE.match(name) and raw and all(isinstance(x, str) for x in raw):
        # HAL-FIRING-001 person_firing: {"hand.R": ["hand.R_prop", ...]}: the key is a bone, the list names its child nodes
        return (dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=0.0, yaw_deg=0.0, frame='local', source_key='name',
                     parent=name, bone_attached=True),
                [('bone_attached', 'bone %r with child nodes %s, no own position -> translation [0,0,0]' % (name, ', '.join(raw)))])
    if isinstance(raw, list) and raw and all(isinstance(x, str) for x in raw):
        return None, [('error', 'list of child node names %s, no position (it is only in the GLB nodes)' % ', '.join(raw))]
    if not isinstance(raw, dict):
        return None, [('error', 'no position and no parent (value is %s)' % type(raw).__name__)]
    a = dict(raw)
    notes = []
    variant, vnote = _variant_for(a, stem, letters)
    if variant is not None:
        a.update(variant)          # the position differs per person model (HILL-PERSON-001 and the other PERSON kits)
        if vnote:
            notes.append(('heuristic', vnote))
    parent = _parent_of(a)
    t, key, heuristic = find_position(a, parent)
    sibling = None
    if t is None and stem is not None:
        sibling, variant = _any_variant(a)
        if variant is not None:
            a.update(variant)
            parent = _parent_of(a)
            t, key, heuristic = find_position(a, parent)
    yaw, _, degenerate = find_yaw(a, parent)
    text = _text_of(a)
    if t is None:
        identity = a.get('local_transform') == 'identity' or _IDENTITY_TRS.search(text)
        child_of = _CHILD_OF.search(text)
        if parent is None and child_of:
            parent = child_of.group(1)
        if parent is None and not identity:
            return None, [('error', 'no position and no parent (keys: %s)' % ','.join(sorted(raw)))]
        out = dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=yaw, yaw_deg=yaw, frame='local' if parent else 'model',
                   source_key='identity' if identity else 'parent', bone_attached=True)
        if parent:
            out['parent'] = parent
            notes.append(('bone_attached', 'only parent %r, no own position -> translation [0,0,0]' % parent))
        else:
            notes.append(('heuristic', 'text says identity TRS at the origin -> translation [0,0,0], yaw 0'))
        return out, notes
    out = dict(translation=t, yaw_deg_about_plusY=yaw, yaw_deg=yaw, frame=frame_of(key, parent), source_key=key)
    if parent:
        out['parent'] = parent
    if sibling:
        notes.append(('heuristic', 'no entry for model %r: position of sibling %r' % (stem, sibling)))
    if heuristic:
        notes.append(('heuristic', 'position taken from unlisted key %r' % key))
    if parent and out['frame'] == 'world':
        notes.append(('world_with_parent', 'position from world key %r but the anchor hangs on %r: translation is world, not parent-relative' % (key, parent)))
    if degenerate:
        notes.append(('degenerate_yaw', 'the orientation points straight up or down: no heading, yaw 0 (tilt is not kept)'))
    return out, notes


def normalize_anchor(raw, stem=None, letters=(), name=None):
    """One raw anchor -> (anchor dict | None, level | None, text). level None means a clean conversion; with several
    notes the level is that of the first and the text joins them."""
    out, notes = normalize_anchor_notes(raw, stem, letters, name)
    if not notes:
        return out, None, ''
    return out, notes[0][0], '; '.join(t for _, t in notes)


def _model_file(model):
    f = model.get('file') or model.get('path')
    return f if isinstance(f, str) else ''


def model_stem(model):
    return _model_file(model).replace('\\', '/').split('/')[-1].split('.glb')[0]


def models_of(asset_json):
    ms = asset_json.get('models')
    if isinstance(ms, dict):
        ms = list(ms.values())
    return [m for m in ms if isinstance(m, dict)] if isinstance(ms, list) else []


def normalize_model_anchors(asset_json, model, borrow=None):
    """Normalised anchors of one model entry of an asset.json.

    `anchors` of a model may be a dict (name -> shape), or a list of names that are defined in the asset's
    top-level `anchors` (EBA-PERSON-001 and every other *-PERSON-001). `borrow` is the raw top-level `anchors` dict of the
    epoch's PERSON-001 (person_anchors_of): used for `carry_anchor` when the model's own only names a parent
    (HILL-INTERVAL-001) and for any anchor whose note says "unchanged" (ENE-BUILD-001, NEO-WELL-001).
    """
    stem = model_stem(model)
    letters = silhouette_letters(model, models_of(asset_json))
    spec = model.get('anchors')
    top = asset_json.get('anchors')
    if isinstance(spec, list):
        defs = top if isinstance(top, dict) else {}
        raws = {n: defs[n] if n in defs else None for n in spec if isinstance(n, str)}
        missing = {n for n, v in raws.items() if v is None}
    elif isinstance(spec, dict):
        raws, missing = spec, set()
    else:
        raws, missing = {}, set()
    borrow = borrow if isinstance(borrow, dict) else {}
    out, log = {}, []
    for name, raw in raws.items():
        if name in missing:
            log.append(('error', name, 'named in the model but not defined in the asset anchors'))
            continue
        a, notes = normalize_anchor_notes(raw, stem, letters, name)
        lent = borrow.get(name)
        wants = (a is None and says_unchanged(raw)) or (name == 'carry_anchor' and a is not None and a.get('bone_attached'))
        if wants and lent is not None:
            b, bnotes = normalize_anchor_notes(lent, stem, letters, name)
            if b is not None and not b.get('bone_attached'):
                if a is not None and a.get('parent'):
                    b['parent'] = a['parent']
                a = b
                notes = [('borrowed', '%s taken from the epoch PERSON-001 (parent %r)' % (name, b.get('parent')))] + \
                        [n for n in bnotes if n[0] not in ('bone_attached',)]
        if a is not None:
            out[name] = a
        log.extend((level, name, text) for level, text in notes)
    return out, log


def person_anchors_of(asset_json):
    """The raw top-level `anchors` of a PERSON asset.json ({} if it has none): what borrow= of normalize_model_anchors takes."""
    top = asset_json.get('anchors')
    return top if isinstance(top, dict) else {}


def carry_anchor_of(asset_json):
    """The raw top-level carry_anchor of a PERSON asset.json (None if it has none)."""
    c = person_anchors_of(asset_json).get('carry_anchor')
    return c if isinstance(c, dict) and find_position(c)[0] is not None else None
