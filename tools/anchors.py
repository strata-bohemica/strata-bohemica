"""Normalise the anchors of a factory asset.json to {translation, yaw_deg_about_plusY}.

The factory returns spell anchors in many shapes (see museum/README.md, "Assets"). This module is pure
(no file access) so tools/sync_assets.py and checks/sync_assets can share it.

normalize_model_anchors(asset_json, model, ...) -> (anchors, log)
  anchors: {name: {"translation": [x,y,z], "yaw_deg_about_plusY": float, "yaw_deg": float, ["parent": str], ["bone_attached": True]}}
           "yaw_deg" repeats the yaw for museum/assets/catalogue.gd, which still reads that key.
  log:     list of (level, anchor name, text); level is "bone_attached", "borrowed", "heuristic" or "error".
           An anchor with neither a position nor a parent is an "error" and is left out of `anchors`.
"""
import math
import re

# Position keys, first match wins. Local (parent-relative) keys come before world/rest keys so that an anchor
# that has both keeps the frame that "translation" always meant; world keys are the fallback.
POSITION_KEYS = (
    'translation', 'translation_m', 'position', 'position_m', 'pos', 'pos_m', 'xyz',
    'local_translation', 'local_translation_m', 'local_translation_m_gltf',
    'rest_position_m', 'rest_position', 'rest_translation_m', 'rest_translation', 'rest_pose_position_m',
    'rest_position_m_gltf', 'rest_model_position', 'model_position_m', 'position_m_rest', 'translation_rest_m',
    'pos_rest_m',
    'rest_world_position', 'rest_world_position_m', 'rest_world_translation', 'rest_world_translation_m',
    'rest_world_m', 'world_position', 'world_position_m', 'world_translation', 'world_translation_m',
    'world_rest_translation', 'world_rest_translation_m', 'world_rest_position', 'translation_world',
    'translation_world_rest_m', 'translation_rest_world', 'pos_world', 'rest_scene_origin_m_godot',
)
# Unknown key names that still look like a position (flagged "heuristic" in the log).
_POSITION_LIKE = re.compile(r'(translation|position|^pos(_|$)|^xyz$)')
_NOT_POSITION = re.compile(r'(gap|clearance|offset|rotation|axis|surface|nearest|snap|height|scale|tile|landing|drop)')

YAW_KEYS = ('yaw_deg_about_plusY', 'godot_yaw_deg_about_plusY', 'yaw_deg', 'yaw_deg_of_plus_z',
            'yaw_deg_local_plusZ', 'yaw_deg_local_+Z')
QUAT_KEYS = ('rotation_xyzw', 'local_rotation_xyzw', 'local_rotation_xyzw_gltf', 'world_rotation_xyzw',
             'rot_world_xyzw', 'rest_rotation_xyzw', 'godot_global_quat_xyzw')
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
    if math.hypot(x, z) < 1e-6:
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


def find_yaw(a):
    """-> (yaw_deg_about_plusY, found)."""
    for k in YAW_KEYS:
        y = _num(a.get(k))
        if y is not None:
            return y, True
    for k in QUAT_KEYS:
        y = yaw_from_quat_xyzw(a.get(k))
        if y is not None:
            return y, True
    y = yaw_from_basis_columns(a.get('basis_columns'))
    if y is not None:
        return y, True
    y = _yaw_from_euler_string(a.get('bind_pose_rotation_deg_godot'))
    if y is not None:
        return y, True
    for k in FORWARD_KEYS:
        v = _vec3(a.get(k))
        if v is not None:
            y = _yaw_of_forward(v[0], v[2])
            if y is not None:
                return y, True
    return 0.0, False


def find_position(a):
    """-> (translation or None, key used, heuristic?)."""
    for k in POSITION_KEYS:
        v = _vec3(a.get(k))
        if v is not None:
            return v, k, False
    for k, raw in a.items():
        if _POSITION_LIKE.search(k) and not _NOT_POSITION.search(k) and _vec3(raw) is not None:
            return _vec3(raw), k, True
    return None, None, False


def _parent_of(a):
    for k in PARENT_KEYS:
        v = a.get(k)
        if isinstance(v, str) and v:
            return v
        if isinstance(v, list) and v and isinstance(v[0], str):
            return v[0]
    return None


