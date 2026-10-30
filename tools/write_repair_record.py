"""Summarize verified repairs without rewriting teacher material or study saves."""
import hashlib,json,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'qa/repair-20261023'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
runs=read(OUT/'regression.json');offline=read(OUT/'offline.json')
assert len(runs)==20 and all(r['exit_code']==0 and not r['errors'] for r in runs)
assert all(r['code']==0 for r in offline)
launcher=read(ROOT/'modules/review/qa/topics-launcher.json')
assert not launcher['failures'] and launcher['user_files_unchanged'] and not launcher['script_errors']
cleanup=read(OUT/'legacy-cleanup.json')
assert all(not Path(p).exists() for p in cleanup['removed'])
for p,value in cleanup['before'].items():assert hashlib.sha256(Path(p).read_bytes()).hexdigest().upper()==value
for p in ['migration-tests.json']:
    assert all(r['passed'] for r in read(OUT/p))
assert all(r['passed'] for r in read(ROOT/'qa/reading-words-results.json'))
rows='\n'.join('| '+r['name']+' | '+next((s for s in reversed(r['tail']) if 'checks' in s),'通过')+' |' for r in runs)
report=f'''# 程序逐章修缮记录

2026-10-23。对应《程序逐章检查报告_2026-10-23.md》中的已确认问题，现已修改程序并完成下述回归。

## 已落实的修改

| 原问题 | 现在的行为 |
|---|---|
| 原作业、舱壁讲解查词未接入 | 普通讲解句与原生计算说明统一接入即时释义。显示中文与带重音原形；相同原形不重复。 |
| 关键词形漏查 | 补齐实际问答及讲解中的词形，包括“较小”“不足”“确定”、肋距和分舱术语。现有词条ID保留；原来排除的基础词仍不进记背卡。 |
| 总布置只变箭头和方框 | 新建并接入总布置船模：驾驶室及其栏杆一起升降，上层建筑围壁与设备同步内收，艏楼采用实际船体变形。俯视图作为辅助保留。 |
| 整船被计算栏挡住 | 计算栏展开后，3D视口使用剩余宽度；观察角度与缩放保留。图表使用同一可用宽度，避免重复缩窄。 |
| 尺度比讲解相同 | 长宽比、宽吃水比、型深吃水比分别说明当前比较的两个尺度。 |
| 艏艉尖舱说明相同 | 分别指出艏尖舱、艉尖舱；教师给定的“强肋距等于普通肋距”在讲解与公式中同时标紫色。 |
| 干舷三题重复开场 | 保留一次比较开场，连续演示足够→临界→不足；旧步骤通过别名恢复，题目定位同步更新。 |
| 历史公式重复追加 | 删除裕量公式、艉尖舱整数集合、诺曼初始方程的重复记录；保留不同舱室的明细、迭代和最终汇总。中俄两套同步。 |
| 切俄语后当前公式移出视野 | 当前记录可见时以它保持滚动位置；向上回看历史时保留历史位置。最小窗口的AP3查图步骤已复测。 |
| 切题时生词高亮报错 | 切题立即清除旧词形位置；文本重建前不再使用上一题的字符坐标。 |
| 测试与当前交互不一致 | 讲解采用当前Q/E，阅读揭晓采用F；最小窗口实际调整尺寸；剖切按当前路由验证；失败退出码正确。 |
| 旧程序、语音残留 | 已删除旧工程、旧启动入口及旧用户目录中的密钥、语音缓存和测试音频。删除前保存并逐字节核验9份进度/损坏记录；现有学习数据未覆盖。 |
| 来源说明过期 | 舱壁文档更新为70段，明确教师规则、本人采用值和第三次近似最终尺寸的衔接。 |

## 覆盖范围

9个作业章节、9个题目专题、616段讲解、62张题卡、90个来源编号。两段重复开场删除前为618段。

词典从685条增至985条。扫描范围为全部章内讲解及题目问答；剩余未按词典匹配的片段是单位或公式记号，按原有记号释义处理。新增解释通过构建审校层保存，不会在重建时丢失。新增动画用词不会扩入背词范围：记背仍只提取题目及短答。

## 验证

以下20组运行检查全部通过，退出码为0，日志无脚本错误或警告。使用实际渲染窗口与应用内部输入，未移动系统鼠标；常规窗口和实际小窗口分别验证。

| 检查 | 结果 |
|---|---|
{rows}

另外通过：

- 删除旧工程后，从原“开始学习.cmd”启动，完成{launcher['checks']}项专题检查；实际学习文件哈希未变。
- 整词导航、生词标记、揭晓和当前快捷键：37项。
- 首次迁移、再次迁移、保留已有目标、保留损坏内容：5项。
- 原作业3873项、公式记号8673项、舱壁独立数值25项、第二及第三次近似34项、题目专题560项、9p映射233项、7a相关35项、游艇334项、稳性数值验证通过。
- 稳性、质量、尺寸计算模块和计算输入未因本轮界面修缮而改变；第二、第三次近似通过逐段运行回归。未将人工读图改为伪造精确求解。
- 剖切、公式与重音、相机保持、F2、历史回看、退出返回、科学复习和生词等级通过对应回归。来源样式与近似章节检查还覆盖125%、150%、200%的应用缩放。

这次的“通过”指数据验证、实际自动遍历与代表画面的复核；不表示人工看过每段动画的所有中间帧，也不表示这些教学模型可作实船工程认证。

## 文件与记录

- 唯一启动入口：`开始学习.cmd`。
- 可编辑模型：`船舶原理学习/models/总布置与驾驶室.blend`；运行模型：`modules/review/assets/arrangement_ship.glb`。
- 新模型使用一个可见Blender窗口完成，导出后已关闭。驾驶室的分组包括栏杆等附属件，避免出现悬空结构。
- 完整日志与截图：`船舶原理学习/qa/repair-20261023/`；最终运行汇总 `regression.json`，离线核验 `offline.json`，清理与存档哈希 `legacy-cleanup.json`。
- 老进度原始副本：应用用户目录 `船舶原理学习/review/legacy-import/20261023`；没有迁移密钥或音频。
- 修改前的代码与课程数据副本：`qa/repair-20261023/before/`。

### 代表画面

驾驶室升高（栏杆随对应部件移动）：

![驾驶室升高]({(OUT/'bridge-1.0.png').as_posix()})

上层建筑围壁内收后的甲板室：

![围壁内收]({(OUT/'width-1.0.png').as_posix()})

舱壁讲解中的规则样式和俄语查词：

![肋距查词]({(OUT/'bulkhead-tooltip.png').as_posix()})
'''
(ROOT.parent/'程序逐章修缮记录_2026-10-23.md').write_text(report,encoding='utf8')
print('Verified repair record written; current learning hashes unchanged.')
