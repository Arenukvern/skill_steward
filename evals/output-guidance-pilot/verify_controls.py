"""Six no-model controls for the frozen native oracle."""
import os
import shutil
import tempfile
from pathlib import Path
from fixtures import prepare
from grade import grade

binary = Path(os.environ['STEWARD_GUIDANCE_BINARY']).resolve()
for task in ['invalid-config', 'durability']:
    root = Path(tempfile.mkdtemp(prefix='steward-guidance-control-'))
    try:
        original = prepare(root, task)
        assert not grade(root, task, original, binary)['passed'], task + ': original must fail'
        if task == 'invalid-config':
            import json
            repaired = json.loads((root/'steward.yaml').read_text())
            repaired['actions']['check.local']['limits']['timeout_ms'] = 10000
            (root/'steward.yaml').write_text(json.dumps(repaired))
        else:
            import subprocess
            subprocess.run(['git', 'add', 'steward.yaml', 'steward/scenarios/pilot.smoke.yaml'], cwd=root, check=True)
            subprocess.run(['git', 'commit', '-qm', 'Qualify required inputs'], cwd=root, check=True)
        assert grade(root, task, original, binary)['passed'], task + ': narrow repair must pass'
        (root/'private-note.txt').write_text('changed')
        assert not grade(root, task, original, binary)['passed'], task + ': protected mutation must fail'
        print(task + ': 3 controls passed')
    finally:
        shutil.rmtree(root)
