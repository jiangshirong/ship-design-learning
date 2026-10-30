import subprocess,json,time,sys,concurrent.futures
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
OUT.joinpath('.gdignore').touch()
def run(name,args,timeout):
 start=time.time();log=OUT/(name+'.log')
 with log.open('w',encoding='utf8') as stream:
  p=subprocess.Popen(args,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
  try:code=p.wait(timeout=timeout)
  except subprocess.TimeoutExpired:p.kill();p.wait();code='timeout'
 text=log.read_text(encoding='utf8',errors='replace')
 return dict(name=name,exit=code,seconds=round(time.time()-start,2),log=str(log.relative_to(ROOT)),tail=text[-2500:])
def offline():
 specs=['tools/verify_formal.py','tools/verify_notation.py','qa/verify_bulkheads.py','tools/verify_yacht.py','modules/review/tools/verify_topics.py','modules/review/tools/verify_revision9p.py','modules/review/tools/verify_module11.py','modules/review/tools/verify_stability.py']
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  rows=list(pool.map(lambda f:run('offline-'+Path(f).stem,[sys.executable,f],120),specs))
 (OUT/'offline.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
 for r in rows:print(r['name'],r['exit'],flush=True)
def runtime():
 specs=[('original-normal',['--full']),('topics-normal',['--topics']),('bulkheads-normal',['--bulkheads']),('approx-normal',['--approximations']),('original-minimum',['--full','--minimum']),('topics-minimum',['--topics','--minimum']),('bulkheads-minimum',['--bulkheads','--minimum']),('approx-minimum',['--approximations','--minimum']),('inspection',['--inspection-all']),('optimization',['--optimization']),('camera',['--camera-free']),('sources',['--source-check']),('words',['--word-picker']),('review',['--scientific-review'])]
 rows=[]
 for name,flags in specs:
  args=[str(ROOT/'runtime/godot.exe'),'--path',str(ROOT),'--log-file',str(OUT/(name+'-godot.log')),'--','--qa']+flags
  r=run(name,args,240);rows.append(r);(OUT/'runtime.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
  print(name,r['exit'],r['seconds'],flush=True)
if sys.argv[-1]=='offline':offline()
else:runtime()
