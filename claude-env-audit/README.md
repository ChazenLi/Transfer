# claude-env-audit

LLM 客户端**环境一致性审计**：把「你以为的本机状态」和「远端服务实际观测到的状态」之间的差距测出来。

一份长文手册 + 一个可复用的只读审计技能（Windows PowerShell 与 macOS / Linux bash 两套脚本）。

---

## 目录结构

```
claude-env-audit/
├── README.md                本文件
├── claude-env-audit.md      ★ 手册（source of truth，已脱敏）
├── claude-env-audit.html    手册渲染版（自包含单文件，可直接用浏览器打开）
├── sync.ps1                 一键同步：镜像技能 → 提交 → 推送
├── _render/                 渲染素材（pandoc 模板 + 元数据），产物是上面的 .html
│   ├── template.html
│   └── meta.yaml
└── skill/                   技能本体（本地 ~/.workbuddy/skills/claude-env-audit 的镜像）
    ├── SKILL.md
    └── scripts/
        ├── check-claude-env.ps1    Windows 只读审计脚本
        └── check-claude-env.sh     macOS / Linux 只读审计脚本
```

`skill/` 是**单向镜像**（本地 → 仓库），不是手写内容。
要改技能，改本地技能目录，再跑 `sync.ps1` 覆盖，**不要直接编辑 `skill/` 下的文件**。

---

## 手册要解决的问题

下面这些症状通常被当成同一个问题，其实是七条独立通道：

- 明明挂了代理，某些程序却像没挂一样
- 换了出口 IP，别的信号还留在原地
- TUN 开着，但流量仍然从物理网卡走了出去
- 节点断了之后，客户端**静默切到直连**（而不是断网）
- 本机残留的客户端标识，把两次使用关联到一起

手册把它们拆成七层，**按顺序修**——先修后面的层、前面的层还脏，只会得到一台"看起来干净但依然被关联"的机器：

| 层 | 内容 | 能否脚本化 |
|---|---|---|
| **端点** | `ANTHROPIC_BASE_URL` 等指向非官方端点的覆盖项 | 能 |
| **代理双通道** | (a) 系统代理设置 (b) 代理**环境变量** | 能，但 **(b) 最常被漏掉** |
| **出口身份** | 出口 IP、ASN、住宅段 vs 机房段、滥用记录 | 部分（依赖外部站点） |
| **地址族泄漏** | IPv6 绕过 IPv4-only 的 TUN；DNS 解析器位置 | 能 |
| **失效模式** | 节点死掉时是 fail-open 还是 fail-closed | **不能，必须人工测** |
| **本地标识** | 客户端追踪 ID、遥测目录、凭据管理器条目 | 能 |
| **账号面** | 手机号、邮箱、支付、共享与自动化 | 不能，只能给建议 |

### 最核心的一条：代理是两条通道

「用了代理」是两个互相独立、却经常被混为一谈的东西：

| 通道 | 机制 | 谁读它 |
|---|---|---|
| **系统代理设置** | WinINET / WinHTTP 注册表、macOS 网络偏好设置 | 走 OS 网络栈的程序 |
| **代理环境变量** | `HTTP_PROXY` / `HTTPS_PROXY` / `http_proxy` / `https_proxy` / `ALL_PROXY` | **每一个 libcurl / Node / Python / Go 子进程** |

TUN 网卡清空的是第一条通道，对第二条**毫无作用**。而用 Node 写的 CLI 客户端——包括 Claude Code——读的正是第二条。

由此推出一个容易翻车的测试结论：**如果 shell 里设了 `HTTPS_PROXY`，那 `curl https://ipinfo.io` 测的就不是你的路由，而是本地代理。**
任何没有加 `--noproxy "*"` 就得出的 IPv6 泄漏或出口 IP 结论，都是无效的。

---

## 脱敏说明（重要）

本目录中的手册是**已脱敏的公开版本**。本地私有版本里锚定在具体机器上的实测值——
出口 IP、ASN、运营商、内网网段、主机名、代理端口、系统时区——**全部已移除**。

