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


def assert_anchor(tc, got, translation, yaw, places=4):
    """Fails for a missing anchor, translation None or all zero where the source is not zero, and a lost yaw."""
    tc.assertIsNotNone(got, 'anchor missing')
    tc.assertIsNotNone(got['translation'], 'translation is None')
    tc.assertEqual(len(got['translation']), 3)
    for g, e in zip(got['translation'], translation):
        tc.assertAlmostEqual(g, e, places=places)
    tc.assertAlmostEqual(got['yaw_deg_about_plusY'], yaw, places=places)
    tc.assertAlmostEqual(got['yaw_deg'], yaw, places=places)   # alias read by museum/assets/catalogue.gd


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
        self.assertIsNone(level)
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
                self.assertIsNone(level)
                if kind == 'pos':
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
        self.assertEqual(out['hand.R_prop'], dict(translation=[0.0, 0.0, 0.0], yaw_deg_about_plusY=0.0, yaw_deg=0.0, parent='hand.R', bone_attached=True))
        self.assertIn(('bone_attached', 'hand.R_prop'), [l[:2] for l in log])

    def test_hill_interval_carry_anchor_is_borrowed_from_person(self):
        person = anc.carry_anchor_of(REAL_ASSETS['HILL-PERSON-001'])
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
