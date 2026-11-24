"""Anchor normalisation of tools/sync_assets.py (tools/anchors.py).

Run: python3 -m unittest discover -s checks/sync_assets   (or checks/museum_village/run.sh sync_assets)

Fixtures are real anchors copied from the factory returns' asset.json (CC BY 4.0, same licence as the models):
  real_anchors.json  one anchor per position key / yaw key, as spelled in the source
  real_assets.json   small asset.json excerpts: the shapes named in the card (HILL-RAMPART gate_pincer, HILL-PIT
                     grainpit_deep, HILL-CRAFT rotation_xyzw, HILL-ADORN basis_columns, HILL-PERSON per_model, ...)
Expected numbers below are typed from the source files, not computed by the code under test.
"""
import json, math, os, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(HERE, '..', '..', 'tools')
sys.path.insert(0, TOOLS)
import anchors as anc  # noqa: E402

REAL_ANCHORS = json.load(open(os.path.join(HERE, 'real_anchors.json')))
REAL_ASSETS = json.load(open(os.path.join(HERE, 'real_assets.json')))


def model_anchors(asset, stem, carry=None):
    a = REAL_ASSETS[asset]
    m = next(x for x in a['models'] if anc.model_stem(x) == stem)
    out, log = anc.normalize_model_anchors(a, m, carry)
    return out, log


def assert_anchor(tc, got, translation, yaw, places=4, yaw_places=None):
    """Fails for a missing anchor, translation None or all zero where the source is not zero, and a lost yaw."""
    tc.assertIsNotNone(got, 'anchor missing')
    tc.assertIsNotNone(got['translation'], 'translation is None')
    tc.assertEqual(len(got['translation']), 3)
    for g, e in zip(got['translation'], translation):
        tc.assertAlmostEqual(g, e, places=places)
    yaw_places = places if yaw_places is None else yaw_places
    tc.assertAlmostEqual(got['yaw_deg_about_plusY'], yaw, places=yaw_places)
    tc.assertAlmostEqual(got['yaw_deg'], yaw, places=yaw_places)   # alias read by museum/assets/catalogue.gd


