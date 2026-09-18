# 期刊规范 · Nature 系列子刊

> 正刊（Nature）见 `nature.md`。本文只讲**子刊**。
> 全部结论为 2026-09-18 实测，窗口 `2026-09-14 ~ 09-18`。

## 1 · 身份与分组

**⚠️ 俗称缩写有歧义，先确认再执行。** 实测中遇到的歧义：

| 俗称 | 可能的全称 | 处置 |
|---|---|---|
| **NCS** | Nature Catalysis / Nature Computational Science / Nature Cell Biology | **必须问用户** |
| **NM** | Nature Medicine / Nature Materials / Nature Methods / Nature Neuroscience | **必须问用户** |
| NB | Nature Biotechnology | 无歧义 |
| NMI | Nature Machine Intelligence | 无歧义 |
| NC | Nature Communications（也偶指 Nature Cancer） | 一般指 Communications |

**分组**（按学科，用于报告聚类）：

| 组 | 子刊 |
|---|---|
| 生命科学 | Nature Medicine、Nature Biotechnology、Nature Genetics、Nature Methods、Nature Cell Biology、Nature Immunology、Nature Neuroscience、Nature Structural & Molecular Biology、Nature Chemical Biology、Nature Microbiology、Nature Ecology & Evolution、Nature Cancer、Nature Metabolism、Nature Aging |
| 物质科学 | Nature Chemistry、Nature Physics、Nature Materials、Nature Nanotechnology、Nature Photonics、Nature Energy、Nature Catalysis |
| 地球 / 环境 / 社会 | Nature Climate Change、Nature Sustainability、Nature Water、Nature Ecology & Evolution、Nature Food、Nature Plants、Nature Human Behaviour、Nature Cities、Nature Mental Health |
| 交叉 / 综合 | Nature Machine Intelligence、Nature Computational Science、Nature Communications、Nature Cardiovascular Research、Nature Chemical Engineering |
| 综述刊 | Nature Reviews 系列（Molecular Cell Biology / Genetics / Cancer / Immunology / Neuroscience / Microbiology / Drug Discovery / Chemistry / Physics / Materials / Earth & Environment / Clinical Oncology / Bioengineering）—— **只发综述与评论，与正刊节奏不同，报告里单独说明** |

## 2 · 通道策略（★本文核心）

子刊**不能用单通道**。实测同一天同一 API，不同子刊的可用性差异极大，
**必须按刊分档选主干**：

| 档 | 判据 | 主干 | 理由 |
|---|---|---|---|
| **A** | EPMC `hits` > 1000 | **Europe PMC 按 ISSN** | 收录全、带摘要与 `pubType` |
| **B** | EPMC `hits` < 500 | **nature.com RSS** | EPMC 对这类刊近乎未收录 |
| **C** | 补漏 / 历史回溯 | Crossref 按 ISSN | 拿未编期 First Release、补页码 |

**判档方法**：跑一次 `JOURNAL:"<刊名>"` 拿 `hitCount`，对照 §4 的表。

### 组合流程

```
逐刊判档（EPMC hits）
  ├─ 档 A → EPMC 按 ISSN 枚举窗口内全量（含摘要 + pubType 过滤）
  ├─ 档 B → nature.com RSS 拉当期 8 条（含编辑摘要）
  ├─ 两端都缺 → Crossref 按 ISSN 补
  └─ 合并 → 按日期窗口过滤 → 按学科分组 → 收敛呈现
```

## 3 · nature.com 子刊 RSS（★档 B 的救命通道）

### 3.1 路径与格式

```
https://www.nature.com/<abbr>.rss
```

返回 **RSS 1.0 / RDF**（与 Cell 同为 RDF，字段命名空间却是 `prism` + `dc` 混用）。

### 3.2 实拉到的字段（一手验证）

| 字段 | 内容 | 备注 |
|---|---|---|
| `dc:title` / `title` | 论文题名 | |
| `dc:creator` | **作者全名单**，每个作者一个节点 | 不是单个字符串 |
| `prism:doi` / `dc:identifier` | DOI | |
| `dc:date` | 在线发表日期 | 窗口过滤用这个 |
| `content:encoded` | **编辑撰写的论文要点摘要** | 去掉 HTML 标签后可用，四层写作的原料 |
| `prism:publicationName` | 刊名 | |
| `dc:source` | `"<刊名>, Published online: YYYY-MM-DD; \| doi:..."` | 日期二次确认 |
| **`prism:issn`** | **空值** | ⚠️ 不要指望从 RSS 取 ISSN |

### 3.3 缩写表（★全部实测）

**✅ 可用**（27 个）：

