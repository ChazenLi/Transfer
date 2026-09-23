---
title: Claude 账号环境体检与修复手册
version: 1.0
compiled: 2026-09-23
scope: 客户端本地环境一致性审计 · 代理链路审计 · 账号资产配置审计
source_material: 两篇中文社区长文（@gkxspace 配置全流程 + 团队级经验总结）经联网核实、勘误、补全
target_platform: Windows / macOS / Linux 三平台对照
distribution: 公开版（已脱敏，不含任何本机实测标识）
---

# Claude 账号环境体检与修复手册

> 本手册把两篇社区长文中零散的经验，重构成一套**可执行、可验收、标注证据等级**的审计流程。
> 每一节都回答三个问题：**它在查什么 → 怎么查 → 查到之后怎么改 → 改成什么样算过**。

---

## 0. 阅读须知（先读这一节）

### 0.1 本文的定位

本文是一份 **环境一致性审计清单（environment consistency audit）**，不是"绕过风控教程"。
两者差别很大：前者的目标是**让本机环境、网络出口、账号资料三者自洽，并把所有历史残留清干净**；
后者依赖伪造与对抗，且随时会因为服务端策略变更而失效。

### 0.2 合规边界：先把官方明文摆出来

以下是 Anthropic 官方页面与条款的**逐字引用**（证据等级 A）。这些是硬边界，本文所有建议都不应越过它们：

