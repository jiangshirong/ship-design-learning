"""Exercise the real Windows launcher, with viewport-only QA and isolated saves."""
import hashlib
import json
import os
import subprocess
import time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
COURSE=ROOT.parent
REPORT=ROOT/"modules/review/qa/topics-checks.json"
LOG=ROOT/"qa/topics-launcher.log"
USER=Path(os.environ["APPDATA"])/"Godot/app_userdata/船舶原理学习"
def snapshots():
    files=[USER/"progress.json"]
    files += [p for p in (USER/"review").glob("*.json") if not p.name.startswith("qa-")]
    return {str(p.relative_to(USER)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.exists()}
before=snapshots()
stamp=REPORT.stat().st_mtime_ns if REPORT.exists() else 0
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
args=["cmd","/d","/c",str(COURSE/"开始学习.cmd"),"--position","-6000,-6000",
      "--log-file",str(LOG),"--","--qa","--topics"]
result=subprocess.run(args,cwd=COURSE,startupinfo=startup,creationflags=0x08000000,timeout=15)
if result.returncode:raise RuntimeError("Launcher failed")
deadline=time.monotonic()+180
while not (REPORT.exists() and REPORT.stat().st_mtime_ns>stamp):
    if time.monotonic()>deadline:raise TimeoutError("Launcher QA did not finish; inspect topics-launcher.log")
    time.sleep(.2)
time.sleep(.5)
data=json.loads(REPORT.read_text(encoding="utf-8"));log=LOG.read_text(encoding="utf-8")
after=snapshots()
summary={"launcher":"开始学习.cmd","checks":data["checks"],"failures":data["failures"],
         "script_errors":log.count("SCRIPT ERROR"),"user_files_unchanged":before==after,
         "user_file_hashes_before":before,"user_file_hashes_after":after,
         "qa_inputs":"SubViewport/ViewPort push_input; offscreen, no-focus; no system mouse",
         "log":"qa/topics-launcher.log"}
(ROOT/"modules/review/qa/topics-launcher.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps({k:v for k,v in summary.items() if not k.startswith("user_file_hashes")},ensure_ascii=False))
raise SystemExit(bool(data["failures"] or "SCRIPT ERROR" in log or "ERROR:" in log or before!=after))
