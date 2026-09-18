# 期刊规范 · Nature（自然）及系列子刊

## 1 · 身份

| 项 | 值 |
|---|---|
| 刊名 | Nature |
| 出版社 | Springer Nature |
| ISSN | 0028-0836（print）/ 1476-4687（online） |
| DOI 前缀 | `10.1038/s41586-...`（正刊） |
| 出版节奏 | **周刊，每周四出版** |
| 访问 | 部分订阅制；News/Comment 栏目多为开放 |

## 2 · 卷期换算

**已核对的锚点（2026 年）：**

| 期号 | 出版日 |
|---|---|
| Volume 657, Issue 8130 | 2026-09-03 |
| Volume 657, Issue 8131 | 2026-09-10 |
| Volume 657, Issue 8132 | 2026-09-17 |

- 期号每周 **+1**；Volume 657 覆盖 2026 年 9 月（也含 8 月末/10 月初的一部分，**跨月边界必须核对**）。
- 核对入口：`https://www.nature.com/nature/volumes`（✅ 可访问，但只给卷-月映射）。
- **不要凭记忆推卷号**，每次都用 volumes 页确认。

### ⚠️ 关键：`firstPublicationDate` 比期日早一天

同一条论文在**官网单篇页面**上有两个日期：

```
Published: 16 September 2026          ← 在线出版日（= Europe PMC 的 firstPublicationDate）
Version of record: 16 September 2026
Issue date: 17 September 2026         ← 编入期次的日期（周四）
```

**后果**：用 `FIRST_PDATE:[周一 TO 周日]` 查一个自然周，命中的是**上周四那一期**的内容，而不是本周四的。
例：查 `[2026-09-14 TO 2026-09-18]`，返回的 50 条全部落在 09-14/09-15/09-16，
其中主体（~46 条）是 **09-16 上线、09-17 期日** 的 Issue 8132。

→ 报告里必须同时写清"上线日"与"期日"，否则读者会以为这一期是 9/16 出的。

## 3 · 栏目结构（决定什么算"研究论文"）

**计入研究论文：**
- Article（含 Open Access Article）
- Review Article
- Analysis
- Perspective（视具体期次，通常单列）

**不计入（非研究内容）：**
- News、News Feature、News & Views（**这是对他人论文的点评，不是原创研究**）
- Editorial、Comment、Correspondence
- Books & Arts、Careers、Career Feature、Technology Feature、Work Feature
- Obituary、Where I Work、Futures

**单列且绝不计入新论文：**
- Author Correction、Publisher Correction、Amendments & Corrections、Retraction

> ⚠️ 典型错误：把 **News & Views** 当成研究论文。它是编辑邀请的评论文章，同期通常还会配一篇真正的 Article。

## 4 · 官方入口与反爬现状

| 入口 | 状态 | 说明 |
|---|---|---|
| `nature.com/nature/volumes` | ✅ | 只有卷-月映射，无文章 |
| `nature.com/nature/volumes/<vol>` | ❌ | **"Client Challenge" 浏览器校验页** |
| `nature.com/nature/research-articles` | ❌ | 同上 |
| `nature.com/nature/current-issue` | ❌ | 同上 |
| `feed.nature.com/nature/current-issue`（RSS） | ⚠️ | 内容有效（可被检索命中），但直接 fetch 会 302 回官网；**只给当前一期** |

**结论：不要试图爬 nature.com 的目次页。** 走 `00-workflow.md` 的 Layer 0。

## 5 · Nature 的可用源优先级

1. **Europe PMC API** —— 枚举主干
   ```
   JOURNAL:"Nature" AND FIRST_PDATE:[YYYY-MM-DD TO YYYY-MM-DD]
   ```
   **拉全量后本地按 `pubType` 分类**（`journal article` / `review; journal article` / `news` / `published erratum`）。
   **不要用 `PUB_TYPE:"research-article"` 过滤，实测返回 0。**
   > 实测 ①：2026-09-07~13 窗口 `hitCount = 55`（含 news）。
   > 实测 ②：2026-09-14~18 窗口 `hitCount = 50` = 27 研究论文 + 2 综述 + 19 新闻 + 2 勘误。
   > 该量级远超中文导读的高亮覆盖（每期仅 6–10 篇），是"全量 vs 高亮"差异的直接证据。
