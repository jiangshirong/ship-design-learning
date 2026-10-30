import json,hashlib,datetime
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):return json.loads((ROOT/name).read_text('utf8'))
checks={}
for name,path in [('normal','qa/formal-runtime-normal.json'),('minimum','qa/formal-runtime-minimum.json'),('reopen','qa/formal-reopen.json'),('launcher','qa/checks-launcher.json'),('b02','qa/b02-normal.json'),('b02_minimum','qa/b02-minimum.json')]:
    rows=read(path);checks[name]=dict(passed=sum(r['passed'] for r in rows),failed=sum(not r['passed'] for r in rows),report=path)
numeric=read('qa/formal-data-checks.json');checks['calculation_and_content']=dict(passed=numeric['total']-numeric['failed'],failed=numeric['failed'],report='qa/formal-data-checks.json')
for name in ['normal','minimum']:
    path=f'qa/tooltip-runtime-{name}.json'
    rows=read(path);checks[f'tooltip_{name}']=dict(passed=sum(r['passed'] for r in rows),failed=sum(not r['passed'] for r in rows),report=path)
notation=read('qa/notation-checks.json');checks['source_notation']=dict(passed=notation['total']-notation['failed'],failed=notation['failed'],report='qa/notation-checks.json')
continuity=read('qa/continuity.json');rows=continuity['checks']
checks['transition_continuity']=dict(passed=sum(r['passed'] for r in rows),failed=sum(not r['passed'] for r in rows),rendered_frames=continuity['samples'],report='qa/continuity.json')
assert all(c['failed']==0 for c in checks.values()),checks
manifest=read('content/manifest.json')
files=[ROOT/'main.gd',ROOT/'project.godot',*sorted((ROOT/'core').glob('*.gd')),*sorted((ROOT/'view').glob('*.gd')),*sorted((ROOT/'content').rglob('*.json')),*sorted((ROOT/'tools').glob('*.py')),*sorted((ROOT/'assets').glob('*.glb')),*sorted((ROOT/'models').glob('*.blend'))]
report=dict(date=str(datetime.date.today()),revision='正式课程与DPI公式累计记录',engine='4.7.2.stable.official.ed1daf0bf',content=manifest,checks=checks,processes=read('qa/processes.json'),launcher=read('qa/launcher-process.json'),latex=read('qa/latex-build.json'),rendering=dict(formula_texture='DPITexture SVG',formula_em=30,title_px=20,body_px=22,ship_msaa='8x',canvas_scales=[1,1.25,1.5,2]),screenshots=[str(p.relative_to(ROOT)) for p in sorted((ROOT/'qa').glob('formal-*.png'))],human_review_pending=['Windows真实跨屏DPI与原生全屏','系统鼠标拖选手感','学习者对讲解顺序和效果的确认'],limits=['正式计算在构建时由独立Python模块计算，运行期间离线读取同一记录；预期结果仅用于核验。','缩放测试使用应用画布和自有窗口，不代表真实多显示器系统DPI验收。','船壳和横剖面为教学示意，不用于真实静水力积分。'],sha256={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files})
report['notation_final_processes']=read('qa/final-notation-processes.json')
report['tooltip_final_processes']=read('qa/tooltip-processes.json')
report['subscript_final_processes']=read('qa/subscript-processes.json')
report['subscript_typography']=read('content/latex_assets.json')['typography']
report['sha256']['tools/latex/build.cjs']=hashlib.sha256((ROOT/'tools/latex/build.cjs').read_bytes()).hexdigest()
report['notation_run_note']='一次最小窗口全量测试在载荷章中途返回目录，导致后续该章检查失败；增加调用栈诊断后复跑12914项全部通过，未复现，触发原因未确定。诊断代码已移除，未改变用户输入处理。这里汇总的是最后一次完整通过的结果。'
(ROOT/'qa/交付核验.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8')
text=f'''# 正式课程验证记录

日期：{report['date']}。Godot {report['engine']}，Compatibility。

交付包含{manifest['chapters']}章、{manifest['beats']}个讲解小段、25个正式计算步骤。ОСТ资料保留，课程与首页没有ОСТ入口。

| 验证 | 通过 | 失败 |
|---|---:|---:|
'''
for name,c in checks.items():text+=f'| {name} | {c["passed"]} | {c["failed"]} |\n'
text+='''
## 覆盖内容

- 俄文下标在MathJax排版前注册真实字宽和矢量字形，小写字高与英文下标对齐；取消估算字宽及事后替换缩小字形。检查所有俄文字形路径、连续字母间距、公式宽度及更新后的悬停范围；常规/最小窗口全课程回归通过，并保留100%、125%、150%、200%下多字母俄文下标实际截图（subscript-dpi-*.png）。此处缩放仍为应用画布缩放。
- 全课程符号对照原始Word作业/讲义，包含俄文下标、载荷原表质量矩、T2采用下标及诺曼直接变化记号；未命名中间量保留英文下标。覆盖164个讲解步骤及13组图内公式。见[逐项核对表](公式符号核对.md)。
- 俄文下标的悬停释义包含带重音俄语及中文翻译，按变量区分同名缩写（如T的н与η的н）。提示延迟为零，内部悬停后两帧内验证弹出；取消原生外层黑框，保留单层提示面板。中俄界面、长式分行、弹出/关闭、复制内容及最小窗口均检查。测试仅向应用内部投递悬停输入。实际截图见notation-hover-normal.png及notation-hover-minimum.png。
- 独立从确认输入计算全部25步，与确认包逐个比较数值和两份完整二分轨迹；核对九个油舱、十三项载荷、质量表整数及百分比。额外改变输入验证输出确实由公式产生。
- 核对B01=0.60；第二港5000吨、剩余136立方米；纵倾−2.8米、艏吃水6.3米、平均4.9米。
- 全船20616吨；竖向矩140879.07吨·米、纵向矩1547648.03吨·米；重心6.8335米、75.0702米。
- Т2采用44388吨；B计算26.61米、采用26.60米；H计算14.88米、采用14.89米；差额计算6.70吨、报告7吨。没有跳过确认包规定的中间取位。
- 每个小段中俄显示、正文完整高度、无对话框滚动条、不盖住当前讲解锚点；公式禁止整体缩小，长式按数学结构分行。
- 当前步骤新揭示的公式使用暖色边框、背景及字色，历史记录保持原样。验证D揭示后高亮、待揭示时不误标历史、A回退、高亮取消不改变排版、F2保留高亮与阅读位置；逐条检查正常/最小窗口的公式没有越过记录宽度。
- 六个首页节点通过应用内部点击进入课程；A/D/F2/Esc、长按重复事件、动画中切语言、退出取消、公式累计与回放去重、回退隐藏未来条目、滚动回看和F2保持公式行位置。
- B01在1440×900和1100×760窗口逐帧检查实际D前进、动作、停留、A回退和F2切换；不快进布局动画，每帧检查左侧剖面画布铺满高度，同布局步骤的图形尺寸不变。结果见continuity.json；画面见continuity-transition-1100.png及continuity-settled-1100.png。
- B02改为详细货船剖开、Blender货箱、已占/剩余舱容高亮；装载因数分句解释。两个窗口分别验证10段中俄文、实际D装货、A恢复、F2保持中间状态、节点复用、指示线锚点及动画质量/容积比例；最终15950吨、余舱136立方米。货箱外观不代表原题指定货种，舱容区域按确认计算比例生成，不从示意船壳积分。
- 移动货物时抽查中间帧，货物位置、全船重心与质量矩一致；旧课程ID迁移；损坏测试存档保留且阻止覆盖；重开与根目录真实启动脚本。
- 常规1440×900及最小1100×760窗口；应用画布100%、125%、150%、200%缩放。检查DPITexture类型、30px公式不缩小、可见附近纹理上限；船模8×MSAA单独检查。

## 实际画面

- [B01最小窗口](formal-B01-meaning-minimum.png)
- [当前公式与历史计算样式](formula-current-minimum.png)
- [B02剩余舱容](b02-volume2-zh-minimum.png)、[第二港装货中途](b02-loading-mid-normal.png)、[B02最终状态](b02-check-zh-normal.png)
- [油舱位置与质量矩](formal-L01-tank1-x-normal.png)
- [船宽求解与回代](formal-T13-back-normal.png)
- [最终差额](formal-T15-report-normal.png)
- [100%画布缩放](formal-dpi-100-normal.png)、[125%](formal-dpi-125-normal.png)、[150%](formal-dpi-150-normal.png)、[200%](formal-dpi-200-normal.png)

## 边界

测试只在自有屏幕外窗口中投递内部输入，没有控制系统鼠标，使用独立测试存档。真实Windows跨屏DPI、原生全屏和系统拖选手感仍需人工确认。自动检查不代表学习者已认可教学效果。

课程由tools/formal_course.py生成；计算模块为tools/course_calculations.py。可运行tools/build_formulas.py重建并核验，再运行tools/run_qa.py、tools/verify_launcher.py和tools/write_verification.py生成本记录。完整结果及源文件哈希见交付核验.json。
'''
(ROOT/'qa/正式课程验证.md').write_text(text,'utf8')
print(json.dumps(checks,ensure_ascii=False))
