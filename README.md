# 船舶设计原理学习模型
# Ship Design Principles Learning Model
# Учебная модель по основам проектирования судов

[中文](#中文) · [English](#english) · [Русский](#русский)

## 中文

### 项目介绍

这是为**广东海洋大学圣彼得堡船舶与海洋技术学院**的俄方课程 **《船舶设计原理》**制作的学习模型。**课程授课时间为2026年10月份。**

项目基于Godot，将船舶概念、作业计算和专业俄语结合起来，帮助学习者理解船体结构、计算关系和俄语题意。包含精细三维船模、连续动画讲解、公式推导与计算记录、俄汉题目、悬停查词和科学复习。这是个人课程学习辅助项目，不是学院官方教材或船舶工程设计软件。

### 内容与操作

作业章节涵盖认识船舶、基础题、载荷与重心、排水量估算、主尺度设计、第二次近似、第三次近似、舱壁布置及补充理解。题目关联的连续专题与原作业章节树分别组织。

| 入口 | 当前内容 |
|---|---|
| 课程题目 | 62道课程题目 |
| 考前题目 | 66道独立题目及6组识图辅助，来自12p/13a |
| 考试真题 | 周四真题10道，独立题库，不配动画 |

12p-3与13a-30共用一张题卡，保留两个来源编号。演算展示公式、数值代入和中间结果，优先沿用原题符号；演示数值与原题给定值分开标明。

题目页：**Q/E**切题，**F**揭晓，悬停查词，**Esc**返回。科学复习：**1/2/3/4**记录词汇等级。动画：**A/D**前后推进，**F2**切换中俄语言，**Esc**返回，并支持阶段跳转和相机自由观察。具体操作以当前页面提示为准。

### 启动与维护

安装 **Godot 4.7.2**，使用 **Compatibility** 渲染器，打开 `project.godot`。Windows也可双击 `开始学习.cmd`：将环境变量 `GODOT_BIN` 设为引擎可执行文件的完整路径，或将引擎放在 `%LOCALAPPDATA%/ShipLearningTools/Godot/4.7.2/godot.exe`。

`runtime/godot.exe`只是约6 KiB的启动桥，**不是完整引擎**。源码和重建脚本为 `runtime/engine_launcher.cs`、`runtime/build_launcher.cmd`。首次启动会生成 `.godot/` 导入缓存，耗时较长；该目录无需提交Git。

维护方式见[维护与重建](docs/维护与重建.md)。当前运行数据和本说明优先于历史资料；新题答案维护源为 `tools/focused_new_answers.py`，考试真题为 `tools/thursday_exam.py`。

仓库不包含上一级目录中的教师原始DOCX、个人作业、手机签名密钥或个人学习记录。它们不影响现有内容运行；从原始资料重新导入时须另行提供对应文件。

## English

### About

This is a learning model for the **Russian-side course “Ship Design Principles” (《船舶设计原理》)** at **广东海洋大学圣彼得堡船舶与海洋技术学院 — St. Petersburg Institute of Shipbuilding and Marine Technology, Guangdong Ocean University** (English translation). **The course was taught in October 2026.**

Built with Godot, it connects ship concepts, coursework calculations and technical Russian. It includes detailed 3D ship models, continuous animated explanations, formula derivations and calculation records, Russian–Chinese questions, hover definitions and vocabulary review. This is a personal study aid, rather than an official institutional textbook or an engineering design application.

### Content and controls

Coursework covers ship basics, introductory exercises, loads and centres of mass, displacement estimation, principal dimensions, second and third approximations, bulkhead arrangement and supplementary concepts. Question-based animated topics are organised separately from the coursework tree.

| Application entry | Current content |
|---|---|
| 课程题目 — Course questions | 62 questions |
| 考前题目 — Pre-exam questions | 66 distinct questions and 6 figure-review groups from 12p/13a |
| 考试真题 — Actual exam questions | 10 Thursday exam questions, in a separate bank without animations |

12p-3 and 13a-30 share one card while retaining both source identifiers. Calculations show formulas, substitutions and intermediate results. Original notation takes precedence; demonstration values are distinguished from values supplied in the questions.

Question pages: **Q/E** change questions, **F** reveals, hovering shows definitions, and **Esc** returns. Vocabulary review: **1/2/3/4** record proficiency ratings. Animated lessons: **A/D** move backwards/forwards, **F2** switches Chinese/Russian, and **Esc** returns. Stage navigation and free camera observation are available. Follow the controls shown on the active page.

### Running and maintenance

Install **Godot 4.7.2**, use the **Compatibility** renderer, and open `project.godot`. On Windows, you can also run `开始学习.cmd`: set `GODOT_BIN` to the full path of the engine executable, or place the engine at `%LOCALAPPDATA%/ShipLearningTools/Godot/4.7.2/godot.exe`.

`runtime/godot.exe` is an approximately 6 KiB launcher bridge, **not the complete engine**. Its source and build script are `runtime/engine_launcher.cs` and `runtime/build_launcher.cmd`. The first launch generates the `.godot/` import cache and takes longer. This generated directory does not belong in Git.

See [Maintenance and rebuilding](docs/维护与重建.md) (Chinese). Current runtime data and this README take precedence over historical material. Answer maintenance sources are `tools/focused_new_answers.py` for pre-exam questions and `tools/thursday_exam.py` for actual exam questions.

The repository excludes teachers’ original DOCX files and personal coursework in the parent directory, mobile signing keys and personal learning records. These are not needed to run existing content. Reimporting from original documents requires supplying those source files separately.

## Русский

### О проекте

Это учебная модель по **курсу российской стороны «Основы проектирования судов» (《船舶设计原理》)** для **Санкт-Петербургского института судостроения и морской техники Гуандунского океанического университета** (广东海洋大学圣彼得堡船舶与海洋技术学院). **Занятия проходили в октябре 2026 года.**

Проект создан на Godot и объединяет понятия о судне, расчёты практических работ и профессиональную русскую лексику. В нём есть подробные трёхмерные модели судов, последовательные анимационные объяснения, вывод формул и записи расчётов, вопросы на русском и китайском языках, подсказки при наведении и повторение слов. Это личный учебный проект, а не официальный учебник института или программа инженерного проектирования.

### Содержание и управление

Практические работы охватывают знакомство с судном, базовые задачи, нагрузки и центр масс, оценку водоизмещения, главные размерения, второе и третье приближения, расположение переборок и дополнительные понятия. Анимационные темы вопросов организованы отдельно от дерева практических работ.

| Раздел приложения | Содержание |
|---|---|
| 课程题目 — Вопросы курса | 62 вопроса |
| 考前题目 — Подготовка к экзамену | 66 отдельных вопросов и 6 групп рисунков из 12p/13a |
| 考试真题 — Экзаменационные вопросы | 10 вопросов экзамена в четверг, отдельный набор без анимаций |

12p-3 и 13a-30 объединены в одну карточку с сохранением обоих номеров источника. В расчётах показаны формулы, подстановка чисел и промежуточные результаты. Используются обозначения исходных задач; демонстрационные значения отделены от заданных условий.

На странице вопросов: **Q/E** — сменить вопрос, **F** — показать ответ, наведение мыши — значение слова, **Esc** — вернуться. При повторении слов **1/2/3/4** задают уровень знания. В анимационных уроках: **A/D** — назад/вперёд, **F2** — сменить китайский и русский языки, **Esc** — вернуться. Доступны переходы по этапам и свободное наблюдение камерой. Точные команды указаны на текущей странице.

### Запуск и сопровождение

Установите **Godot 4.7.2**, выберите рендерер **Compatibility** и откройте `project.godot`. В Windows также можно запустить `开始学习.cmd`: укажите полный путь к исполняемому файлу движка в переменной `GODOT_BIN` или разместите движок по пути `%LOCALAPPDATA%/ShipLearningTools/Godot/4.7.2/godot.exe`.

Файл `runtime/godot.exe` — программа запуска размером около 6 KiB, **а не полный движок**. Исходный код и сценарий сборки: `runtime/engine_launcher.cs` и `runtime/build_launcher.cmd`. При первом запуске создаётся кэш импорта `.godot/`, поэтому запуск занимает больше времени. Этот каталог не нужно добавлять в Git.

См. [Сопровождение и пересборка](docs/维护与重建.md) (на китайском языке). Актуальные данные приложения и этот README имеют приоритет над историческими материалами. Исходники для обновления ответов: `tools/focused_new_answers.py` и `tools/thursday_exam.py` — для подготовки к экзамену и экзаменационных вопросов соответственно.

В репозиторий не входят исходные DOCX преподавателей и личные работы из родительского каталога, ключи подписи мобильного приложения и личный учебный прогресс. Для запуска существующих материалов они не нужны. Для повторного импорта из исходных документов эти файлы нужно предоставить отдельно.

## 项目结构 / Project structure / Структура проекта

| 路径 / Path / Путь | 中文 | English | Русский |
|---|---|---|---|
| `main.gd`, `core/`, `view/` | 主界面、播放、计算和船模视图 | Interface, playback, calculations and ship views | Интерфейс, уроки, расчёты и виды судна |
| `assets/`, `content/` | 运行资源、作业课程与公式 | Runtime assets, coursework and formulas | Ресурсы, практические работы и формулы |
| `modules/review/` | 三个题库、词典、科学复习与专题动画 | Question banks, dictionary, review and animated topics | Вопросы, словарь, повторение и анимационные темы |
| `models/` | 当前Blender源文件；运行无需Blender | Editable Blender sources; Blender not required to run | Исходники Blender; для запуска Blender не нужен |
| `tools/`, `qa/` | 维护工具、测试和必要基准 | Maintenance tools, tests and essential baselines | Инструменты, тесты и необходимые эталоны |
| `archives/` | 压缩历史资料，不作运行或构建输入 | Historical archives, excluded from runtime/build inputs | Архивы, не используемые при запуске и сборке |
| `runtime/`, `docs/` | 启动桥、Godot许可证与维护文档 | Launcher bridge, Godot licence and documentation | Программа запуска, лицензия Godot и документация |
