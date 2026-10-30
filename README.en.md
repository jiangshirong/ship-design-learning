# Ship Design Principles Learning Model

[中文](README.md) · [English](README.en.md) · [Русский](README.ru.md)

## About

This is a learning model for the **Russian-side course “Ship Design Principles”** at **St. Petersburg Institute of Shipbuilding and Marine Technology, Guangdong Ocean University**. **The course was taught in October 2026.**

Built with Godot, it connects ship concepts, coursework calculations and technical Russian. It includes detailed 3D ship models, continuous animated explanations, formula derivations and calculation records, Russian–Chinese questions, hover definitions and vocabulary review. This is a personal study aid, rather than an official institutional textbook or an engineering design application.

## Content and controls

Coursework covers ship basics, introductory exercises, loads and centres of mass, displacement estimation, principal dimensions, second and third approximations, bulkhead arrangement and supplementary concepts. Question-based animated topics are organised separately from the coursework tree.

| Application entry | Current content |
|---|---|
| Course questions | 62 questions |
| Pre-exam questions | 66 distinct questions and 6 figure-review groups from 12p/13a |
| Actual exam questions | 10 Thursday exam questions, in a separate bank without animations |

12p-3 and 13a-30 share one card while retaining both source identifiers. Calculations show formulas, substitutions and intermediate results. Original notation takes precedence; demonstration values are distinguished from values supplied in the questions.

Question pages: **Q/E** change questions, **F** reveals, hovering shows definitions, and **Esc** returns. Vocabulary review: **1/2/3/4** record proficiency ratings. Animated lessons: **A/D** move backwards/forwards, **F2** switches Chinese/Russian, and **Esc** returns. Stage navigation and free camera observation are available. Follow the controls shown on the active page.

## Running and maintenance

Install **Godot 4.7.2**, use the **Compatibility** renderer, and open `project.godot`. On Windows, you can also run `开始学习.cmd`: set `GODOT_BIN` to the full path of the engine executable, or place the engine at `%LOCALAPPDATA%/ShipLearningTools/Godot/4.7.2/godot.exe`.

`runtime/godot.exe` is an approximately 6 KiB launcher bridge, **not the complete engine**. Its source and build script are `runtime/engine_launcher.cs` and `runtime/build_launcher.cmd`. The first launch generates the `.godot/` import cache and takes longer. This generated directory does not belong in Git.

See [Maintenance and rebuilding](docs/维护与重建.md) (Chinese). Current runtime data and this README take precedence over historical material. Answer maintenance sources are `tools/focused_new_answers.py` for pre-exam questions and `tools/thursday_exam.py` for actual exam questions.

The repository excludes teachers’ original DOCX files and personal coursework in the parent directory, mobile signing keys and personal learning records. These are not needed to run existing content. Reimporting from original documents requires supplying those source files separately.

## Project structure

| Path | Purpose |
|---|---|
| `main.gd`, `core/`, `view/` | Interface, playback, calculations and ship views |
| `assets/`, `content/` | Runtime assets, coursework and formulas |
| `modules/review/` | Question banks, dictionary, review and animated topics |
| `models/` | Editable Blender sources; Blender not required to run |
| `tools/`, `qa/` | Maintenance tools, tests and essential baselines |
| `archives/` | Historical archives, excluded from runtime/build inputs |
| `runtime/`, `docs/` | Launcher bridge, Godot licence and documentation |
