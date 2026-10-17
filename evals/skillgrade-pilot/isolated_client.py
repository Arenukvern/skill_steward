#!/usr/bin/env python3
"""macOS-only experimental Skillgrade command adapter; no credential copying."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time

client = sys.argv[1]
if client not in ('codex', 'zcode') or sys.platform != 'darwin':
    raise SystemExit('Usage on macOS: python3 isolated_client.py codex|zcode')
root = Path(os.environ['STEWARD_PILOT_ROOT']).resolve().parents[1]
adapter_sha256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
workspace = Path.cwd().resolve()
home = Path.home()
artifacts = Path(os.environ['STEWARD_PILOT_ARTIFACTS']).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
run_id = f'{client}-{time.time_ns()}'
receipt = artifacts / run_id
receipt.mkdir()
runtime = Path(tempfile.mkdtemp(prefix='steward-client-'))
prompt = sys.stdin.read()
env = os.environ.copy()
# Never expose unrelated inherited provider secrets to model-controlled shells.
# Clients use their existing native auth/config; no credential files are read here.
for key in list(env):
    if any(word in key.upper() for word in ('API_KEY', 'TOKEN', 'PASSWORD', 'SECRET')):
        env.pop(key)
read_denied = [home/'.agents/skills', home/'.codex/skills', home/'.codex/plugins',
               home/'.codex/memories', home/'.codex/AGENTS.md', home/'.optmem',
               home/'.zcode/skills', home/'.zcode/cli/plugins', home/'.zcode/cli/memories',
               home/'.zcode/AGENTS.md', home/'.zcode/cli/AGENTS.md', root, workspace/'tests']
if client == 'zcode':
    read_denied.append(home/'.zcode/cli/config.json')
# Home/application writes are blocked, except the client's own required runtime.
# Codex has no independent runtime-root flag while retaining native login.
profile = ['(version 1)', '(allow default)']
for path in read_denied:
    profile.append(f'(deny file-read* (subpath {json.dumps(str(path))}))')
for path in [home, Path('/Applications'), Path('/opt/homebrew')]:
    profile.append(f'(deny file-write* (subpath {json.dumps(str(path))}))')
runtime_home = home / ('.codex' if client == 'codex' else '.zcode')
profile.append(f'(allow file-write* (subpath {json.dumps(str(runtime_home))}))')
for path in read_denied + [home/'.codex/auth.json', home/'.codex/config.toml',
                           home/'.codex/secrets', home/'.zcode/cli/config.json',
                           home/'.zcode/v2/provider_config.json']:
    profile.append(f'(deny file-write* (subpath {json.dumps(str(path))}))')
profile_path = runtime/'isolation.sb'
profile_path.write_text('\n'.join(profile)+'\n')
shutil.copy(profile_path, receipt/'isolation.sb')
# Confirm the OS boundary, without reading the contents of protected files.
checks = {}
for path in [root/'evals/skillgrade-pilot/grade.py', home/'.agents/skills/skill-eval-improve/SKILL.md']:
    probe = subprocess.run(['sandbox-exec', '-f', str(profile_path), '/bin/cat', str(path)], capture_output=True)
    checks[str(path)] = probe.returncode != 0 and b'Operation not permitted' in probe.stderr
if not all(checks.values()):
    raise SystemExit('Isolation preflight failed; no model run started')
if client == 'codex':
    args = [shutil.which('codex'), 'exec', '--ignore-user-config', '--ignore-rules',
            '--skip-git-repo-check', '--ephemeral', '-c', 'features.plugins=false',
            '-c', 'features.skill_search=false', '-c', 'project_doc_max_bytes=0',
            '--sandbox', 'danger-full-access', '--model', 'gpt-5.6-sol', '--json', '-']
    stdin = prompt.encode()
else:
    config_dir = workspace/'.zcode'
    config_dir.mkdir(exist_ok=True)
    config_path = config_dir/'config.json'
    if config_path.exists():
        raise SystemExit('Refusing to overwrite existing workspace ZCode config')
    config_path.write_text(json.dumps({'plugins': {'enabled': False}, 'features': {'memory': False, 'mcp': False, 'subagent': False}, 'hooks': {'enabled': False}, 'memory': {'use': False}}))
    zcode_storage = Path(os.environ['STEWARD_PILOT_ZCODE_STORAGE']).resolve()
    if zcode_storage.is_relative_to(root) or zcode_storage == home/'.zcode':
        raise SystemExit('Use a dedicated prewarmed ZCode storage directory outside the checkout')
    env.update({'ZCODE_STORAGE_DIR': str(zcode_storage), 'ZCODE_SESSION_DB_PATH': str(runtime/'session.sqlite'),
                'ZCODE_BUILTIN_PROVIDER_CONFIG_FILE': '/Applications/ZCode.app/Contents/Resources/config/provider/zcode-builtin.json',
                'ZCODE_PERSONAL_PROVIDER_CONFIG_FILE': str(home/'.zcode/v2/provider_config.json')})
    cli = '/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs'
    if os.environ.get('STEWARD_PILOT_CATALOG_PREFLIGHT') == '1':
        catalog = subprocess.run(['sandbox-exec', '-f', str(profile_path), shutil.which('node'), cli,
                                  'skills', 'list', '--cwd', str(workspace), '--json'], env=env, capture_output=True, timeout=45)
        (receipt/'skills.json').write_bytes(catalog.stdout)
        (receipt/'skills.stderr').write_bytes(catalog.stderr)
        if catalog.returncode:
            raise SystemExit('ZCode skill discovery preflight failed')
    args = [shutil.which('node'), cli, '--cwd', str(workspace), '--mode', 'guarded', '--json', '--prompt', prompt]
    stdin = None
log = home/'.zcode/cli/log'/f'zcode-{datetime.date.today().isoformat()}.jsonl'
log_offset = log.stat().st_size if client == 'zcode' and log.exists() else 0
start = time.monotonic()
process = subprocess.Popen(['sandbox-exec', '-f', str(profile_path), *args], env=env,
                           stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
timed_out = False
try:
    out, err = process.communicate(stdin, timeout=240)
except subprocess.TimeoutExpired:
    timed_out = True
    os.killpg(process.pid, signal.SIGKILL)
    out, err = process.communicate()
(receipt/'client.stdout').write_bytes(out)
(receipt/'client.stderr').write_bytes(err)
# Preserve final task artifacts before Skillgrade deletes its temporary workspace.
for name in ['hook.sh', 'decision.json', 'maturity.txt', 'done.txt']:
    path = workspace/name
    if path.is_file(): shutil.copy(path, receipt/name)
metadata = {'client': client, 'workspace': str(workspace), 'duration_ms': round((time.monotonic()-start)*1000),
            'exit_code': process.returncode, 'timed_out': timed_out, 'isolation_checks': checks,
            'adapter_sha256': adapter_sha256, 'receipt': str(receipt)}
if client == 'zcode':
    try:
        response = json.loads(out)
        session_id = response['sessionId']
        metadata['session_id'] = session_id
        # Only events from this adapter-created session, never other conversations.
        events = []
        log_stream = log.open()
        log_stream.seek(log_offset)
        for line in log_stream:
            if session_id not in line: continue
            event = json.loads(line)
            context = event.get('context') or {}
            events.append({'timestamp': event.get('timestamp'), 'event': event.get('event'),
                           'context': {k: v for k,v in context.items() if k in ('toolName','modelId','providerId','model','skillName','skillPath','name','path')}})
        log_stream.close()
        (receipt/'events.json').write_text(json.dumps(events, indent=2)+'\n')
    except (OSError, ValueError, KeyError):
        metadata['event_collection'] = 'unavailable'
(receipt/'adapter.json').write_text(json.dumps(metadata, indent=2)+'\n')
sys.stdout.buffer.write(out)
sys.stdout.flush()
sys.stderr.buffer.write(err)
print('\n'+json.dumps({'steward_adapter': metadata}))
# Temporary runtime is retained for this experimental pilot, not globally installed.
raise SystemExit(124 if timed_out else process.returncode)
