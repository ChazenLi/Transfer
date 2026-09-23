<#
    check-claude-env.ps1  -  Claude environment audit (Windows / Windows PowerShell 5.1 compatible)
    Read-only. Changes nothing. Prints a report and writes it to a file.

    Usage:
        powershell -ExecutionPolicy Bypass -File .\check-claude-env.ps1
        powershell -ExecutionPolicy Bypass -File .\check-claude-env.ps1 -OutFile C:\temp\audit.txt

    Output is intentionally ASCII-only so it survives any console codepage.

    CRITICAL MAINTENANCE RULE
    -------------------------
    This file must remain PURE ASCII. Windows PowerShell 5.1 decodes a BOM-less
    .ps1 using the system ANSI codepage (GBK on a zh-CN machine). Any non-ASCII
    byte, even inside a comment or a quoted string, corrupts the token stream and
    the script fails to parse with misleading errors. Keep Unicode handling in
    the bash variant, or add a UTF-8 BOM after editing.
#>

[CmdletBinding()]
param(
    [string]$OutFile = "$env:USERPROFILE\Desktop\claude-env-audit.txt"
)

$Report = New-Object System.Collections.ArrayList

function Add-Line {
    param([string]$Text = "")
    [void]$Report.Add($Text)
}

function Add-Section {
    param([string]$Title)
    Add-Line ""
    Add-Line ("=" * 72)
    Add-Line ("  " + $Title)
    Add-Line ("=" * 72)
}

