# 期刊规范 · Cell（细胞）及 Cell Press 系列

## 1 · 身份

| 项 | 值 |
|---|---|
| 刊名 | Cell |
| 出版社 | Cell Press（Elsevier） |
| ISSN | 0092-8674（print）/ 1097-4172（online） |
| DOI 前缀 | `10.1016/j.cell.<YYYY>.<MM>.<NNN>` |
| 出版节奏 | **双周刊，隔周周四出版** |
| 访问 | 强订阅制；部分期次标为 FREE ISSUE |

## 2 · 卷期换算（**双周刊，最易出错**）

**已核对的锚点（2026 年）：**

| 期号 | 出版日 |
|---|---|
| Volume 189, Issue 18 | 2026-09-03 |
| Volume 189, Issue 19 | 2026-09-17 |

- 期号每两周 **+1**，**不是每周**。
- ⚠️ **后果：在一个"上周"（7 天）窗口里，Cell 很可能一期都没出。** 这是正常结论，**要如实说"该窗口无新出版期次，最近一期为 …"，不要硬凑，也不要把上一期拿来充数而不加说明。**
- 一个自然月通常只有 2 期。

### 2.1 ★ 口径基线：AOP 提前期长，两个口径可能完全不相交

**这是 Cell 追踪最容易出错的地方——比"双周刊"本身更容易踩。**

Cell 的论文以 AOP（在线首发）形式提前上线，**提前期可长达两个月**，之后才被编入某一期。
因此"本周 Cell 发了什么"必须分清两个**不重叠**的集合：

| 口径 | 定义 | 回答的问题 |
|---|---|---|
| **A · 期次口径** | 该窗口内出版的那一期（整期目次） | "这一期讲了什么" |
| **B · 在线首发口径** | 该窗口内新上线、**尚未编入任何期次**的论文 | "这周有什么新东西" |

**实测（Issue 19，2026-09-14 ~ 09-18 窗口）：**

| | 内容 |
|---|---|
| 口径 A | **26 条** = 研究论文 17 + 综述 1 + 非研究 7 + 勘误 1 |
| 口径 B | **6 篇**，全部未编期 |
| **交集** | **空集** |

本期 17 篇研究论文的首发日横跨 **2026-07-16 ~ 2026-09-17**，其中**只有 3 篇**
（scBaseCount / Tahoe-100M / LongevityBench）是随本期上线的。

**做法：**
- **报告必须双口径并列**，并在开头显式说明交集情况——只看一个口径会得到相反结论；
- 每张卡片标注**该篇的在线首发日**，不能只写期日；
- 关心"最新进展"用口径 B；关心"这期值不值得读"用口径 A。

**三问自查（每次追踪前先回答）：**
1. 本期论文的首发日跨度是多少？
2. 本周新上线的论文里，几篇尚未编期？
3. 两个口径的交集是否为空？

## 3 · 栏目结构

**计入研究论文：**
- Article（主体长文）
- Resource（资源类，如图谱、数据集、连接组——**学术价值等同研究论文**）
- Theory（理论文章）
- Short Article

**不计入：**
- Preview（**这是对同期某篇论文的点评，不是原创研究**，与 Nature 的 News & Views 同性质）
- Commentary、Voices、Q&A、Correspondence、Letters
- Leading Edge（栏目统称，内含上述多种非研究内容）
- Editorial、Obituary、In Memoriam
- Benchmarks（部分为方法评估，需逐条判断）

**单列：**
- Correction、Author Correction、Retraction

> ⚠️ Cell 的 **Preview** 与 **Leading Edge** 是最常被误统计的两个栏目。实测 2026-09-17 那期的 RSS 中，Editorial / Commentary / Perspective / Preview 占了相当比例。

**★ RSS 里的栏目判据**：`prism:section` 字段，取值如 `Article` / `Resource` /
`Short article` / `Review` / `Perspective` / `Commentary` / `Editorial` / `Voices` / `Correction`。
**注意 `Resource` 与 `Short article` 也是研究论文**，不要漏计。
实测分布（Issue 19，26 条）：Article 8、Resource 8、Short article 1、Review 1、
Perspective 4、Commentary 1、Editorial 1、Voices 1、Correction 1
→ **研究论文 = 8 + 8 + 1 = 17 篇**。

## 4 · 官方入口与反爬现状 —— **Cell 是三家中最好抓的**

| 入口 | 状态 | 说明 |
|---|---|---|
| `cell.com/cell/current` | ✅ | **无反爬**，返回完整目次，**含封面说明与 artist credit** |
| `cell.com/current` | ✅ | 同上（会跳转到当前期） |
| `cell.com/cell/current.rss` | ✅ | **RSS 1.0（RDF），实测 26 条**。字段齐全：`prism:section`（栏目）、`prism:volume`/`prism:number`/`prism:issueIdentifier`（卷期）、**`prism:startingPage`/`prism:endingPage`（页码）**、`dc:date`/`prism:publicationDate`（日期）、`dc:creator`、`dc:description`（**即摘要**）、`dc:identifier`（DOI） |
| `cell.com/<刊名>/current` | ✅ | Cell Press 各刊同平台，预期同状态 |

**这意味着 Cell 家族可以直接抓官网目次，不需要绕道。** 这是与 Nature/Science 最大的差别。
**且 RSS 自带页码 ⇒ 无需再用 Crossref 补**（Nature / Science 都要补）。

## 5 · Cell 的可用源优先级

