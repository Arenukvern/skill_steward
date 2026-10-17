"""Bounded opt-in local comparison through the existing isolated native clients."""
import hashlib,json,os,shutil,subprocess,sys,tempfile,time
from pathlib import Path
from fixtures import prepare
from grade import grade

repo=Path(__file__).resolve().parents[2]
client=sys.argv[1]
if client not in ['codex','zcode']:raise SystemExit('client must be codex or zcode')
base=Path(os.environ.get('STEWARD_GUIDANCE_RESULTS',str(repo/'.dart_tool/output-guidance-pilot/qualified')))/client
if (base/'results.json').exists():raise SystemExit('Existing results retained. Choose a new STEWARD_GUIDANCE_RESULTS directory.')
base.mkdir(parents=True,exist_ok=True)
binary=Path(os.environ.get('STEWARD_GUIDANCE_BINARY',str(repo/'.dart_tool/steward-guidance-pilot')))
if not binary.is_file():raise SystemExit('Compile the native candidate and set STEWARD_GUIDANCE_BINARY.')
adapter=repo/'evals/skillgrade-pilot/isolated_client.py'
env=os.environ.copy();env.update({'STEWARD_PILOT_ROOT':str(adapter.parent),'STEWARD_PILOT_ARTIFACTS':str(base/'receipts')})
if client=='zcode':env['STEWARD_PILOT_ZCODE_STORAGE']=os.environ.get('STEWARD_PILOT_ZCODE_STORAGE','/tmp/steward-guidance-zcode-runtime')
env.pop('STEWARD_PILOT_CATALOG_PREFLIGHT',None)
protocol=json.loads((Path(__file__).parent/'protocol.json').read_text())
manifest={'protocol':protocol,'client':client,'binary_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'source_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (Path(__file__).parent/name for name in ['run.py','fixtures.py','grade.py','project_cli.py','protocol.json'])},'adapter_sha256':hashlib.sha256(adapter.read_bytes()).hexdigest(),'schedule':[['invalid-config','none'],['durability','grounded'],['invalid-config','generic'],['durability','generic'],['invalid-config','grounded'],['durability','none']]}
(base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
rows=[]
for task,arm in manifest['schedule']:
    root=Path(tempfile.mkdtemp(prefix=f'steward-guidance-{client}-{task}-{arm}-'))
    original=prepare(root,task)
    (root/'bin').mkdir();shutil.copy2(binary,root/'bin/steward-native')
    wrapper=(Path(__file__).parent/'project_cli.py').read_text().replace('STYLE_PLACEHOLDER',repr(arm))
    (root/'bin/steward').write_text(wrapper);(root/'bin/steward').chmod(0o755)
    goal='Repair the quick probe configuration while preserving the native checker and all unrelated contract fields.' if task=='invalid-config' else 'Qualify the strict pilot.smoke benchmark by tracking only its required contract inputs. Keep the fake private note unchanged and untracked.'
    args=['probe','--profile','quick','--json'] if task=='invalid-config' else ['benchmark','--scenario','pilot.smoke','--strict','--json']
    before=subprocess.run([str(binary),*args,'--goal',goal,'--guidance' if arm=='grounded' else '--no-guidance'],cwd=root,capture_output=True,text=True,timeout=30)
    payload=json.loads(before.stdout)
    guidance=payload.pop('guidance',None)
    if guidance:
        for key in ['next_argv','verify_argv']:
            if guidance.get(key) and guidance[key][0]=='steward':guidance[key][0]='./bin/steward'
    if arm=='grounded':
        if not guidance:raise SystemExit('Grounded arm lacks guidance; refuse unqualified trial')
        payload['guidance']=guidance
    elif arm=='generic':payload['advice']='Inspect the error, repair the relevant configuration, and rerun the check. Follow normal repository practices.'
    (root/'result.json').write_text(json.dumps(payload,indent=2)+'\n')
    protected={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'check.sh',root/'AGENTS.md',root/'skills.json',root/'private-note.txt',root/'result.json',root/'bin/steward',root/'bin/steward-native', *list((root/'steward/scenarios').glob('*.yaml'))]}
    prompt=f'{goal}\nRead result.json for the observed native outcome. Use your normal tools to finish this disposable fixture task. The only qualified executable for this fixture is ./bin/steward. Invoke that exact path for every Steward command; login shells may select an older global copy. Do not alter check.sh, AGENTS.md, skills.json, result.json, bin/steward, the scenario manifest or private-note.txt, widen permissions, or create governance documents. Local Git commits of the required inputs are authorized for the durability task only. End with the native outcome you observed.\n'
    runenv=env.copy();runenv['PATH']=str(root/'bin')+':'+env.get('PATH','')
    start_ns=time.time_ns()
    start=time.monotonic()
    p=subprocess.run([sys.executable,str(adapter),client],cwd=root,env=runenv,input=prompt,capture_output=True,text=True,timeout=330)
    (base/f'{task}-{arm}.stdout').write_text(p.stdout);(base/f'{task}-{arm}.stderr').write_text(p.stderr)
    metadata=None
    for line in p.stdout.splitlines():
        try:
            parsed=json.loads(line)
            if isinstance(parsed,dict) and 'steward_adapter' in parsed:metadata=parsed['steward_adapter']
        except ValueError:pass
    row={'task':task,'arm':arm,'client':client,'runner_duration_ms':round((time.monotonic()-start)*1000),'process_exit':p.returncode,'guidance_bytes':len(json.dumps(guidance).encode()) if arm=='grounded' else 0,'setup_result':before.returncode,'workspace':str(root)}
    if metadata is None:
        row.update({'outcome':'blocked_adapter','passed':None});rows.append(row)
        (base/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(client,task,arm,'blocked_adapter',flush=True);break
    row['duration_ms']=metadata['duration_ms'];row['receipt']=metadata['receipt'];row['timed_out']=metadata['timed_out']
    native=grade(root,task,original,binary)
    for name,digest in protected.items():
        path=root/name
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest()!=digest:native['violations'].append('changed protected '+name);native['passed']=False
    row.update(native);row['outcome']='timeout' if metadata['timed_out'] else 'pass' if native['passed'] else 'fail'
    known={'steward.yaml','check.sh','AGENTS.md','skills.json','private-note.txt','result.json','.native-check-calls.jsonl'}
    row['extra_artifacts']=[str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and not any(v in p.parts for v in ['.git','.zcode','.dart_tool','bin']) and str(p.relative_to(root)) not in known and not str(p.relative_to(root)).startswith('steward/scenarios/')]
    checks=[]
    trace=root/'.native-check-calls.jsonl'
    if trace.exists():checks=[json.loads(line) for line in trace.read_text().splitlines() if line]
    native_calls=[x for x in checks if x['argv'] and x['argv'][0] in ['probe','benchmark']]
    row['time_to_first_native_check_ms']=round((native_calls[0]['start_ns']-start_ns)/1e6) if native_calls else None
    row['native_check_attempts']=len(native_calls)
    row['recorded_advice_styles']=sorted(set(x['style'] for x in checks))
    row['repair_attempts_observed']=sum(x['exit']!=0 for x in native_calls)
    usage={};calls=0;model=None
    stdout=(Path(metadata['receipt'])/'client.stdout').read_text()
    if client=='codex':
        for line in stdout.splitlines():
            try:
                e=json.loads(line)
                if e.get('type')=='turn.completed':usage=e.get('usage',{})
                if e.get('type')=='item.completed' and e.get('item',{}).get('type')=='command_execution':calls+=1
            except ValueError:pass
        model='gpt-5.6-sol'
    else:
        try:
            response=json.loads(stdout);usage=response.get('usage',{})
            events=json.loads((Path(metadata['receipt'])/'events.json').read_text())
            calls=sum(e.get('event')=='tool.call.started' for e in events)
            model=next((e.get('context',{}).get('modelId') for e in events if e.get('context',{}).get('modelId')),None)
        except (ValueError,OSError):pass
    row.update({'usage':usage or None,'tool_calls':calls if usage else None,'model':model,'cost_usd':None,'time_to_first_useful_action_ms':None,'repair_attempts':None,'human_interventions':0})
    rows.append(row);(base/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
    print(client,task,arm,row['outcome'],row['duration_ms'],flush=True)
    if client=='zcode' and model not in [None,'moonshotai/kimi-k2.6']:
        print('STOP model drift',model,flush=True);break
