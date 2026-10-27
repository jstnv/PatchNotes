"""Repeat native/input and predecessor checks on one already imported final copy."""
import checks

project = checks.RAW / 'keyboard-green/project'
before = checks.sim.source_hashes(checks.ROOT / 'patch-notes')
assert checks.sim.source_hashes(project) == before, 'Final copy must match canonical source'
results = []
results.append(checks.run('native-v2', project, project / 'scripts/debug/verify_store_prerequisite_links.gd', native=True, reuse=True))
for predecessor in ['previous-editor', 'previous-pack']:
    results.append(checks.run('final-' + predecessor, project, checks.HERE / 'world_probe.gd',
        ['--input=' + str(checks.RAW / predecessor / 'result.json')], reuse=True))
unchanged = checks.sim.source_hashes(checks.ROOT / 'patch-notes') == before
report = {'pass': unchanged and all(item['pass'] for item in results), 'canonical_unchanged': unchanged,
          'source': before, 'checks': results}
checks.sim.write_json(checks.RAW / 'final-audit.json', report)
raise SystemExit(0 if report['pass'] else 1)