class PositiveControls(unittest.TestCase):
    def test_hill_rampart_gate_pincer_pos_and_yaw(self):
        out, log = model_anchors('HILL-RAMPART-001', 'gate_pincer')
        assert_anchor(self, out['walk_post_1'], [-2.65, 2.6, 3.6], 90.0)
        assert_anchor(self, out['walk_post_2'], [0.0, 2.6, 7.3], -180.0)
        self.assertEqual(log, [])

    def test_hill_pit_grainpit_deep_position_m_and_yaw(self):
        out, _ = model_anchors('HILL-PIT-001', 'grainpit_deep')
        assert_anchor(self, out['ladder_bottom'], [-0.3994, -2.4, 0.0], 90.0)
        assert_anchor(self, out['lid_rest'], [-0.6928, 0.004, 0.4], 60.0)

    def test_craft_rotation_xyzw(self):
        out, _ = model_anchors('HILL-CRAFT-001', 'smithy_shed')
        assert_anchor(self, out['bellows_stand'], [-1.48, 0.012, -0.75], 90.0, places=2)   # quaternion (0, .70711, 0, .70711)
        assert_anchor(self, out['smith_stand'], [0.55, 0.012, -0.66], 0.0)
        self.assertEqual(out['bellows_stand']['parent'], 'smithy_shed')
        out, _ = model_anchors('HILL-CRAFT-001', 'charcoal_stack')
        assert_anchor(self, out['stack_rake_1'], [1.125, 0.0, 1.94856], -150.0, places=2)    # y -.96593, w .25882
        assert_anchor(self, out['stack_rake_2'], [-1.44627, 0.0, 1.7236], 140.0, places=2)   # y .93969, w .34202

    def test_adorn_basis_columns(self):
        out, _ = model_anchors('HILL-ADORN-001', 'temple_ring_s_small')
        assert_anchor(self, out['attach_bronze'], [0.0, 0.0, 0.007], 0.0)           # translation_m, identity basis
        assert_anchor(self, out['display_bronze'], [-0.00069, -0.00505, 0.007], 0.0)  # Z column is vertical: no heading

    def test_basis_columns_heading(self):
        # +90 deg about +Y: X column (0,0,-1), Y (0,1,0), Z column (1,0,0)
        a, level, _ = anc.normalize_anchor(dict(translation_m=[1, 2, 3], basis_columns=[[0, 0, -1], [0, 1, 0], [1, 0, 0]]))
        self.assertIsNone(level)
        assert_anchor(self, a, [1, 2, 3], 90.0)

    def test_fence_yaw_is_not_lost(self):
        out, _ = model_anchors('FENCE-001', 'gate_hurdle_open')
        assert_anchor(self, out['open_stand'], [0.62, 0.0, 0.42], 180.0)
        assert_anchor(self, out['latch'], [0.0, 1.0, -0.835], 90.0)

    def test_eba_pottery_local_wins_over_world(self):
        out, _ = model_anchors('EBA-POTTERY-002', 'drying_shelf_row')
        assert_anchor(self, out['shelf_spot_1'], [-0.93, 0.04, 0.0], 0.0)

    def test_world_position_alone(self):
        raw = dict(REAL_ASSETS['EBA-POTTERY-002']['models'][0]['anchors']['shelf_spot_1'])
        for k in ('local_translation', 'local_rotation_xyzw'):
            del raw[k]
        a, level, _ = anc.normalize_anchor(raw)
        self.assertEqual(level, 'world_with_parent')     # parent drying_shelf_row, only a world position
        self.assertEqual((a['frame'], a['source_key']), ('world', 'world_position'))
        assert_anchor(self, a, [-0.93, 0.04, 0.0], 0.0)

    def test_bare_xyz_list(self):
        out, log = model_anchors('ROM-POTTERY-001', 'terrine_fine')
        assert_anchor(self, out['rim_center'], [0.0, 0.11, 0.0], 0.0)
        self.assertEqual(log, [])

    def test_model_key_path_and_file(self):
        self.assertEqual(anc.model_stem(dict(path='models/gate_pincer.glb')), 'gate_pincer')
        self.assertEqual(anc.model_stem(dict(file='models/gate_pincer.glb.import')), 'gate_pincer')

    def test_every_position_key_and_yaw_key_of_the_returns(self):
        listed = set(anc.POSITION_KEYS) | set(anc.YAW_KEYS)
        for label, case in REAL_ANCHORS.items():
            kind, key = label.split(':', 1)
            with self.subTest(label, source='%s %s %s' % (case['source'], case['model'], case['name'])):
                self.assertIn(key, listed)
                a, level, _ = anc.normalize_anchor(case['raw'], case['model'])
                world = kind == 'pos' and ('world' in key or key == 'rest_scene_origin_m_godot')
                if world and a.get('parent'):
                    self.assertEqual(level, 'world_with_parent')     # the position is world, the anchor hangs on a parent
                else:
                    self.assertIsNone(level)
                if world:
                    self.assertEqual(a['frame'], 'world')
                if kind == 'pos':
                    self.assertEqual(a['source_key'], key)
                    self.assertEqual(a['translation'], [float(v) for v in case['raw'][key]])
                    self.assertTrue(any(a['translation']), 'all zero')
                else:
                    self.assertEqual(a['yaw_deg_about_plusY'], case['raw'][key])
                    self.assertNotEqual(a['yaw_deg_about_plusY'], 0.0)

    def test_the_card_key_lists_are_covered(self):
        pos = 'translation translation_m position position_m pos pos_m xyz rest_position_m rest_world_position local_translation local_translation_m_gltf world_position'.split()
        yaw = 'yaw_deg_about_plusY yaw_deg yaw_deg_of_plus_z godot_yaw_deg_about_plusY'.split()
        for k in pos:
            a, level, _ = anc.normalize_anchor({k: [1.0, 2.0, 3.0]})
            self.assertEqual(a['translation'], [1.0, 2.0, 3.0], k)
            self.assertIsNone(level, k)
        for k in yaw:
            a, _, _ = anc.normalize_anchor({'pos': [1, 2, 3], k: 33.5})
            self.assertEqual(a['yaw_deg_about_plusY'], 33.5, k)
        for k in ('rotation_xyzw', 'local_rotation_xyzw'):
            a, _, _ = anc.normalize_anchor({'pos': [1, 2, 3], k: [0, math.sin(math.radians(20)), 0, math.cos(math.radians(20))]})
            self.assertAlmostEqual(a['yaw_deg_about_plusY'], 40.0, places=3, msg=k)