| abbr | 刊物 | abbr | 刊物 |
|---|---|---|---|
| `nm` | Nature Medicine | `natrevmats` | Nature Reviews Materials |
| `nbt` | Nature Biotechnology | `natrevphys` | Nature Reviews Physics |
| `ng` | Nature Genetics | `natrevchem` | Nature Reviews Chemistry |
| `nmeth` | Nature Methods | `nrmicro` | Nature Reviews Microbiology |
| `ncb` | Nature Cell Biology | `nrg` | Nature Reviews Genetics |
| `nsmb` | Nature Structural & Molecular Biology | `nrc` | Nature Reviews Cancer |
| `nenergy` | Nature Energy | `nrd` | Nature Reviews Drug Discovery |
| `nclimate` | Nature Climate Change | `nrm` | Nature Reviews Molecular Cell Biology |
| `natsustain` | Nature Sustainability | `nrclinonc` | Nature Reviews Clinical Oncology |
| `natecolevol` | Nature Ecology & Evolution | `natrevearthenviron` | Nature Reviews Earth & Environment |
| `nplants` | Nature Plants | `nphoton` | Nature Photonics |
| `nchem` | Nature Chemistry | `nphys` | Nature Physics |
| `nmat` | Nature Materials | `nnano` | Nature Nanotechnology |
| `ncomms` | Nature Communications | `natrevmats` | （同上） |
| `natmachintell` | **Nature Machine Intelligence** | `natcatal` | **Nature Catalysis** |
| `natcancer` | Nature Cancer | `nathumbehav` | Nature Human Behaviour |
| `natcomputsci` | Nature Computational Science | `natcardiovascres` | Nature Cardiovascular Research |

**⚠️ 命名无规律，两个坑**：

1. **新刊用 `nat<全词>`，不要用俗称**：
   - ❌ `nmi.rss` → ✅ `natmachintell.rss`
   - ❌ `ncatal.rss` → ✅ `natcatal.rss`
2. **不要从刊名推缩写**。老刊用短缩写（`nm`/`ng`/`ncb`/`nchem`/`nphys`/`nmat`/`nnano`/`nphoton`），
   新刊用全词（`natmachintell`/`natcatal`/`natcancer`/`natcomputsci`）。
   **唯一可靠做法是先探一次，不要猜。**

**❌ 实测取不到**（14 个，需走 EPMC 或重试）：
`ni`（Nature Immunology）、`nn`（Nature Neuroscience）、`nmeta`（Nature Metabolism）、
`nfood`、`naging`、`nrn`（Reviews Neuroscience）、`nri`（Reviews Immunology）、
`natrevgenet`、`natchemeng`、`natwater`、`natrevbioeng`、`natcities`、`natmentalhealth`、`nmi`、`ncatal`

> 注意 `ni`/`nn` 等老刊在 EPMC 里是**档 A**（实时且收录全），所以 RSS 取不到不构成缺口。

### 3.4 ⚠️ 风控（必踩）

**症状**：返回 **3036 字节**的 HTML（`<title>Client Challenge</title>`），而非 RSS。
**特征**：**随机拦截**——同一 URL 第一轮成功、第二轮被拦，反之亦然。

实测同一批 44 个 URL 连跑三轮，成功率约 **60% → 70% → 略升**，被拦的刊每轮不同。

**处置**：
- 请求间隔 **≥ 800ms**，被拦时退避 **≥ 1500ms** 重试（最多 4 次）
- **必须在写入前判 `$r.Content -like "*rdf:RDF*"`**，否则会把 HTML 拦页写进 `.rss` 文件，
  下一轮解析时报"无法转换为 XmlDocument"（本次就踩到了，6 个刊被污染）
- 接受**部分覆盖**：单轮拿不全属正常，写进口径声明；缺的刊用 EPMC 补

### 3.5 ⚠️ 只有 8 条

RSS 固定只给**最近 8 条**，不是"某窗口全部"。后果：

- 月刊子刊（Nature Cancer、Nature Machine Intelligence…）通常够用
- **Nature Communications 每天数十篇 → 8 条严重采样不足**，必须另走 EPMC
  （EPMC 对 NC 是最全的，`hits = 91597`）

## 4 · EPMC 收录深度分档（★机制性发现）

**这不是"滞后"，是"收录范围"问题。** EPMC 以 MEDLINE/PubMed 为主源，
所以对**生物医学刊覆盖全、对物理/材料/能源刊几乎不收录**。

用 `JOURNAL:"<刊名>"` 的 `hitCount` 可判档（2026-09-18 实测）：

