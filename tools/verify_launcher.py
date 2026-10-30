import os,json,subprocess,time,ctypes
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
report=ROOT/'qa/checks-launcher.json'
start=time.time()
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
subprocess.run(['cmd','/d','/c',str(ROOT.parent/'开始学习.cmd'),'--position','-6000,-6000','--','--qa','--formal','--launch-only'],check=True,startupinfo=startup,creationflags=0x08000000,timeout=10)
deadline=time.time()+25
while time.time()<deadline:
    if report.exists() and report.stat().st_mtime>=start:break
    time.sleep(.25)
else:raise RuntimeError('Launcher produced no fresh report')
checks=json.loads(report.read_text(encoding='utf-8'));assert all(x['passed'] for x in checks),checks
process=json.loads((ROOT/'qa/launcher-process.json').read_text(encoding='utf-8'))
kernel=ctypes.windll.kernel32;kernel.OpenProcess.restype=ctypes.c_void_p
for _ in range(30):
    handle=kernel.OpenProcess(0x100000,False,process['pid'])
    if not handle:break
    result=kernel.WaitForSingleObject(ctypes.c_void_p(handle),100)
    kernel.CloseHandle(ctypes.c_void_p(handle))
    if result==0:break
else:raise RuntimeError('Owned launcher process still alive')
process.update(normal_exit=True,remaining=False,started=start)
(ROOT/'qa/launcher-process.json').write_text(json.dumps(process,indent=2),encoding='utf-8')
print('Real root launcher passed',process)
