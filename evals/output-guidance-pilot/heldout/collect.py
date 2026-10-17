"""Portable analysis of retained traces; does not change frozen oracle outcomes."""
import hashlib,json,statistics,sys
from pathlib import Path
base=Path(sys.argv[1]);destination=Path(sys.argv[2]);cohorts=[]
for client in ['codex','zcode']:
 manifest=json.loads((base/client/'manifest.json').read_text());rows=json.loads((base/client/'results.json').read_text());portable=[]
 for raw in rows:
  row={k:v for k,v in raw.items() if k not in ['workspace','receipt']}
  row['qualified_family']=row['task']!='stale-receipt'
  if not row['qualified_family']:row['qualification_note']='Frozen oracle conflicts with observational summary semantics; raw outcome retained, excluded symmetrically from quality comparison.'
  trace=Path(raw['workspace'])/'.native-check-calls.jsonl'
  calls=[json.loads(x) for x in trace.read_text().splitlines()] if trace.exists() else []
  row['native_call_summary']=[{'argv_head':x['argv'][:3],'help_requested':'--help' in x['argv'],'status':x['status'],'exit':x['exit'],'style':x['style']} for x in calls]
  # A successful parser/help invocation is not an executed verification.
  executed=[x for x in calls if '--help' not in x['argv'] and (x['argv'][:2]==['action','run'] or x['argv'][:1] in [['probe'],['benchmark']]) and (x['status'] in ['passed','failed'] or (x['argv'][:3]==['action','run','check.local'] and x['exit'] in [0,7]))]
  row['executed_native_verifications']=len(executed)
  row['known_action_text_verifications']=sum(x['status'] is None for x in executed)
  row['failed_executed_native_verifications']=sum(x['exit']!=0 for x in executed)
  row['native_inspection_calls']=sum(x['argv'][:2]==['action','inspect'] for x in calls)
  row['native_receipt_sha256']=hashlib.sha256((Path(raw['receipt'])/'client.stdout').read_bytes()).hexdigest() if raw.get('receipt') else None
  # Frozen ownership proxy remains intact. Interpretation is separate, not a regrade.
  if row.get('wrong_owner_observed_paths') and not row.get('wrong_owner_final_paths'):
   row['interpretation_note']='Outside-owner changes were restored; inspect trace to distinguish mistaken repair from deliberate negative verification. Conservative frozen metric retained.'
  if row.get('wrong_owner_final_paths'):
   row['interpretation_note']='Wrong-owner final change; native green does not satisfy the frozen policy/owner contract.'
  portable.append(row)
 summary=[]
 for arm in sorted({r['arm'] for r in portable}):
  rr=[r for r in portable if r['arm']==arm and r['qualified_family']]
  summary.append({'arm':arm,'attempted':len(rr),'strict_pass':sum(r.get('passed') is True and not r.get('timed_out') for r in rr),'native_pass':sum(r.get('native_pass',False) for r in rr),'wrong_owner_final_runs':sum(bool(r.get('wrong_owner_final_paths')) for r in rr),'outside_owner_observed_content_changes':sum(r.get('wrong_owner_content_changes',0) for r in rr),'protected_receipt_overwrites':sum('result.json' in r.get('protected_adapter_changes',[]) for r in rr),'observed_edit_episodes':sum(r.get('repair_edit_episodes',0) for r in rr),'owner_rework_changes':sum(r.get('owner_rework_changes',0) for r in rr),'added_lines':sum(r.get('changed_lines_added',0) for r in rr),'removed_lines':sum(r.get('changed_lines_removed',0) for r in rr),'executed_native_verifications':sum(r['executed_native_verifications'] for r in rr),'failed_executed_native_verifications':sum(r['failed_executed_native_verifications'] for r in rr),'median_wall_ms':statistics.median(r['duration_ms'] for r in rr if r.get('duration_ms') is not None),'extra_artifact_count':sum(len(r.get('extra_artifacts',[])) for r in rr)})
 cohorts.append({'client':client,'manifest':manifest,'raw_results_sha256':hashlib.sha256((base/client/'results.json').read_bytes()).hexdigest(),'summary':summary,'retained_attempts':len(portable),'qualified_attempts':sum(r['qualified_family'] for r in portable),'rows':portable})
result={'schema':'steward.ambiguous-owner-comparison/v1','date':'2026-10-13','cohorts':cohorts,'oracle_defect':{'family':'stale-receipt','frozen_checker_unchanged':True,'proof':'Frozen oracle accepts policy echo; native check then accepts an invalid actual package. Four raw original outcomes retained, family excluded from quality interpretation.'},'report_limits':['Observed edit episodes/content changes are actual sampled work, with possible missed transients; not complete semantic repair attempts.','Frozen outside-owner metric includes purposeful restored negative verification; interpretation does not alter oracle or frozen counts.','Help/parser navigation is separated from native verifications in derived metrics; original raw counters retained.','Current guidance holdout was authored by same maintainer session; revised guidance reruns are exposed regression evidence.','No consumer/private project data, official benchmark, broad safety or production ROI claim.']}
destination.parent.mkdir(parents=True,exist_ok=True);destination.write_text(json.dumps(result,indent=2)+'\n')
for c in cohorts:print(c['client'],json.dumps(c['summary']))