function Add-Result {
    param(
        [string]$Label,
        [string]$Value,
        [ValidateSet("OK", "WARN", "INFO", "HIT")][string]$Status = "INFO"
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { $Value = "<empty>" }
    $tag = "[$Status]"
    Add-Line ("{0,-6} {1,-42} {2}" -f $tag, $Label, $Value)
}

function Test-CommandExists {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------- header
Add-Line ("Claude Environment Audit - Windows")
Add-Line ("Generated : " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Line ("Host      : " + $env:COMPUTERNAME)
Add-Line ("User      : " + $env:USERNAME)
Add-Line ("PSVersion : " + $PSVersionTable.PSVersion.ToString())
Add-Line ""
Add-Line "This script is READ-ONLY. Nothing is modified."

# ---------------------------------------------------------------- 1 timezone
Add-Section "1. TIMEZONE AND LOCALE"

try {
    $tz = Get-TimeZone
    Add-Result "System timezone Id"     $tz.Id "INFO"
    Add-Result "System timezone name"   $tz.DisplayName "INFO"
    Add-Result "UTC offset"             $tz.BaseUtcOffset.ToString() "INFO"
} catch {
    Add-Result "Get-TimeZone" "failed: $($_.Exception.Message)" "WARN"
}

Add-Result "Culture"  ([System.Globalization.CultureInfo]::CurrentCulture.Name) "INFO"
Add-Result "UI culture" ([System.Globalization.CultureInfo]::CurrentUICulture.Name) "INFO"

# The API Claude Code itself uses (needs node on PATH)
if (Test-CommandExists "node") {
    try {
        $nodeTz = & node -e "console.log(Intl.DateTimeFormat().resolvedOptions().timeZone)" 2>$null
        Add-Result "node Intl timeZone" ($nodeTz | Out-String).Trim() "INFO"
    } catch {
        Add-Result "node Intl timeZone" "query failed" "WARN"
    }
} else {
    Add-Result "node Intl timeZone" "node not found on PATH" "INFO"
}

# ---------------------------------------------------------------- 2 system proxy
Add-Section "2. SYSTEM PROXY (WinINET / WinHTTP / .NET)"

try {
    $ie = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction Stop
    if ($ie.ProxyEnable -eq 1) {
        Add-Result "WinINET ProxyEnable" "1  <-- PROXY IS ON" "HIT"
    } else {
        Add-Result "WinINET ProxyEnable" "0" "OK"
    }
    Add-Result "WinINET ProxyServer"   $ie.ProxyServer   "INFO"
    Add-Result "WinINET AutoConfigURL" $ie.AutoConfigURL "INFO"
    Add-Result "WinINET ProxyOverride" $ie.ProxyOverride "INFO"
} catch {
    Add-Result "WinINET registry read" "failed: $($_.Exception.Message)" "WARN"
}

# netsh output is localized (e.g. Chinese). Force UTF-8 decoding around the call,
# then match every known localized phrasing for "no proxy" instead of English only.
try {
    $prevEnc = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $winhttp = (netsh winhttp show proxy 2>&1) | Out-String
    } finally {
        [Console]::OutputEncoding = $prevEnc
    }
    $winhttp = $winhttp.Trim()

    # Detection is deliberately LANGUAGE-INDEPENDENT: Windows localizes netsh output,
    # so matching an English phrase like "direct access" silently fails on a zh-CN host.
    # Rule: if any endpoint-looking token is present -> a proxy IS configured.
    #       if none is present              -> netsh reports "direct access (no proxy)".
    #
    # !! DO NOT ADD localized (non-ASCII) STRING LITERALS TO THIS FILE. !!
    # Windows PowerShell 5.1 reads a BOM-less .ps1 as ANSI/GBK. Non-ASCII bytes get
    # mangled, strings fail to terminate, and the whole script fails to parse.
    # Keep this file pure ASCII. Unicode matching belongs in the bash variant.
    $looksLikeProxy =
        ($winhttp -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+") -or
        ($winhttp -match "[A-Za-z0-9.\-]+\.[A-Za-z]{2,}:\d{2,5}") -or
        ($winhttp -match "(?i)https?://")

    if ($looksLikeProxy) {
        Add-Result "WinHTTP proxy" "CONFIGURED - a proxy endpoint was found" "HIT"
        Add-Line ("       raw: " + ($winhttp -replace "\s+", " "))
    } else {
        Add-Result "WinHTTP proxy" "direct access (no proxy)" "OK"
    }
} catch {
    Add-Result "WinHTTP proxy" "netsh failed" "WARN"
}

# .NET default proxy. When no proxy is configured, GetProxy() returns the request
# URI unchanged -- that means "no proxy", NOT "proxy = api.anthropic.com".
try {
    $reqUri = [uri]"https://api.anthropic.com"
    $req = [System.Net.WebRequest]::Create($reqUri)
    $p = $req.Proxy
    if ($null -eq $p) {
        Add-Result ".NET default proxy" "none" "OK"
    } else {
        $proxied = $p.GetProxy($reqUri)
        if ($proxied.Host -eq $reqUri.Host) {
            Add-Result ".NET default proxy" "none in effect" "OK"
        } else {
            Add-Result ".NET default proxy" $proxied.ToString() "HIT"
        }
    }
} catch {
    Add-Result ".NET default proxy" "query failed" "INFO"
}

# ---------------------------------------------------------------- 3 env vars
Add-Section "3. PERSISTED ENVIRONMENT VARIABLES"

$proxyNames = @(
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
    "http_proxy", "https_proxy", "all_proxy", "no_proxy",
    "FTP_PROXY", "ftp_proxy", "RSYNC_PROXY"
)

# Scope "Process" is the one that actually reaches Claude Code. It is ALSO the scope
# that a system-proxy-only mindset forgets, and TUN mode does nothing about it: TUN
# empties the *system proxy settings*, but an env-var proxy is a completely separate
# channel that every libcurl/Node/Python child process will happily obey.
# Check all three scopes, and label where each hit came from.
$found = $false
foreach ($scope in @("Process", "User", "Machine")) {
    $hitsHere = 0
    if ($scope -eq "Process") {
        # Enumerate the real block: catches mixed-case / unusual names a fixed list misses.
        $all = [Environment]::GetEnvironmentVariables("Process")
        foreach ($k in $all.Keys) {
            if ($k -match "(?i)proxy") {
                Add-Result "Process $k" ([string]$all[$k]) "HIT"
                $hitsHere++
                $found = $true
            }
        }
    } else {
        foreach ($n in $proxyNames) {
            $v = [Environment]::GetEnvironmentVariable($n, $scope)
            if (-not [string]::IsNullOrWhiteSpace($v)) {
                Add-Result "$scope $n" $v "HIT"
                $hitsHere++
                $found = $true
            }
        }
    }
    if ($hitsHere -eq 0) { Add-Line "[OK]   $scope scope: no proxy environment variables." }
}

if ($found) {
    Add-Line ""
    Add-Line "  >>> HOW TO READ THIS:"
    Add-Line "      - A hit in 'User' or 'Machine' scope is a REAL, PERSISTED leftover."
    Add-Line "        It will be in every terminal you open. Go clean it (manual 4.5)."
    Add-Line "      - A hit in 'Process' scope ONLY can be inherited from whatever launched"
    Add-Line "        this shell. Confirm in YOUR OWN terminal before acting:"
    Add-Line "            set | findstr /i proxy"
    Add-Line "      - IMPORTANT: TUN mode does NOT hide env-var proxies. TUN empties the"
    Add-Line "        system proxy settings; env vars are a separate channel."
}

# ---------------------------------------------------------------- 4 anthropic vars
Add-Section "4. ANTHROPIC / CLAUDE ENVIRONMENT VARIABLES  (HIGH PRIORITY)"

$found = $false
foreach ($scope in @("User", "Machine")) {
    try {
        $vars = [Environment]::GetEnvironmentVariables($scope)
        foreach ($k in $vars.Keys) {
            if ($k -match "(?i)anthropic|claude") {
                Add-Result "$scope $k" ([string]$vars[$k]) "HIT"
                $found = $true
            }
        }
    } catch { }
}
try {
    Get-ChildItem env: | Where-Object { $_.Name -match "(?i)anthropic|claude" } | ForEach-Object {
        Add-Result "Process $($_.Name)" ([string]$_.Value) "HIT"
        $found = $true
    }
} catch { }
if (-not $found) { Add-Line "[OK]   No ANTHROPIC_* / CLAUDE_* environment variables found." }

# BASE_URL deserves an explicit callout
$baseUrl = [Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
$baseUrlM = [Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "Machine")
$baseUrlP = $env:ANTHROPIC_BASE_URL
Add-Line ""
if ([string]::IsNullOrWhiteSpace($baseUrl) -and [string]::IsNullOrWhiteSpace($baseUrlM) -and [string]::IsNullOrWhiteSpace($baseUrlP)) {
    Add-Line "[OK]   ANTHROPIC_BASE_URL is not set anywhere. This is the desired state."
} else {
    Add-Line "[HIT]  ANTHROPIC_BASE_URL IS SET. Clear it - see manual section 4.5."
    Add-Line "       Any non-official endpoint is a strong correlation signal."
}

# ---------------------------------------------------------------- 5 npm / git
Add-Section "5. PACKAGE MANAGER AND GIT PROXY CONFIG"

if (Test-CommandExists "npm") {
    try {
        $np = (& npm config get proxy 2>$null | Out-String).Trim()
        $nh = (& npm config get https-proxy 2>$null | Out-String).Trim()
        if ($np -match "null" -or [string]::IsNullOrWhiteSpace($np)) { Add-Result "npm proxy" "none" "OK" } else { Add-Result "npm proxy" $np "HIT" }
        if ($nh -match "null" -or [string]::IsNullOrWhiteSpace($nh)) { Add-Result "npm https-proxy" "none" "OK" } else { Add-Result "npm https-proxy" $nh "HIT" }
    } catch { Add-Result "npm config" "query failed" "WARN" }
} else {
    Add-Result "npm" "not installed" "INFO"
}

foreach ($f in @("$env:USERPROFILE\.npmrc", "$env:USERPROFILE\.yarnrc", "$env:USERPROFILE\.pnpmrc")) {
    if (Test-Path $f) {
        $hits = Select-String -Path $f -Pattern "(?i)proxy" -ErrorAction SilentlyContinue
        if ($hits) {
            foreach ($h in $hits) { Add-Result (Split-Path $f -Leaf) $h.Line.Trim() "HIT" }
        } else {
            Add-Result (Split-Path $f -Leaf) "present, no proxy lines" "OK"
        }
    }
}

if (Test-CommandExists "git") {
    try {
        $gp = (& git config --global --get http.proxy  2>$null | Out-String).Trim()
        $gs = (& git config --global --get https.proxy 2>$null | Out-String).Trim()
        if ($gp) { Add-Result "git http.proxy"  $gp "HIT" } else { Add-Result "git http.proxy"  "none" "OK" }
        if ($gs) { Add-Result "git https.proxy" $gs "HIT" } else { Add-Result "git https.proxy" "none" "OK" }
        Add-Line ""
        Add-Line "NOTE: a git proxy entry may be INTENTIONAL (needed for GitHub access)."
        Add-Line "      Do not delete it blindly. Decide, then document the decision."
    } catch { Add-Result "git config" "query failed" "WARN" }
} else {
    Add-Result "git" "not installed" "INFO"
}

# ---------------------------------------------------------------- 6 claude local state
Add-Section "6. CLAUDE LOCAL STATE"

$claudeDir  = Join-Path $env:USERPROFILE ".claude"
$claudeJson = Join-Path $env:USERPROFILE ".claude.json"

if (Test-Path $claudeDir) {
    $sz = (Get-ChildItem $claudeDir -Recurse -Force -File -ErrorAction SilentlyContinue |
           Measure-Object -Property Length -Sum).Sum
    Add-Result "~\.claude exists" ("size = " + [math]::Round($sz / 1MB, 2) + " MB") "INFO"

    $targets = @("telemetry", "statsig", "paste-cache", "shell-snapshots", "session-env", "debug")
    foreach ($t in $targets) {
        $p = Join-Path $claudeDir $t
        if (Test-Path $p) { Add-Result "subdir $t" "PRESENT - candidate for cleanup" "HIT" }
    }
    foreach ($t in @("stats-cache.json", "history.jsonl", "credentials.json")) {
        $p = Join-Path $claudeDir $t
        if (Test-Path $p) {
            $len = (Get-Item $p).Length
            Add-Result "file $t" ("PRESENT (" + $len + " bytes)") "HIT"
        }
    }
} else {
    Add-Result "~\.claude" "not present" "OK"
}

if (Test-Path $claudeJson) {
    Add-Result "~\.claude.json" ("present, size = " + (Get-Item $claudeJson).Length + " bytes") "INFO"
    Add-Line ""
    Add-Line "  Tracking fields (each one found is a link to your past sessions):"
    $fields = @("userID", "anonymousId", "firstStartTime", "claudeCodeFirstTokenDate",
                "oauthAccount", "s1mAccessCache", "groveConfigCache",
                "passesEligibilityCache", "clientData")
    foreach ($f in $fields) {
        $hit = Select-String -Path $claudeJson -Pattern ('"' + $f + '"') -SimpleMatch -ErrorAction SilentlyContinue
        if ($hit) { Add-Result "  field $f" "PRESENT" "HIT" } else { Add-Result "  field $f" "absent" "OK" }
    }
} else {
    Add-Result "~\.claude.json" "not present" "OK"
}

# settings.json scanning
$settings = Join-Path $claudeDir "settings.json"
if (Test-Path $settings) {
    $hits = Select-String -Path $settings -Pattern "(?i)proxy|base_url|anthropic_" -ErrorAction SilentlyContinue
    if ($hits) {
        foreach ($h in $hits) { Add-Result "settings.json" $h.Line.Trim() "HIT" }
    } else {
        Add-Result "settings.json" "no proxy / base_url / anthropic_ entries" "OK"
    }
} else {
    Add-Result "settings.json" "not present" "INFO"
}

# Desktop app leftovers
foreach ($p in @("$env:APPDATA\Claude", "$env:LOCALAPPDATA\Claude", "$env:LOCALAPPDATA\AnthropicClaude")) {
    if (Test-Path $p) {
        $n = (Get-ChildItem $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Add-Result "desktop data" ("$p  ($n files)") "HIT"
    }
}

# ---------------------------------------------------------------- 7 credentials
Add-Section "7. WINDOWS CREDENTIAL MANAGER"

if (Test-CommandExists "cmdkey") {
    try {
        $ck = (cmdkey /list 2>$null) | Out-String
        $lines = $ck -split "`r?`n" | Where-Object { $_ -match "(?i)claude|anthropic" }
        if ($lines) {
            foreach ($l in $lines) { Add-Result "credential" $l.Trim() "HIT" }
        } else {
            Add-Result "credential entries" "no claude/anthropic entries found" "OK"
        }
    } catch { Add-Result "cmdkey" "query failed" "WARN" }
} else {
    Add-Result "cmdkey" "not available" "INFO"
}

# ---------------------------------------------------------------- 8 adapter / route
Add-Section "8. NETWORK ADAPTERS AND DEFAULT ROUTE (TUN check)"

try {
    $tun = Get-NetAdapter -ErrorAction SilentlyContinue |
           Where-Object { $_.InterfaceDescription -match "(?i)wintun|tap-|tun|wireguard|clash|sing" }
    if ($tun) {
        foreach ($a in $tun) {
            Add-Result "tun-like adapter" ("{0} | {1} | {2}" -f $a.Name, $a.InterfaceDescription, $a.Status) "INFO"
        }
    } else {
        Add-Line "[INFO] No TUN-style adapter detected. If you use system-proxy mode, see manual 4.4."
    }
} catch { Add-Result "Get-NetAdapter" "failed" "WARN" }

try {
    $routes = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
              Sort-Object RouteMetric | Select-Object -First 3
    foreach ($r in $routes) {
        $idx = $r.ifIndex
        $nm = (Get-NetAdapter -IfIndex $idx -ErrorAction SilentlyContinue).Name
        Add-Result "default route" ("ifIndex=$idx ($nm) metric=$($r.RouteMetric) nexthop=$($r.NextHop)") "INFO"
    }
} catch { Add-Result "Get-NetRoute" "failed" "WARN" }

# DNS servers
try {
    $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.ServerAddresses.Count -gt 0 }
    foreach ($d in $dns) {
        Add-Result "DNS (IPv4)" ("{0} -> {1}" -f $d.InterfaceAlias, ($d.ServerAddresses -join ", ")) "INFO"
    }
} catch { Add-Result "DNS query" "failed" "WARN" }

# IPv6 presence
# IPv6 presence. A global IPv6 address is a real bypass risk: many TUN/split-route
# setups only take over IPv4, so v6 traffic can leave through your ISP while v4
# goes through the proxy. If Anthropic sees a v6 egress, the geography flips.
try {
    $v6 = Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue |
          Where-Object { $_.PrefixOrigin -ne "WellKnown" -and $_.IPAddress -notmatch "^fe80" }
    if ($v6) {
        foreach ($a in $v6) { Add-Result "IPv6 global address" ("{0} | {1}" -f $a.InterfaceAlias, $a.IPAddress) "WARN" }
        Add-Line ""
        Add-Line "  >>> ACTION: confirm your TUN/proxy also captures IPv6."
        Add-Line "      If it does not, v6 traffic exits via your ISP while v4 exits via the proxy."
        Add-Line "      Two different egress countries from one host is a strong inconsistency signal."
        Add-Line "      Fix: enable IPv6 handling in the proxy client, or disable IPv6 on the adapter."
        Add-Line "      Verify:  curl -6 -s https://ipinfo.io   (should fail or show the proxy country)"
    } else {
        Add-Result "IPv6 global address" "none" "OK"
    }
} catch { }

# ---------------------------------------------------------------- 9 outbound identity
Add-Section "9. TERMINAL-SIDE EGRESS CHECK"

Add-Line "Browser IP is NOT terminal IP. Verify both separately."
Add-Line ""

if (Test-CommandExists "curl") {
    try {
        $ip = (& curl.exe -s --max-time 12 https://ipinfo.io 2>$null | Out-String).Trim()
        if ($ip) { Add-Line $ip } else { Add-Line "curl returned nothing (proxy down / blocked?)" }
    } catch {
        Add-Line "curl failed: $($_.Exception.Message)"
    }
} else {
    Add-Line "curl not found. Run manually:  curl -s https://ipinfo.io"
    Add-Line "PowerShell alternative:  (Invoke-RestMethod https://ipinfo.io/json)"
    try {
        $j = Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 12 -ErrorAction Stop
        Add-Line ("ip=" + $j.ip + "  country=" + $j.country + "  org=" + $j.org + "  tz=" + $j.timezone)
    } catch {
        Add-Line "Invoke-RestMethod also failed: $($_.Exception.Message)"
    }
}

Add-Line ""
Add-Line "Cross-check the resulting IP on at least TWO of these:"
Add-Line "  https://scamalytics.com/          fraud score: want < 30"
Add-Line "  https://ipdata.co/                Threats: no Tor/Proxy/Abuser flags"
Add-Line "  https://www.abuseipdb.com/        abuse confidence: want 0%"
Add-Line "  https://ping0.cc/                 residential vs IDC"
Add-Line "  https://www.dnsleaktest.com/      click 'Extended test'"

# ---------------------------------------------------------------- 10 manual items
Add-Section "10. MANUAL ITEMS THIS SCRIPT CANNOT CHECK"

@(
  "fail-closed behaviour  : unplug the node, confirm new requests are BLOCKED (not routed direct)",
  "client exit test       : quit the proxy app entirely, re-test. Most setups fail this one.",
  "split-routing rules    : claude.ai / api.anthropic.com must not fall through to DIRECT",
  "sniff / domain restore : confirm the client actually resolves the domain, not just the IP",
  "VPS relay (if any)     : both ends must block fallback to the server's own egress",
  "web + desktop + CLI    : test all three surfaces separately, not just one",
  "browser storage        : clear claude.ai / anthropic.com cookies and site data",
  "browser isolation      : use a separate browser profile per account",
  "phone number           : must be from a supported location and NOT VoIP; max 3 accounts per number",
  "payment method         : stable, renewable, in your own name; no resold gift cards",
  "account behaviour      : no credential sharing, no automation on consumer tokens, no multi-account rotation",
  "usage pacing           : do not run the weekly quota to the limit every week"
) | ForEach-Object { Add-Line ("  - " + $_) }

# ---------------------------------------------------------------- write out
Add-Line ""
Add-Line ("=" * 72)
Add-Line "END OF REPORT"
Add-Line ("=" * 72)

$text = ($Report -join [Environment]::NewLine)

Write-Output $text

try {
    $dir = Split-Path $OutFile -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $OutFile -Value $text -Encoding UTF8
    Write-Output ""
    Write-Output ("Report written to: " + $OutFile)
} catch {
    Write-Output ("Could not write report file: " + $_.Exception.Message)
}
