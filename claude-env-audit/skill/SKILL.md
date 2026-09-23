---
name: claude-env-audit
description: This skill should be used when auditing a local machine's LLM-client environment for consistency problems — proxy residue, endpoint overrides, egress-IP identity, TUN vs system-proxy coverage, IPv6 leaks, DNS leaks, or local tracking-identifier leftovers left behind by Claude Code / Claude Desktop. It provides a pair of read-only audit scripts (Windows PowerShell + macOS/Linux bash) plus a layered checklist that separates what a script can prove from what only the user can test. It also encodes the hard rules for writing a PowerShell audit script that actually runs on a zh-CN Windows host — pure-ASCII source, language-independent output matching, and checking the Process environment scope rather than only persisted scopes. Trigger on requests to "check my proxy settings", "did my proxy leak", "why is my traffic not going through the proxy", "audit my Claude/LLM environment", "is my exit IP clean", "clean up Claude leftovers", "check for IPv6 leak", "环境体检", "代理残留", "IP 纯净度", "出口 IP", "TUN 模式", "清理 Claude 残留", "换 IP 后还是被封", or any request to verify that local environment state matches what a remote service would observe.
agent_created: true
---

# LLM client environment audit

Read-only audit of the gap between **what you believe your machine looks like** and
**what a remote service actually observes**.

The failure mode this exists to prevent: someone fixes their exit IP, believes they
are clean, and never checks the four other channels that leak the same information.

## When to apply

Apply when the ask is any of:

- "Is my environment clean / consistent?"
- "Why does traffic that should be proxied behave otherwise?"
- "Is my exit IP good enough?"
- "Something keeps flagging me / banning me despite a foreign IP."
- "Clean up the local leftovers from <client>."

Do **not** apply this to auditing a full OS or to personal-file cleanup. This audits
network/env state and one application's local identifiers only.

## Non-negotiable rules

1. **Read-only.** The scripts print a report. They change nothing. Any cleanup is a
   separate, explicitly-confirmed step. Never delete `~/.claude` wholesale — it
   contains the user's settings and session history. Back up first.

2. **Never let a proxy env-var decision touch the user's machine before confirming
   the scope.** A hit in `User`/`Machine` scope is a real persisted leftover. A hit
   in `Process` scope only may have been injected by whatever launched the shell —
   including the agent sandbox itself. Report the scope; let the user confirm in
   their own terminal before changing anything.

3. **Separate what the script proved from what it could not.** Blocks like
   fail-closed behaviour, split-routing rule correctness, and per-surface testing
   (web vs desktop vs CLI) cannot be automated. State them as open items, never as
   passes.

4. **State the compliance boundary, not just the technique.** These configurations
   sit in a policy grey zone. Include the provider's literal wording on supported
   locations, credential sharing, and automation. Do not present the audit as a
   way to defeat a ban.

## The layer model

Signals group into layers. Fix them in this order — fixing a later layer while an
earlier one is dirty produces a "clean-looking" machine that is still correlated.

| Layer | What it is | Automatable? |
|---|---|---|
| **Endpoints** | `ANTHROPIC_BASE_URL`, `*_base_url` overrides pointing at non-official hosts | Yes |
| **Proxy channels** | (a) system proxy settings, (b) proxy **env vars** | Yes — but **(b) is the one missed** |
| **Egress identity** | exit IP, ASN, residential vs datacenter, abuse history | Partly (needs external sites) |
| **Address-family leaks** | IPv6 bypassing an IPv4-only TUN; DNS resolver location | Yes |
| **Failure mode** | Does a dead node fall back to direct (fail-open)? | **No — user must test** |
| **Local identity** | client tracking IDs, telemetry dirs, keychain entries | Yes |
| **Account surface** | phone, email, payment, sharing, automation | No — advisory only |

## The two-channel rule (the single most valuable finding)

"Using a proxy" means two independent things that are routinely conflated:

| Channel | Mechanism | Who reads it |
|---|---|---|
| **System proxy settings** | WinINET/WinHTTP registry, macOS network preferences | apps using the OS network stack |
| **Proxy environment variables** | `HTTP_PROXY` / `HTTPS_PROXY` / `http_proxy` / `https_proxy` / `ALL_PROXY` | **every libcurl / Node / Python / Go child process** |

A TUN adapter empties channel (a). It does **nothing** to channel (b). CLI clients
written in Node — which is most of them, including Claude Code — read channel (b).

Consequence for testing: if `HTTPS_PROXY` is set in the shell, then
`curl https://ipinfo.io` does **not** measure your routing at all. It measures the
local proxy. Any IPv6-leak or exit-IP conclusion drawn without `--noproxy "*"` is
void. Verified the hard way: a `curl -6` test reported a plausible-looking foreign
IPv4 because curl had silently used `https_proxy=http://127.0.0.1:<port>`.

## Writing a PowerShell audit script that actually runs

These are the failure modes that cost real time. They are not stylistic.

1. **Keep the `.ps1` pure ASCII. Every byte.**
   Windows PowerShell 5.1 decodes a BOM-less `.ps1` using the system ANSI codepage
   (GBK on a zh-CN host). A single non-ASCII character — **even inside a comment** —
   corrupts the token stream: strings fail to terminate and you get a pile of
   syntax errors that point at unrelated lines. Observed: adding a few localized
   string literals to a working script produced 25 parse errors and the script
   silently did not execute.
   The Write tool emits **BOM-less** UTF-8, so do not put non-ASCII in a `.ps1`.
   If you must, add a BOM afterwards:
   `[System.IO.File]::WriteAllText($p,$t,(New-Object System.Text.UTF8Encoding($true)))`

2. **Match system-command output by shape, not by language.**
   `netsh` output is localized. Matching English `direct access` **silently fails**
   on a zh-CN host and inverts the result (reports "proxy configured" when there is
   none). Match endpoint-shaped tokens instead: a regex for `ip:port`,
   `host:port`, or `https?://`. Language-independent, and it cannot invert.

3. **Know that `GetProxy()` returns the input URI when no proxy is set.**
   `[System.Net.WebRequest]::DefaultWebProxy.GetProxy($uri)` returning `$uri` means
   *no proxy*. Comparing that value against `$null` mislabels every clean machine.
   Compare the returned Host against the requested Host.

4. **Check the `Process` environment scope.**
   Iterating only `User` and `Machine` misses the only scope a child process
   actually inherits. Enumerate the real block so mixed-case and unusual names
   are not missed:
   `[Environment]::GetEnvironmentVariables("Process")`

## Verify the script ran, not just that it should have

Tooling that swallows stdout will report "exit code 0" for a script that never
executed. Never accept a report file's *contents* as proof it is current.

- Record `LastWriteTime` **and** `Length` alongside the content.
- Write to a **new filename** each run. A reader that caches by path will hand back
  the previous run's content while the file on disk is new — this is real and it
  looks exactly like success.
- Before trusting a hand-written `.ps1`, assert both of these are zero:

```powershell
$b = [System.IO.File]::ReadAllBytes($ps1)
($b | Where-Object { $_ -gt 127 }).Count          # must be 0 (pure ASCII)

$pe = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($ps1, [ref]$null, [ref]$pe)
$pe.Count                                          # must be 0 (parses clean)
```

## Workflow

1. Run the platform script.
   `scripts/check-claude-env.ps1` (Windows) or `scripts/check-claude-env.sh` (POSIX).
   Both are read-only and write a report to a path you choose.

2. Read the report. Classify every hit by **scope**, not just by presence.

3. Close the automatable gaps the script cannot: unplug the node and confirm new
   requests are **blocked** rather than routed direct. Quit the proxy app entirely
   and repeat — most setups fail that second test.

4. Cross-check the exit IP on at least **two** independent reputation sources.
   They disagree routinely; one source is not a measurement.
   Datacenter vs residential matters more than country.

5. Emit the open-items list verbatim. Do not mark anything "verified" that a
   script cannot verify.