1. **eTOC RSS** `cell.com/cell/current.rss` —— **主干**（整期目次 + 栏目 + 卷期 + 页码 + 摘要）
2. **官网目次** `cell.com/cell/current` —— 补封面说明与 artist credit（RSS 不给封面）
3. **Europe PMC API** —— ⚠️ 见下方实测，**只能作补充，不能当主干**
   ```
   JOURNAL:"Cell" AND ISSN:"0092-8674" AND FIRST_PDATE:[...]
   ```
4. **中国科学报"小柯"秀 / 科学网论文速递** —— 中文摘要（Cell 没有单独的"一周论文导读"，
   其内容混编在科学网的短讯页里）
   - 入口形如 `news.sciencenet.cn/sbhtmlnews/YYYY/M/<id>.shtm`
   - 同一页常同时含 Nature / Science / Cell 条目，**需按刊名切分**
5. **机构新闻稿** —— Cell 的中国团队工作常由院校首发新闻稿

### 5.1 ★ EPMC 对 Cell 是"部分实时"（实测 2026-09-18）

| 查询 | 结果 |
|---|---|
| `FIRST_PDATE:[2026-09-14 TO 2026-09-18]` | **hitCount = 6** |
| `FIRST_PDATE:[2026-09-01 TO 2026-09-30]` | hitCount = 27 |

**这 6 条全部不在本期 RSS 的 26 条里**——它们是线上优先（AOP）部分。
**Issue 19 的多数论文（含 14 篇已发表的）不在当周 EPMC 结果中。**

→ 所以：**不要用 EPMC 判断 Cell 当周产出**，会严重低估。
→ EPMC 的正确用法是**按 DOI 反查**：对 RSS 拿到的 DOI 逐条查 `resultType=core`，
  可补齐完整摘要与通讯机构（实测 18 篇中 14 篇可查到，4 篇尚未索引）。

> 三刊对照（同一天、同一 API）：Nature 实时（50 条）/ Science 滞后 ≥1 期（0 条）/
> Cell 部分实时（6 条，但非本期主体）。**逐刊实测，不要照抄别刊结论。**

## 6 · Cell Press 系列

| 大类 | 刊物 |
|---|---|
| 旗舰与综合 | **Cell**、Molecular Cell、Cell Reports、Cell Systems、Cell Genomics、Cell Chemical Biology、Structure |
| 生命科学 | Cell Stem Cell、Cancer Cell、Immunity、Neuron、Cell Metabolism、Cell Host & Microbe、Developmental Cell、Current Biology、Molecular Cell |
| 医学转化 | Cell Reports Medicine、Med、Cancer Cell |
| 物质科学 | Chem、Joule、Matter、Chem Catalysis |
| 综述刊 | **Trends in 系列**（Trends in Cell Biology / Genetics / Biochemical Sciences / Immunology / Microbiology / Ecology & Evolution / Chemistry / Pharmacological Sciences / Biotechnology / Cancer / Molecular Medicine / Neurosciences / Plant Science / Endocrinology & Metabolism）—— 只发综述 |

**DOI 反查**：Cell Press 统一为 `10.1016/j.<刊名>.<年>.<月>.<序号>`
- `10.1016/j.cell.*` → Cell ✅
- `10.1016/j.molcel.*` → Molecular Cell
- `10.1016/j.cellrep.*` → Cell Reports
- `10.1016/j.chom.*` → Cell Host & Microbe
- `10.1016/j.ccell.*` → Cancer Cell
- `10.1016/j.immuni.*` → Immunity
- `10.1016/j.neuron.*` → Neuron
- `10.1016/j.cmet.*` → Cell Metabolism
（除 Cell 外为通用规则，❓ 用前可快速核）

**RSS 模式**（✅ Cell 实测通过，其余为模式推断）：`https://www.cell.com/<刊名小写>/current.rss`

## 7 · Cell 专属坑

1. **口径双轨，交集可为空。** 见 §2.1——这是本刊最大的坑，**报告不写双口径就是错的**。
2. **双周刊 ≠ 周报适配。** 用周窗口追 Cell 会经常空手。**正确做法**：默认用"最近一期"口径，
   或把窗口放宽到双周/一个月。若用户坚持按周，必须在口径声明里写明"Cell 为双周刊"。
3. **不要用 EPMC 判断当周产出。** 见 §5.1，会漏掉本期绝大多数论文。
4. **Preview 和 Leading Edge 混入统计。** 这是 Cell 追踪最常见的统计错误。
5. **Correction 会出现在 RSS 里。** 实测 Issue 19 的 RSS 含一条 Correction
   （`Sequencing-free whole-genome spatial transcriptomics...`，指向 2025-11 的原文），
   **不要当成新论文**。
6. **`dc:date` 是在线首发日，不是期日。** 同一期内各篇的 `dc:date` 会相差数月
   （实测 Issue 19 从 07-16 到 09-17），**不要用它判断"是否属于本期"**——属于本期的判据是
   在当期 RSS 里。反过来，期日应从 `prism:publicationDate`（channel 级）取。
7. **⚠️ RSS 解析：XPath 取字段会静默失败。** 该 feed 是 RDF 格式（默认命名空间 +
   prism + dc 混合）。实测 `SelectSingleNode("*[local-name()='section']")` **返回空值**
   （字段明明存在），必须改用 **`$item.ChildNodes` 遍历 + 读每个节点的 `.LocalName`**。
   遇到"所有字段都空但 item 数正确"就是这个症状，**不要误判为数据缺失**。
8. **Cell 的"封面说明"信息量很大**，会点出该期重点论文（例：2026-09-17 封面为 LongevityBench）。
   **做周报时把封面描述带上，比单纯列标题有用。**
9. Cell 论文偏长、偏机制完整，**"关键发现"字段要提炼机制链（谁调控谁、通过什么修饰、
   导致什么表型），不要只写结论。**
