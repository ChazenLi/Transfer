# 00 · 通用工作流

适用于所有期刊。期刊特有的规则见 `journals/*.md`。

---

## Step 1 · 锁定窗口与卷期

把用户的口语（"上周""这个月""最近"）换成**明确的日期区间**，再换算成卷期。

- "上周" = 上一个完整的周一至周日。**不要**理解成"最近 7 天"。
- 报告里必须写出日期区间起止，否则结论无法复核。
- 三家正刊出版节奏不同（见各刊规范），同一日期区间对应的期数可能不等于 1，**"某刊该窗口无新期"是正常结论，要如实说，不要硬凑**。

## Step 2 · Layer 0 枚举（主干）

优先用机器可读通道拿到**完整清单**，而不是抽样的高亮列表。

**Europe PMC REST API**（背骨，覆盖三家全部正刊与子刊）：

```
https://www.ebi.ac.uk/europepmc/webservices/rest/search
  ?query=JOURNAL:"Nature" AND FIRST_PDATE:[2026-09-07 TO 2026-09-13]
  &format=json&pageSize=100&resultType=core
```

- 返回字段含 `doi` / `title` / `journalTitle` / `authorString` / `pubType` / `firstPublicationDate` / `pmid` / `citedByCount`
- **`pubType` 是关键**，用它区分新闻与研究论文
- **⚠️ 必须在客户端过滤，不要用 `PUB_TYPE:` 查询语法。** 实测（2026-09-18）：
  - `PUB_TYPE:"research-article"` 返回 **hitCount = 0**，而不过滤时同一窗口有 50 条
  - 返回体里 `pubType` 的**实际取值是小写且带空格的**：
    | 返回值 | 含义 |
    |---|---|
    | `journal article` | 研究论文 |
    | `review; journal article` | 综述（注意是分号连接的两个词） |
    | `news` | 新闻、News & Views、News Feature、Daily briefing |
    | `published erratum` | 勘误（含 Author Correction） |
  - 所以正确做法：**拉全量 → 读 `pubType` 字段 → 在本地分类**。用 `-like` / `contains` 做子串匹配，不要做等值匹配。
- DOI 前缀可直接判类型：`s41586` = 研究论文，`d41586` = 新闻类（Nature 的 news DOI 单独走 `d` 编号）
- 分页用 `cursorMark`（返回体里有 `nextCursorMark`），不要用 offset
- **局限**：只覆盖被 MEDLINE/PMC 索引的内容，索引有**延迟，且延迟量随期刊而异**——这一点必须按刊实测，不要假设通用。实测（2026-09-18，同一时间点）：
  - **Nature：实时**（窗口内 50 条，含当周）
  - **Science：滞后 ≥1 期**（当周 0 条；9 月最新仅到 9/11，而 9/17 那期完全未入库）
  → 所以 **EPMC 只是 Nature 侧的背骨**；对 Science 当期枚举无效，必须改用该刊的 eTOC RSS（见 `journals/science.md`）。**每次换刊先跑一次"本周期内 hitCount 是否 > 0"的探针，再决定是否以 EPMC 为主干。**
- `resultType=lite` 给基础字段（快），`resultType=core` 额外给 `abstractText` / `affiliation` / `journalInfo` / `pageInfo`（慢但信息全，可直接省掉 Crossref 富化步骤）

**期刊 eTOC RSS**（补当期完整目次 + 栏目）：

见 `01-sources.md` 的可用性表。RSS 的价值在于它给的是**整期目次**且带栏目字段，能补 Europe PMC 的漏网条目。

> 两个来源交叉比对，取并集；只在一方出现的条目要人工确认是栏目差异还是真遗漏。

### ⚠️ 提取纪律（实测逼出来的，违反会污染技能本身）

**从网页/RSS/API 提取字段名、栏目名、取值时，提问里不要预设答案。**

- 反例（已被证伪）：提问写"给出 `prism:section` 字段"→ 模型返回"`prism:section` = Research Article"，
  看起来确认了，**实际该 feed 用的是 `dc:type`**。模型只是顺着 prompt 里的词复述。
- 正例：提问写"**逐字列出 `<item>` 里出现的所有 XML 标签名**，只报你能实际看到的，不要推断"。
- 同理适用于：`pubType` 的取值（实测是小写 `journal article`，不是 `research-article`）、
  栏目名、卷期字段。**凡是写进本技能的具体字符串，都应当是中立复验过的。**
- 校验方法：拿一个**已知答案的反例**混进去问（如问"这个 feed 里有 `xyz:abc` 字段吗"），
  如果模型说"有"，说明它在顺从——该次提取不可信。

> 这条纪律专门防"技能被自己的错误假设污染"：一旦把错误字段名写进规范，
> 下次执行会照着错的做，且看起来一切正常。

## Step 3 · 过滤与分类

按各刊规范的栏目表判定：

1. **研究论文**：Article / Research Article / Report / Resource / Analysis（各刊定义不同，见其规范）
2. **综述**：Review / Review Article / Perspective —— 通常单列
3. **非研究内容**：News / News Feature / Editorial / Comment / Correspondence / Preview / News & Views / Books & Arts / Careers / Obituary
4. **勘误与撤稿**：Author Correction / Publisher Correction / Erratum / Corrigendum / Retraction —— **单列，绝不计入新论文**

## Step 4 · 富化