class SharedAndAttached(unittest.TestCase):
    def test_hill_person_position_from_per_model(self):
        a = REAL_ASSETS['HILL-PERSON-001']
        rider, lady = (anc.normalize_model_anchors(a, m)[0] for m in a['models'])
        assert_anchor(self, rider['temple_ring.L'], [0.07473, 0.085, 0.06098], 0.0)
        assert_anchor(self, lady['temple_ring.L'], [0.08335, 0.07769, 0.06871], 0.0)
        self.assertEqual(rider['temple_ring.L']['parent'], 'head')
        self.assertNotIn('bone_attached', rider['temple_ring.L'])

    def test_hill_person_carry_anchor_has_own_translation_and_rotation(self):
        a = REAL_ASSETS['HILL-PERSON-001']
        out, _ = anc.normalize_model_anchors(a, a['models'][0])
        c = out['carry_anchor']
        self.assertAlmostEqual(c['translation'][0], 0.2235044538974762, places=9)
        self.assertAlmostEqual(c['translation'][1], -0.1527375727891922, places=9)
        self.assertAlmostEqual(c['yaw_deg_about_plusY'], math.degrees(math.atan2(2 * (-0.05528111010789871 * 0.04663475975394249 + 0.9938109517097473 * 0.08431489765644073), 1 - 2 * (0.04663475975394249 ** 2 + 0.08431489765644073 ** 2))), places=3)

    def test_anchors_as_list_of_names(self):
        a = REAL_ASSETS['EBA-PERSON-001']
        out, log = anc.normalize_model_anchors(a, a['models'][0])
        self.assertEqual(sorted(out), sorted(a['models'][0]['anchors']))
        assert_anchor(self, out['pin_shoulder.L'], [0.072, 0.1217, 0.022], out['pin_shoulder.L']['yaw_deg_about_plusY'])
        self.assertNotEqual(out['pin_shoulder.L']['yaw_deg_about_plusY'], 0.0)
        self.assertAlmostEqual(out['wrist_ornament.L']['yaw_deg_about_plusY'], 170.0, places=0)   # quaternion (-.9962, 0, -.0872, 0)
        self.assertEqual(log, [])

    def test_name_without_definition_is_an_error_not_a_crash(self):
        out, log = anc.normalize_model_anchors({}, dict(path='models/x.glb', anchors=['hitch']))
        self.assertEqual(out, {})
        self.assertEqual(log[0][:2], ('error', 'hitch'))

    def test_parent_only_is_bone_attached(self):
        a = REAL_ASSETS['HILL-INTERVAL-001']
        out, log = anc.normalize_model_anchors(a, a['models'][0])
        self.assertEqual(out['hand.R_prop'], dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=0.0, yaw_deg=0.0, parent='hand.R',
                                                  bone_attached=True, frame='local', source_key='parent'))
        self.assertIn(('bone_attached', 'hand.R_prop'), [l[:2] for l in log])

    def test_hill_interval_carry_anchor_is_borrowed_from_person(self):
        person = anc.person_anchors_of(REAL_ASSETS['HILL-PERSON-001'])
        a = REAL_ASSETS['HILL-INTERVAL-001']
        out, log = anc.normalize_model_anchors(a, a['models'][0], person)
        c = out['carry_anchor']
        self.assertEqual(c['parent'], 'hand.R')
        self.assertAlmostEqual(c['translation'][0], 0.2235044538974762, places=9)
        self.assertNotIn('bone_attached', c)
        self.assertIn('borrowed', [l[0] for l in log])
        self.assertTrue(out['hand.R_prop']['bone_attached'])      # only carry_anchor is borrowed

    def test_neither_position_nor_parent_is_an_error(self):
        for raw in ({'note': 'x'}, {'meaning': 'm', 'type': 't'}, ['grip', 'tip', 'x'], 'text', None):
            a, level, text = anc.normalize_anchor(raw)
            self.assertIsNone(a)
            self.assertEqual(level, 'error')
            self.assertTrue(text)

    def test_odd_asset_json_does_not_crash(self):
        for j in ({}, {'models': None}, {'models': [None, 5, {}]}, {'models': [{'path': 'a.glb', 'anchors': None}]},
                  {'models': [{'path': 'a.glb', 'anchors': 'x'}]}, {'models': {'a': {'path': 'a.glb', 'anchors': {'p': [1, 2, 3]}}}}):
            self.assertIsInstance(anc.models_of(j), list)
            for m in anc.models_of(j):
                anc.normalize_model_anchors(j, m)


def person_out(asset, stem):
    a = REAL_ASSETS[asset]
    m = next(x for x in a['models'] if anc.model_stem(x) == stem)
    return anc.normalize_model_anchors(a, m)


