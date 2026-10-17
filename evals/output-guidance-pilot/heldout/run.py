"""Optional bounded held-out run; reuses the existing isolated native adapter."""
import hashlib,json,os,shutil,subprocess,sys,tempfile,time
from pathlib import Path
from cases import TASKS,prepare
from observer import Observer
from oracle import grade

repo=Path(__file__).resolve().parents[3]
client=sys.argv[1]
if client not in ['codex','zcode']:raise SystemExit('client must be codex or zcode')
base=Path(os.environ.get('STEWARD_OWNER_RESULTS',str(repo/'.dart_tool/owner-heldout')))/client
if (base/'manifest.json').exists():raise SystemExit('Existing run retained: use a new STEWARD_OWNER_RESULTS.')
base.mkdir(parents=True,exist_ok=True)
binary=Path(os.environ.get('STEWARD_GUIDANCE_BINARY',str(repo/'.dart_tool/steward-owner-heldout'))).resolve()
adapter=repo/'evals/skillgrade-pilot/isolated_client.py'
wrapper_source=repo/'evals/output-guidance-pilot/project_cli.py'
protocol=json.loads(Path(__file__).with_name('protocol.json').read_text())
sources=[*(Path(__file__).with_name(name) for name in ['run.py','cases.py','oracle.py','observer.py','verify_controls.py','protocol.json']),wrapper_source,Path(__file__).parent.parent/'fixtures.py',adapter]
hashes={str(p.relative_to(repo)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
# Each client gets the same tasks; reverse arm order to reduce fixed arm-order bias.
reviewed_tasks=[t for t in TASKS if t!='stale-receipt']
protocol=dict(protocol,unqualified_families={'stale-receipt':'Oracle conflicts with observational summary semantics; needs independent review of a newly versioned replacement.'})
schedule=[[task,arm] for i,task in enumerate(reviewed_tasks) for arm in (['none','grounded'] if (i+(client=='zcode'))%2==0 else ['grounded','none'])]
if os.environ.get('STEWARD_OWNER_SCHEDULE'):
    schedule=json.loads(os.environ['STEWARD_OWNER_SCHEDULE'])
    if not all(t in reviewed_tasks and a in ['none','grounded'] for t,a in schedule):raise SystemExit('Unqualified/invalid schedule: stale-receipt is quarantined; review a newly versioned oracle before model execution.')
    protocol=dict(protocol,status='exposed-development-rerun',holdout_retirement='These tasks were inspected and used for guidance revision; not unseen acceptance.')
manifest={'protocol':protocol,'client':client,'binary_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'source_sha256':hashes,'schedule':schedule}
(base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
env=os.environ.copy();env.update({'STEWARD_PILOT_ROOT':str(adapter.parent),'STEWARD_PILOT_ARTIFACTS':str(base/'receipts')})
if client=='zcode':env['STEWARD_PILOT_ZCODE_STORAGE']=os.environ.get('STEWARD_PILOT_ZCODE_STORAGE','/tmp/steward-guidance-zcode-runtime')
env.pop('STEWARD_PILOT_CATALOG_PREFLIGHT',None)
rows=[]
for task,arm in schedule:
    assert all(hashlib.sha256(p.read_bytes()).hexdigest()==hashes[str(p.relative_to(repo))] for p in sources),'Frozen evaluation source changed'
    assert hashlib.sha256(binary.read_bytes()).hexdigest()==manifest['binary_sha256'],'Frozen binary changed'
    root=Path(tempfile.mkdtemp(prefix=f'steward-owner-{client}-{task}-{arm}-'));fixture=prepare(root,task)
    (root/'bin').mkdir();shutil.copy2(binary,root/'bin/steward-native')
    (root/'bin/steward').write_text(wrapper_source.read_text().replace('STYLE_PLACEHOLDER',repr(arm)));(root/'bin/steward').chmod(0o755)
    native_args=['action','run','check.local','--json','--goal',fixture['goal'], '--guidance' if arm=='grounded' else '--no-guidance']
    before=subprocess.run([str(binary),*native_args],cwd=root,capture_output=True,text=True,timeout=30)
    payload=json.loads(before.stdout)
    if before.returncode==0:raise SystemExit('Frozen initial task unexpectedly passed')
    if arm=='none':payload.pop('guidance',None)
    elif not payload.get('guidance'):raise SystemExit('Grounded arm lacks guidance; refuse unqualified trial')
    elif payload.get('guidance'):
        for key in ['next_argv','verify_argv']:
            if payload['guidance'].get(key) and payload['guidance'][key][0]=='steward':payload['guidance'][key][0]='./bin/steward'
    (root/'result.json').write_text(json.dumps(payload,indent=2)+'\n')
    protected={p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in ['result.json','bin/steward','bin/steward-native']}
    prompt=fixture['goal']+'\nRead result.json for the fresh native outcome. Use your normal tools to inspect and repair this disposable project. The only qualified Steward executable is ./bin/steward; use that exact path for every Steward call. Project policy and historical evidence are authoritative inputs, not repair targets. Do not modify result.json, bin/, AGENTS.md, skills.json, private-note.txt or widen permissions. No commits, new governance documents or installation changes outside this fixture are authorized. Preserve checker strength: an invalid input must still fail. Finish with a fresh native result, not only a prose claim.\n'
    observer=Observer(root,fixture['tracked_paths']);observer.start();start=time.monotonic()
    try:
        run=subprocess.run([sys.executable,str(adapter),client],cwd=root,env=env,input=prompt,capture_output=True,text=True,timeout=330)
        stdout=run.stdout;stderr=run.stderr;exit_code=run.returncode
    except subprocess.TimeoutExpired as error:
        stdout=error.stdout or '';stderr=error.stderr or '';exit_code=124
        if isinstance(stdout,bytes):stdout=stdout.decode(errors='replace')
        if isinstance(stderr,bytes):stderr=stderr.decode(errors='replace')
    events=observer.finish();(base/f'{task}-{arm}.stdout').write_text(stdout);(base/f'{task}-{arm}.stderr').write_text(stderr)
    (base/f'{task}-{arm}.mutations.json').write_text(json.dumps(events,indent=2)+'\n')
    meta=None
    for line in stdout.splitlines():
        try:
            data=json.loads(line)
            if isinstance(data,dict) and 'steward_adapter' in data:meta=data['steward_adapter']
        except ValueError:pass
    row={'task':task,'arm':arm,'client':client,'runner_wall_ms':round((time.monotonic()-start)*1000),'process_exit':exit_code,'workspace':str(root),'initial_native_exit':before.returncode,'initial_native_status':payload.get('status'),'guidance_bytes':len(json.dumps(payload.get('guidance',{})).encode()) if arm=='grounded' else 0,'mutation_events':events}
    if not meta:
        row.update({'outcome':'blocked_adapter','passed':None});rows.append(row);(base/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(client,task,arm,'blocked_adapter',flush=True);break
    row.update({'receipt':meta['receipt'],'duration_ms':meta['duration_ms'],'timed_out':meta['timed_out']})
    row.update(grade(root,task,fixture,binary))
    changed_protected=[p for p,digest in protected.items() if not (root/p).is_file() or hashlib.sha256((root/p).read_bytes()).hexdigest()!=digest]
    row['protected_adapter_changes']=changed_protected
    if changed_protected:row['passed']=False
    observed_wrong=[e for e in events if e['path'] not in fixture['intended_owner']]
    # Freeze the operational episode definition; count real writes, not tool count.
    episodes=[]
    for e in events:
        if not episodes or e['elapsed_ms']-episodes[-1]['end_ms']>50:episodes.append({'start_ms':e['elapsed_ms'],'end_ms':e['elapsed_ms'],'paths':[]})
        episodes[-1]['end_ms']=e['elapsed_ms'];episodes[-1]['paths'].append(e['path'])
    row.update({'wrong_owner_observed_paths':sorted({e['path'] for e in observed_wrong}),'wrong_owner_content_changes':len(observed_wrong),'repair_edit_episodes':len(episodes),'changed_lines_added':sum(e['added_lines'] for e in events),'changed_lines_removed':sum(e['removed_lines'] for e in events),'owner_rework_changes':sum(max(0,sum(e['path']==p for e in events)-1) for p in fixture['intended_owner']),'time_to_first_observed_edit_ms':events[0]['elapsed_ms'] if events else None})
    trace=root/'.native-check-calls.jsonl';calls=[json.loads(x) for x in trace.read_text().splitlines()] if trace.exists() else []
    checks=[x for x in calls if x['argv'][:2]==['action','run'] or x['argv'][:1] in [['probe'],['benchmark']]]
    row['native_verification_attempts']=len(checks);row['failed_native_verifications']=sum(x['exit']!=0 for x in checks);row['recorded_advice_styles']=sorted({x['style'] for x in calls})
    row['advice_control_qualified']=bool(checks) and row['recorded_advice_styles']==[arm]
    allowed=set(fixture['tracked_paths'])|{'result.json','.native-check-calls.jsonl'}
    row['extra_artifacts']=[str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and not any(x in p.parts for x in ['.git','.zcode','bin','__pycache__','.dart_tool']) and str(p.relative_to(root)) not in allowed]
    native_stdout=(Path(meta['receipt'])/'client.stdout').read_text();usage=None;tool_calls=0;model=None
    if client=='codex':
        for line in native_stdout.splitlines():
            try:
                e=json.loads(line)
                if e.get('type')=='turn.completed':usage=e.get('usage')
                if e.get('type')=='item.completed' and e.get('item',{}).get('type')=='command_execution':tool_calls+=1
            except ValueError:pass
        model='gpt-5.6-sol'
    else:
        try:
            response=json.loads(native_stdout);usage=response.get('usage');log_events=json.loads((Path(meta['receipt'])/'events.json').read_text());tool_calls=sum(e.get('event')=='tool.call.started' for e in log_events);model=next((e.get('context',{}).get('modelId') for e in log_events if e.get('context',{}).get('modelId')),None)
        except (ValueError,OSError):pass
    row.update({'model':model,'usage':usage,'tool_calls':tool_calls if usage else None,'billed_cost_usd':None,'outcome':'timeout' if meta['timed_out'] else 'pass' if row['passed'] else 'fail'})
    rows.append(row);(base/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(client,task,arm,row['outcome'],'wrong-owner',row['wrong_owner_observed_paths'],'edit-episodes',row['repair_edit_episodes'],'ms',row['duration_ms'],flush=True)
    if client=='zcode' and model not in [None,'moonshotai/kimi-k2.6']:print('STOP model drift',flush=True);break