| 要补什么 | 去哪 |
|---|---|
| 卷/期/页码 | Crossref API（`https://api.crossref.org/journals/<ISSN>/works?filter=from-pub-date:...`） |
| 中文题名与摘要 | 科学网《XX》一周论文导读；X-MOL 论文详情页 |
| 通讯作者与所属机构 | 机构/高校新闻稿；Europe PMC `resultType=core` 的 affiliation 字段 |
| 中国团队识别 | 机构新闻稿 + 作者姓名拼音反查；不要仅凭姓名猜测国籍 |
| 引用与热度 | Crossref `is-referenced-by-count`；Altmetric API |
| 主题/方法标签 | 读摘要自行归纳，不要照抄关键词列表 |

## Step 5 · 热度与质量信号（可选，但周报建议做）

- Altmetric score 与百分位 —— 用于排序"最受关注"，**不等于学术重要性**，措辞要留余地
- 引用数在窗口内几乎必然为 0，**不要拿引用数排序新论文**
- 反向信号必查：PubPeer 质疑、Retraction Watch（尤其追踪旧论文时）

## Step 6 · 落盘与交付

### 6.1 先落素材，再写报告

**所有抓取的原始数据必须落成文件，不要只留在会话上下文里。** 两个理由：
重抓有索引漂移风险（EPMC 是滚动库，同式不同日返回不同）；长报告撰写可能中断
（实测中断 2 次），素材是唯一的接续依据。

约定目录 **`data/<journal>-<窗口起始日>/`**，用**语义化文件名**：

| 文件 | 内容 |
|---|---|
| `entries.tsv` | Layer 0 主干的全量条目（含 `pubType`，**未过滤**） |
| `core.tsv` | `resultType=core` 的卷期页码与通讯机构 |
| `abstracts.md` | 研究论文的**完整未截断摘要**——写机理层的原料，截断版（如 620 字符）不够用 |
| `crossref.tsv` | 补充来源（DOI / 页码 / 未编期条目） |
| `probe.md` | 探针结论（EPMC 滞后实测记录等） |

并写 `data/README.md` 登记：抓取时间、每份文件的来源与检索式、口径限制、**未落盘项**。

> **踩过的坑**：抓取时顺手产生的 `_summary.txt` / `_xxx_summary.txt` 是过程日志，
> 事后毫无价值却会淹没真正的素材。落盘时不要产生它们，或交付后立即清理。
> 临时校验文件（标签平衡检查的中间产物等）同理，**一律不留在工作区根目录**。

### 6.2 交付

按 `02-output-spec.md` 执行，默认**单文件 HTML 周报**。
最终版放工作区根目录，**被取代的旧版移入 `archive/`**（不删，留作口径对照），
最后调用 `present_files`。

---

## 检索式模板（直接改参数用）

```
# Nature 正刊，某窗口的全部条目（推荐起手式，先拉全量再本地分类）
query=JOURNAL:"Nature" AND FIRST_PDATE:[YYYY-MM-DD TO YYYY-MM-DD]
    &format=json&pageSize=100&resultType=core

# Science 正刊（刊名用 Science，注意不要匹配到子刊）
query=JOURNAL:"Science" AND ISSN:"0036-8075" AND FIRST_PDATE:[...]

# Cell 正刊
query=JOURNAL:"Cell" AND ISSN:"0092-8674" AND FIRST_PDATE:[...]

# 某个子刊
query=JOURNAL:"Nature Medicine" AND FIRST_PDATE:[...]

# 按机构追踪（如追踪中国团队）
query=JOURNAL:"Nature" AND AFF:"China" AND FIRST_PDATE:[...]
```

> 不要用 `PUB_TYPE:"..."` 过滤——实测无效（见 Step 2）。

**PowerShell 起手式**（stdout 常不被捕获，一律写文件后 Read）：

```powershell
$dir="<工作目录>\epmc"; if(!(Test-Path $dir)){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
$q='JOURNAL:"Nature" AND FIRST_PDATE:[YYYY-MM-DD TO YYYY-MM-DD]'
$u="https://www.ebi.ac.uk/europepmc/webservices/rest/search?query="+[uri]::EscapeDataString($q)+"&format=json&pageSize=100&resultType=core"
$r=Invoke-RestMethod -Uri $u -Method Get -TimeoutSec 90
$r.resultList.result | ForEach-Object {
  "$($_.firstPublicationDate)`t$($_.pubType)`t$($_.doi)`t$($_.journalInfo.volume)`t$($_.journalInfo.issue)`t$($_.pageInfo)`t$($_.title)`t$($_.affiliation)"
} | Set-Content -Path (Join-Path $dir "out.tsv") -Encoding UTF8
"hitCount=$($r.hitCount)" | Set-Content -Path (Join-Path $dir "_summary.txt") -Encoding UTF8
```

> 注意 `[uri]::EscapeDataString` 与 `Invoke-RestMethod` 在 Windows PowerShell 5.1 下可用；
> 不要用 `&&`、三元运算符等 PS7 语法。

在 WebSearch 里找二手来源时用这类式：

```
《自然》(YYYYMMDD出版) 一周论文导读
《科学》(YYYYMMDD出版) 一周论文导读
<刊名> <年月> 在线发表 论文 DOI
Nature 子刊 <年月> 封面 <关键词>
```

## 常见失败模式

| 症状 | 原因 | 对策 |
|---|---|---|
| 官网 fetch 返回 "Client Challenge" / 验证页 | 反爬 | 换 Layer 0 通道，见 `01-sources.md` |
| 只拿到零散几篇，怀疑漏了 | 用的是一周导读（高亮，非全量） | 改用 Europe PMC 枚举；并在报告里声明口径 |
| 中文来源与英文原文数字不一致 | 中文摘要笔误 | **以英文 abstract 为准** |
| 把某期的 Correction 当成新论文 | 栏目未过滤 | Step 3 硬过滤 |
| 某刊该窗口"没有论文" | 该刊是双周刊/月刊 | 核对出版节奏，如实说明 |
