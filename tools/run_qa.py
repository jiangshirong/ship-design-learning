import json, subprocess, time, os, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ENGINE=ROOT/'runtime/godot.exe'
def run(name,args,timeout=60):
    start=time.time()
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    with (ROOT/'qa'/f'{name}.log').open('w',encoding='utf-8') as stream:
        p=subprocess.Popen([str(ENGINE),'--path',str(ROOT),*args],stdout=stream,stderr=stream,startupinfo=startup,creationflags=0x08000000)
        try: code=p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            p.terminate();p.wait(5);raise RuntimeError(f'Timeout of owned PID {p.pid}')
    text=(ROOT/'qa'/f'{name}.log').read_text(encoding='utf-8')
    print(name,code,text[-1500:] if code or 'ERROR' in text else text[-750:],flush=True)
    if code or 'SCRIPT ERROR' in text or 'ERROR:' in text:raise RuntimeError(name)
    return dict(name=name,pid=p.pid,normal_exit=True,exit_code=code,started=start)
if __name__=='__main__':
    records=[run('import',['--headless','--editor','--import','--quit'])]
    if '--import-only' not in sys.argv:
        records.append(run('pair',['--position','-6000,-6000','--','--qa','--pair'],90))
        records.append(run('pair-minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--pair','--minimum'],90))
        records.append(run('teaching',['--position','-6000,-6000','--','--qa','--teaching'],90))
        records.append(run('teaching-minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--teaching','--minimum'],90))
        records.append(run('fuel',['--position','-6000,-6000','--','--qa','--fuel'],90))
        records.append(run('fuel-minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--fuel','--minimum'],90))
        records.append(run('progress',['--position','-6000,-6000','--','--qa','--progress'],90))
        records.append(run('progress-minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--progress','--minimum'],90))
        records.append(run('b02',['--position','-6000,-6000','--','--qa','--b02'],90))
        records.append(run('b02-minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--b02','--minimum'],90))
        records.append(run('runtime',['--position','-6000,-6000','--','--qa','--formal','--full'],360))
        records.append(run('minimum',['--position','-6000,-6000','--resolution','1100x760','--','--qa','--formal','--full','--minimum'],360))
        records.append(run('reopen',['--position','-6000,-6000','--','--qa','--formal','--reopen'],30))
        records.append(run('continuity',['--position','-6000,-6000','--','--qa','--continuity'],90))
    (ROOT/'qa/processes.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