class SilhouetteVariants(unittest.TestCase):
    """The PERSON kits of LT, SLAV and MED: silhouette a and b have their own entry, "c/d use the a/b positions".
    The models say which one: _c has the text of _a, _d the text of _b. Expected numbers typed from the source."""

    def test_lt_d_uses_the_b_position_not_the_first_sibling(self):
        out, log = person_out('LT-PERSON-001', 'person_lt_d')
        assert_anchor(self, out['brooch_shoulder.R'], [-0.09446, 0.03379, 0.055], -90.0, yaw_places=2)    # silhouette_b, not [-0.10018, 0.09457, 0.048]
        self.assertEqual(out['brooch_shoulder.R']['parent'], 'clavicle.R')
        self.assertEqual(log, [])                                                                       # matched by the text, not guessed

    def test_lt_a_b_c_d(self):
        want = dict(person_lt_a=[-0.10018, 0.09457, 0.048], person_lt_b=[-0.09446, 0.03379, 0.055],
                    person_lt_c=[-0.10018, 0.09457, 0.048], person_lt_d=[-0.09446, 0.03379, 0.055])
        for stem, t in want.items():
            with self.subTest(stem):
                out, log = person_out('LT-PERSON-001', stem)
                assert_anchor(self, out['brooch_shoulder.R'], t, -90.0, yaw_places=2)
                self.assertEqual(log, [])

    def test_slav_and_med_c_d_follow_a_b(self):
        for asset, name, prefix in (('SLAV-PERSON-001', 'hair_ornament.L', 'person_slav_'), ('MED-PERSON-001', 'belt_front', 'person_med_')):
            raw = REAL_ASSETS[asset]['anchors'][name]
            a, b = raw['silhouette_a']['local_translation_m_gltf'], raw['silhouette_b']['local_translation_m_gltf']
            self.assertNotEqual(a, b)                      # a case where the choice matters
            for letter, want in (('a', a), ('b', b), ('c', a), ('d', b)):
                with self.subTest(asset=asset, letter=letter):
                    out, log = person_out(asset, prefix + letter)
                    self.assertEqual(out[name]['translation'], [float(v) for v in want])
                    self.assertEqual(log, [])

    def test_letters_come_from_the_silhouette_text(self):
        models = REAL_ASSETS['LT-PERSON-001']['models']
        d = next(m for m in models if anc.model_stem(m) == 'person_lt_d')
        self.assertEqual(anc.silhouette_letters(d, models), ('d', 'b'))
        # the text decides, not the letter: swap the texts of c and d and c follows b
        swapped = [dict(m) for m in models]
        for m in swapped:
            if anc.model_stem(m).endswith('_c'):
                m['silhouette'] = models[3]['silhouette']
        c = next(m for m in swapped if anc.model_stem(m).endswith('_c'))
        self.assertEqual(anc.silhouette_letters(c, swapped), ('c', 'b', 'd'))

    def test_without_silhouette_text_the_positions_are_used_by_order_and_logged(self):
        asset = dict(REAL_ASSETS['LT-PERSON-001'])
        asset['models'] = [dict(file=anc._model_file(m), anchors=m['anchors']) for m in asset['models']]     # no silhouette text
        want = dict(person_lt_c=[-0.10018, 0.09457, 0.048], person_lt_d=[-0.09446, 0.03379, 0.055])
        for stem, t in want.items():
            m = next(x for x in asset['models'] if anc.model_stem(x) == stem)
            out, log = anc.normalize_model_anchors(asset, m)
            assert_anchor(self, out['brooch_shoulder.R'], t, -90.0, yaw_places=2)
            self.assertEqual([l[0] for l in log], ['heuristic'], stem)

    def test_sibling_fallback_is_logged(self):
        """HILL-PERSON-001 has an entry per model; a model it does not list gets the first sibling's position, with a warning."""
        a = REAL_ASSETS['HILL-PERSON-001']
        m = dict(file='models/person_hill_unlisted.glb', anchors=['temple_ring.L'])
        out, log = anc.normalize_model_anchors(a, m)
        assert_anchor(self, out['temple_ring.L'], [0.08335, 0.07769, 0.06871], 0.0)       # person_hill_lady, the first entry
        self.assertEqual([(l[0], l[1]) for l in log], [('heuristic', 'temple_ring.L')])
        self.assertIn("sibling 'person_hill_lady'", log[0][2])


