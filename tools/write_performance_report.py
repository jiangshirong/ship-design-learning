"""Summarize the rendered-window benchmark and isolated regression results."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "qa"


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


before = read("qa/performance-before.json")
after = read("qa/performance-after.json")
b = {row["name"]: row for row in before["rows"]}
a = {row["name"]: row for row in after["rows"]}
stress = read("qa/performance-stress.json")
math = read("qa/performance-math-results.json")
launch = read("qa/performance-launcher.json")
physics = read("modules/review/qa/stability-physics.json")
assert not stress["failures"] and not math["failures"] and not launch["failures"]
assert physics["failures"] == 0

lines = [
    "# 性能优化验证 · 2026-10-20",
    "",
    "更新原工程与原「开始学习.cmd」入口。课程、题库、几何资源及正常学习存档格式未改动。",
    "",
    "## 测量方法",
    "",
    "- 同一机器：NVIDIA GeForce RTX 4050 Laptop GPU；Godot 4.7.2，Compatibility 渲染器，1440×900，原 8× MSAA。",
    "- 基准使用修改前脚本的独立副本，课程和资源与主工程相同；两次测试串行运行，采样路径与窗口相同。",
    "- 使用真实渲染窗口，放在屏幕外并设置不抢焦点；没有使用无界面模式测量画面性能，没有移动系统鼠标。",
    "- 每个页面记录 180 帧；稳性后半段另采样 90 次连续状态更新。首次打开耗时包括等待 8 帧完成布局。",
    "- 启动是新建应用进程，从引擎计时开始到首页完成布局；不是重启系统后的冷磁盘测试。",
    "- 内存采用 Godot 的 MEMORY_STATIC；渲染内存采用 RENDER_VIDEO_MEM_USED，均为 MiB，不等同于任务管理器的进程工作集。",
    "- 帧间隔包括 CPU、绘制与等待；静止页面受约 165 Hz 的刷新节奏限制，不能据此声称静止页帧率倍增。",
    "",
    "## 主要实测结果",
    "",
    "| 项目 | 修改前 | 修改后 |",
    "|---|---:|---:|",
]
for label, old, new, unit in [
    ("首页可操作时间", (b["home"]["startup_ms"] + b["home"]["open_ms"]) / 1000,
     (a["home"]["startup_ms"] + a["home"]["open_ms"]) / 1000, "s"),
    ("首页引擎分配内存", b["home"]["static_mb"], a["home"]["static_mb"], "MiB"),
    ("首页渲染内存", b["home"]["render_mb"], a["home"]["render_mb"], "MiB"),
    ("稳性状态更新中位耗时", b["stability_state_updates"]["p50_ms"],
     a["stability_state_updates"]["p50_ms"], "ms"),
    ("稳性状态更新 P95", b["stability_state_updates"]["p95_ms"],
     a["stability_state_updates"]["p95_ms"], "ms"),
    ("连续状态更新时的中位帧间隔", b["stability_state_updates"]["frame_p50_ms"],
     a["stability_state_updates"]["frame_p50_ms"], "ms"),
    ("连续状态更新时的 P95 帧间隔", b["stability_state_updates"]["frame_p95_ms"],
     a["stability_state_updates"]["frame_p95_ms"], "ms"),
]:
    lines.append(f"| {label} | {old:.2f} {unit} | {new:.2f} {unit} |")
lines += [
    "",
    "状态更新包括本次船舶结果、模型、曲线与公式记录的更新，不是单独的求解器耗时，也不是整个程序的提速倍数。",
    "",
    "## 页面加载与资源",
    "",
    "网格数为当时整棵场景树的 MeshInstance3D 数，包含保留的最近场景；绘制调用为当前帧的实际渲染统计。",
    "",
    "| 页面 | 首次打开 ms（前→后） | 分配内存 MiB（前→后） | 网格节点（前→后） | 绘制调用（前→后） |",
    "|---|---:|---:|---:|---:|",
]
names = {"home": "首页", "reading": "读题", "scientific": "科学复习",
         "loads": "载荷与重心 L06:x", "bulkheads": "分舱 BH:opening",
         "stability": "稳性后半段", "damage": "进水", "freeboard": "干舷"}
for key, name in names.items():
    x, y = b[key], a[key]
    opening = "见启动时间" if key == "home" else f'{x["open_ms"]:.1f} → {y["open_ms"]:.1f}'
    lines.append(f'| {name} | {opening} | {x["static_mb"]:.1f} → {y["static_mb"]:.1f} | '
                 f'{x["meshes"]} → {y["meshes"]} | {x["draw_calls"]:.0f} → {y["draw_calls"]:.0f} |')
lines += [
    "",
    "按需加载将部分成本移到首次进入页面，因此读题、科学复习和部分章节首次进入较慢；首页不再提前建立它们的船模。",
    "同一连续专题中保留场景。跨专题只保留当前及最近一个重型场景；再次进入尚在缓存中的场景直接复用，已淘汰的场景按需恢复。",
    "",
    "| 页面 | 静止画面中位帧间隔 ms（前→后） | P95 ms（前→后） |",
    "|---|---:|---:|",
]
for key, name in names.items():
    x, y = b[key], a[key]
    lines.append(f'| {name} | {x["frame_p50_ms"]:.2f} → {y["frame_p50_ms"]:.2f} | '
                 f'{x["frame_p95_ms"]:.2f} → {y["frame_p95_ms"]:.2f} |')

first, warm, last = stress["rounds"][0], stress["rounds"][1], stress["rounds"][-1]
lines += [
    "",
    "## 重复进入与后台停用",
    "",
    "- 完成 20 轮完整往返，共 160 次页面访问：主页、阅读、科学复习、原作业、分舱、稳性、进水、干舷。",
    "- 每次都检查重型视口不超过两个；首页、读题、科学复习的启用 3D 视口数量均为零。",
    f'- 相同终点的节点数始终为 {last["nodes"]}，网格数 {last["meshes"]}，资源数 {last["resources"]:.0f}，孤立节点 {last["orphans"]:.0f}。',
    f'- 第 2—20 轮渲染内存为 {warm["render_mb"]:.3f} → {last["render_mb"]:.3f} MiB；'
    f'引擎分配内存为 {warm["static_mb"]:.3f} → {last["static_mb"]:.3f} MiB。资源和节点数量稳定，小幅分配内存变化如实保留。',
    "- 缓存淘汰后的船模可以重建，观察相机恢复；共同基础与章节进度保持原 ID。",
    "",
    "## 实现与验证要点",
    "",
    "- 稳性当前结果统一传给船模、曲线和公式；完整曲线及极值只在实际形状、尺度或重心参数变化时更新。",
    "- 数值缓存键使用参数原始二进制表示，没有增加舍入。值缓存最多 256 项，曲线和极值各 32 项。",
    "- 已完成计算按专题保存轻量结果；动画只更新当前条目。切题、返回专题和语言切换不重算稳定历史。",
    "- 公式按内容、数值、尺寸、DPI、滚动与布局变化刷新；静止时零重绘请求。布局移动也触发可见区域刷新，避免公式滚动后空白。",
    "- 公式纹理每组件最多 80 项，离开可见邻近区域后回收；船模剖切与甲板形变仅提交变化参数。",
    "- 首页不创建船模。原作业按当前船型加载；比较船仅在比较阶段创建；进水和干舷不创建稳性计算船壳及比较船。",
    "- 隐藏页面停止处理与输入，3D SubViewport 显式停止更新；资源异步读取，货物节点分批创建，加载中阻止操作半成品页面，Esc 可取消。",
    "- 词典、词形匹配与学习词集合共享；对话框文字尺寸缓存，镜头移动只改变投影标注。",
    "",
    "## 正确性与使用路径",
    "",
    "| 检查 | 结果 |",
    "|---|---|",
    f'| 新旧稳性逐字段、完整曲线、极值精确比较 | {math["comparisons"]:,} 项完全相等 |',
    f'| 独立物理验证 | {len(physics["checks"])} 项，失败 {physics["failures"]} |',
]
for name, path in [
    ("原作业完整流程（中俄）", "qa/formal-runtime-normal.json"),
    ("六专题、37 题、41 来源及返回路径", "modules/review/qa/topics-checks.json"),
    ("分舱数值、拖动与恢复", "qa/bulkheads-check.json"),
    ("稳性动作、滑块、回退与缩放", "modules/review/qa/stability-checks.json"),
    ("科学复习等级与数字键", "qa/scientific-review.json"),
    ("动画查词", "modules/review/qa/topic-hover-results.json"),
    ("相机自由观察与 A/D", "qa/camera-free-results.json"),
    ("性能不变量、取消加载、相机恢复", "qa/optimization-results.json"),
]:
    result = read(path)
    checks = result["results"] if isinstance(result, dict) else result
    failures = sum(not check["passed"] for check in checks)
    assert failures == 0, (name, failures)
    lines.append(f"| {name} | {len(checks):,} 项，失败 {failures} |")
lines += [
    f'| 原「开始学习.cmd」实际启动 | {launch["window"]}，{launch["checks"]} 项通过，无焦点抢占 |',
    "",
    "窗口检查覆盖正常及 1100×760 最小窗口，100%、125%、150%、200% 内容缩放；查看实际截图确认分数、根号、俄文下标和重音显示。缩放测试使用 Godot 窗口缩放，不切换用户的 Windows 桌面 DPI 设置。",
    "",
    "测试只写 qa 命名的隔离存档。保留原题、原学习记录体系、A/D 相机行为、朗读删除状态和全部现有精细模型；没有增加用户需要配置的性能选项。",
    "",
    "## 对应文件",
    "",
    "- 原始性能记录：`performance-before.json`、`performance-after.json`、`performance-stress.json`。",
    "- 精确数值比较：`performance-math-results.json`；参考实现：`performance_reference_math.gd`。",
    "- 原入口记录：`performance-launcher.json`、`performance-launcher.log`。",
    "- 修改前脚本：课程根目录 `性能优化工作记录/修改前代码/`。临时基准副本保留在 `性能优化工作记录/基准工程/`：自动审批拒绝了删除，未返回具体原因；正式启动入口不使用这份副本。",
    "- 渲染截图：`../modules/review/qa/optimization-stability.png`、`../modules/review/qa/stability-scale-1.0.png` 至 `stability-scale-2.0.png`。",
    "- 性能运行：`-- --qa --perf`；20 轮往返：`-- --qa --perf-stress`；优化不变量：`-- --qa --optimization`。",
    "",
]
(QA / "性能优化验证-2026-10-20.md").write_text("\n".join(lines), encoding="utf-8")
print("Performance report written; all referenced regressions passed.")
