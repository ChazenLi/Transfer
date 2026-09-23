#Requires -Version 5.1
<#
    sync.ps1 -- publish the claude-env-audit skill and manual to
                https://github.com/ChazenLi/Transfer

    Usage:
        powershell -ExecutionPolicy Bypass -File .\sync.ps1
        powershell -ExecutionPolicy Bypass -File .\sync.ps1 -NoPush

    What it does:
        1. Mirror  <skills>\claude-env-audit  ->  .\skill\   (robocopy /MIR)
        2. Redaction gate: refuse to publish if a real machine IP literal has
           leaked back into the public edition.
        3. git add (scoped to this folder + root README) -> commit -> push

    Notes:
        - This file is intentionally ASCII-only. Windows PowerShell 5.1 reads a
          BOM-less .ps1 using the legacy ANSI code page; a single non-ASCII
          character - even inside a comment - corrupts the token stream and
          produces a pile of syntax errors pointing at unrelated lines.
        - The env vars HTTP(S)_PROXY on this machine point at a port that is not
          usable for GitHub's git endpoints. Network operations therefore force
          -c http.proxy=<Proxy>, which has the highest git precedence.
        - The commit is deliberately scoped: it will not sweep up unrelated
          changes elsewhere in the repository.
#>

[CmdletBinding()]
param(
    # Local clone of the Transfer repository (this directory's parent).
    # Resolved in the body; $PSScriptRoot is not reliable inside param().
    [string]$RepoDir,

    # Skill source (single source of truth on this machine).
    [string]$SkillSource,

    # Working proxy for GitHub on this machine.
    [string]$Proxy = "http://127.0.0.1:7897",

    # Skip the push step (stage + commit only).
    [switch]$NoPush,

    # Commit message; auto-generated when omitted.
    [string]$Message
)

$ErrorActionPreference = "Stop"

# --- resolve defaults -------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($RepoDir)) {
    $here = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($here)) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrWhiteSpace($here)) {
        throw "Cannot resolve script directory; pass -RepoDir explicitly."
    }
    # script lives in <repo>\claude-env-audit\  ->  repo is one level up
    $RepoDir = Split-Path -Parent $here
}
if ([string]::IsNullOrWhiteSpace($SkillSource)) {
    $SkillSource = Join-Path $env:USERPROFILE ".workbuddy\skills\claude-env-audit"
}

$TopicDir = Join-Path $RepoDir "claude-env-audit"

function Write-Step([string]$t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Write-Ok([string]$t)   { Write-Host "  [ok]   $t" -ForegroundColor Green }
function Write-Warn2([string]$t){ Write-Host "  [warn] $t" -ForegroundColor Yellow }

# ----------------------------------------------------------------------------
# Locate git
# ----------------------------------------------------------------------------
$git = "D:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) {
    $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($cmd) { $git = $cmd.Source } else { throw "git not found" }
}

Write-Host "git     : $git"
Write-Host "repo    : $RepoDir"
Write-Host "topic   : $TopicDir"
Write-Host "skill   : $SkillSource"

if (-not (Test-Path (Join-Path $RepoDir ".git"))) {
    throw "Not a git repository: $RepoDir"
}

# Run git with the working proxy forced on the command line.
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & $git `
        -c "http.proxy=$Proxy" `
        -c "http.version=HTTP/1.1" `
        -C $RepoDir @GitArgs
}

# ----------------------------------------------------------------------------
# 1. Mirror the skill
# ----------------------------------------------------------------------------
Write-Step "1. Mirror skill"

if (-not (Test-Path (Join-Path $SkillSource "SKILL.md"))) {
    throw "Skill source looks wrong (no SKILL.md): $SkillSource"
}

$skillDest = Join-Path $TopicDir "skill"
New-Item -ItemType Directory -Force -Path $skillDest | Out-Null
# /MIR makes the destination an exact mirror of the source.
robocopy $SkillSource $skillDest /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) { throw "robocopy failed with exit code $rc" }
Write-Ok "mirrored to claude-env-audit\skill (robocopy rc=$rc)"

# ----------------------------------------------------------------------------
# 2. Redaction gate
# ----------------------------------------------------------------------------
Write-Step "2. Redaction gate"

# The public edition must contain no machine-identifying IP literal. Only these
# documented examples are legitimate: the loopback address and the unspecified
# address, plus any 0.x.y.z sentinel or bare /24 prefix.
$allowed = @("127.0.0.1", "0.0.0.0", "255.255.255.255")
$ipRe = [regex]"\b(?:\d{1,3}\.){3}\d{1,3}\b"

$hits = @()
foreach ($f in @("claude-env-audit.md", "claude-env-audit.html")) {
    $p = Join-Path $TopicDir $f
    if (-not (Test-Path $p)) { Write-Warn2 "missing: $f"; continue }
    $raw = Get-Content $p -Raw -Encoding UTF8
    foreach ($m in $ipRe.Matches($raw)) {
        $v = $m.Value
        if ($allowed -contains $v) { continue }
        if ($v -match "^0\.") { continue }
        if ($v -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.0$") { continue }
        $hits += "$f : $v"
    }
}

if ($hits.Count -gt 0) {
    Write-Host "  leaked literals:" -ForegroundColor Red
    $hits | Sort-Object -Unique | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    throw "redaction gate failed - refusing to publish"
}
Write-Ok "no unexpected IP literal in the public edition"

# ----------------------------------------------------------------------------
# 3. Commit and push
# ----------------------------------------------------------------------------
Write-Step "3. Commit and push"

Invoke-Git add -A -- claude-env-audit README.md | Out-Null
$status = (Invoke-Git status --porcelain) -join "`n"

if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Ok "nothing to commit; working tree already clean"
    return
}

Write-Host $status

if ([string]::IsNullOrWhiteSpace($Message)) {
    $parts = @()
    if ($status -match "claude-env-audit/skill/")            { $parts += "update skill" }
    if ($status -match "claude-env-audit\.(md|html)")        { $parts += "update manual" }
    if ($parts.Count -eq 0) { $parts += "sync" }
    $Message = "claude-env-audit: " + ($parts -join "; ")
}

Invoke-Git commit -m $Message | Out-Null
Write-Ok "committed: $Message"

if ($NoPush) {
    Write-Warn2 "-NoPush set; not pushing"
    return
}

$branch = (Invoke-Git rev-parse --abbrev-ref HEAD).Trim()
Invoke-Git push origin $branch
if ($LASTEXITCODE -ne 0) { throw "git push failed with exit code $LASTEXITCODE" }
Write-Ok "pushed to origin/$branch"