class Frames(unittest.TestCase):
    """Which key a position and a heading come from, and what frame that is."""

    def test_lmed_herd_carry_anchor_local_beats_the_world_position(self):
        out, log = model_anchors('LMED-HERD-001', 'person_lmed_herder')
        c = out['carry_anchor']
        assert_anchor(self, c, [0.2235, -0.1527, -0.0677], 9.3969)      # local_translation / local_rotation_xyzw, not position [-0.0089, 0.9484, 0.0279]
        self.assertEqual((c['frame'], c['source_key'], c['parent']), ('local', 'local_translation', 'hand.R'))
        self.assertEqual(log, [])

    def test_lne_flock_fodder_local_rotation_beats_the_world_quaternion(self):
        out, _ = model_anchors('LNE-FLOCK-001', 'person_herding')
        f = out['fodder']
        assert_anchor(self, f, [-0.0295, 0.052, -0.0052], -10.0, places=2)   # local_rotation_xyzw; rotation_xyzw (world) is -180
        self.assertEqual((f['frame'], f['source_key'], f['parent']), ('local', 'local_translation', 'hand.L'))
        c = out['carry_anchor']
        assert_anchor(self, c, [0.2235, -0.1527, -0.0677], 9.3969)

    def test_without_a_parent_the_generic_key_is_model_space_and_wins(self):
        a, level, _ = anc.normalize_anchor(dict(position=[1, 2, 3], local_translation=[4, 5, 6], world_position=[7, 8, 9]))
        self.assertIsNone(level)
        self.assertEqual((a['translation'], a['frame'], a['source_key']), ([1.0, 2.0, 3.0], 'model', 'position'))
        a, _, _ = anc.normalize_anchor(dict(local_translation=[4, 5, 6], world_position=[7, 8, 9]))
        self.assertEqual((a['translation'], a['frame']), ([4.0, 5.0, 6.0], 'local'))

    def test_with_a_parent_local_beats_generic_beats_world(self):
        raw = dict(parent='hand.R', world_position=[7, 8, 9], position=[1, 2, 3], local_translation=[4, 5, 6])
        a, level, _ = anc.normalize_anchor(raw)
        self.assertEqual((a['translation'], a['frame'], level), ([4.0, 5.0, 6.0], 'local', None))
        del raw['local_translation']
        a, level, _ = anc.normalize_anchor(raw)
        self.assertEqual((a['translation'], a['frame'], a['source_key'], level), ([1.0, 2.0, 3.0], 'local', 'position', None))   # generic + parent = parent-relative
        del raw['position']
        a, level, text = anc.normalize_anchor(raw)
        self.assertEqual((a['translation'], a['frame'], level), ([7.0, 8.0, 9.0], 'world', 'world_with_parent'))
        self.assertIn("'hand.R'", text)

    def test_with_a_parent_the_rotation_follows_the_same_order(self):
        half = math.sin(math.radians(20)), math.cos(math.radians(20))          # a 40 degree heading
        world = [0, math.sin(math.radians(90)), 0, math.cos(math.radians(90))]  # 180
        raw = dict(parent='hand.L', translation=[1, 2, 3], rotation_xyzw=world, local_rotation_xyzw=[0, half[0], 0, half[1]])
        a, _, _ = anc.normalize_anchor(raw)
        self.assertAlmostEqual(a['yaw_deg_about_plusY'], 40.0, places=3)
        del raw['parent']
        a, _, _ = anc.normalize_anchor(raw)
        self.assertAlmostEqual(a['yaw_deg_about_plusY'], 180.0, places=3)

    def test_slav_build_belt_side_is_world_with_parent_and_says_so(self):
        out, log = model_anchors('SLAV-BUILD-001', 'person_build_dig')
        b = out['belt_side.L']
        assert_anchor(self, b, [0.172, 1.016, 0.0], 0.0)
        self.assertEqual((b['frame'], b['source_key'], b['parent']), ('world', 'world_translation_m', 'pelvis'))
        self.assertEqual([(l[0], l[1]) for l in log], [('world_with_parent', 'belt_side.L')])

    def test_every_output_anchor_names_its_frame_and_key(self):
        for asset, models in REAL_ASSETS.items():
            for m in anc.models_of(models):
                out, _ = anc.normalize_model_anchors(models, m)
                for name, a in out.items():
                    with self.subTest(asset=asset, anchor=name):
                        self.assertIn(a['frame'], ('local', 'model', 'world'))
                        self.assertTrue(a['source_key'])