2. **科学网《自然》一周论文导读** —— 补中文题名与完整摘要，**中英对照、按学科分组**，质量最高的中文源
   - 检索式：`《自然》(YYYYMMDD出版) 一周论文导读`
   - 手机版正文更全：`wap.sciencenet.cn/mobile.php?cat=7&id=<id>&mobile=1&type=detail`
   - ⚠️ **通常延迟约 2 天**（9/17 的期，9/18 时导读尚未发布）。做当周追踪不要指望它，只有回溯前几周时才可用。
3. **中国科学报"小柯"秀**（`news.sciencenet.cn/sbhtmlnews/...`）—— 单篇短讯，带 DOI
4. **X-MOL** —— 补 DOI 与发表日期
5. **机构新闻稿** —— 补通讯作者与团队

## 6 · 系列子刊

子刊**节奏各异**（月刊为主，Nature Communications 近乎日报），一律按**在线发表日期**归入窗口。

| 大类 | 子刊 |
|---|---|
| 生命科学 | Nature Medicine、Nature Biotechnology、Nature Genetics、Nature Methods、Nature Cell Biology、Nature Immunology、Nature Neuroscience、Nature Structural & Molecular Biology、Nature Chemical Biology、Nature Microbiology、Nature Ecology & Evolution、Nature Cancer、Nature Metabolism |
| 物质科学 | Nature Chemistry、Nature Physics、Nature Materials、Nature Nanotechnology、Nature Photonics、Nature Energy、Nature Climate Change、Nature Sustainability |
| 交叉 / 综合 | Nature Machine Intelligence、Nature Human Behaviour、Nature Water、**Nature Communications**（开放获取，**每日数十篇，必须按主题收敛，不可全量罗列**） |
| 综述刊 | Nature Reviews 系列（Molecular Cell Biology / Genetics / Chemistry / Physics / Materials / Cancer / Drug Discovery / Microbiology 等）—— 只发综述，节奏与正刊不同，追踪时单独说明 |

**DOI 前缀 → 刊物反查表**（本次实测确认，用于快速判定一篇论文属于哪个子刊）：

| 前缀 | 刊物 |
|---|---|
| `s41586` | **Nature 正刊** ✅ |
| `s41591` | Nature Medicine ✅ |
| `s41565` | Nature Nanotechnology ✅ |
| `s42256` | Nature Machine Intelligence ✅ |
| `s43018` | Nature Cancer ✅ |
| `s41467` | Nature Communications ✅ |
| `s41567` | Nature Physics ❓ |
| `s41563` | Nature Materials ❓ |
| `s41566` | Nature Photonics ❓ |

> 其余子刊前缀未实测。**不确定时用 DOI 直接解析，不要猜。**

子刊 RSS 模式（❓ 用前实测）：`feeds.nature.com/<刊名缩写>/current-issue`

## 7 · Nature 专属坑

1. **中文摘要有笔误。** 实例：科学网导读把 S301 的 `m_K = 19.3` 写成 `m_K = 9.3`（英文摘要为 19.3）。**凡遇数量级可疑的数字，回英文 abstract 核对。**
2. **中文导读 ≠ 全量。** 科学网每期只挑 6–10 篇高亮，按学科分组。该期实际研究论文数量远多于此。**报告里必须声明这一口径。**
3. **期号与"在线优先"是两个集合，且有机器判据。** 大量论文以 AOP（Advance Online Publication）形式先上线，几周后才编入某一期。追踪"上周"时要**同时覆盖**：该周出版的那一期 + 该周上线的 AOP。
   - **判据：Europe PMC 返回的 `journalInfo` 为空、`pageInfo` 为空 ⇒ 尚未编入固定期次（AOP）**，**不是抓取失败**。反之有卷/期/页码 ⇒ 已编期。二者不要混为一谈。
   - 实测（Issue 8132，2026-09-14~18 窗口）：29 篇研究内容中**仅 7 篇已编期**（页码 `10996-5` / `11011-7` / `11000-w` / `11015-3` / `10985-8` / `10918-5` / `10948-z`），**其余 22 篇为 AOP**。
   - → 报告须在卡片上标注「AOP」，并在口径说明里写明这个二分；否则读者会把"有页码的那 7 篇"误读成该期全部产出。
4. **周三/周四是在线优先的高峰日。** 若某窗口内条目突然集中，先确认是不是发布了新一期，而不是"当周特别高产"。
5. **Correction 栏目每期都有。** 不要误当成新论文（本次检索已见到 4 条 Author Correction + 1 条 Publisher Correction 混在目次里）。
