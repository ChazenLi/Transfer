# 期刊规范 · Science（科学）及系列子刊

## 1 · 身份

| 项 | 值 |
|---|---|
| 刊名 | Science |
| 出版社 | AAAS（美国科学促进会） |
| ISSN | 0036-8075（print）/ 1095-9203（online） |
| DOI 前缀 | `10.1126/science.<code>` |
| 出版节奏 | **周刊，每周四出版**（网站 06:00–07:00 UTC 上线） |
| 访问 | 强订阅制；News 栏目开放 |

## 2 · 卷期换算

**已核对的锚点（2026 年）：**

| 期号 | 出版日 |
|---|---|
| Volume 393, Issue 6816 | 2026-09-10 |
| Volume 393, Issue 6817 | 2026-09-17 |

- 卷号与 Nature 完全不同（**2026 年 9 月 Science 是 Vol 393，Nature 是 Vol 657**，别记混）。
- 期号每周 +1。
- 注意：Science 有 **Volume** 与 **Issue** 两套编号，报告里两个都要写。

## 3 · 栏目结构

**计入研究论文：**
- Research Article（长文，通常含多个图注主图）
- Report（短文）
- （部分期次有 Research Article 与 Report 之外的 Analysis）

**不计入：**
- Perspective、Review（综述，单独列出）
- Policy Forum、Education Forum、Books et al.、Letters（读者来信）、Editorial
- News、Perspectives、In Science Journals / In Other Journals（**这是本期内容摘要栏目，不是论文**）
- Working Life、Career Feature

**单列：**
- Erratum、Correction、Retraction、Technical Comment、eLetter

> ⚠️ `In Science Journals` 是 Science 自己的"本期速览"栏目。**别把它当成一批论文。** 本次实测的 eTOC RSS 中 37 条里有相当一部分是这类非研究项。

## 4 · 官方入口与反爬现状

| 入口 | 状态 |
|---|---|
| `science.org/toc/science/current` | ❌ 强反爬（Cloudflare） |
| `science.org/doi/...`（单篇） | ⚠️ 通常可读摘要 |
| **eTOC RSS** | ✅ **完全可用，是首选** |

### ✅ 首选入口：Science eTOC RSS

```
https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=science
```

- 返回 **RSS 1.0（RDF）**，实测一次返回 37 个 `<item>`，覆盖整期
- 每条含 `title`、`link`、`dc:date`、`dc:creator`、**`dc:type`**（栏目）
- **`dc:type` 用于区分栏目**，`dc:date` 做窗口过滤
- ⚠️ **不是 `prism:section`**（`prism:volume` / `prism:number` 才是 prism 命名空间下的，用于卷期）。
  先前误记为 `prism:section`，根因是**提取时在提问里预设了该字段名，模型顺着"确认"了**——
  见 `00-workflow.md` Step 2 的「提取纪律」。**凡字段名，必须用不预设的中立提问复验一次。**
- 局限：**只给当前一期**，历史期次拿不到

> 这是三家正刊中**最规整的官方通道**。Science 追踪优先用它，Europe PMC 做补充与历史回溯。

## 5 · Science 的可用源优先级

> **⚠️ 与 Nature 相反，Science 的主干是 RSS，不是 Europe PMC。** 见下方"实测：EPMC 滞后"。

1. **eTOC RSS**（上面那条 URL）—— **本期主干，整期目次**
2. **Crossref API** —— 补 DOI / 页码 / 卷期（比 RSS 多出"未编期的 First Release"）
   ```
   https://api.crossref.org/journals/0036-8075/works?filter=from-pub-date:YYYY-MM-DD,until-pub-date:YYYY-MM-DD&rows=100&select=DOI,title,author,page,volume,issue,published,type
   ```
   > 实测（2026-09-14~18）：返回 38 条 = RSS 的 37 条 + 1 条卷/期/页码全空的 **First Release**。**First Release 是 RSS 抓不到的**，必须靠 Crossref 或官网补。
3. **官网单篇 DOI 页** —— ✅ **摘要可读，且给教编辑摘要（Editor's summary）**，是 Science 唯一能稳定拿到正文摘要的通道（Science 是订阅制，Crossref 不给摘要）
4. **`In Science Journals` 栏目**（本期速览，DOI 形如 `10.1126/science.aem****`，页 p1200 附近）
   > ✅ **一次性拿到本期全部研究论文的编辑一段式摘要 + 起始页**。实测 2026-09-17 期该栏目含 **17 条**：正刊 14 条（其中 CRISPR 双发合并成 1 条，实际覆盖 15 篇）+ 3 条子刊预告。
   > **这是追踪 Science 单期的最高性价比入口**——抓 1 页 ≈ 抓 15 篇。起手应先抓它，再用单篇补关键数字。
