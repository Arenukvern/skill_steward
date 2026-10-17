"""No-model original/pass/wrong-owner/counterexample and observer controls."""
import json,os,shutil,tempfile,time
from pathlib import Path
from cases import TASKS,CHECKER,prepare
from observer import Observer
from oracle import grade
binary=Path(os.environ['STEWARD_GUIDANCE_BINARY']).resolve()
for task in TASKS:
 root=Path(tempfile.mkdtemp(prefix='steward-owner-control-'))
 try:
  fixture=prepare(root,task)
  assert not grade(root,task,fixture,binary)['passed']
  observer=Observer(root,fixture['tracked_paths']);observer.start()
  if task=='outdated-checker':(root/'check_release.py').write_text(CHECKER)
  elif task=='implementation-drift':(root/'packages/cli.json').write_text('{"name":"cli","version":"1.1.0"}')
  elif task=='stale-copy':shutil.copyfile(root/'check_release.py',root/'installed/check_release.py')
  else:(root/'summary.py').write_text("def release_summary(policy):\n    return dict(policy['expected'])\n")
  time.sleep(.06);events=observer.finish()
  assert {e['path'] for e in events}==set(fixture['intended_owner'])
  assert grade(root,task,fixture,binary)['passed']
  (root/'release-policy.json').write_text('{}')
  assert not grade(root,task,fixture,binary)['passed']
  print(task+': original-fail, narrow-repair-pass, wrong-owner-fail and observer controls passed')
 finally:shutil.rmtree(root)
for task in ['outdated-checker','stale-receipt']:
 root=Path(tempfile.mkdtemp(prefix='steward-owner-counterexample-'))
 try:
  fixture=prepare(root,task)
  (root/fixture['intended_owner'][0]).write_text('print("pass")\n' if task=='outdated-checker' else "def release_summary(policy):\n    return {'core':'1.1.0','cli':'1.0.0'}\n")
  assert not grade(root,task,fixture,binary)['semantic_oracle_pass']
  print(task+': weakened/hardcoded repair rejected')
 finally:shutil.rmtree(root)
