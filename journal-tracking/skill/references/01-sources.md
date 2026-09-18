# 01 · 数据源登记表

**核心原则：先机器可读，再人工网页；先一手，再二手。**
下表中"状态"列的 ✅ 表示**本次已实测可用**，⚠️ 表示**可用但有局限**，❓ 表示**模式推断，用前需实测**。

---

## Layer 0 · 机器可读通道（首选主干）

| 源 | 入口 | 给什么 | 状态 |
|---|---|---|---|
| **Europe PMC REST API** | `https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=...&format=json` | **按期刊+日期区间枚举全量条目**，含 `doi`/`pubType`/`firstPublicationDate`/`authorString`/`pmid`/`citedByCount`。`pubType` 可区分 news 与研究论文 | ⚠️ **仅对部分期刊实时**：Nature ✅ 实时（当周 50 条）；**Science ❌ 滞后 ≥1 期**（当周 0 条，最新停在上一期）。用前必跑探针 |
| **Science eTOC RSS** | `https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=science` | 整期目次，RSS 1.0，含 `dc:date`、**`dc:type`**（栏目）、`dc:creator`、`prism:volume`/`prism:number` | ✅ **Science 的主干**（因其 EPMC 不可用）。实测返回整期 37 条 |
| **Science `In Science Journals`** | 官网单篇页，DOI 形如 `10.1126/science.aem****`（每期 p1200 附近一条） | **本期全部研究论文的编辑一段式摘要 + 起始页** | ✅ **摘要最高性价比入口**：1 页 ≈ 15 篇（实测 17 条） |
| **Cell eTOC RSS** | `https://www.cell.com/cell/current.rss` | 整期目次，RSS 1.0（RDF）。**字段最全**：`prism:section`（栏目）、`prism:volume`/`prism:number`、**`prism:startingPage`/`prism:endingPage`（页码）**、`dc:date`、`dc:creator`、`dc:description` | ✅ 实测 26 条 |
| **Nature RSS** | `http://feeds.nature.com/nature/current-issue` | 当期全部题名+作者 | ⚠️ 直接 fetch 会 302 到 `www.nature.com/nature/current-issue`（反爬）；内容可通过检索命中 |
| Crossref API | `https://api.crossref.org/journals/<ISSN>/works?filter=from-pub-date:YYYY-MM-DD,until-pub-date:YYYY-MM-DD&rows=100&select=DOI,title,author,page,volume,issue,published,type` | 权威 DOI、卷期页码、`is-referenced-by-count`；**能抓到 RSS 漏掉的"未编期 First Release"** | ✅ 实测可用（Science ISSN 0036-8075，2026-09-14~18 返回 38 条）。加 `&mailto=` 更礼貌 |
| OpenAlex API | `https://api.openalex.org/works?filter=primary_location.source.issn:<ISSN>,from_publication_date:...` | 机构归属、引用网络、开放获取状态 | ❓ 标准 REST，未实测 |
| PubMed E-utilities | `esearch.fcgi` + `efetch.fcgi` | 与 Europe PMC 互补的索引 | ❓ 标准 REST，未实测 |
| Altmetric API | `https://api.altmetric.com/v1/doi/<doi>` | 关注度评分与百分位 | ❓ 需申请 key（部分端点免费） |
| bioRxiv / medRxiv API | `https://api.biorxiv.org/details/biorxiv/YYYY-MM-DD/YYYY-MM-DD` | 预印本，及其"已发表于 X"的映射 | ❓ 标准 REST，未实测 |
| arXiv API | `http://export.arxiv.org/api/query?...` | 物理/数学/CS 预印本 | ❓ 标准 API |

> **为什么 Europe PMC 是背骨（但有前提）**：它一次调用就能给出"某刊在某个日期区间的全部被索引条目"，且自带栏目类型，解决了"一周导读只是高亮、不是全量"这个最常见失真点。
> **但它的实时性按刊而异**：Nature 实时、Science 滞后 ≥1 期、Cell 未实测。**每换一本刊，先跑一次"当周窗口 hitCount 是否为 0"的探针**，再决定主干——EPMC 为 0 时立即切到该刊的 eTOC RSS。

