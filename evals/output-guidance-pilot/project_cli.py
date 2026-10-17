#!/usr/bin/env python3
"""Experimental projection wrapper; forwards native exit unchanged in every arm."""
import json,os,subprocess,sys,time
from pathlib import Path

style=STYLE_PLACEHOLDER
root=Path(__file__).resolve().parent.parent
args=[str(Path(__file__).with_name('steward-native')),*sys.argv[1:]]
guided=bool(sys.argv[1:]) and (sys.argv[1] in ['doctor','probe','benchmark','eval','blocked','validate'] or sys.argv[1:3]==['action','run'])
if guided:args.append('--guidance' if style=='grounded' else '--no-guidance')
start=time.time_ns()
p=subprocess.run(args,capture_output=True)
out=p.stdout
status=None
try:
    payload=json.loads(out)
    status=payload.get('status',payload.get('result'))
    if style=='generic':payload['advice']='Inspect the error, repair the relevant configuration, and rerun the check. Follow normal repository practices.'
    out=(json.dumps(payload,indent=2)+'\n').encode()
except ValueError:
    if style=='generic':out+=b'\nAdvice: inspect the error, repair configuration and rerun the check.\n'
with (root/'.native-check-calls.jsonl').open('a') as f:
    f.write(json.dumps({'start_ns':start,'end_ns':time.time_ns(),'argv':sys.argv[1:],'status':status,'exit':p.returncode,'style':style})+'\n')
sys.stdout.buffer.write(out);sys.stderr.buffer.write(p.stderr)
raise SystemExit(p.returncode)
