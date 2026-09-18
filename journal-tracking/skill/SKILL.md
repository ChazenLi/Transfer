---
name: journal-paper-tracking
description: 顶级期刊论文发表追踪的**总入口/路由技能**。追踪 Nature、Science、Cell 及其系列子刊的定期发表情况，生成周报、月度综述或主题追踪。当用户说"追踪/汇总/统计某周或某月的 Nature/Science/Cell 论文""上周顶刊发了什么""按学科整理正刊文章""某个团队/主题最近发了什么"时使用。本技能负责路由到对应期刊规范，不要在本文件里直接写期刊细节。
agent_created: true
---

# 顶刊追踪 · 路由入口

本技能是**总入口**。它只做三件事：**判定任务类型 → 路由到期刊规范 → 强制通用约束**。
每个期刊的具体规则（卷期换算、栏目结构、反爬现状、专属数据源、专属坑）分散在
`references/journals/` 下的独立规范文件中，**一刊一规范**。

## 路由表

先读 `references/00-workflow.md` 和 `references/01-sources.md`（这两份是任何任务都要用的基础层），
再按用户提到的期刊加载对应规范。**只加载需要的期刊文件，不要一次性全读。**

| 用户提到 | 加载 |
|---|---|
| Nature、自然、正刊、Nature 子刊 | `references/journals/nature.md` |
| Science、科学、AAAS、Science Advances / 子刊 | `references/journals/science.md` |
| Cell、细胞、Cell Press、Cell 子刊 | `references/journals/cell.md` |
| 新增期刊（NEJM / Lancet / JAMA / BMJ / PNAS 等） | 先读 `references/journals/_template.md`，按模板落一份新规范后再执行 |

| 任务形态 | 加载 |
|---|---|
| 周报 / 月报 / 定期追踪 | `references/00-workflow.md` + `references/02-output-spec.md` |
| 交付格式、口径声明、质检 | `references/02-output-spec.md` |
| 换数据源、官网抓不到、要自动化 | `references/01-sources.md` |

## 强制约束（不可省略）

1. **口径声明必写。** 任何报告结尾必须写明：统计窗口起止、对应卷期、"所列为高亮/枚举来源覆盖的条目，非该期全量目次"（若确实非全量）、未确认条目的标注、窗口边界外的论文单独说明。见 `02-output-spec.md`。
2. **区分"研究论文"与"非研究内容"。** 新闻、社论、评论、Correspondence、Preview、News & Views **不算**研究论文。
3. **勘误绝不算新论文。** Author Correction / Publisher Correction / Erratum / Corrigendum / Retraction 一律单列或剔除。
4. **枚举优先走机器可读通道。** 首选 Europe PMC API / 期刊 eTOC RSS（见 `01-sources.md` 的 Layer 0），**不要一上来就爬官网 HTML**——三家反爬强度差别很大。
   - **EPMC 的实时性按刊而异，换刊必跑探针**：Nature ✅ 实时（当周 50 条）/ Science ❌ 滞后 ≥1 期（当周 0 条）/ Cell ⚠️ 部分实时（当周 6 条，但**不含本期主体**）。
   - **并确认该刊的"AOP vs 期次"口径。** Cell 的两个口径**交集为空**：本期论文首发日可横跨两个月，而本周上线的论文全部未编期——**不写双口径就是错的**。见各刊规范 §2.1。
5. **中文二手来源只用于补充解读，结论与数字以英文原文/官方 DOI 为准。** 中文导读存在笔误（已见过把 m_K = 19.3 写成 9.3 的案例）。
6. **不得编造 DOI、卷期、页码、作者、机制。** 拿不到就标注"待核实"，不要猜。
7. **★ 每篇论文按"问题 → 手段 → 机理 → 结论"四层写，不留空。** 只写结论的卡片是检索工具而非阅读材料。
   - **"机理"层是硬要求**：必须给出因果链（为什么这个手段能绕过那个卡点），不是术语或背景知识。
   - 机理层性质为"解释性归纳"，**必须在口径声明中标明**（不等于作者原话）。
   - 材料不足写不下来时，标注"机理未展开（材料不足）"，**不许编**。
   - 详细规范、正反例、分层策略见 `02-output-spec.md` 第一节。
8. **★ 周报必须含一节"贯穿本期的方法学主线"**：横向提炼 2–4 个可迁移的解题动作，而非复述各篇结论。

## 快速决策流

```
用户要追踪某周/某月
  ├─ 哪家期刊？→ 加载对应 journals/*.md
  ├─ 先定窗口与卷期（各规范里有换算锚点）
  ├─ 跑探针：EPMC 当周 hitCount 是否为 0？→ 决定主干是 EPMC 还是 eTOC RSS
  ├─ Layer 0 枚举：主干通道拉全量目次（含栏目字段）
  ├─ Layer 0 补漏：Crossref 补 DOI/页码/未编期 First Release
  ├─ Layer 4 富化：机构新闻稿确认团队/通讯作者
  ├─ Layer 3 补充：科学网导读/X-MOL 补中文题名与摘要
  ├─ ★ 素材落盘：data/<journal>-<窗口>/（写报告前完成，防止中断丢失）
  ├─ ★ 逐篇撰写四层：问题 → 手段 → 机理 → 结论
  ├─ ★ 横向提炼：贯穿本期的方法学主线（2–4 条可迁移动作）
  └─ 按 02-output-spec.md 出交付物 + 口径声明（含机理层性质说明）
     最终版留根目录，旧版移入 archive/
```

## 扩展位（尚未落规范）

需要时按 `_template.md` 补：NEJM、The Lancet（含子刊）、JAMA 系列、BMJ、PNAS、
Nature Reviews 系列（综述刊，节奏不同）、Science Partner Journals。

## 相关文件

- `references/00-workflow.md` — 通用六步工作流
- `references/01-sources.md` — 六层数据源登记表（含已实测可用的 URL 与 API）
- `references/02-output-spec.md` — 输出规范、口径声明模板、质检清单
- `references/journals/{nature,science,cell}.md` — 各刊规范
- `references/journals/_template.md` — 新刊规范模板
