"""Disposable native fixtures; no project/customer data or model dependency."""
import json, subprocess
from pathlib import Path


def prepare(root: Path, task: str):
    root.mkdir(parents=True, exist_ok=True)
    config = {
        'schema':'steward/v1', 'repo':{'id':'pilot','archetype':'cli_tool'},
        'harness':{'name':'steward','mode':'cli','entrypoints':{'cli':'steward'}},
        'adoption':{'status':'adopting','owner':'pilot','gate':{'pillar':'quality'}},
        'stewardship':{
            'governance':{'charter':'AGENTS.md'},'knowledge':{'docs_map':'AGENTS.md'},
            'repo_quality':{'contract_spec':'steward.yaml','maturity_model':'general_stewardship'},
            'skill_lifecycle':{'installable_skills':True},'quality':{'validate':'steward validate'},
            'harness':{'enabled':True},'release':{'changelog':'CHANGELOG.md'},
            'review_handoff':{'moe_required_for_architecture':True},
            'strategic_alignment':{'vision_source':'AGENTS.md'},
            'security':{'action_effects':'required'},'org':{'owners':'AGENTS.md'},
        },
        'actions':{'check.local':{
            'kind':'command','desc':'Run the immutable native fixture check.',
            'command':{'argv':['/bin/sh','check.sh'],'shell':False},'cwd':'.',
            'effects':{'fs_read':['check.sh'],'fs_write':[],'git':False,'network':False,'secrets':False,'destructive':False},
            'safety':{'class':'observe','default_policy':'auto','requires_confirmation':False},
            'limits':{'timeout_ms':60000 if task=='invalid-config' else 10000,'max_output_bytes':200000},
            'outputs':[{'id':'stdout','kind':'stream','required':True,'retention':'summary','format':'text'}],
            'evidence':{'redact':[]},
        }},
        'probes':{'quick':{'profile':'quick','actions':['check.local']}},
        'diagnostics':{'cases':{}},'unknown_cases':{'path':'.steward/unknown-cases/','retention':'local'},
        'provenance':{'dependencies':[],'artifacts':[],'benchmarks':[]},
    }
    (root/'check.sh').write_text('echo native-fixture-pass\n')
    (root/'AGENTS.md').write_text('Keep the original task narrow. check.sh is an immutable native owner.\n')
    (root/'skills.json').write_text('{"skills":[]}\n')
    (root/'private-note.txt').write_text('Disposable fake private note; keep unchanged and untracked.\n')
    if task=='durability':
        subprocess.run(['git','init','-q'],cwd=root,check=True)
        subprocess.run(['git','config','user.name','Fixture'],cwd=root,check=True)
        subprocess.run(['git','config','user.email','fixture@example.invalid'],cwd=root,check=True)
        subprocess.run(['git','remote','add','origin','https://example.com/fixture.git'],cwd=root,check=True)
        subprocess.run(['git','add','check.sh','AGENTS.md','skills.json'],cwd=root,check=True)
        import os
        commit_env=os.environ.copy();commit_env.update({'GIT_AUTHOR_DATE':'2026-10-13T00:00:00Z','GIT_COMMITTER_DATE':'2026-10-13T00:00:00Z'})
        subprocess.run(['git','commit','-qm','Immutable fixture owner'],cwd=root,env=commit_env,check=True)
        rev=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
        config['provenance']['benchmarks']=[{'id':'pilot.smoke','manifest':'steward/scenarios/pilot.smoke.yaml'}]
        scenario={'schema':'steward/scenario-manifest/v1','repo':'pilot','scenario':'pilot.smoke','status':'runnable',
                  'source':{'git':'https://example.com/fixture.git','commit':rev,'steward_contract':'steward.yaml'},
                  'safe_first_probe':'check.local','required_actions':['check.local'],
                  'artifacts':[{'id':'contract','kind':'yaml','path':'steward.yaml','required':True,'durability':'input'},
                               {'id':'checker','kind':'shell','path':'check.sh','required':True,'durability':'input'}],
                  'blocked_by':None,'owner':'pilot'}
        (root/'steward/scenarios').mkdir(parents=True)
        (root/'steward/scenarios/pilot.smoke.yaml').write_text(json.dumps(scenario,indent=2)+'\n')
    (root/'steward.yaml').write_text(json.dumps(config,indent=2)+'\n')
    return config
