"""Rendered regression, isolated application saves and internal input only."""
import json, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'qa/repair-20261023'
CASES=[('repair',['--chapter-repair']),('repair-minimum',['--chapter-repair','--minimum']),
 ('formal',['--formal','--full']),('formal-minimum',['--formal','--full','--minimum']),
 ('topics',['--topics']),('topics-minimum',['--topics','--minimum']),
 ('bulkheads',['--bulkheads']),('bulkheads-minimum',['--bulkheads','--minimum']),
 ('approximations',['--approximations']),('approximations-minimum',['--approximations','--minimum']),
 ('inspection',['--inspection-all']),('inspection-minimum',['--inspection-all','--minimum']),
 ('source',['--source-check']),('camera',['--camera-free']),('optimization',['--optimization']),
 ('word-picker',['--word-picker']),('scientific',['--scientific-review']),
 ('revision9p',['--revision9p']),('module11',['--module11']),('yacht',['--yacht'])]
chosen=set(sys.argv[1:])
records=[]
for name,args in CASES:
    if chosen and name not in chosen:continue
    path=OUT/(name+'.log');start=time.monotonic()
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
    with path.open('w',encoding='utf8') as out:
        proc=subprocess.Popen([str(ROOT/'runtime/godot.exe'),'--path',str(ROOT),'--position','-6000,-6000','--','--qa',*args],cwd=ROOT,stdout=out,stderr=out,startupinfo=si,creationflags=0x08000000)
        try:code=proc.wait(timeout=480)
        except subprocess.TimeoutExpired:proc.terminate();proc.wait(10);code='timeout'
    log=path.read_text(encoding='utf8');errors=[l for l in log.splitlines() if any(x in l for x in ['SCRIPT ERROR','ERROR:','WARNING:'])]
    row=dict(name=name,exit_code=code,seconds=round(time.monotonic()-start,2),errors=errors,tail=log.splitlines()[-4:])
    records.append(row);(OUT/'regression.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
    print(name,code,round(row['seconds']),errors[:6],row['tail'][-1:],flush=True)