- 附录 B 由「本机实测快照」改写为**可填空的表格模板 + 判定标准**，任何人都能填入自己的结果；
- 手册正文中的实测结论表改为**通用参考基线**（写「期望结果」而非「实测结果」）；
- 手册的「审计脚本缺陷记录」原样保留——它不含任何本机标识，而且是全套内容里方法论价值最高的一节。

本地完整版（含实测值）**不进入本仓库**。

---

## 定位与边界

本手册是一份 **环境一致性审计清单**，不是「绕过风控教程」。
前者的目标是让本机环境、网络出口、账号资料三者自洽并把历史残留清干净；
后者依赖伪造与对抗，且随时会因为服务端策略变更而失效。

服务商的条款是硬边界，手册开头逐字引用了官方明文。其中最直接的一条是：

> "Only users **physically located** in one of our supported locations can create and use Claude accounts."

也就是说，官方约束的是**用户物理所在位置**，而非出口 IP 归属。
**因此本文描述的所有配置本身都处在条款灰区，手册不为此背书。** 它的定位是「止损与体检」：
你已经在用、想搞清楚为什么被关联、想把一台脏机器洗干净——那它对；想绕开条款，那它不替代正面解法。

---

## 如何继续同步

```powershell
# 默认：镜像技能 + 提交 + 推送
powershell -ExecutionPolicy Bypass -File .\sync.ps1

# 只暂存与提交，不推送
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -NoPush
```

脚本行为：

1. 用 `robocopy /MIR` 把 `~/.workbuddy/skills/claude-env-audit` 全量镜像到 `skill/`；
2. **推送前做一次脱敏闸门检查**——扫 `claude-env-audit.md` / `.html`，命中出口 IP 模式即中止；
3. `git add`（**限定本目录与根 README**，不会顺手提交仓库里其他无关改动）→ `commit` → `push`。

> **代理注意**：本机环境变量 `HTTP(S)_PROXY` 指向的端口对 GitHub 的 git 端点不可用，
> 脚本已强制改用可用端口 `127.0.0.1:7897`（命令行 `-c` 优先级最高）。
>
> **脚本编码**：`sync.ps1` 保持**纯 ASCII**。Windows PowerShell 5.1 读取无 BOM 的 `.ps1` 时
> 按系统 ANSI 代码页解码，一个非 ASCII 字符（**哪怕在注释里**）就会让字符串无法终止、
> 报出一堆指向无关行的语法错误。这不是风格问题。

---

## 重新渲染 HTML

`claude-env-audit.html` 由 `claude-env-audit.md` 渲染而来，自包含、无外部依赖、跟随系统深浅色。
渲染素材在 `_render/`，所以下面这一条命令在任何机器上都能复现出仓库里的这一版：

```powershell
pandoc .\claude-env-audit.md `
  -f markdown+yaml_metadata_block+pipe_tables+fenced_code_blocks-smart `
  -t html5 -s --toc --toc-depth=2 `
  --metadata-file=_render/meta.yaml `
  --template=_render/template.html `
  -o claude-env-audit.html
```

三个参数是必须的，**不要顺手"简化"**：

- **`yaml_metadata_block`** —— 让 pandoc **吃掉**文首的 YAML 头。改用 `-f gfm` 就没有这个概念，
  开头的 `---` 会被当水平线、`title: ...` 会被当 setext 二级标题直接印在正文里。
- **`-smart`** —— 关掉引号自动弯排。reader 之间剩下的差异只在目录锚点上（`gfm` 会带上章节号前缀），无实质影响。
- **`--template` / `--metadata-file`** —— 少了就退回 pandoc 默认样式，与仓库里这一版不一致。

> **改完 `.md` 必须同步重渲染**，否则 `.md` 与 `.html` 会漂移——
> 本仓库的约定是长文成对发布，漂移等于发布了两份互相矛盾的内容。

---

## 许可与来源

- 手册基于 2026-09-23 的公开信息整理，由 AI 辅助完成；**服务条款、支持地区与检测策略会持续变化，一切以官方页面为准**。
- 手册 §9 涉及的工具与服务商横评中，**原始社区材料普遍带有邀请码 / 返利链接**，手册已逐条标注该利益关联。
