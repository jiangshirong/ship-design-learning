"""Rebuild offline LaTeX assets after editing course formulas."""
import subprocess,sys,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
node=shutil.which('node')
if not node:raise SystemExit('Rebuilding formulas requires Node.js; running the learning app does not.')
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
def run(args):subprocess.run(args,cwd=ROOT,check=True,startupinfo=startup,creationflags=0x08000000)
run([sys.executable,str(ROOT/'tools/formal_course.py')])
run([str(ROOT/'runtime/godot.exe'),'--headless','--path',str(ROOT),'--script','res://qa/export_formula_values.gd'])
run([node,str(ROOT/'tools/latex/build.cjs')])
run([sys.executable,str(ROOT/'tools/verify_formal.py')])
run([sys.executable,str(ROOT/'tools/verify_notation.py')])
