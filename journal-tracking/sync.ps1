#Requires -Version 5.1
<#
    sync.ps1 -- publish the journal-paper-tracking skill and weekly reports
                to https://github.com/ChazenLi/Transfer

    Usage:
        powershell -ExecutionPolicy Bypass -File .\sync.ps1 `
            -ReportSourceDir "D:\wbdata\2026-09-18-09-37-35"

        powershell -ExecutionPolicy Bypass -File .\sync.ps1 -NoPush

    What it does:
        1. Mirror  <skills>\journal-paper-tracking  ->  .\skill\
        2. Archive *-weekly-*.html from -ReportSourceDir -> .\reports\YYYY-MM\
        3. git add / commit / push

    Notes:
        - This file is intentionally ASCII-only. Windows PowerShell 5.1 reads
          .ps1 without a BOM using the legacy ANSI code page; non-ASCII
          characters in a script can be mangled. Keep it ASCII.
        - The env var HTTP(S)_PROXY on this machine points at 127.0.0.1:9767,
          which returns 502 for GitHub. Network ops therefore force
          -c http.proxy=<Proxy> which has the highest git precedence.
#>

[CmdletBinding()]
param(
    # Directory holding freshly generated *-weekly-*.html reports.
    [string]$ReportSourceDir,

    # Local clone of the Transfer repository (this directory's parent).
    # Resolved in the body when left empty ($PSCommandPath is not reliable
    # inside a param() default expression).
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
    # script lives in <repo>\journal-tracking\  ->  repo is one level up
    $RepoDir = Split-Path -Parent $here
}
if ([string]::IsNullOrWhiteSpace($SkillSource)) {
    $SkillSource = Join-Path $env:USERPROFILE ".workbuddy\skills\journal-paper-tracking"
}

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
Write-Host "git    : $git"
Write-Host "repo   : $RepoDir"
Write-Host "skill  : $SkillSource"

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

$skillDest = Join-Path $RepoDir "journal-tracking\skill"

if (-not (Test-Path (Join-Path $SkillSource "SKILL.md"))) {
    throw "Skill source looks wrong (no SKILL.md): $SkillSource"
}

New-Item -ItemType Directory -Force -Path $skillDest | Out-Null
# /MIR makes the destination an exact mirror of the source.
robocopy $SkillSource $skillDest /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) { throw "robocopy failed with exit code $rc" }
Write-Ok "mirrored to journal-tracking\skill (robocopy rc=$rc)"

# ----------------------------------------------------------------------------
# 2. Archive reports
# ----------------------------------------------------------------------------
Write-Step "2. Archive reports"

if ([string]::IsNullOrWhiteSpace($ReportSourceDir)) {
    Write-Warn2 "-ReportSourceDir not given; skipping report archiving"
} elseif (-not (Test-Path $ReportSourceDir)) {
    Write-Warn2 "Report source does not exist; skipping: $ReportSourceDir"
} else {
    $candidates = @()
    $candidates += Get-ChildItem -Path $ReportSourceDir -Filter "*-weekly-*.html" -File
    # Also sweep the archive sub-folder: it holds final deliverables for older
    # windows, AND superseded drafts of the current window.
    $arch = Join-Path $ReportSourceDir "archive"
    if (Test-Path $arch) {
        $candidates += Get-ChildItem -Path $arch -Filter "*-weekly-*.html" -File -ErrorAction SilentlyContinue
    }

    if (-not $candidates -or $candidates.Count -eq 0) {
        Write-Warn2 "no *-weekly-*.html found under $ReportSourceDir"
    }

    # One deliverable per (journal, window): group by the name with the
    # "-deep" marker stripped, and keep the deep version when both exist.
    $selected = @()
    foreach ($grp in ($candidates | Group-Object { $_.Name -replace "-deep", "" })) {
        $deep = @($grp.Group | Where-Object { $_.Name -like "*-deep.html" })
        if ($deep.Count -gt 0) {
            if ($deep.Count -gt 1) {
                Write-Warn2 "duplicate -deep for $($grp.Name); keeping the newest"
                $selected += ($deep | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
            } else {
                $selected += $deep[0]
            }
        } else {
            $selected += $grp.Group
        }
    }

    foreach ($f in $selected) {
        $m = [regex]::Match($f.Name, "(\d{4})-(\d{2})-\d{2}")
        if (-not $m.Success) {
            Write-Warn2 "cannot parse date from $($f.Name); skipped"
            continue
        }
        $ym = "$($m.Groups[1].Value)-$($m.Groups[2].Value)"
        $destDir = Join-Path $RepoDir "journal-tracking\reports\$ym"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Copy-Item $f.FullName (Join-Path $destDir $f.Name) -Force
        Write-Ok "$($f.Name)  ->  reports/$ym/"

        # Prune a superseded sibling for the SAME (journal, window) only.
        # Scoped deliberately: never touch other windows / workspaces.
        $key = $f.Name -replace "-deep", ""
        $sibs = Get-ChildItem -Path $destDir -Filter "*.html" -File -ErrorAction SilentlyContinue |
                Where-Object { (($_.Name -replace "-deep", "") -eq $key) -and ($_.Name -ne $f.Name) }
        foreach ($s in $sibs) {
            Remove-Item $s.FullName -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $s.FullName)) {
                Write-Warn2 "pruned superseded: reports/$ym/$($s.Name)"
            }
        }
    }
}

# ----------------------------------------------------------------------------
# 3. Commit and push
# ----------------------------------------------------------------------------
Write-Step "3. Commit and push"

Invoke-Git add -A | Out-Null
$status = (Invoke-Git status --porcelain) -join "`n"

if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Ok "nothing to commit; working tree already clean"
    return
}

Write-Host $status

if ([string]::IsNullOrWhiteSpace($Message)) {
    $skillChanged = $status -match "journal-tracking/skill/"
    $reportCount = ([regex]::Matches($status, "reports/.+\.html")).Count
    $parts = @()
    if ($skillChanged) { $parts += "update skill" }
    if ($reportCount -gt 0) { $parts += "archive $reportCount report(s)" }
    if ($parts.Count -eq 0) { $parts += "sync" }
    $Message = ($parts -join "; ").Substring(0, 1).ToUpper() + ($parts -join "; ").Substring(1)
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