def _variant_for(a, stem):
    """The per-model sub-entry of a shared anchor: per_model[stem], a[stem], a['all_models'], a['silhouette_<x>']
    for a stem ending in _<x>, or the entry whose key is the longest prefix of the stem (person_mig_f for person_mig_f_b)."""
    if stem is None:
        return None
    per = a.get('per_model')
    pools = [per] if isinstance(per, dict) else []
    pools.append(a)
    for pool in pools:
        v = pool.get(stem)
        if isinstance(v, dict):
            return v
    v = a.get('all_models')
    if isinstance(v, dict):
        return v
    v = a.get('silhouette_' + stem.split('_')[-1])
    if isinstance(v, dict):
        return v
    for pool in pools:
        keys = [k for k, x in pool.items() if isinstance(x, dict) and stem.startswith(k + '_')]
        if keys:
            return pool[max(keys, key=len)]
    return None


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


def normalize_anchor(raw, stem=None):
    """One raw anchor -> (anchor dict | None, level | None, text). level None means a clean conversion."""
    if _vec3(raw) is not None:
        t = _vec3(raw)
        return dict(translation=t, yaw_deg_about_plusY=0.0, yaw_deg=0.0), None, ''
    if not isinstance(raw, dict):
        return None, 'error', 'no position and no parent (value is %s)' % type(raw).__name__
    a = dict(raw)
    variant = _variant_for(a, stem)
    if variant is not None:
        a.update(variant)          # the position differs per person model (HILL-PERSON-001 and the other PERSON kits)
    t, key, heuristic = find_position(a)
    sibling = None
    if t is None and stem is not None:
        sibling, variant = _any_variant(a)
        if variant is not None:
            a.update(variant)
            t, key, heuristic = find_position(a)
    yaw, _ = find_yaw(a)
    parent = _parent_of(a)
    if t is None:
        if parent is None and a.get('local_transform') != 'identity':
            return None, 'error', 'no position and no parent (keys: %s)' % ','.join(sorted(raw))
        out = dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=yaw, yaw_deg=yaw, bone_attached=True)
        if parent:
            out['parent'] = parent
        return out, 'bone_attached', 'only parent %r, no own position -> translation [0,0,0]' % (parent or 'identity')
    out = dict(translation=t, yaw_deg_about_plusY=yaw, yaw_deg=yaw)
    if parent:
        out['parent'] = parent
    if sibling:
        return out, 'heuristic', 'no entry for model %r: position of sibling %r' % (stem, sibling)
    if heuristic:
        return out, 'heuristic', 'position taken from unlisted key %r' % key
    return out, None, ''


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


def normalize_model_anchors(asset_json, model, borrow_carry=None):
    """Normalised anchors of one model entry of an asset.json.

    `anchors` of a model may be a dict (name -> shape), or a list of names that are defined in the asset's
    top-level `anchors` (EBA-PERSON-001 and every other *-PERSON-001). borrow_carry is the raw `carry_anchor`
    of the epoch's PERSON-001, used when the model's own carry_anchor only names a parent (HILL-INTERVAL-001).
    """
    stem = model_stem(model)
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
    out, log = {}, []
    for name, raw in raws.items():
        if name in missing:
            log.append(('error', name, 'named in the model but not defined in the asset anchors'))
            continue
        a, level, text = normalize_anchor(raw, stem)
        if level == 'bone_attached' and name == 'carry_anchor' and borrow_carry is not None:
            b, blevel, _ = normalize_anchor(borrow_carry, stem)
            if b is not None and not b.get('bone_attached'):
                b['parent'] = a.get('parent', b.get('parent'))
                a, level, text = b, 'borrowed', 'carry_anchor taken from the epoch PERSON-001 (parent %r)' % b.get('parent')
        if a is not None:
            out[name] = a
        if level:
            log.append((level, name, text))
    return out, log


def carry_anchor_of(asset_json):
    """The raw top-level carry_anchor of a PERSON asset.json (None if it has none)."""
    top = asset_json.get('anchors')
    c = top.get('carry_anchor') if isinstance(top, dict) else None
    return c if isinstance(c, dict) and find_position(c)[0] is not None else None