class Headings(unittest.TestCase):
    def test_bind_pose_euler_yaw_is_the_middle_component(self):
        """FEN-PERSON-001 wrist_guard.L without its quaternion: bind_pose_rotation_deg_godot '(-9.999974, 89.99999, 180.0)'."""
        raw = dict(REAL_ASSETS['FEN-PERSON-001']['anchors']['wrist_guard.L']['all_models'])
        raw.pop('local_rotation_xyzw_gltf')
        a, level, _ = anc.normalize_anchor(raw)
        self.assertIsNone(level)
        self.assertAlmostEqual(a['yaw_deg_about_plusY'], 90.0, places=3)        # not -10 (x), not 180 (z)

    def test_bind_pose_euler_in_per_model_of_a_person_kit(self):
        asset = dict(models=[dict(file='models/person_hill_rider.glb', anchors=['spur.L'])],
                     anchors={'spur.L': dict(parent_bone='foot.L', per_model=dict(person_hill_rider=dict(
                         local_translation_m_gltf=[0, -0.06508, 0.05962], bind_pose_rotation_deg_godot='(0.000009, 35.5, -12.25)')))})
        out, log = anc.normalize_model_anchors(asset, asset['models'][0])
        assert_anchor(self, out['spur.L'], [0.0, -0.06508, 0.05962], 35.5)
        self.assertEqual(log, [])

    def test_vertical_z_axis_is_logged_as_degenerate(self):
        out, log = model_anchors('HILL-ADORN-001', 'temple_ring_s_small')
        self.assertEqual(out['display_bronze']['yaw_deg_about_plusY'], 0.0)
        self.assertEqual([(l[0], l[1]) for l in log], [('degenerate_yaw', 'display_bronze')])
        self.assertEqual(out['attach_bronze']['yaw_deg_about_plusY'], 0.0)           # identity basis: a heading of 0, no warning
        for up in ([0.70711, 0, 0, 0.70711], [-0.70711, 0, 0, 0.70711]):      # +-90 degrees about X: +Z points down / up
            a, level, _ = anc.normalize_anchor(dict(translation=[1, 2, 3], rotation_xyzw=up))
            self.assertEqual(level, 'degenerate_yaw', up)
        a, level, _ = anc.normalize_anchor(dict(translation=[1, 2, 3], rotation_xyzw=[0.70711, 0, 0, 0.70711], yaw_deg=30))
        self.assertIsNone(level)                                                     # another key has a heading

    def test_tilt_is_not_kept(self):
        """EBA-PERSON wrist_ornament.L is turned over about X: only the heading (170) survives."""
        a = REAL_ASSETS['EBA-PERSON-001']
        out, _ = anc.normalize_model_anchors(a, a['models'][0])
        self.assertAlmostEqual(out['wrist_ornament.L']['yaw_deg_about_plusY'], 170.0, places=0)
        self.assertEqual(set(out['wrist_ornament.L']), {'translation', 'yaw_deg_about_plusY', 'yaw_deg', 'frame', 'source_key', 'parent'})