| 档 | hits 量级 | 子刊 |
|---|---|---|
| **A · 全覆盖** | 万级 | Nature Communications (91597)、Nature Medicine (14185)、Nature Biotechnology (12584)、Nature Genetics (10229)、Nature Neuroscience (7793)、Nature Methods (6485)、Nature Immunology (6415)、Nature Materials (6377)、Nature Cell Biology (6066)、Nature Reviews Drug Discovery (5004)、Nature Structural & Mol Biol (4868)、Nature Chemical Biology (4770)、Nature Nanotechnology (4637)、Nature Chemistry (4288)、Nature Reviews Microbiology (3410)、Nature Reviews Immunology (3334)、Nature Reviews Molecular Cell Biology (3163)、Nature Reviews Genetics (3117)、Nature Reviews Neuroscience (3076)、Nature Reviews Clinical Oncology (2959)、Nature Cancer (2917)、Nature Microbiology (2883)、Nature Plants (2818)、Nature Human Behaviour (2362)、Nature Metabolism (1604)、Nature Food (1254)、Nature Aging (1156)、Nature Computational Science (1039)、Nature Cardiovascular Research (871) |
| **B · 收录稀少** | 百级以下 | **Nature Physics (287)**、Nature Photonics (168)、Nature Machine Intelligence (154)、Nature Climate Change (108)、**Nature Reviews Materials (88)**、Nature Reviews Bioengineering (58)、Nature Sustainability (36)、Nature Reviews Physics (33)、Nature Energy (30)、Nature Water (24)、**Nature Chemical Engineering (17)**、**Nature Mental Health (12)**、**Nature Reviews Earth & Environment (11)**、**Nature Cities (4)** |
| **C · 近乎未收录** | — | **Nature Catalysis**（最新仅到 2026-03） |

> 交叉验证：`Nature Physics` 的 RSS 在窗口内有 8 条（9/14–9/17），
> 而 EPMC 窗口 `hitCount = 0`、全库仅 287 条、最新停在 2026-08-24。
> **RSS 与 EPMC 在这里是互补而非冗余** —— 若只走 EPMC 会得出"Nature Physics 这周什么都没发"的错误结论。

### 4.1 ⚠️ Nature Reviews 系列必须用带句点的刊名

EPMC 里这批刊的 `journalTitle` 是 **`Nature reviews. <小写标题>`**：

| 查询式 | 结果 |
|---|---|
| `JOURNAL:"Nature Reviews Molecular Cell Biology"` | **0** ❌ |
| `JOURNAL:"Nature Reviews. Molecular Cell Biology"` | 3163 ✅ |
| `ISSN:"1471-0072"` | 3163 ✅ |

**结论：对 Nature Reviews 系列一律用 ISSN 查询，不要用刊名。**

## 5 · ISSN 白名单（46 本，一手实测）

> 来源：EPMC `journalInfo.journal.issn`（一手），非推测。
> ** Crossref 按 ISSN 查是档 C 通道的前提。**

| 刊物 | ISSN | 刊物 | ISSN |
|---|---|---|---|
| Nature Medicine | 1078-8956 | Nature Machine Intelligence | 2522-5839 |
| Nature Biotechnology | 1087-0156 | Nature Human Behaviour | 2397-3374 |
| Nature Genetics | 1061-4036 | Nature Computational Science | 2662-8457 |
| Nature Methods | 1548-7091 | Nature Communications | 2041-1723 |
| Nature Cell Biology | 1465-7392 | Nature Cardiovascular Research | 2731-0590 |
| Nature Immunology | 1529-2908 | Nature Chemical Engineering | 2948-1198 |
| Nature Neuroscience | 1097-6256 | Nature Cancer | 2662-1347 |
| Nature Structural & Molecular Biology | 1545-9993 | Nature Metabolism | 2522-5812 |
| Nature Chemical Biology | 1552-4450 | Nature Aging | 2662-8465 |
| Nature Microbiology | 2058-5276 | Nature Mental Health | 2731-6076 |
| Nature Ecology & Evolution | 2397-334X | Nature Cities | 2731-9997 |
| Nature Chemistry | 1755-4330 | Nature Food | 2662-1355 |
| Nature Physics | 1745-2473 | Nature Water | 2731-6084 |
| Nature Materials | 1476-1122 | Nature Plants | 2055-0278 |
| Nature Nanotechnology | 1748-3387 | Nature Catalysis | 2520-1158 |
| Nature Photonics | 1749-4885 | Nature Climate Change | 1758-678X |
| Nature Energy | 2058-7546 | Nature Sustainability | 2398-9629 |
| NR Molecular Cell Biology | 1471-0072 | NR Genetics | 1471-0056 |
| NR Cancer | 1474-175X | NR Immunology | 1474-1733 |
| NR Neuroscience | 1471-003X | NR Microbiology | 1740-1526 |
| NR Drug Discovery | 1474-1776 | NR Chemistry | 2397-3358 |
| NR Physics | 2522-5820 | NR Materials | 2058-8437 |
| NR Earth & Environment | 2662-138X | NR Clinical Oncology | 1759-4774 |
| NR Bioengineering | 2731-6092 | | |

