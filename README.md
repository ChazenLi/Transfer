# Transfer

learning process and data transfering storage bank

A personal bank of long-form, AI-assisted study documents and the tooling that produces them.

---

## Contents

| Path | What it is |
|---|---|
| [`crispr/`](crispr/) | CRISPR-Cas 天然机制、演化与生化全景解析：[`crispr.md`](crispr/crispr.md) 中文长文（含专著 / 原始论文 / 综述书单与配套视频课程）+ [`crispr-2-mechanism-lecture.md`](crispr/crispr-2-mechanism-lecture.md) 英文讲解稿（Act 1–4，含 NHEJ / HDR 修复机制）+ [`crispr-1.html`](crispr/crispr-1.html) 交互式分子流程动态演示 |
| [`journal-tracking/`](journal-tracking/) | 顶级期刊追踪：**技能本体**（Nature / Science / Cell 规范）+ **每周运行结果**归档 |

---

## Conventions

- Every top-level folder is one topic, self-contained, with its own `README.md`.
- Long-form write-ups ship as a pair: `.md` (source) + `.html` (rendered).
- Reports generated on a schedule are archived by their statistics window, not by the date they were generated.

### crispr

- `crispr/crispr.md` — 中文全景长文；末尾第七章为**权威经典书籍、里程碑学术文献与配套视频课程**。
- `crispr/crispr-2-mechanism-lecture.md` — **英文讲解稿**，按 Act 1–4 组织，对应配套视频 1。
  补全中文正文未展开的部分：RecBCD / Chi 位点取样、REC / NUC / PI 结构域命名、**NHEJ 与 HDR 修复机制**。
- `crispr/crispr-1.html` — 交互式分子流程动态演示（四阶段 SVG 动画 + 配套视频课程入口）。
  它是独立产物，**不是 md 的渲染结果**，属于上文 pair 约定的例外。

> 三份材料的关系：`crispr.md`（中文长文，机制主线）↔ `crispr-2-mechanism-lecture.md`（英文讲稿，
  补修复结局）↔ `crispr-1.html`（可视化演示）。三者互相链接，可按任一入口进入。

### journal-tracking

See [journal-tracking/README.md](journal-tracking/README.md). In short:

- `journal-tracking/skill/` — the tracking skill (spec + per-journal norms). Mirrored from `~/.workbuddy/skills/journal-paper-tracking`.
- `journal-tracking/reports/YYYY-MM/` — weekly deliverables (`<journal>-weekly-YYYY-MM-DD[-deep].html`).
- `journal-tracking/sync.ps1` — one command to mirror the skill, archive new reports, commit and push.

> The deep reports use a four-layer structure: **问题 → 手段 → 机理 → 结论**. The mechanism layer is an
> explanatory reconstruction from abstracts, **not the authors' wording**. See each report's closing note.