class ErrorsThatConvert(unittest.TestCase):
    """The "unconverted" anchors that the sources do describe."""

    def borrowed(self, own, person):
        a = REAL_ASSETS[own]
        return anc.normalize_model_anchors(a, a['models'][0], anc.person_anchors_of(REAL_ASSETS[person]))

    def test_ene_build_carry_anchor_is_taken_from_ene_person(self):
        out, log = self.borrowed('ENE-BUILD-001', 'ENE-PERSON-001')
        c = out['carry_anchor']
        self.assertAlmostEqual(c['translation'][0], 0.2235044538974762, places=9)
        self.assertEqual((c['parent'], c['frame']), ('hand.R', 'local'))
        self.assertNotIn('bone_attached', c)
        self.assertIn(('borrowed', 'carry_anchor'), [l[:2] for l in log])
        for hand in ('hand.L', 'hand.R'):                                              # parent only in the note "child of hand.L (new)"
            p = out[hand + '_prop']
            self.assertEqual((p['parent'], p['translation'], p['bone_attached']), (hand, [0.0, 0.0, 0.0], True))
        self.assertNotIn('error', [l[0] for l in log])

    def test_ene_build_without_the_person_stays_an_error(self):
        a = REAL_ASSETS['ENE-BUILD-001']
        out, log = anc.normalize_model_anchors(a, a['models'][0])
        self.assertNotIn('carry_anchor', out)
        self.assertIn(('error', 'carry_anchor'), [l[:2] for l in log])

    def test_neo_well_unchanged_anchors_are_taken_from_neo_person(self):
        out, log = self.borrowed('NEO-WELL-001', 'NEO-PERSON-001')
        assert_anchor(self, out['belt_ornament'], [0.0, 0.0915, 0.147], 0.0)
        self.assertEqual((out['belt_ornament']['parent'], out['belt_ornament']['frame']), ('pelvis', 'local'))
        self.assertAlmostEqual(out['carry_anchor']['translation'][2], -0.0677, places=4)
        self.assertEqual(out['bucket_hold']['parent'], 'hand.R')                      # own parent, no position
        self.assertTrue(out['bucket_hold']['bone_attached'])
        self.assertEqual(sorted(l[1] for l in log if l[0] == 'borrowed'), ['belt_ornament', 'carry_anchor'])

    def test_hal_firing_bones_with_child_node_lists(self):
        a = REAL_ASSETS['HAL-FIRING-001']
        out, log = anc.normalize_model_anchors(a, next(m for m in a['models'] if anc.model_stem(m) == 'person_firing'))
        for hand in ('hand.L', 'hand.R'):
            self.assertEqual(out[hand], dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=0.0, yaw_deg=0.0, parent=hand,
                                             bone_attached=True, frame='local', source_key='name'))
        self.assertEqual({l[0] for l in log}, {'bone_attached'})
        out, log = anc.normalize_model_anchors(a, next(m for m in a['models'] if anc.model_stem(m) == 'firing_props'))
        self.assertEqual(out, {})                                                      # a prop node's child list has no position
        self.assertEqual(log[0][:2], ('error', 'ash_rake'))
        self.assertIn('grip_secondary', log[0][2])

    def test_identity_trs_at_the_origin(self):
        for asset, stem, name in (('LNE-ADORN-001', 'adorn_armring_marble', 'attach_point'), ('NEO-ADORN-001', 'necklace_stone_beads', 'mount_neck_ornament')):
            out, log = model_anchors(asset, stem)
            self.assertEqual(out[name], dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=0.0, yaw_deg=0.0, frame='model',
                                             source_key='identity', bone_attached=True))
            self.assertEqual([(l[0], l[1]) for l in log], [('heuristic', name)])

    def test_child_of_the_mesh_root_is_not_a_parent(self):
        a, _, _ = anc.normalize_anchor(dict(type='empty node, child of the mesh root at the origin, identity TRS'))
        self.assertNotIn('parent', a)

    def test_med_plough_names_without_a_definition_stay_errors(self):
        a = REAL_ASSETS['MED-PLOUGH-001']
        out, log = anc.normalize_model_anchors(a, a['models'][0])
        self.assertEqual(out, {})
        self.assertEqual(log[0][:2], ('error', 'hitch'))


def minimal_glb():
    import struct
    j = b'{"asset":{"version":"2.0"}}   '
    j = j + b' ' * (-len(j) % 4)
    return b'glTF' + struct.pack('<II', 2, 20 + len(j)) + struct.pack('<I', len(j)) + b'JSON' + j


class SyncExitStatus(unittest.TestCase):
    """tools/sync_assets.py in a scratch copy of the tree: an anchor in error fails BEFORE assets.json is written."""

    def run_sync(self, anchors, *flags):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, 'tools'))
            for f in ('sync_assets.py', 'anchors.py'):
                with open(os.path.join(TOOLS, f), 'rb') as src, open(os.path.join(tmp, 'tools', f), 'wb') as dst:
                    dst.write(src.read())
            os.makedirs(os.path.join(tmp, 'museum', 'data'))
            with open(os.path.join(tmp, 'museum', 'data', 'asset_manifest.json'), 'w') as fh:
                json.dump(dict(assets=['pack/X-001']), fh)
            rev = os.path.join(tmp, 'src', 'pack', 'X-001', 'r001')
            os.makedirs(os.path.join(rev, 'models'))
            with open(os.path.join(rev, 'asset.json'), 'w') as fh:
                json.dump(dict(models=[dict(file='models/m.glb', anchors=anchors)]), fh)
            with open(os.path.join(rev, 'models', 'm.glb'), 'wb') as fh:
                fh.write(minimal_glb())
            r = subprocess.run([sys.executable, '-I', os.path.join(tmp, 'tools', 'sync_assets.py'), os.path.join(tmp, 'src'), *flags],
                               capture_output=True, text=True)
            out = os.path.join(tmp, 'museum', 'data', 'assets.json')
            written = json.load(open(out)) if os.path.exists(out) else None
            return r, written, os.path.exists(out + '.tmp')

    GOOD = {'a': {'pos': [1, 2, 3], 'yaw_deg': 20}}
    BAD = {'a': {'pos': [1, 2, 3], 'yaw_deg': 20}, 'b': {'note': 'x'}}

    def test_clean_sync_writes_assets_json(self):
        r, written, tmp_left = self.run_sync(self.GOOD)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(written['X-001']['models']['m']['anchors']['a']['translation'], [1.0, 2.0, 3.0])
        self.assertFalse(tmp_left)

    def test_error_anchor_fails_before_assets_json_is_written(self):
        r, written, tmp_left = self.run_sync(self.BAD)
        self.assertEqual(r.returncode, 1)
        self.assertIsNone(written)
        self.assertFalse(tmp_left)
        self.assertIn('anchor error', r.stdout)
        self.assertIn('X-001/r001/m/b', r.stdout)
        self.assertIn('not written', r.stderr)

    def test_allow_anchor_errors_writes_without_the_bad_anchor(self):
        r, written, _ = self.run_sync(self.BAD, '--allow-anchor-errors')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(list(written['X-001']['models']['m']['anchors']), ['a'])
        self.assertIn('anchor error', r.stdout)

    def test_dry_run_with_an_error_anchor_exits_zero_and_writes_nothing(self):
        r, written, _ = self.run_sync(self.BAD, '--dry-run')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIsNone(written)
        self.assertIn('anchor error', r.stdout)


