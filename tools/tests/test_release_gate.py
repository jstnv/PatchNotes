"""Keep fresh-process checkpoint dependencies inside the gate's own profiles."""
from pathlib import Path
import importlib.util, json, tempfile, unittest

spec=importlib.util.spec_from_file_location('release_gate',Path(__file__).parents[1]/'release_gate.py')
gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)

class ContinuationProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output=Path(self.temp.name)/'gate';self.output.mkdir()
        self.profile=self.output/'profiles/producer-1'
        for key in ('APPDATA','LOCALAPPDATA'):(self.profile/key).mkdir(parents=True)
        self.record={'exit':0,'errors':[],'profile':str(self.profile)}
    def resolve(self):
        (self.output/'producer.command.json').write_text(json.dumps(self.record))
        return gate.continuation_profile(self.output,'producer')
    def test_successful_prior_process_reuses_exact_isolated_profile(self):
        self.assertEqual(self.resolve(),self.profile.resolve())
    def test_failed_producer_cannot_supply_a_save(self):
        self.record['exit']=1
        with self.assertRaises(RuntimeError):self.resolve()
    def test_erroring_producer_cannot_supply_a_save(self):
        self.record['errors']=['ERROR: bad save']
        with self.assertRaises(RuntimeError):self.resolve()
    def test_missing_provenance_fails_closed(self):
        del self.record['profile']
        with self.assertRaises(RuntimeError):self.resolve()
    def test_outside_profile_cannot_touch_player_saves(self):
        self.record['profile']=str(Path(self.temp.name)/'other-profile')
        for key in ('APPDATA','LOCALAPPDATA'):(Path(self.record['profile'])/key).mkdir(parents=True)
        with self.assertRaises(RuntimeError):self.resolve()
    def test_missing_profile_directory_is_rejected(self):
        self.record['profile']=str(self.output/'profiles/missing')
        with self.assertRaises(RuntimeError):self.resolve()
    def test_only_finite_calendar_fixture_gets_longer_limit(self):
        self.assertEqual(gate.verifier_timeout('verify_sidestreet_scope_and_year'),1200)
        self.assertEqual(gate.verifier_timeout('verify_bank_integration'),240)

    def test_cold_consumers_follow_their_producers(self):
        jobs=gate.verifier_jobs()
        names=[name for name,path in jobs]
        self.assertEqual(len(names),len(set(names)))
        for cold,producer in gate.COLD_PRODUCERS.items():
            self.assertLess(names.index(producer),names.index(cold))

    def test_cold_mode_requires_successful_artifact_and_clears_other_modes(self):
        name='verify_alpha_shop_pack_cold';producer=gate.COLD_PRODUCERS[name]
        with self.assertRaises(FileNotFoundError):gate.verifier_environment(self.output,name)
        record=self.output/(producer+'.command.json')
        record.write_text(json.dumps({'exit':0,'errors':[]}))
        with self.assertRaises(RuntimeError):gate.verifier_environment(self.output,name)
        artifact=self.output/'verifier-artifacts'/producer/'result.json'
        artifact.parent.mkdir(parents=True);artifact.write_text('{}')
        env=gate.verifier_environment(self.output,name)
        self.assertEqual(env['PN_CARD_FRAME_OUTPUT'],str(artifact))
        self.assertEqual(env['PN_ALPHA_PACK_COLD'],'1')
        self.assertEqual(env['PN_INDEX_COLD'],'')
        record.write_text(json.dumps({'exit':1,'errors':[]}))
        with self.assertRaises(RuntimeError):gate.verifier_environment(self.output,name)

    def test_ordinary_mode_clears_cold_and_migration_inputs(self):
        env=gate.verifier_environment(self.output,'verify_card_frame')
        self.assertEqual(env['PN_INDEX_COLD'],'')
        self.assertEqual(env['PN_ALPHA_PACK_COLD'],'')
        self.assertEqual(env['PN_OLD_WORLD_FRAME'],'')
        self.assertEqual(env['PN_GAMEPLAY_PRIOR_SAVES'],'')

    def test_gameplay_parent_migration_uses_pinned_actual_prior_dtos(self):
        env=gate.verifier_environment(self.output,'verify_gameplay_tree')
        fixture=Path(env['PN_GAMEPLAY_PRIOR_SAVES'])
        provenance=json.loads(fixture.with_suffix('.provenance.json').read_text())
        self.assertEqual(gate.sha(fixture),provenance['sha256'])
        self.assertEqual(sorted(json.loads(fixture.read_text())),provenance['keys'])
        self.assertEqual(len(provenance['keys']),9)

    def test_world_file_restore_requires_and_receives_this_run_artifact(self):
        with self.assertRaises(RuntimeError):
            gate.verifier_arguments(self.output,'verify_world_restore_file','probe.gd')
        source=self.output/'verifier-artifacts/verify_legacy_world/result.json'
        source.parent.mkdir(parents=True);source.write_text('{}')
        destination=self.output/'verifier-artifacts/verify_world_restore_file/result.json'
        self.assertEqual(gate.verifier_arguments(self.output,'verify_world_restore_file','probe.gd'),
                         ['--script','probe.gd','--',str(source),str(destination)])
        self.assertEqual(gate.verifier_arguments(self.output,'verify_card_frame','card.gd'),
                         ['--script','card.gd'])

    def test_migration_uses_pinned_historical_fixture(self):
        env=gate.verifier_environment(self.output,'verify_queue_source_migration')
        fixture=Path(env['PN_OLD_WORLD_FRAME'])
        manifest=json.loads(fixture.with_suffix('.provenance.json').read_text())
        self.assertEqual(gate.sha(fixture),manifest['sha256'])
        frame=json.loads(fixture.read_text())
        self.assertEqual(frame['world']['source_identity'],manifest['runtime_identity'])
        self.assertEqual(frame['player']['content_revision'],manifest['content_revision'])

if __name__=='__main__':unittest.main()