### 5.1 ⚠️ 字段名不可跨出版社推定（重复强调）

| 出版社 | eTOC 栏目字段 |
|---|---|
| AAAS（Science） | `dc:type` |
| Elsevier（Cell） | `prism:section` |
| Springer Nature（子刊 RSS） | 无 section，只有 `content:encoded` |

**互套会静默取到空值。** 见 `00-workflow.md` 的「提取纪律」。

## 6 · 专属坑

1. **子刊 DOI 前缀可用于反查刊物**（实测）：`s41586`=正刊、`s41591`=NMed、`s41588`=NGen、
   `s41593`=NNeuro、`s41556`=NCB、`s41564`=NMicrobiol、`s41589`=NChemBiol、
   `s42255`=NMetab、`s42256`=NMI、`s43018`=NCancer、`s41929`=NCatal、`s41557`=NChem、
   `s41567`=NPhys、`s41563`=NMat、`s41565`=NNano、`s41560`=NEnergy、`s41467`=NComms、
   `s41559`=NEcoEvol、`s41893`=NSustain、`s41578`=NRMater、`s41576`=NRGenet、`s41583`=NRNeuro、
   `s41577`=NRImmunol、`s42254`=NRPhys、`s43017`=NREarthEnv、`s41571`=NRClinOnc、`s43587`=NAging。
   **不确定时用 DOI 解析，不要猜。**
2. **子刊的 AOP 提前期很长**：本期论文的 `dc:date`（在线首发）可横跨数月。
   例如 Nature Metabolism 某期作者更正的首发日早于窗口。**按 `dc:date` 归窗，不要按期号。**
3. **更正与撤稿混在 RSS 里且没有类型字段**：题名以 `Author Correction:` / `Publisher Correction:` /
   `Retraction Note:` 开头。**必须按题名前缀过滤**，不能计入研究论文。
   （实测窗口内就有至少 8 条更正 + 1 条撤稿：NI×1、NMetab×3、NCommons×2、NAging×1、NCardiovasc×1、NRClinOnc×1）
4. **RSS 的编辑摘要 ≠ 作者摘要**：`content:encoded` 是编辑写的要点（类似 Science 的
   "In Science Journals"），不像 EPMC 那样给完整作者摘要。**做四层写作时，
   "机理"层必须基于它 + 学科常识重建，并遵守口径声明的免责条款。**
5. **别把"RSS 没给"当成"这周没发"**：RSS 只有最近 8 条 + 风控拦截，
   两者都会造成空洞。写口径前先确认该刊是不是被拦了。

## 7 · 报告策略（★子刊必须收敛）

**正刊可以逐篇四层，子刊不行**：实测一周窗口内，仅 30 本子刊的 RSS 就给了 **125 条**，
Nature Communications 单独一天就是几十条。全量四层会失控。

**分层策略**：

| 层 | 对象 | 形式 |
|---|---|---|
| **深读卡** | 8–15 条：方法学突破 / 概念性发现 / 中国团队 / 与用户领域相关 | 完整四层 |
| **分刊摘要** | 其余全部条目 | 按学科分组，一行：题名 + DOI + 一句要点 |
| **综述刊单列** | Nature Reviews 系列 | 单独说明其"只发综述"的性质，不与研究论文混排 |
| **更正/撤稿** | 全部 | 单列或剔除，**绝不进研究论文段** |

**选取深读的优先级**：① 中国团队通讯单位 ② 方法学/概念性突破 ③ 与当期其他刊形成共振的
④ 临床/转化价值明确的。**每组 2–4 条，不要平均分配。**

## 8 · 与其他刊的对接

- 子刊追踪与正刊追踪**同窗口对齐**（周一~周五），便于横向看"同一周 Nature 系整体在推什么"
- 子刊的"方法学主线"应**优先与同周正刊/ Science / Cell 对照**——同一方法学动作跨刊复现
  比单刊内部复现更有信号价值
- 同步脚本（`00-workflow.md` §6.3）对子刊报告同样适用，命名沿用
  `<刊名缩写>-weekly-<窗口起始日>-deep.html`