### ⚠️ RSS 字段名不可跨出版社推定（实测对照）

三家用的是不同命名空间，**把一个刊的字段名套到另一个刊上会静默失败**（取到空值，不报错）：

| 刊 | 栏目字段 | 卷期字段 | 页码 |
|---|---|---|---|
| **Science**（AAAS） | `dc:type` | `prism:volume` / `prism:number` | ❌ 无，需 Crossref 补 |
| **Cell**（Elsevier） | `prism:section` | `prism:volume` / `prism:number` / `prism:issueIdentifier` | ✅ **自带** `prism:startingPage` / `prism:endingPage` |
| **Nature**（Springer） | 无需（无反爬 RSS 可用，走 EPMC） | EPMC `journalInfo` | EPMC `pageInfo` |

> 此表**第一版填错过**——把 Science 的栏目字段记成 `prism:section`，根因是提取时在提问里预设了该字段名。
> 复验方法见 `00-workflow.md` Step 2 的「提取纪律」。**凡新增期刊字段，一律中立提问复验后再入表。**

---

## Layer 1 · 官方网页入口（含反爬现状）

| 期刊 | 可用入口 | 反爬现状 |
|---|---|---|
| Nature | `https://www.nature.com/nature/volumes` | ✅ 可访问，**但只给卷期列表，无文章** |
| Nature | `/nature/volumes/<vol>`、`/nature/research-articles`、`/nature/current-issue` | ❌ 一律返回 **"Client Challenge" 浏览器校验页** |
| Science | `https://www.science.org/toc/science/current` | ❌ 强反爬（Cloudflare），**改走 eTOC RSS** |
| Cell | `https://www.cell.com/cell/current`、`https://www.cell.com/current` | ✅ **无反爬，可直接抓**，连封面说明都有 |
| Cell Press 其他刊 | `https://www.cell.com/<刊名小写>/current` | ✅ 同一平台，预期同状态 |

**结论：三家的网页可抓性差别很大——Cell 最好抓，Nature 只能抓卷期列表，Science 基本封死。所以统一走 Layer 0，不要为每家写不同的爬虫。**

---

## Layer 2 · 预印本平台

用于两类需求：
1. **前置追踪**——某篇正刊论文其实 3 个月前的预印本已经出现过，做脉络梳理时有用
2. **窗口外补充**——正刊窗口内没有，但同主题预印本刚出

| 平台 | 领域 |
|---|---|
| bioRxiv / medRxiv | 生命科学 / 临床医学（与 Nature、Cell 系列重叠最大） |
| arXiv | 物理、数学、CS、量化生物（与 Science 物理/天文板块重叠） |
| chemRxiv | 化学 |
| Research Square | 综合，Springer 系多 |
| SSRN | 社科、经济 |

---

## Layer 3 · 中文专业媒体（补中文题名、摘要与解读）

| 源 | 位置 | 覆盖 | 状态 |
|---|---|---|---|
| **科学网《自然》一周论文导读** | `news.sciencenet.cn/htmlnews/...`、手机版 `wap.sciencenet.cn/mobile.php?cat=7&id=<id>&mobile=1&type=detail` | Nature 正刊，**中英对照题名+完整摘要，按学科分组** | ✅ 最有效的中文源 |
| **科学网《科学》一周论文导读** | `paper.sciencenet.cn/htmlnews/...`、`wap.sciencenet.cn/mobile.php?cat=news&id=<id>` | Science 正刊 | ✅ |
| **中国科学报"小柯"秀** | `news.sciencenet.cn/sbhtmlnews/YYYY/M/<id>.shtm` | 《自然》《科学》《细胞》短讯**混编在同一页** | ✅ |
| 科学网论文速递 | `paper.sciencenet.cn/htmlpaper/...` | 单篇中文摘要，含英文原文题名与作者全名 | ✅ |
| X-MOL | `x-mol.com/paper/<id>` | 论文详情，DOI + 发表日期 + 中英题名 | ✅ |
| 学术经纬（药明康德） | 公众号 | 生命科学/医药解读 | — |
| BioArt / 小柯生命 / 生物世界 / 生物谷 | 公众号、网站 | 生命科学深度解读 | — |
| 智源社区 | `hub.baai.ac.cn` | AI4S 论文解读，**常带 DOI 与代码仓库** | ✅ |
| 腾讯新闻「本周 AI 热点」「本周科研进展」 | `news.qq.com` | 中文二次解读，带 DOI | ✅ 有 3–7 天滞后 |
| 澎湃「科普中国」/ 返朴 / 赛先生 / 科研圈 | 网站、公众号 | 综合科普解读 | — |

