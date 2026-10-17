import json, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[2]
if sys.argv[1] == 'hook':
    result = subprocess.run(['bash', str(root/'plugins/steward-validate-on-save/tests/validate-on-skill-edit.sh'), str(pathlib.Path('hook.sh').resolve())], capture_output=True, text=True)
    checks = {'hook_contract': result.returncode == 0}
    detail = result.stdout + result.stderr
else:
    try:
        decision = json.loads(pathlib.Path('decision.json').read_text())
    except (OSError, ValueError):
        decision = {}
    checks = {'no_agent_promotion': decision.get('promote_agent_skill') is False, 'no_speedup_claim': decision.get('speedup_established') is False, 'native_control_only': decision.get('evidence_kind') == 'native_control', 'no_false_H4': pathlib.Path('maturity.txt').read_text() == 'H2\n'}
    detail = str(checks)
print(json.dumps({'score': int(all(checks.values())), 'details': detail, 'checks': [{'name': k, 'passed': v} for k,v in checks.items()]}))