5. **科学网《科学》一周论文导读** —— 中英对照摘要（**延迟约 2 天**，通常晚于 Nature 版）
   - 检索式：`《科学》(YYYYMMDD出版) 一周论文导读`
   - 入口形如 `paper.sciencenet.cn/htmlnews/YYYY/M/<id>.shtm`、`wap.sciencenet.cn/mobile.php?cat=news&id=<id>`
6. **X-MOL / 机构新闻稿 / 第三方日刊镜像**（如康奈尔 Liu Group 的 CMP Daily Journal 会逐条转载物理类论文的完整摘要）

### 实测：EPMC 对 Science 存在多日级索引滞后（2026-09-18 验证）

| 查询 | hitCount |
|---|---|
| `JOURNAL:"Science" AND FIRST_PDATE:[2026-09-14 TO 2026-09-18]` | **0** |
| `JOURNAL:"Science" AND FIRST_PDATE:[2026-09-01 TO 2026-09-18]` | 78（日期分布：09-03=38, 09-08=1, 09-10=38, **09-11=1 ←最新止于此**） |
| `JOURNAL:"Science" AND ISSN:"0036-8075"` | 189082 |

**结论：** 同一时间点，EPMC 对 Nature 是**实时**的（本周 50 条），对 Science 却**完全滞后**（本周 0 条，最新停在上一期）。**不要用 EPMC 做 Science 的当期枚举**，只可用于"补 1–2 期前的旧论文"以及栏目过滤（`pubType` 规则与 `00-workflow.md` 相同）。

## 6 · 系列子刊

Science 子刊的 DOI 特征比 Nature 更直观（`10.1126/<刊名缩写>.<code>`）：

| 子刊 | DOI 特征 | 节奏 |
|---|---|---|
| Science Advances | `10.1126/sciadv.<code>` ✅ | 每周多次，**开放获取，量大，需按主题收敛** |
| Science Immunology | `10.1126/sciimmunol.<code>` | 周刊 |
| Science Signaling | `10.1126/scisignal.<code>` | 周刊 |
| Science Translational Medicine | `10.1126/scitranslmed.<code>` | 周刊 |
| Science Robotics | `10.1126/scirobotics.<code>` | 月刊 |
| Science Partner Journals (SPJ) | 多平台，DOI 前缀各异 | 不等 —— **需单独确认** |

子刊 RSS 模式（❓ 用前实测）：把 `jc=science` 换成对应刊名参数，例如
`https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=sciadv`

## 7 · Science 专属坑

1. **不要用期刊名 `Science` 直接查 Europe PMC 而不加 ISSN**——会匹配到大量名字里带 Science 的刊。加了 ISSN 也一样：**该源对 Science 当期是空的**（见 §5 实测表），本期枚举必须走 RSS。
2. **eTOC RSS 混排 News 与 Research。** 实测 37 条里研究论文只占 15 条，社论、书评、读者来信、In Science Journals 都在里面。**必须按 `dc:type` 过滤后再统计。**
3. **Science 的新闻栏目有独立的高质量内容**（深度报道、政策解读）。如果用户问的是"Science 这周发了什么"，**要先确认是要研究论文还是全部内容**——Science 的新闻在科学界影响力很大，不该被无脑过滤掉。这一条与 Nature/Cell 不同，要主动问。默认做法：研究论文为主，新闻/评论单列不删。
4. **Science 的封面故事常与某篇 Report/Research Article 对应**，做周报时把封面说明带上会更完整。（注：官网 TOC 页受 Cloudflare 拦截，封面说明不易取；eTOC RSS 不含封面字段。）
5. 英文题名首词大小写不统一（RSS 里有的全大写作者、有的标题带句点），**呈现时统一格式**，不要原样复制粘贴出杂乱观感。
6. **RSS 的 `dc:type` 不区分 Report 与 Research Article**——本期所有原创研究统一标 `Research Article`。若报告需要区分，只能靠页码跨度（Report 约 4–5 页）或官网栏目，**不确定就别硬分**，统一称"研究论文"并注明。
7. **First Release 不在 RSS 里。** Science 有"在线优先、未编期次"的论文（Crossref 表现为 volume/issue/page 全空）。抓当期时用 Crossref 的日期区间比对，**差集即为 First Release**，单列处理。
8. **`In Science Journals` 与 `In Other Journals` 是速览栏目，不是论文。** 前者是本刊论文的编辑导读汇总（**应作为摘要主入口**），后者是其他刊的速览。两者都出现在 RSS 中且常被误计为论文条目。
9. **同题双发要合并处理。** 实测 2026-09-17 期 Doudna 组两篇（`aei0498` + `aei3472`）各占一个 DOI/p 区间，但 `In Science Journals` 里合并成一条。统计篇数时以 DOI 为准（2 篇），撰写摘要时按 1 组呈现。