**用法**：Layer 3 只用来**补中文表述和背景**。任何数字、结论、作者顺序，一律回 Layer 0/1 核对。

---

## Layer 4 · 机构与团队侧

用于回答"哪些是中国团队""谁是通讯作者""这个工作属于哪个实验室"。

- **高校/院所新闻稿**——信息最全（含共同一作、通讯、资助编号）。例：南开大学、厦门大学、上海交大、北大前沿交叉院、中科院各所
- **基金委 / 学会发布**——国家自然科学基金委、中国化学会、中国物理学会等
- **实验室主页 / ORCID / Google Scholar**——做团队级长期追踪时建立作者白名单
- **大学科研院汇总页**——如某些学校有"CNS 论文速递"栏目

**注意**：新闻稿有宣传倾向，标题常夸大。以论文原文为准。

---

## Layer 5 · 舆情与质量信号

| 源 | 用途 | 注意 |
|---|---|---|
| Altmetric | 关注度评分、百分位、媒体报道数 | **关注度 ≠ 学术重要性**，措辞要留余地 |
| X / Twitter | 期刊官方账号、作者自述 | 期刊官号是最快的"新论文"信号源之一 |
| Reddit r/science | 公众讨论 | 有专门讨论线程的论文很有限 |
| Faculty Opinions (F1000) | 专家推荐 | 覆盖稀疏 |
| **PubPeer** | 论文质疑 | **追踪旧论文时必查** |
| **Retraction Watch** | 撤稿数据库 | 同上；另见各刊 Retraction 栏目 |

---

## Layer 6 · 人工订阅（合规且稳定）

自动化之外，最稳的其实是**官方 eTOC 邮件**：

- Nature：注册账号后在期刊页订阅 eTOC alert
- Science：`science.org` 账号 → Content alerts
- Cell Press：`cell.com` → Register for eTOC alerts（页面自带该提示）

建议为需要的期刊各订阅一份，作为交叉校验的第四来源。

---

## 组合策略（推荐默认）

**先探针，再定主干**——EPMC 的实时性按刊而异（Nature 实时 / Science 滞后）：

```
先跑探针：JOURNAL:"<刊名>" AND FIRST_PDATE:[本周一 TO 本周五]  →  hitCount?
  ├─ >0 → EPMC 作主干 ──┐
  └─ =0 → 改用该刊 eTOC RSS 作主干 ──┤
                                     ├─ 取并集 → 按 pubType / dc:type 过滤
        Crossref ──补 DOI/页码/First Release──┘
              │
              ├─ Science：官网 `In Science Journals` ── 一次拿全期摘要 ★
              ├─ 官网单篇 DOI 页 ── 补关键数字与 Editor's summary
              ├─ 科学网导读 / X-MOL ── 补中文题名与摘要（有 2 天延迟）
              ├─ 机构新闻稿 ────────── 补团队与通讯作者
              └─ Altmetric ─────────── 补关注度
```

**两个来源不一致时的裁决顺序**：官方 DOI/原文 > Europe PMC / Crossref 结构化字段 > 期刊 RSS > 机构新闻稿 > 中文媒体。
