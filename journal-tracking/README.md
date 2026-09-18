# journal-tracking

顶级期刊（Nature / Science / Cell 及系列子刊）的**追踪规范**与**每周运行结果**。

本目录是 [`journal-paper-tracking`](https://github.com/ChazenLi/Transfer) 技能的公开镜像 + 产出归档。

---

## 目录结构

```
journal-tracking/
├── README.md            本文件
├── sync.ps1             一键同步脚本（把本地技能与最新报告推到这里）
├── skill/               ★ 技能本体（本地 ~/.workbuddy/skills/journal-paper-tracking 的镜像）
│   ├── SKILL.md             路由入口：按期刊 / 任务形态分发
│   └── references/
│       ├── 00-workflow.md       通用六步工作流 + 检索式模板
│       ├── 01-sources.md        分层数据源登记表（含各源实测可用性）
│       ├── 02-output-spec.md    输出规范：四层结构 / 口径声明 / 质检清单
│       └── journals/
│           ├── nature.md         Nature 正刊 + 子刊
│           ├── science.md        Science 正刊 + 子刊
│           ├── cell.md           Cell 正刊 + Cell Press 家族
│           └── _template.md      新增期刊照此填写
└── reports/
    └── YYYY-MM/         按统计窗口起始月归档
        └── <journal>-weekly-YYYY-MM-DD[-deep].html
```

---

## 两份内容是两种东西，别混着读

| | `skill/` | `reports/` |
|---|---|---|
| 本质 | **代码 / 规范** | **数据 / 产物** |
| 变化频率 | 每次**迭代**改一次 | 每次**运行**产一批 |
| 是否可再生 | ❌ 不可再生（是判断的沉淀） | ✅ 可再生（数据源与检索式都在） |
| 同步方向 | 本地 → repo（**单向镜像**） | 本地 → repo（**新增归档**） |

所以两者分顶层目录，**不要合并**——否则 `git log` 会被数据提交淹没，看不出规范是怎么演进的。

---

## 报告口径说明（重要）

- 深读版（`-deep` 后缀）为四层结构：**问题 → 手段 → 机理 → 结论**。
- **机理层是解释性归纳**——基于摘要与学科常识重建的因果链，**不是论文作者原话**。
- 统计窗口、对应卷期、数据源、口径限制：见每份报告文末的「口径与说明」。
- 「高亮版」与「全量枚举版」口径不同，前者只是来源覆盖的条目，非该期全量目次。

---

## 关于原始素材（data/）为何不在此仓库

周刊运行时会抓取 Europe PMC / Crossref 的原始条目与**逐字摘要文本**。
这些**未收录**本仓库——报告是二次加工（转述 + DOI 标注），而批量逐字搬运摘要属版权灰区。

元数据（题名 / DOI / 作者 / 页码 / 卷期）属事实性信息，如需可另行归档。

---

## 如何继续同步

```powershell
# 默认：镜像技能 + 归档指定工作区里的周报 + 提交 + 推送
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -ReportSourceDir "D:\wbdata\<你的工作区>"

# 只暂存与提交，不推送
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -NoPush
```

脚本行为：
1. 把 `~/.workbuddy/skills/journal-paper-tracking` 全量镜像到 `skill/`
2. 把 `-ReportSourceDir` 及其 `archive/` 下的 `*-weekly-*.html` 归档到 `reports/YYYY-MM/`
   - **同刊同窗口有 `-deep` 时只取 `-deep`**（被取代的中间版不进仓库，只留在本地 `archive/`）；
     并对仓库内同 key 的旧版做定向清理（**严格限定在该 (journal, window) 内**，不跨窗口）。
   - 即：`reports/` 存的是**每个窗口的最终交付物**，不是每次运行的全部草稿。
3. `git add` → `commit` → `push`

> **代理注意**：本机环境变量 `HTTP(S)_PROXY` 指向 `127.0.0.1:9767`，该端口对 GitHub 的 git 端点返回 502
> （`api.github.com` 反而能直连 —— 所以"API 能查"不等于"git 能推"）。
> 脚本已强制改用可用端口 `127.0.0.1:7897`。
>
> **提交身份**：账号开了「阻止暴露私有邮箱」，提交必须用
> `114374202+ChazenLi@users.noreply.github.com`（已设为本仓库局部配置）。

---

## 许可与来源

- 本仓库内容由 AI 辅助整理，**引用格式与数字以各刊官网 / DOI 原文为准**。
- 论文题名与摘要的著作权归原作者与出版方；此处仅作学术追踪与摘录。