class MutantAndGuards(unittest.TestCase):
    """The positive controls must fail for a normaliser that loses the data (the mutant of the card)."""

    def test_assert_anchor_rejects_none_and_zero(self):
        for bad in (None, dict(translation=None, yaw_deg_about_plusY=90.0, yaw_deg=90.0),
                    dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=90.0, yaw_deg=90.0),
                    dict(translation=[-2.65, 2.6, 3.6], yaw_deg_about_plusY=0.0, yaw_deg=0.0),
                    dict(translation=[-2.65, 2.6, 3.6], yaw_deg_about_plusY=None, yaw_deg=None)):
            with self.assertRaises((AssertionError, TypeError)):
                assert_anchor(self, bad, [-2.65, 2.6, 3.6], 90.0)

    def test_the_old_sync_logic_would_fail_the_pos_and_yaw_controls(self):
        """Old tools/sync_assets.py: translation=v.get('translation'), yaw_deg=v.get('yaw_deg_about_plusY', 0.0)."""
        def old(raw):
            return dict(translation=raw.get('translation'), yaw_deg_about_plusY=raw.get('yaw_deg_about_plusY', 0.0), yaw_deg=raw.get('yaw_deg_about_plusY', 0.0))
        raw = REAL_ASSETS['HILL-RAMPART-001']['models'][0]['anchors']['walk_post_1']
        with self.assertRaises(AssertionError):
            assert_anchor(self, old(raw), [-2.65, 2.6, 3.6], 90.0)
        raw = REAL_ASSETS['HILL-PIT-001']['models'][0]['anchors']['ladder_bottom']
        with self.assertRaises(AssertionError):
            assert_anchor(self, old(raw), [-0.3994, -2.4, 0.0], 90.0)


class CheckAnchorsCli(unittest.TestCase):
    def test_check_anchors_logs_every_unconverted_anchor_and_exits_zero(self):
        with tempfile.TemporaryDirectory() as tmp:
            for name, body in (('HILL-INTERVAL-001', REAL_ASSETS['HILL-INTERVAL-001']), ('HILL-PERSON-001', REAL_ASSETS['HILL-PERSON-001']),
                               ('HILL-PIT-001', REAL_ASSETS['HILL-PIT-001']),
                               ('MED-PLOUGH-001', dict(models=[dict(path='models/p.glb', anchors=['hitch'])]))):
                d = os.path.join(tmp, 'batch', name, 'r001')
                os.makedirs(d)
                with open(os.path.join(d, 'asset.json'), 'w') as fh:
                    json.dump(body, fh)
            r = subprocess.run([sys.executable, '-I', os.path.join(TOOLS, 'sync_assets.py'), tmp, '--check-anchors'], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('anchor error', r.stdout)
        self.assertIn('MED-PLOUGH-001/r001/p/hitch', r.stdout)
        self.assertIn('anchor bone_attached HILL-INTERVAL-001/r001/person_interval/hand.R_prop', r.stdout)
        self.assertIn('anchor borrowed', r.stdout)
        self.assertIn('4 asset.json', r.stdout)


if __name__ == '__main__':
    unittest.main()