| 事项 | 官方原文 | 来源 |
|---|---|---|
| 地理限制 | "Only users **physically located** in one of our supported locations can create and use Claude accounts." | [Verify your phone number](https://support.claude.com/en/articles/8287232-verify-your-phone-number) |
| 手机号来源 | "We also require a phone number from a **supported location** to create an account, and there isn't a way to skip this step." | 同上 |
| 不可用号码类型 | "you cannot use **VoIP numbers, Google Voice**, phone numbers created using apps, **landlines**, or other numbers that can't receive texts to verify your account." | 同上 |
| 号码复用上限 | "We only allow a maximum of **three** Claude accounts to be verified with the same phone number." | 同上 |
| 号码不可更改 | "There isn't a way to change your phone number associated with your Claude account once it has been verified." | 同上 |
| 凭证共享 | "You may not share your Account login information, Anthropic API key, or Account credentials with anyone else. You also may not make your Account available to anyone else." | [Consumer Terms](https://www.anthropic.com/legal/consumer-terms) 第 2 条 |
| 自动化访问 | 禁止 "to access the Services through **automated or non-human means**, whether through a bot, script, or otherwise"（经 Anthropic API Key 访问除外） | Consumer Terms 第 3 条 |
| 多账号规避 | 禁止 "**Create or manage multiple accounts to evade detection or circumvent platform safeguards**" | [Using Agents According to Our Usage Policy](https://support.claude.com/en/articles/12005017-using-agents-according-to-our-usage-policy) |
| 违规终止不退款 | "If we terminate your access to the Services due to a violation of these Terms and you have a Subscription, you will not be entitled to any refund." | Consumer Terms 第 12 条 |
| 闲置回收 | "We may also terminate your Account if you have been **inactive for over a year** and you do not have a paid Account."（会提前通知） | 同上 |

**需要直说的三件事**：

1. **"改时区 / 换住宅 IP / 用美国号"这套做法，其本身不改变第 0.2 节第一条的结论。** 官方约束的是"物理所在位置（physically located）"，不是"出口 IP 归属"。任何以隐匿实际位置为目的的配置，都处在条款灰区。本文不为此背书。
2. **真正零风险的合规路径有三条**：① 使用国内可合法访问的替代模型；② 通过 Anthropic 官方 API（Console）按其支持地区政策使用；③ 等待官方支持范围变化。本手册不替代这三条。
3. **如果目的是"止损与体检"**——比如你已经在用、想搞清楚为什么被关联、想把一台脏机器洗干净——那本文是对的，请往下读。

### 0.3 证据分级

本文对每条论断标注等级，便于判断可信度：

| 等级 | 定义 | 例子 |
|---|---|---|
| **A** | 官方页面/条款逐字明文，或可复现的技术事实 | "手机号必须来自支持地区" |
| **B** | 官方人员公开承认，或多来源一致的权威报道 | "2.1.196 隐蔽标记机制确实存在" |
| **C** | 社区广泛共识、多份独立资料互相印证，但无官方确认 | "阈值累积模型" |
| **D** | 单人经验、来源不明、或已被证伪 | "骂 AI 会被封号" |

---

## 1. 结论先行：按优先级该做什么

如果你时间有限，只做这 6 件事，能覆盖绝大部分实际风险：

| 优先级 | 动作 | 验收标准 | 本文位置 |
|---|---|---|---|
| **P0** | 清空所有指向非官方端点的 `ANTHROPIC_BASE_URL` 与代理环境变量 | 全平台 `env`/注册表/配置文件中无残留 | §4.5 |
| **P0** | 代理切到 **TUN 模式**，系统代理设置置空 | 系统代理查询结果全 0 / 全空 | §4.4 |
| **P0** | 代理**不再自动切换节点、不允许直连（fail-closed）** | 断线测试中请求被阻断而非改走直连 | §4.6 |
| **P1** | 本地 Claude 残留（ID / 遥测 / Keychain / 会话）清理 | 追踪字段为空、Keychain 条目不存在 | §4.1 |
| **P1** | 出口 IP 做纯净度体检（Scamalytics / ping0 / IPQS 交叉验证） | 欺诈分 < 30，无 proxy/Tor/abuse 标记 | §4.3 |
| **P2** | 账号资料自洽性（手机号、邮箱、支付、套餐节奏） | 见 §4.8–4.11 各节验收项 | §4.8–4.11 |

---

## 2. 事实基线：先把 2026 年那件事说准确

两篇原始材料都把"时区检测"作为核心论据。这个论据的**技术细节基本准确，但结论已经过期**。这是本手册最重要的勘误。

### 2.1 事件时间线

| 时间 | 事件 | 等级 |
|---|---|---|
| 2026-03 | Anthropic 上线所称的"实验性反滥用措施"（工作人员说法） | B |
| 2026-04-02 | 相关代码随 Claude Code **2.1.91** 版本发布，未出现在任何 changelog | B |
| 2026-06-12 | 美国政府针对外国公民的 AI 模型出口管制条款生效 | B |
| 2026-06-30 | 上述出口管制被解除 | B |
| 2026-07-01 | 开发者 Thereallo 逆向 2.1.196 发现隐蔽标记；Anthropic 工程师 Thariq Shihipar 在 X 上回应，称其为"3 月上线的实验"，旨在防止未授权账号转售与蒸馏攻击 | B |
| 2026-07-02 | 回滚版本发布，相关检测代码被删除 | B |
| 2026-07-08 | 工业和信息化部网络安全威胁和漏洞信息共享平台（NVDB）发布风险提示，建议排查受影响版本、卸载或升级 | B |

### 2.2 机制的真实细节（这决定了我们该防什么）

根据逆向披露，该机制的行为如下：

- **触发条件**：**仅当** `ANTHROPIC_BASE_URL` 指向**非官方端点**（即非 `api.anthropic.com`）时才会执行。**直连官方 API 的流量不参与检测。**
- **两项检查**：
  1. 本机系统时区是否为 `Asia/Shanghai` 或 `Asia/Urumqi`；
  2. 端点域名是否命中一份约 **147 条**的域名清单，以及一个 AI 实验室关键词表
     （关键词包括 `deepseek`、`moonshot`、`minimax`、`zhipu`、`bigmodel`、`baichuan`、`stepfun`、`01ai`、`dashscope`、`volces` 等）。
- **混淆方式**：域名表 Base64 编码后再以密钥 `91` 做 XOR 加密。
- **外送方式（隐写）**：不新增遥测字段，而是改写系统提示词中的两个字符级细节——
  - 日期分隔符：`2026-06-30` → `2026/06/30`（命中中国时区时）
  - `Today's` 中的撇号替换为不同 Unicode 码点：
    - `U+0027`（普通撇号）= 无命中
    - `U+2019` = 命中已知域名
    - `U+02BC` = 命中 AI 实验室关键词
    - `U+02B9` = 两者都命中
- **版本痕迹**：2.1.196 中实现该逻辑的函数名为 `Crt`、`Rrt(e)`、`e0t`、`Zup`、`edp`、`Vla`。

### 2.3 由此得出的三条判断

1. **"客户端读时区"这个组件在 2026-07-02 已被移除。** 因此"必须把时区改成台北"这条建议，其**原始证据基础已消失**。这不等于说改时区没用（服务端侧仍可能做 IP/时区一致性分析），但**它不再是因为"客户端在扫你时区"**。
2. **`ANTHROPIC_BASE_URL` 是当时唯一被证实的"强信号"来源。** 也就是说，那波风控里，**用第三方中转站的人比用官方 API + 干净代理的人危险得多**。这条结论至今仍有指导意义：**能用官方端点就别用中转站**。
3. **反向也成立**：该机制只在走中转时生效，说明**官方端点的正常流量没有被这套东西标记**。所以本手册把"清掉 BASE_URL 残留"排在 P0，不是因为它今天还在被扫，而是因为它是一个**你无法控制的、随时可能被重新启用的信号位**。

---

## 3. 信号面总览

综合官方条款与社区案例，风控信号可归为 8 个维度。下表的"权重"是社区经验值（等级 C），不要当精确数字用，它的用途是**排优先级**。

| # | 维度 | 社区估计权重 | 主要证据来源 | 本手册章节 |
|---|---|---|---|---|
| 1 | 网络出口（IP 类型 / 纯净度 / 地理跳跃） | 高 | 官方：不接受境外号码 + 仅限支持地区 | §4.3 |
| 2 | 代理可见性（系统代理残留 / TUN / DNS 泄漏） | 高 | 技术事实 + 官方自动化检测 | §4.4–4.7 |
| 3 | 凭证与行为合规性（共享、自动化、多账号规避） | 高 | **官方明文禁止** | §4.11 |
| 4 | 支付渠道（虚拟卡 / 卡段风险 / 账单地址） | 中高 | 官方反欺诈流程 | §4.10 |
| 5 | 注册资料（手机号归属地 / 邮箱稳定性） | 中高 | **官方明文要求** | §4.8–4.9 |
| 6 | 本地设备残留（追踪 ID / Keychain / 会话） | 中 | 可复现的技术事实 | §4.1 |
| 7 | 使用节奏（额度打满 / 短期暴涨） | 中 | 社区案例 | §4.11 |
| 8 | 环境一致性（时区 / 语言 / WebRTC） | 低（★已降级） | 详见 §2.3 | §4.2 |

**核心心智模型（等级 C）**：命中信号后**不立即封号**，而是进风控队列累积打分，达阈值才触发。
这解释了为什么有人裸连两年没事、有人环境干净却几天就没了——**阈值是动态的，封禁潮期间会整体下调**。
实操含义：**不要指望"我今天做对了某事"就不被封；要做的是把所有维度的分数都压到最低。**

---

## 4. 逐项检测与修复

### 4.1 本地设备残留

**为什么**：Claude Code 在本地持久化了跨会话追踪标识。清除后，从服务端视角看这台机器是"新设备"。

**追踪标识清单（等级 A，实测可复现）**

| 标识 | 存储位置 | 说明 |
|---|---|---|
| `userID` | `~/.claude.json` | 随机 64 位十六进制串，**跨会话追踪主键** |
| `anonymousId` | `~/.claude.json` | 格式 `claudecode.v1.` 备用 ID |
| `firstStartTime` | `~/.claude.json` | 首次启动时间 |
| `claudeCodeFirstTokenDate` | `~/.claude.json` | 首次取 token 时间 |
| `oauthAccount` | `~/.claude.json` | 含 `accountUuid`、`emailAddress`，**直接绑定身份** |
| `s1mAccessCache` / `groveConfigCache` / `passesEligibilityCache` / `clientData` | `~/.claude.json` | 各类缓存 |
| Statsig Stable ID | `~/.claude/statsig/` | 特性开关系统的设备标识 |

**需清理的目录**

```
~/.claude/telemetry/
~/.claude/statsig/
~/.claude/stats-cache.json
~/.claude/history.jsonl
~/.claude/paste-cache/
~/.claude/shell-snapshots/
~/.claude/session-env/
~/.claude/debug/
~/.claude/settings.json        <-- 检查其中的 proxy / base_url / anthropic_ 字段
~/.claude/credentials.json     <-- 若存在
```

**Keychain（macOS 专属，最容易被漏掉）**

```bash
security delete-generic-password -s "claude-code"
security delete-generic-password -s "claude-code-credentials"
```

**Windows 对应位置**

| macOS / Linux | Windows |
|---|---|
| `~/.claude/` | `%USERPROFILE%\.claude\` |
| `~/.claude.json` | `%USERPROFILE%\.claude.json` |
| Keychain | 凭据管理器 → `cmdkey /list` 查找 `claude` 相关条目 |
| — | `%APPDATA%\Claude\`（桌面端） |
| — | `%LOCALAPPDATA%\Claude\`（桌面端缓存） |

**桌面端与应用支持目录**

```bash
# macOS
ls -la ~/Library/Application\ Support/Claude/
ls -la ~/Library/Logs/Claude/
# 若知道旧账号 org_id，可用它作为关键字搜索残留
grep -rl "<org_id>" ~/Library/Application\ Support/Claude/ 2>/dev/null
```

**浏览器侧**

- 清除 `claude.ai` / `anthropic.com` 的 Cookie 与站点数据（全部时间范围）。
- 若要隔离多账号登录态：使用**浏览器独立配置文件**（Chrome Profile / Firefox Container），无需上指纹浏览器。
- **不要**把不同账号的登录态混在同一个默认 profile 里。

**⚠️ 三条重要提醒**

1. **清理本地 ≠ 服务端记录消失。** 删掉 `userID` 只是让新会话无法与旧记录关联，不会删除 Anthropic 侧的账号历史。
2. **不要无脑 `rm -rf ~/.claude`。** 这个目录里同时含有你的设置、会话历史、自定义命令。**先备份，再选择性清理**：
   ```bash
   cp -a ~/.claude ~/.claude.bak.$(date +%Y%m%d)
   ```
3. **Windows 上删除文件可能报 `[safe-delete] trash-failed` 但文件实际已删除**（本机已知噪声）。复核时以**列目录结果**为准，不要被报错误导。

**验收**：`~/.claude.json` 中上述字段全部不存在；下一次启动 Claude Code 会生成新的 `userID`。

---

### 4.2 时区与环境一致性

**这一节的结论与两篇原文都不同，请注意。**

**两份原始材料的冲突**

| 材料 | 主张 |
|---|---|
| 材料一（配置全流程） | 手机和电脑都改成 **Asia/Taipei**，"台北在 Claude 允许的范围，和北京时间完全一样，日常使用零感知" |
| 材料二（团队经验） | **不建议改**。"东八区也有 Claude 支持的地区，单凭时区不能判断一个人能不能使用服务……没有明确证据，我不想先给自己增加这些麻烦" |

**裁定（本手册立场）**

- **不要再把"改时区"当成防封的核心动作。** 理由是 §2.3 第 1 条：**触发时区检测的那个客户端组件已于 2026-07-02 被移除**。材料一写于 7 月，它的论证在当时成立，现在证据基础已失效。
- **也不要为了防封去改时区。** 理由与材料二一致：改了时区，日历、会议、文件时间戳、Git commit 时间全要跟着适应，而收益从"确定有效"降级为"可能有点用"。这是一笔明显不划算的交易。
- **唯一值得做的一致性检查**（等级 C）：**不要出现"美国出口 IP + `zh-CN` 系统语言 + UTC+8 时区"这种极端组合**。这不是要你伪装，而是提醒——如果你已经在用美国出口，那本机语言/时区与出口的错位本身就是个弱信号。

**如果你决定改（仅在你自己的权衡下）**

macOS：
1. 系统设置 → 通用 → 日期与时间 → 关掉「自动设置时区」→ 手动选 Taipei
2. 隐私与安全性 → 定位服务 → 系统服务 → **关掉「设定时区」**（否则 Apple 会依据 Wi-Fi 定位改回）

iPhone：同上两步（防止 iCloud 把时区偏好同步回 Mac）

Windows（本机）：
```powershell
# 查看当前时区
Get-TimeZone
# 列出候选（台北对应 "Taipei Standard Time"）
tzutil /l | Select-String "Taipei"
# 设置（需要管理员权限）
tzutil /s "Taipei Standard Time"
# 关闭自动时区
Set-Service w32time -StartupType Manual   # 停止 Windows 时间服务自动校时
```

**通用验收命令（跨平台，也是 Claude Code 内部读时区用的同一个 API）**

```bash
node -e "console.log(Intl.DateTimeFormat().resolvedOptions().timeZone)"
```

---

### 4.3 网络出口：IP 类型与纯净度

**为什么**：这是社区案例中占比最高的维度。"住宅 / 静态 / 独享"是**三个不同概念**，购买时务必分清：

| 术语 | 含义 | 常见误区 |
|---|---|---|
| **住宅 IP** | 网络**类型**属于 ISP 家宽，非机房 | 买了住宅 ≠ 别人没用过 |
| **静态 IP** | IP **地址固定**不变 | 静态 ≠ 独享 |
| **独享 IP** | **没有其他人**共用 | 机场的"独享"多为营销话术 |

**检测工具与判读标准（等级 C，多来源一致）**

| 工具 | 看什么 | 判读 |
|---|---|---|
| [scamalytics.com](https://scamalytics.com/) | 欺诈分（0–100） | **< 15 优秀；< 30 可用；> 30 有不良记录；> 75 基本废掉**。真家宽通常 5–25 |
| [ipdata.co](https://ipdata.co/) | Threats 模块 | Tor / Proxy / Abuser 三项**不能有红色告警** |
| [ip2location.com](https://www.ip2location.com/) | `Usage Type` | 显示 `ISP` = 住宅；`Hosting` / `Business` = 机房 |
| [db-ip.com](https://db-ip.com/) | ASN / 归属 | 归属地须与商家标注一致，避免"广播 IP" |
| [ping0.cc](https://ping0.cc/) | 原生 vs 广播、风控值 | 国内访问友好；但只有「家宽 / IDC」两档，中间地带易误判 |
| [radar.cloudflare.com](https://radar.cloudflare.com/) | ASN 的 bot 流量占比 | 机器人流量越低越好，直接关联"跳盾"频率 |
| [abuseipdb.com](https://www.abuseipdb.com/) | 近 90 天滥用举报 | 目标为 **0%** |

> **重要方法论**：不同工具的判定经常互相矛盾（同一 IP 在 Scamalytics 标红、ping0 标绿很常见）。
> **至少用两个不同数据源交叉验证，不要只信一个。**

**两条路线（源自材料一，已核实）**

**路线 A：自建 VPS**（适合愿意动手）

| 类别 | 建议 | 说明 |
|---|---|---|
| 优先 | DMIT、搬瓦工（BandwagonHost） | 长期验证过的 CN2 GIA 线路，贵但质量稳定；DMIT 常断货 |
| 次选 | CloudCone、Vultr、Linode、Hostinger | 独立域名 hostname，不与国内厂商域名关联 |
| 大厂云 | AWS / GCP / Azure 的**美国区域** | 机房 IP，但域名不在风险清单内 |
| **避开** | 任何名字含 `alibaba` / `aliyun` / `tencent` / `qcloud` / `huawei` / `volces` / `bytedance` 的服务商 | 无论标"海外版"还是"国际版"。"美国出口 + 国内大厂域名"是**极强的关联信号** |

**路线 B：住宅 IP 服务商**（省事）
材料一推荐 IPEqual（EqualVPN），材料二另有一份工具横评。这些服务商**均在原文中附带邀请码/返利链接**，见 §9 的说明与风险提示。

**验收**
```bash
# 出口 IP 归属（终端侧！浏览器查到的 IP 不代表终端也走代理）
curl -s https://ipinfo.io | grep -E '"ip"|"country"|"org"|"timezone"'
curl -s https://ipinfo.io/country   # 期望：US 或你选择的支持地区
```

> **⚠️ 材料二强调的关键点，务必记住**：**"浏览器走了代理，不代表 Claude Code 也走了。"**
> 系统代理需要应用主动支持才生效；终端、桌面端、APP 各有自己的配置路径。
> **浏览器里查到的 IP 只代表浏览器这一次请求的出口。** 必须在**终端里**用 `curl` 单独验证一次。

---

### 4.4 代理模式：TUN 优于系统代理

**两种模式的差异（等级 A，技术事实）**

| 模式 | 机制 | 检测可见性 |
|---|---|---|
| **系统代理模式** | 客户端把系统的 HTTP/HTTPS proxy 改成 `127.0.0.1:7890` 之类 | 系统代理查询会直接暴露；任何读系统配置的程序都能看到 |
| **TUN 模式** | 内核层创建虚拟网卡（macOS 为 `utun0`，Windows 为 Wintun 适配器），接管全系统 IP 流量；**系统代理配置保持为空** | 系统层面看不到任何 proxy 记录，表现为"直连" |

**结论**：**用 TUN 模式，不用系统代理。** 这是材料一和材料二**一致**的建议（少有的不冲突之处）。

> ### ⚠️ TUN 覆盖不到的那一半：环境变量代理
>
> **这是本手册在实测中发现、而两份原始材料都低估的一个盲区。**
>
> TUN 模式让**系统代理设置**变空。但"代理"在这台机器上其实有**两条完全独立的通道**：
>
> | 通道 | 表现形式 | TUN 能否覆盖 | 谁会读它 |
> |---|---|---|---|
> | **① 系统代理设置** | WinINET/WinHTTP 注册表、macOS network preferences | ✅ 能（TUN 就是为此而生） | 使用系统网络栈的应用 |
> | **② 代理环境变量** | `HTTP_PROXY` / `HTTPS_PROXY` / `http_proxy` / `https_proxy` / `ALL_PROXY` | ❌ **完全不能** | **所有基于 libcurl / Node / Python / Go 的子进程** |
>
> **Claude Code 是 Node 程序。它读的是第 ② 条通道。**
>
> 而材料一的检查清单第 2 条（`env | grep -iE "proxy"`）恰恰是罗列中最容易被当成"顺手一查"、实际却是**最关键**的一条。
> 如果你在 `~/.zshrc`、`~/.bashrc`、`$PROFILE` 里 `export HTTPS_PROXY=http://127.0.0.1:7890`，
> **TUN 开得再干净也没用**——进程环境里那条记录照样被读走。
>
> **自查（三平台）**
>
> ```bash
> # macOS / Linux
> env | grep -iE "proxy"
> ```
> ```powershell
> # Windows —— 注意：必须查"当前进程"，不能只查持久化作用域
> Get-ChildItem env: | Where-Object { $_.Name -match "(?i)proxy" }
> [Environment]::GetEnvironmentVariables("Process").GetEnumerator() |
>     Where-Object { $_.Name -match "(?i)proxy" }
> ```
>
> **判读要点**：作用域决定性质。
> - 命中 **User / Machine（持久化）** → 是**真残留**，你开的每个终端都有，必须清。
> - 只命中 **Process（进程级）** → 由**父进程传入**，未必是你机器上的问题。先在**你自己的终端**里复核再动手。
>
> 本节 §4.5 的检查清单，请把这条当作第一优先级。

**macOS 验证**

```bash
# 期望：HTTPEnable / HTTPSEnable / SOCKSEnable 全为 0
scutil --proxy | grep -E "HTTPEnable|HTTPSEnable|SOCKSEnable"
```

**Windows 验证**

```powershell
# 1. WinINET（IE/系统设置里的代理）—— 期望 ProxyEnable = 0
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" |
    Select-Object ProxyEnable, ProxyServer, AutoConfigURL

# 2. WinHTTP（服务/部分应用的代理）—— 期望 "Direct access (no proxy server)"
netsh winhttp show proxy

# 3. .NET 默认代理
[System.Net.WebRequest]::DefaultWebProxy

# 4. 是否有 TUN 虚拟网卡（期望能看到 Wintun / TUN 适配器，且为默认路由）
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wintun|TAP|TUN" } |
    Select-Object Name, InterfaceDescription, Status
Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object ifIndex, NextHop, RouteMetric
```

**⚠️ 一个常被忽略的事实（材料二原文，等级 A）**

> "开 TUN 不等于所有流量都必须走代理，也 **不等于 Claude 一定不会直连**。
> **TUN 管的是流量有没有被接管，分流规则管的是接管以后走哪条线路，这两个设置要一起看。**"

也就是说，开 TUN 只解决了一半问题。**必须同时检查分流规则**——见下一节。

---

### 4.5 代理与端点残留清理（P0）

**为什么**：这是 **P0 级别**。理由在 §2.3 第 2–3 条——`ANTHROPIC_BASE_URL` 是已被证实的强信号来源，且是"你无法控制、随时可能被重新启用"的信号位。

**检查清单（macOS / Linux 原始命令，逐条来自材料一）**

```bash
# 1. 系统代理（应该全 0）
scutil --proxy | grep -E "HTTPEnable|HTTPSEnable|SOCKSEnable"

# 2. 当前 shell 环境变量
env | grep -iE "proxy"

# 3. shell 启动文件里有没有硬编码 proxy
grep -iE "proxy" ~/.zshrc ~/.bashrc ~/.profile ~/.zshenv 2>/dev/null

# 4. npm / yarn / pnpm 配置
npm config get proxy
npm config get https-proxy
cat ~/.npmrc 2>/dev/null | grep -i proxy

# 5. Git 配置
git config --global --get http.proxy
git config --global --get https.proxy

# 6. Claude Code 自己的 settings.json
cat ~/.claude/settings.json 2>/dev/null | grep -iE "proxy|base_url|anthropic_"

# 7. 所有 anthropic / claude 相关环境变量（重点：ANTHROPIC_BASE_URL）
env | grep -iE "anthropic|claude"

# 8. Homebrew
brew config | grep -i proxy
```

> **判读规则**：任何一处**不是空、不是 0、不是 null**，就手动清掉。
> 第 6、7 条是重中之重。用过第三方中转（各种镜像站 / aihubmix / 各类 `claude-code-hub`）或跑过 Claude Code Router 的，**几乎一定留下了指向非 `anthropic.com` 的 base URL**。

**Windows 等效检查（本机适用，对应上表 1–8）**

```powershell
# --- 1. 系统代理 ---
netsh winhttp show proxy
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" |
    Select-Object ProxyEnable, ProxyServer, AutoConfigURL

# --- 2. 当前进程环境变量 ---
Get-ChildItem env: | Where-Object { $_.Name -match "(?i)proxy" }

# --- 3. 持久化环境变量（User + Machine）---
foreach ($scope in "User","Machine") {
    foreach ($n in "HTTP_PROXY","HTTPS_PROXY","ALL_PROXY","NO_PROXY",
                   "http_proxy","https_proxy","all_proxy","no_proxy") {
        $v = [Environment]::GetEnvironmentVariable($n, $scope)
        if ($v) { "HIT  $scope $n = $v" }
    }
}

# --- 4. npm / yarn / pnpm ---
npm config get proxy
npm config get https-proxy
Get-Content "$env:USERPROFILE\.npmrc" -ErrorAction SilentlyContinue |
    Select-String -Pattern "proxy"
Get-Content "$env:USERPROFILE\.yarnrc" -ErrorAction SilentlyContinue |
    Select-String -Pattern "proxy"

# --- 5. Git ---
git config --global --get http.proxy
git config --global --get https.proxy
git config --global --list | Select-String -Pattern "(?i)proxy"

# --- 6. Claude Code settings.json ---
Get-Content "$env:USERPROFILE\.claude\settings.json" -ErrorAction SilentlyContinue |
    Select-String -Pattern "(?i)proxy|base_url|anthropic_"

# --- 7. 所有 anthropic / claude 环境变量（重点）---
foreach ($scope in "User","Machine") {
    [Environment]::GetEnvironmentVariables($scope).GetEnumerator() |
        Where-Object { $_.Name -match "(?i)anthropic|claude" } |
        ForEach-Object { "HIT  $scope $($_.Name) = $($_.Value)" }
}
# 再查当前进程
Get-ChildItem env: | Where-Object { $_.Name -match "(?i)anthropic|claude" }
```

**清除方法（Windows）**

```powershell
# 删除持久化环境变量（对每个命中的变量执行）
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")

# 清除 npm 残留
npm config delete proxy
npm config delete https-proxy

# 清除 git 残留
git config --global --unset http.proxy
git config --global --unset https.proxy
```

> **改完必须开一个新的终端窗口再验证**——已存在的进程仍持有旧的环境变量副本。

**自查参考基线（对照用）**

下表是**一份干净环境应当得到的理想结果**。跑完脚本后逐行对照；
任何一行出现具体代理端点，都要按本节步骤追到来源。

| 项目 | 期望结果 |
|---|---|
| npm proxy / https-proxy | `none` |
| git `http.proxy` / `https.proxy`（**全作用域**：system / global / local 均查） | 无 |
| User / Machine 持久化代理环境变量 | 无 |
| Process 进程级代理环境变量 | **通常应为空** |

**为什么单独盯 Process 作用域**：它不在注册表的 User / Machine 里，若命中，说明是**由启动这个 shell 的父进程注入**的——
可能来自 shell 启动文件，也可能来自某个上层工具。**必须自己复核一次**，因为如果它其实来自你的 shell profile，
Claude Code 作为 Node 程序就会读到一条显式代理记录。

```powershell
# 在你自己的终端里跑（不是任何工具代跑的终端）
set | findstr /i proxy
```

> **注意**：这与"git 代理"是两件事，不要混为一谈——两者是独立的配置面，各自都要单独查一遍。

**验收**：上表全部返回空 / 0 / null。

---

### 4.6 fail-closed：断线必须阻断，不许自动换线（P0）

**为什么**：这是最容易被忽略、后果最严重的一项。

**失效场景**：你平时走代理用 Claude，某天节点断了 → 代理客户端**自动切到直连** → Claude 那边看到的是你的 IP **从美国瞬移回国内**。这种"地理跳跃"是教科书级的异常信号。

**期望行为（术语：fail-closed）**：线路失败时**拒绝连接并报错**，而不是替你换线路。

**检查要点（来自材料二，逐条）**

1. **代理客户端侧**
   - Claude 是否有**单独指定线路**？
   - 它是否被放进了**自动切换节点的策略组**？
   - 节点失败后的兜底是否会选到 `DIRECT`（直连）？
   - ⚠️ **只选中一个节点，不等于断线保护已配好。**

2. **域名识别是否真的生效**
   - 分流规则应按域名匹配，起点是 `claude.ai`、`api.anthropic.com` 等**实际使用的域名**，再通过连接记录补齐遗漏。
   - ⚠️ **如果客户端只拿到目标 IP、没拿到域名，域名规则就匹配不到，请求会落到默认规则**；默认规则若为直连，前面所有设置全部作废。
   - 可能需要开启 **`sniff`（协议嗅探）** 来从连接信息中识别域名。
   - ⚠️ **开 sniff 不等于检查结束**——它不保证每次都能识别成功。

3. **如果中间还有一台自建 VPS（双端检查）**
   - 架构：设备 → VPS → 住宅代理 → Claude。Claude 最终看到的是住宅代理出口，VPS 负责转发。
   - ⚠️ **设备到 VPS 还连着，不代表 VPS 到住宅代理也正常。** 住宅代理坏掉时，VPS 若改用**自己的公网 IP** 访问 Claude，出口同样变了。
   - 因此：**设备端要阻止本地直连，VPS 端也要阻止改用服务器自身出口。**
   - 两端按域名分流时，**要分别检查两端是否都取得了域名**，别假定设备识别到的信息一定传给了 VPS。
   - 对专门承接 Claude 流量的入口，**无法识别或不符合允许规则的连接应当 `reject`（拒绝）**。⚠️ 该规则要限定在专用入口范围，别把服务器其他业务一起断掉。
   - **没有用 VPS 中转的，不要为了这一步专门去买。**

4. **测试方法（关键）**
   - ✅ 正常线路下：网页版 / 桌面端 / Claude Code **三者分别**确认可连接。
   - ✅ **让线路暂时不可用**（保留设备其他网络）：新的请求应当被**阻断**，**不能**改走直连或其他节点。
   - ✅ **只看页面报错不够**，要结合**代理客户端的实际连接记录**确认。
   - ✅ 恢复线路后，确认能重新连接。
   - ⚠️ **"节点断了"和"代理软件整个退出了"要分开测。** 有些配置只能处理前者；软件退出后系统会恢复直连。要连后者也保护住，需要客户端支持**系统断网保护（kill switch）**，或另外配置系统层网络限制。

**可直接交给 Agent 的提示词（材料二原文）**

> 「请先检查 Claude 各个客户端的实际联网路径。我希望 Claude 只走指定线路，线路失效时停止连接，不自动直连，也不换节点。如果经过中转服务器，两端都要检查。请先说明现有配置是否满足要求，再给出修改方案和恢复方法，并分别验证节点失效、代理软件退出两种情况。」

**验收**：断线测试中，三个客户端的**新增请求全部被阻断**，且连接记录中无直连命中。

---

### 4.7 DNS / WebRTC / IPv6 泄漏

**两个概念必须先分清（材料二原文，等级 A）**

| 概念 | 定义 |
|---|---|
| **DNS 泄漏** | 查询**没有经过**你指定的通道 |
| **DNS 污染** | 收到的解析结果**被伪造或篡改** |

> ⚠️ **查到本地运营商 DNS，还不能直接证明 DNS 污染。**
> **解析器所在国家与代理出口不同，也不能只凭这一点下结论。**

**检测**

- [dnsleaktest.com](https://www.dnsleaktest.com/) → 点击 **Extended test**，看出现了哪些解析器。
- [browserleaks.com/dns](https://browserleaks.com/dns)（备用）。
- 若设备支持 **IPv6**，一并检查——IPv6 常绕过 IPv4 的代理规则。

**排查顺序（材料二给的路径）**

1. 浏览器自己的**安全 DNS（DoH）**设置
2. **系统** DNS 设置
3. **代理客户端**的 DNS 配置

以上三处任一都可能影响结果。

**WebRTC**：浏览器侧的 WebRTC 可能暴露真实本地 IP，与代理出口不一致时会被判为"试图隐藏真实地址"。
检测：[browserleaks.com/webrtc](https://browserleaks.com/webrtc)。若做多账号隔离，在浏览器独立配置文件中禁用 WebRTC 或使用不含 WebRTC 的容器。

---

### 4.8 手机号

**官方硬约束（全部等级 A，逐字见 §0.2）**

- 必须验证，**无法跳过**
- 号码必须来自**支持地区**
- **不接受** VoIP、Google Voice、应用生成的号码、固定电话
- 同一号码最多验证 **3 个**账号
- 验证后**无法更改**

**结论**：**接码平台的号能过注册这关，但属于高风险操作**——既可能违反"非 VoIP"要求，又可能因为号码被多人复用而触发关联。材料一和材料二在这一点上完全一致：**要一个长期属于你自己的号码。**

**RedPocket 方案核实结果（等级 C）**

| 项目 | 实情 |
|---|---|
| 价格 | eBay 购年费套餐约 **$30/年**；官网约 $45+/年。建议走 eBay 续费 |
| 网络 | GSMA = AT&T 线路，**真实美国移动号码**（非 VoIP） |
| 在中国大陆 | **接收短信正常，无需 VPN**；拨打/接听电话**需要美国 IP** |
| 漫游流量 | 套餐标注含 1GB 国际漫游流量（属附赠项，建议自行在后台确认，勿当保证规格） |
| 保号 | 每年按时续费即可长期保留 |
| 设备要求 | 需支持 eSIM 的机型（iPhone XS 及以上、Pixel 3+、三星 S20+）。**国行手机不支持 eSIM 时，需借助 estk 之类的实体 eSIM 写入方案** |
| 激活 | 需在**美国网络**下完成激活（激活码 + 设备 IMEI/EID） |
| 注意事项 | 激活流程有已知 bug，需要客服协助；Wi-Fi Calling 建议在连着美国 IP 时开启 |

**验收**：有一个你能**长期控制**、归属支持地区、非 VoIP 的号码；且该号码未被用于超过 3 个账号。

---

### 4.9 邮箱

**要点（材料一 + 材料二一致，等级 C）**

1. **新注册一个干净的 Gmail** 是最省事的做法（材料一做法）。
2. **不要用买来的成品邮箱**——"临时买来的邮箱，如果卖家还掌握恢复权限，账号就没有完全在你手里"（材料二原文）。
3. 如果你有**从未被封过**的 Gmail，可以直接用。
4. **注册和重新登录都从官方入口操作**，按页面完成验证。
5. ⚠️ **一个容易忽略的细节**：点击邮件里的登录链接会打开**哪个浏览器**？如果你专门建了 Claude 浏览器环境，要确认登录流程最后回到了这个环境，**别在默认浏览器里又登录了另一个账号**。
6. **不要把凭据内容复制到聊天里**给 Agent 检查——让 Agent 检查"认证配置是否存在、来自哪里"就够了。

---

### 4.10 支付渠道

**风控逻辑**：支付信息异常是独立的高权维度。核心风险点是**账单地址与登录 IP / 账号地区严重不符**，以及**卡段本身已被标记**。

**方案梯度（材料一给出，按风控友好度排序）**

| 梯度 | 方案 | 门槛 | 说明 |
|---|---|---|---|
| 1（最优） | 美国个人银行卡；或注册美国海外公司后申美卡 | 高 | 风控视角最正常。材料二提到 Mercury（需美国公司）、Capital One（需 ITIN）、HSBC US |
| 2 | 美区 PayPal → 绑国内全币种卡或港卡，再绑到美区 Apple ID | 中 | 材料二补充：美区 PayPal 也可绑中国大陆的 Visa/Mastercard |
| 3 | Starryblu（新加坡实体 Mastercard） | 低 | 材料一的推荐，附邀请码。**见下方风险提示** |
| 4 | 礼品卡 | 低 | ⚠️ **被封号后通常不退款**，材料二明确不推荐来源不明的礼品卡 |

**Starryblu 核实结果（等级 B/C 混合）**

- 主体：由**熊猫速汇（Panda Remit）**运营，持新加坡 MAS 牌照，资金由新加坡华侨银行（OCBC）托管；官网自称受 MAS 监管。
- 产品：虚拟 + 实体 Mastercard，多币种账户，可用于 ChatGPT / Claude / Cursor 等订阅。
- 材料一称"零开卡费、国内身份证不到 10 分钟下卡"，实测可绑 Claude Pro 与 Cursor。
- ⚠️ **代价**：新加坡卡订阅 Claude 走新加坡定价，以 Max 20x 计每月约贵 **100 RMB**。

**⚠️ 红线（以下方案本手册明确不建议）**

- **黑卡、来源不明的礼品卡、利用漏洞的代充**
- **任何要求你交出账号密码、验证码或登录令牌的渠道**——"订阅还没开通，账号控制权先交出去了，这个代价不值得"（材料二原文）
- **信用卡拒付（chargeback）**：材料二与第三方资料一致指出，**在穷尽官方申诉渠道前发起拒付，几乎必然导致该支付方式被永久拉黑，并可能牵连你的身份**。有资料明确指出这会让此后的账号创建变得不可能。

**验证渠道的检查点**

| 购买方式 | 在哪里确认订阅状态 |
|---|---|
| App Store / Google Play | 对应**商店**的订阅管理页 |
| 网页购买 | 网页内的**账单与订阅**页 |

> ⚠️ **两个常见混淆**：`Google Pay` 是**付款方式**，`Google Play` 是**应用商店**，不是一回事；
> **礼品卡充值成功 ≠ Claude 订阅已开通**，还要确认订阅绑定的是**正在使用的那一个** Claude 账号。

**低价区/优惠活动的正确算法**：**把续费一起算进去**。如果只有首付能这么付，之后每次续费都要换渠道、换资料，那省下的首付不值这个麻烦。

---

### 4.11 使用行为与套餐节奏

**官方明文的红线（等级 A）**

- 禁止**共享账号与凭证**（Consumer Terms 第 2 条）
- 禁止**自动化 / 非人类方式访问**（Consumer Terms 第 3 条；经 API Key 访问除外）
- 禁止**创建或管理多个账号以逃避检测或绕开平台保障措施**（Agent Policy）
- 禁止利用自动化**批量注册**

> **判读**：这几条是"写着就一定会被执行"的。**多账号轮换、给同事共用 Max 号、把订阅 token 拿去做后台 agent，都直接踩在上面。**
> 如果需要自动化、定时任务、多步自主执行 —— **正确的做法是走 Anthropic API（Console），而不是消费级订阅 token。**

**社区经验（等级 C，非官方）**

| 项 | 建议 |
|---|---|
| 套餐节奏 | 先买低档用一段，按需逐级升（材料一：Pro → 3 天后 Max 5x → 约 10 天后 Max 20x） |
| 额度 | **不要把额度打满**，尤其避免**每周额度都用到极满** |
| 经济学 | 订阅比 API 亏，**20x 最亏，次之 10x**；"每次都蹬满"是材料二点名的"太多人踩过的坑" |
| 闲置 | **账号不要长时间闲置**。材料二记录了一个**从未登录过、注册后就放着**的账号被封的案例；官方条款也写明**超过一年不活跃且非付费**可被终止 |
| 频繁失败重试 | 出现"account disabled"后**不要反复重试**——多次失败尝试可能加重风控 |
| 行为记录 | **不要反复让它做已经明确拒绝的事**。换角色、编场景绕过去，风险远大于收益 |

**关于正常的开发需求**

如果你的工作是**正常开发、代码审查或有授权的安全测试**，被拒时的正确做法是**把真实目的、授权范围和具体任务讲清楚**——而不是编造授权场景。
材料二原文：**"不要编造授权，也不用因为一次拒绝，就认定账号已经被标记。"**

---

## 5. 两份原始材料的冲突点与裁定

两份材料在若干处直接矛盾。逐条列出并给出裁定，避免你按其中一份做却被另一份否定：

| # | 争议点 | 材料一主张 | 材料二主张 | 本手册裁定 |
|---|---|---|---|---|
| 1 | **是否改时区** | **改**为 Asia/Taipei | **不改**，无明确证据 | **倾向材料二**。理由见 §4.2：触发时区检测的客户端组件已于 2026-07-02 移除，材料一论证的证据基础已失效 |
| 2 | 设备**物理标记**（序列号级） | 提到"@suyuan1711 做了清设备指纹记录的 Skill" | "仅凭先后发生登录和封号，判断不了具体原因"；材料一自己也说"我虽然被封过两次但中间换过设备……不乱说了" | **证据不足（D）**。技术上 Claude Code **不采集 MAC 地址、CPU 型号、内存、GPU 信息**。**不要为此重装系统或改序列号** |
| 3 | **骂 AI 会被封** | 未提及 | 网友提及，作者**明确表示本人与团队未遇到** | **D，不要采信**。但"保持情绪稳定"本身没坏处 |
| 4 | **Codex 调用 Claude 被封** | 未提及 | 作者**明确持怀疑态度**，自己常用 Codex 调 Claude Code 做审查 | **D**。但这仍落在"自动化访问"条款灰区内，见 §4.11 |
| 5 | **指纹浏览器是否必需** | 未提及 | **不是必需品**。只想分离登录态 → 浏览器独立配置文件即可 | **采纳材料二**。指纹浏览器是另一项需求，普通 profile 不替代它，但也不是防封必需品 |
| 6 | **礼品卡** | 列为第 4 方案，注明"被封好像不退款" | 不建议来源不明的礼品卡 | **采纳材料二**。官方渠道 + 可续费性 > 首次省下的钱 |
| 7 | 支付最优解 | Starryblu（新加坡卡） | 美卡 / 美区 PayPal | **不矛盾，是梯度**。按 §4.10 的 1→4 梯度选，能上美卡就上美卡 |
| 8 | 代理工具结论 | 推荐 IPEqual，**批评 Astrill 分流糟糕** | 未横评 Astrill，但强调"分流规则与 TUN 要一起看" | **两者其实是同一结论**：Astrill 的短板正是分流，而分流恰恰是 §4.6 的核心 |
| 9 | 中转站风险 | 未展开 | 未展开 | **本手册新增**：§2.2 证明**走中转站是当时唯一被证实的强信号**。能用官方端点就别用中转 |

---

## 6. 统一自查清单

### 6.1 网络层

- [ ] 系统代理已置空（macOS `scutil --proxy` 全 0 / Windows `netsh winhttp show proxy` = Direct）
- [ ] 使用 **TUN 模式**，且分流规则与 TUN **一起**检查过
- [ ] Claude 有**单独的线路**，未加入自动切换策略组
- [ ] 兜底规则**不是** DIRECT
- [ ] 已开启域名嗅探（sniff），且**验证过**实际识别成功
- [ ] 若经 VPS 中转：**两端**都已阻止直连 / 已阻止改用服务器自身出口
- [ ] **断线测试通过**：线路失效时请求被阻断，未改走直连或其他节点
- [ ] **软件退出测试通过**（或已知此场景不设防，并接受该风险）
- [ ] 终端侧 `curl` 验证出口 IP 归属正确（不只看浏览器）
- [ ] DNS Extended test 无本地运营商泄漏；IPv6 已检查
- [ ] 出口 IP 纯净度：Scamalytics < 30，ipdata 无 Tor/Proxy/Abuser 告警，AbuseIPDB = 0%
- [ ] 出口 IP 归属地、时区、与账号资料**无严重错位**

### 6.2 端点与残留

- [ ] `ANTHROPIC_BASE_URL` 已清空（所有 shell / 注册表 / 配置文件）
- [ ] 所有 `ANTHROPIC_*` / `CLAUDE_*` 环境变量已过一遍
- [ ] `~/.claude/settings.json` 无 proxy / base_url / anthropic_ 字段
- [ ] npm / yarn / pnpm 代理配置已清
- [ ] git 全局代理配置已过一遍（system / global / local 三个作用域都要查）
- [ ] shell 启动文件（`.zshrc` / `.bashrc` / `.profile` / PowerShell `$PROFILE`）无硬编码 proxy

### 6.3 设备本地

- [ ] `~/.claude.json` 中追踪字段已清（`userID` / `anonymousId` / `firstStartTime` / `claudeCodeFirstTokenDate` / `oauthAccount` 等）
- [ ] `~/.claude/` 下遥测与缓存目录已清
- [ ] macOS Keychain 条目已删；Windows 凭据管理器已查
- [ ] 桌面端 `Application Support` / `%APPDATA%` / `%LOCALAPPDATA%` 残留已清
- [ ] 浏览器 claude.ai / anthropic.com 的 Cookie 与站点数据已清
- [ ] 多账号使用**独立浏览器 profile**，未混用默认 profile
- [ ] **清理前已备份**（`~/.claude` 含设置与会话历史，不要无脑删）

### 6.4 账号资料

- [ ] 手机号：长期可控、归属支持地区、**非 VoIP**
- [ ] 手机号**使用次数 ≤ 3**
- [ ] 邮箱：干净的 Gmail，或从未被封过的自有邮箱；**不是买来的成品邮箱**
- [ ] 登录链接最终落在**你预期的那个浏览器环境**
- [ ] 支付：在 §4.10 梯度的 1–3 档之间；**未使用黑卡/不明礼品卡/代充**
- [ ] 账单地址与账号地区**不严重冲突**
- [ ] 未与他人共享账号或凭证
- [ ] 未使用消费级订阅 token 承接自动化 / 后台任务
- [ ] 没有多账号轮换以规避限额或检测
- [ ] 未长时间闲置（或已确认是付费账号）
- [ ] 额度未长期打满
- [ ] 未被拒后反复重试同一请求

---

## 7. 执行顺序（别乱序做）

顺序错了会白干。按这个顺序：

```
第 0 步  备份
         cp -a ~/.claude ~/.claude.bak.$(date +%Y%m%d)   # macOS/Linux
         # Windows: PowerPoint 无关，用 robocopy
         robocopy "%USERPROFILE%\.claude" "D:\backup\.claude" /E /COPYALL

第 1 步  网络（P0）——先把管子接对
         §4.4 TUN 模式  ->  §4.5 清端点残留  ->  §4.6 fail-closed  ->  §4.7 DNS

第 2 步  出口验证（P0）——管子接对了没有
         §4.3 终端 curl + IP 纯净度交叉验证

第 3 步  设备清理（P1）——把本机洗干净
         §4.1 按顺序：追踪 ID -> 遥测/缓存 -> Keychain/凭据 -> 桌面端 -> 浏览器

第 4 步  账号资料（P2）——只有前三步都通过了再动
         §4.8 手机号  §4.9 邮箱  §4.10 支付

第 5 步  行为约束（P2，长期）
         §4.11

第 6 步  复检
         §6 全清单跑一遍；跑 skill/scripts/ 下的自查脚本留档
```

**为什么必须这个顺序**：网络没修好就去注册新账号，等于**用脏环境开新号**——这是最典型的"一出生就带标签"。
材料一的原文写得很直白：**"如果你的设备上被封过很多次账号，那这台设备本身可能已经被标记了。你在上面注册的新号，可能一出生就带着标签。"**

---

## 8. 存疑信息台账

严格区分"已知"和"听说"。以下条目**不要**当作行动依据：

| 说法 | 证据等级 | 本手册判断 |
|---|---|---|
| 客户端读时区（Layer 1 检测） | **B，但已失效** | 2026-07-02 已移除。不要基于此改时区 |
| 147 条域名清单 + AI 实验室关键词 | B | 已被逆向披露，属事实。但同样随 7/2 版本移除 |
| 阈值累积模型 | C | 与观测一致，可作为工作假设 |
| "封号占比 60% 来自 IP" | C（来源存疑） | 数字不可考，方向可信。**别拿它当精确值** |
| Claude 采集硬件指纹 | **D（已证伪）** | Claude Code **不采集** MAC / CPU / 内存 / GPU。不需要换机器或改序列号 |
| 骂 AI 会被封 | D | 无可靠证据，材料二作者明确表示未遇到 |
| Codex 调用 Claude 被封 | D | 材料二作者明确存疑，本人常用 |
| 账号长期闲置会被封 | C | 官方条款确有"超一年不活跃且非付费可终止"，**且有社区案例**。可采信 |
| 第三方工具模拟 Claude Code 被封 | C | 2026 年 1 月确有一批 OpenCode 类工具账号被处理 |
| Astrill 部分节点被 Gemini 识别限制 | D | 单人观察，无法验证 |
| EqualVPN 的住宅 IP 是"套壳假住宅" | D | 材料一自己也转述了这个质疑，但称"未遇到安全问题"。**无法验证** |

---

## 9. 工具与服务商对比（含返利声明）

> ⚠️ **重要**：两篇原文中提及的多个服务**均附带邀请码/返利链接**（云梯子、EqualVPN、Starryblu、RedPocket 的 eBay 链接等）。
> 这**不意味着**信息不实，但意味着**推荐存在利益关联**。请独立验证后再决定。

### 9.1 代理工具（材料一横评）

| 工具 | 类型 | 优点 | 缺点 |
|---|---|---|---|
| **云梯子** | 机场 | 稳定、便宜（20–30/月）、流量近乎不限、7–8 年未跑路 | **主要是动态机房 IP**，对 IP 敏感场景不够用 |
| **EqualVPN / IPEqual** | 住宅 IP 二合一 | **IP 纯净度最高**（材料一称 < 8%）、对 AI 平台友好、基于 Clash 可分流 | **流量少（120G/月）**、贵（70–90/月）、国内访问地址常变、偶发断线卡顿 |
| **voyracloud** | VPS（住宅 IP 服务器） | 便宜（$4–12）、流量充足（1T/2T）、自主可控 | 纯净度次之（10–15%）、需手动搭节点、单 IP 风险、低配偶发不可用 |
| **Astrill** | 商业 VPN | 稳定性强、中国市场友好、使用简单、节点多 | **非常贵**（180u/年，邀请 126/年）、**分流极差**、国内网站体验差、APP 端体验差 |
| **vvcloud** | 机场 | 便宜、速度尚可、标称住宅 IP | **多人共用**、节点常挂、对 AI 平台实际不好用 |

### 9.2 支付

| 方案 | 门槛 | 备注 |
|---|---|---|
| 美国个人银行卡 / 美企申美卡 | 高 | 风控最友好 |
| 美区 PayPal + 全币种卡/港卡 | 中 | 可绑到美区 Apple ID |
| Starryblu（新加坡 Mastercard） | 低 | 熊猫速汇运营，MAS 牌照；**新加坡定价更贵约 100 RMB/月** |

### 9.3 手机号

| 方案 | 成本 | 备注 |
|---|---|---|
| RedPocket eSIM | ~$30/年 | 真美国号，大陆收发短信正常；**需支持 eSIM 的机型** |
| Ultra PayGo 紫卡 / Tello | 略高 | 材料一称 RedPocket 更划算 |

> **接码平台**：能过注册，但属高风险。见 §4.8。

---

## 10. 附录

### 10.1 状态核验命令速查

```bash
# --- 我是谁 / 我在哪 ---
node -e "console.log(Intl.DateTimeFormat().resolvedOptions().timeZone)"   # 时区
scutil --proxy | grep -E "HTTPEnable|HTTPSEnable|SOCKSEnable"             # macOS 系统代理
curl -s https://ipinfo.io | grep -E '"ip"|"country"|"org"|"timezone"'      # 终端出口 IP
curl -s https://ipinfo.io/country                                          # 只要国家

# --- 端点 ---
env | grep -iE "anthropic|claude"
cat ~/.claude/settings.json | grep -iE "proxy|base_url|anthropic_"

# --- Claude Code 账号状态 ---
# 在 Claude Code 内执行：
/status    # 查看当前账号与组织
/logout    # 退出
/login     # 重新登录
# 然后重新跑 /status 核对
```

### 10.2 交给 Agent 的标准提示词

**设备残留清理**

> 「帮我清理这台电脑上 Claude 的本地残留，包括 `.claude` 目录、Keychain 里的 Claude 凭据、应用支持目录里的历史会话文件。**清理前先列出来给我确认**，并先做一次备份。」

**代理残留检查**

> 「帮我全面检查这台电脑的代理残留，包括系统代理、环境变量里的 proxy、shell 启动文件、npm 和 git 的代理配置、claude 的 `settings.json`，以及所有 `ANTHROPIC` 开头的环境变量。**把不干净的列出来给我，先不要改。**」

**联网路径审计（材料二原文）**

> 「请先检查 Claude 各个客户端的实际联网路径。我希望 Claude 只走指定线路，线路失效时停止连接，不自动直连，也不换节点。如果经过中转服务器，两端都要检查。请先说明现有配置是否满足要求，再给出修改方案和恢复方法，并分别验证节点失效、代理软件退出两种情况。」

### 10.3 参考来源

**官方（等级 A/B）**
- [Verify your phone number](https://support.claude.com/en/articles/8287232-verify-your-phone-number) — 手机号硬约束
- [Where can I access Claude?](https://support.claude.com/en/articles/8461763-where-can-i-access-claude) — 支持地区清单（160 个）
- [Anthropic Consumer Terms](https://www.anthropic.com/legal/consumer-terms) — 账号共享 / 自动化 / 终止
- [Using Agents According to Our Usage Policy](https://support.claude.com/en/articles/12005017-using-agents-according-to-our-usage-policy) — 多账号规避
- [Usage Policy](https://www.anthropic.com/legal/archive/7197103a-5e27-4ee4-93b1-f2d4c39ba1e7)

**2.1.196 事件（等级 B）**
- Thereallo 逆向披露；Thariq Shihipar（Anthropic）2026-07-01 X 回应
- [Gblock: Claude Code's Hidden Tracker Used Unicode Steganography](https://www.gblock.app/articles/claude-code-hidden-tracker-unicode-2026)
- [CyberSecurityBeat: Anthropic Removes Hidden Data Marker](https://cybersecuritybeat.com/2026/07/07/anthropic-removes-hidden-data-marker-from-claude-code-after-researcher-discovery)
- [unwire.hk 报道](https://unwire.hk/2026/07/03/claude-code-china-marker/ai/)
- 工业和信息化部 NVDB 风险提示（2026-07-08）

**社区（等级 C/D，需自行判断）**
- [Claude Code 终极防封指南（@app_sail）](https://youmind.com/zh-CN/landing/x-viral-articles/claude-code-anti-ban-guide) — 材料二的主要来源之一
- [清除 Claude Code 追踪数据指南](https://github.com/win4r/cc-notebook/blob/main/清除Claude_Code追踪数据指南.md) — 本地追踪字段清单
- [claude-local-cleanup](https://github.com/BellyBook/claude-local-cleanup) — 清理脚本
- [suyuan2022/suyuan-skill · claude-cleanup](https://skillsmp.com/creators/suyuan2022/suyuan-skill/claude-cleanup) — 材料一提到的 Skill（**注意：该 Skill 自称"不用于规避封禁或平台风控"**）

**IP 纯净度检测**
- [scamalytics.com](https://scamalytics.com/) · [ipdata.co](https://ipdata.co/) · [ip2location.com](https://www.ip2location.com/) · [db-ip.com](https://db-ip.com/) · [ping0.cc](https://ping0.cc/) · [radar.cloudflare.com](https://radar.cloudflare.com/) · [abuseipdb.com](https://www.abuseipdb.com/) · [dnsleaktest.com](https://www.dnsleaktest.com/) · [browserleaks.com](https://browserleaks.com/)

---

## 附：关于"支持地区"的一个事实澄清

Anthropic 官方支持地区清单共 **160 个国家和地区**。其中亚洲区域包含 **中国台湾地区**（列表中的 Taiwan）。

**中国香港**与**中国澳门**均**不在**该清单中。

这不改变本手册 §0.2 的核心结论：官方约束的是**用户物理所在位置**，而非出口 IP 归属。

---

## 附录 B：本机实测模板

> **公开版本说明**：本附录在本地私有版本中填入真实实测值；公开版本只保留**表格结构与判定标准**，
> 所有本机标识（出口 IP、ASN、运营商、内网网段、主机名、代理端口、系统时区）均已移除。
> 自查时请用 `skill/scripts/check-claude-env.ps1`（Windows）或 `skill/scripts/check-claude-env.sh`（macOS / Linux）
> 跑出你自己的一份结果，再按下表逐行填写。

### B.1 逐项结果

| 维度 | 你的实测 | 判定标准 |
|---|---|---|
| 系统时区 | | ⚪ 中性 —— 只要与出口地区不自相矛盾即可 |
| Locale | | ⚪ 中性 |
| WinINET 系统代理 | | ✅ 期望 `ProxyEnable = 0`，ProxyServer 与 AutoConfigURL 均为空 |
| WinHTTP 代理 | | ✅ 期望 direct access（无代理端点） |
| .NET 默认代理 | | ✅ 期望 none in effect |
| **进程级代理环境变量** | | ⚠️ **期望无**。这是唯一会被 Node 程序（含 Claude Code）直接读到的代理配置，**TUN 覆盖不到它** |
| User / Machine 持久化代理变量 | | ✅ 期望无 |
| `ANTHROPIC_*` 环境变量 | | ✅ 期望无 |
| `ANTHROPIC_BASE_URL` | | ✅ 期望**未设置** —— 指向第三方中转端点会显著提高风险 |
| npm / npm https-proxy | | ✅ 期望 none |
| git 代理（system + global + local） | | ✅ 期望 none |
| 系统凭据管理器 | | ✅ 期望无 claude / anthropic 条目 |
| `~/.claude` | | ⚪ 记录体积即可 |
| └ `shell-snapshots/` | | ⚠️ 可清理 |
| └ `session-env/` | | ⚠️ 可清理 |
| `~/.claude.json` | | ⚪ 记录体积即可 |
| └ `userID` | | ⚠️ 存在即为跨会话追踪主键 |
| └ `firstStartTime` | | ⚠️ 存在即记录首次使用时间 |
| └ `oauthAccount` | | ✅ 不存在更干净 |
| `~/.claude/settings.json` | | ✅ 期望无 proxy / base_url / anthropic_ 条目 |

### B.2 网络链路

| 项目 | 你的实测 | 判定标准 |
|---|---|---|
| TUN 网卡 | | ✅ 期望存在且状态 Up |
| IPv4 默认路由 | | ✅ 期望 `0.0.0.0/0` 指向 TUN 网卡，nexthop 落在 TUN 的 fake-ip 网段内 |
| 并行默认路由 | | ⚠️ 若物理网卡上还挂着一条同 metric 的 `0.0.0.0/0`，需确认它不会抢路由 |
| DNS | | ✅ 期望解析走 TUN 的 fake-ip 网关 |
| **出口 IP（走环境变量代理）** | | ✅ 期望国家 / 地区与「绕过代理」那一行一致 |
| **出口 IP（绕过环境变量代理）** | | ⚠️ 与上一行**不一致即说明存在旁路** |
| **IPv6 出口** | | ✅ 期望**无可用路径**，或与 IPv4 出口国家一致 |
| IPv6 全局地址 | | ⚪ 记录是否存在 |
| IPv6 默认路由 | | ⚠️ 期望 `::/0` 指向 TUN，而不是只挂在物理网卡上 |

### B.3 三条典型结论模式

**1. 出口与本地环境是否自洽。**
把出口 IP 的国家 / 地区、系统时区、`ipinfo` 报的 timezone 三者对一遍。
三者一致最好；"美国 IP + 中国时区"这类错位是典型特征。

**2. IPv6 的两种"安全"要分清。**
「v6 不可达」与「v6 被代理接管」在结论上都表现为不泄漏，但**稳健性完全不同**：
前者依赖上游网络状态，一旦 IPv6 恢复可达就会直接走物理网卡出网。
→ 建议二选一：**在代理客户端里显式接管 IPv6**，或**在物理网卡上禁用 IPv6**。

**3. IP 类型通常比配置更容易成为缺口。**
住宅 IP 与机房 IP 的差异，在配置全部做对之后，往往才是唯一剩下的可改进项。
用下表交叉验证，不要只看一家的结论：

| 检测项 | 参考站点 | 期望 |
|---|---|---|
| 欺诈分 | scamalytics.com | < 30 |
| 代理 / Tor / 滥用标记 | ipdata.co | 均无 |
| 滥用举报率 | abuseipdb.com | 0% |

### B.4 待执行动作（按优先级）

| 优先级 | 动作 | 怎么验 |
|---|---|---|
| **P0** | 在**你自己的终端**里复核代理环境变量 | Windows：`set \| findstr /i proxy`；macOS / Linux：`env \| grep -i proxy`。若命中且来自你的 shell 启动文件 → 清掉 |
| **P0** | 验证 fail-closed（脚本无法自动测） | 断开代理节点，确认各客户端的**新请求被阻断**，而不是改走直连或自动换线 |
| **P0** | 验证分流规则覆盖 `claude.ai` / `api.anthropic.com` | 在代理客户端的连接记录里看这两个域名命中了哪条规则、走了哪个节点 |
| **P1** | 对出口 IP 做纯净度交叉验证 | 见 B.3 第三张表 |
| **P1** | 清理 `~/.claude.json` 的 `userID` / `firstStartTime` 与 `shell-snapshots/`、`session-env/` | **先备份**，再按 §4.1 选择性清理 |
| **P2** | 处理 IPv6（接管或禁用） | `curl -6 -s https://ipinfo.io` 应失败、或返回与 IPv4 相同的出口国家 |
| **P2** | 浏览器侧清 `claude.ai` / `anthropic.com` 站点数据；多账号用独立 profile | 手动 |

### B.5 审计脚本自身的缺陷记录（已修复）

诚实记录：这次脚本第一版有 4 个问题，都是实跑之后才暴露的。列出来是提醒你——**能跑通不等于结论对**。

| # | 症状 | 根因 | 修法 |
|---|---|---|---|
| 1 | 脚本完全跑不起来（25 个语法错误，报"字符串缺少终止符"） | 脚本里写了**中文字符串字面量**，而 Windows PowerShell 5.1 读取**无 BOM 的 `.ps1` 时按 ANSI / GBK 解码**，中文字节被扭曲 | 脚本改为**纯 ASCII**（已校验 `non-ascii-bytes=0`），本地化匹配改用语言无关的启发式 |
| 2 | `WinHTTP proxy` 误报 `[HIT] CONFIGURED`，但实际是"无代理" | `netsh` 输出被本地化成中文（`直接访问(没有代理服务器)`），而脚本只匹配英文 `direct access` | 不再匹配语种：**出现 `ip:port` / `host:port` / `http(s)://` 才算有代理** |
| 3 | `.NET default proxy` 误报 `[WARN] https://api.anthropic.com/` | 无代理时 `GetProxy()` 会**原样返回请求 URI**，被当成了代理地址 | 比较返回值的 Host 与请求 Host，相同即判定"无代理" |
| 4 | **漏检**了进程级代理环境变量 | 只遍历了 `User` / `Machine` 两个持久化作用域，没查 `Process` | 三个作用域全查，并分别标注来源 |

> 第 4 条最严重——它漏掉的恰恰是**唯一真正会被 Claude Code 读到的那个作用域**。
> 这正是 §4.4 那个"TUN 覆盖不到的另一半"的由来。

---

*本手册基于 2026-09-23 的公开信息整理。Anthropic 的服务条款、支持地区与检测策略会持续变化，请以官方页面为准。*
