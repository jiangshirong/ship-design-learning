import subprocess,pathlib,json
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'qa/repair-20261023'
cases=['tools/verify_formal.py','tools/verify_notation.py','qa/verify_bulkheads.py','tools/verify_yacht.py','modules/review/tools/verify_topics.py','modules/review/tools/verify_revision9p.py','modules/review/tools/verify_module11.py','modules/review/tools/verify_stability.py','modules/review/tools/verify_glossary_review.py']
rows=[]
for file in cases:
    p=subprocess.run(['python',file],cwd=ROOT,capture_output=True,text=True,encoding='utf8',errors='replace')
    log=p.stdout+p.stderr
    (OUT/(pathlib.Path(file).stem+'.log')).write_text(log,encoding='utf8')
    rows.append(dict(test=file,code=p.returncode,tail=log[-800:]))
    print(file,p.returncode,log[-150:],flush=True)
(OUT/'offline.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
raise SystemExit(any(r['code'] for r in rows))
