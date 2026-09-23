#!/usr/bin/env bash
#
# check-claude-env.sh - Claude environment audit (macOS / Linux)
#
# Read-only. Changes nothing. Prints a report and writes it to a file.
#
# Usage:
#   chmod +x check-claude-env.sh
#   ./check-claude-env.sh
#   ./check-claude-env.sh /tmp/my-audit.txt
#
# Exit code: always 0 unless the script itself cannot run.

OUT="${1:-$HOME/claude-env-audit.txt}"
REPORT=""

add()      { REPORT+="$1"$'\n'; }
section()  { add ""; add "$(printf '=%.0s' {1..72})"; add "  $1"; add "$(printf '=%.0s' {1..72})"; }
result()   { # label, value, status
    local label="$1" value="$2" status="${3:-INFO}"
    [ -z "$value" ] && value="<empty>"
    printf -v line '%-6s %-42s %s' "[$status]" "$label" "$value"
    add "$line"
}
have()     { command -v "$1" >/dev/null 2>&1; }

add "Claude Environment Audit - macOS / Linux"
add "Generated : $(date '+%Y-%m-%d %H:%M:%S')"
add "Host      : $(uname -srm)"
add "User      : $(whoami)"
add "Shell     : ${SHELL:-unknown}"
add ""
add "This script is READ-ONLY. Nothing is modified."

# ------------------------------------------------------------------ 1 OS / timezone
section "1. OS, TIMEZONE AND LOCALE"

if [ -L /etc/localtime ]; then
    result "/etc/localtime ->" "$(readlink /etc/localtime)" "INFO"
fi
if [ -f /etc/timezone ]; then
    result "/etc/timezone" "$(cat /etc/timezone 2>/dev/null)" "INFO"
fi
result "TZ env var" "${TZ:-<unset>}" "INFO"
result "date offset" "$(date '+%Z %z')" "INFO"
result "locale" "${LANG:-<unset>}" "INFO"

if have node; then
    result "node Intl timeZone" "$(node -e 'console.log(Intl.DateTimeFormat().resolvedOptions().timeZone)' 2>/dev/null)" "INFO"
else
    result "node Intl timeZone" "node not found on PATH" "INFO"
fi

# macOS: system timezone + whether Location Services can override it
if [ "$(uname -s)" = "Darwin" ]; then
    result "systemsetup tz" "$(sudo -n systemsetup -gettimezone 2>/dev/null || echo 'needs sudo: systemsetup -gettimezone')" "INFO"
    if have defaults; then
        ls_tz=$(defaults read /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd 2>/dev/null | grep -i timezone || true)
        [ -n "$ls_tz" ] && result "locationd timezone override" "PRESENT - check 'Set time zone' in Location Services" "WARN"
    fi
fi

# ------------------------------------------------------------------ 2 system proxy
section "2. SYSTEM PROXY"

if [ "$(uname -s)" = "Darwin" ]; then
    if have scutil; then
        px=$(scutil --proxy 2>/dev/null)
        for k in HTTPEnable HTTPSEnable SOCKSEnable; do
            v=$(echo "$px" | awk -v key="$k" '$1==key {gsub(/[^0-9]/,"",$3); print $3}')
            if [ "$v" = "0" ] || [ -z "$v" ]; then
                result "scutil $k" "${v:-0}" "OK"
            else
                result "scutil $k" "$v  <-- PROXY IS ON" "HIT"
            fi
        done
    fi
elif [ "$(uname -s)" = "Linux" ]; then
    if have gsettings; then
        result "gsettings http proxy mode" "$(gsettings get org.gnome.system.proxy mode 2>/dev/null)" "INFO"
    fi
    for f in /etc/environment /etc/profile; do
        if [ -f "$f" ]; then
            h=$(grep -iE 'proxy' "$f" 2>/dev/null || true)
            if [ -n "$h" ]; then
                result "$f" "contains proxy lines" "HIT"
                echo "$h" | while read -r l; do add "       $l"; done
            fi
        fi
    done
fi

# ------------------------------------------------------------------ 3 env vars
section "3. ENVIRONMENT VARIABLES (current shell)"

found=0
for n in HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy; do
    v=$(printenv "$n" 2>/dev/null || true)
    if [ -n "$v" ]; then
        result "$n" "$v" "HIT"
        found=1
    fi
done
[ "$found" -eq 0 ] && add "[OK]   No proxy environment variables in the current shell."

# ------------------------------------------------------------------ 4 anthropic vars
section "4. ANTHROPIC / CLAUDE ENVIRONMENT VARIABLES  (HIGH PRIORITY)"

found=0
while IFS='=' read -r k v; do
    case "$k" in
        *[Aa]nthropic*|*[Cc]laude*)
            result "$k" "$v" "HIT"
            found=1
            ;;
    esac
done < <(env)

[ "$found" -eq 0 ] && add "[OK]   No ANTHROPIC_* / CLAUDE_* environment variables."

add ""
if [ -z "${ANTHROPIC_BASE_URL:-}" ]; then
    add "[OK]   ANTHROPIC_BASE_URL is not set. This is the desired state."
else
    add "[HIT]  ANTHROPIC_BASE_URL = $ANTHROPIC_BASE_URL"
    add "       Any non-official endpoint is a strong correlation signal. Clear it."
fi

# ------------------------------------------------------------------ 5 shell startup files
section "5. SHELL STARTUP FILES"

for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.zprofile"; do
    if [ -f "$f" ]; then
        h=$(grep -inE 'proxy' "$f" 2>/dev/null || true)
        if [ -n "$h" ]; then
            result "$(basename "$f")" "contains proxy lines" "HIT"
            echo "$h" | while read -r l; do add "       $l"; done
        else
            result "$(basename "$f")" "present, clean" "OK"
        fi
    fi
done

# ------------------------------------------------------------------ 6 npm / git / brew
section "6. PACKAGE MANAGERS AND GIT"

if have npm; then
    np=$(npm config get proxy 2>/dev/null || echo null)
    nh=$(npm config get https-proxy 2>/dev/null || echo null)
    [ "$np" = "null" ] && result "npm proxy" "none" "OK" || result "npm proxy" "$np" "HIT"
    [ "$nh" = "null" ] && result "npm https-proxy" "none" "OK" || result "npm https-proxy" "$nh" "HIT"
else
    result "npm" "not installed" "INFO"
fi

for f in "$HOME/.npmrc" "$HOME/.yarnrc" "$HOME/.pnpmrc"; do
    if [ -f "$f" ]; then
        h=$(grep -inE 'proxy' "$f" 2>/dev/null || true)
        if [ -n "$h" ]; then
            result "$(basename "$f")" "contains proxy lines" "HIT"
            echo "$h" | while read -r l; do add "       $l"; done
        else
            result "$(basename "$f")" "present, clean" "OK"
        fi
    fi
done

if have git; then
    gp=$(git config --global --get http.proxy 2>/dev/null || true)
    gs=$(git config --global --get https.proxy 2>/dev/null || true)
    [ -n "$gp" ] && result "git http.proxy"  "$gp" "HIT" || result "git http.proxy"  "none" "OK"
    [ -n "$gs" ] && result "git https.proxy" "$gs" "HIT" || result "git https.proxy" "none" "OK"
    add ""
    add "NOTE: a git proxy entry may be INTENTIONAL (needed for GitHub access)."
    add "      Decide, then document the decision. Do not delete blindly."
else
    result "git" "not installed" "INFO"
fi

if have brew; then
    bh=$(brew config 2>/dev/null | grep -i proxy || true)
    [ -n "$bh" ] && result "brew config" "proxy entries present" "HIT" || result "brew config" "no proxy entries" "OK"
fi

# ------------------------------------------------------------------ 7 claude local state
section "7. CLAUDE LOCAL STATE"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"

if [ -d "$CLAUDE_DIR" ]; then
    sz=$(du -sh "$CLAUDE_DIR" 2>/dev/null | cut -f1)
    result "~/.claude" "exists, size = $sz" "INFO"

    for t in telemetry statsig paste-cache shell-snapshots session-env debug; do
        [ -e "$CLAUDE_DIR/$t" ] && result "  subdir $t" "PRESENT - cleanup candidate" "HIT"
    done
    for t in stats-cache.json history.jsonl credentials.json; do
        [ -e "$CLAUDE_DIR/$t" ] && result "  file $t" "PRESENT" "HIT"
    done
else
    result "~/.claude" "not present" "OK"
fi

if [ -f "$CLAUDE_JSON" ]; then
    result "~/.claude.json" "present" "INFO"
    add ""
    add "  Tracking fields (each one present links you to past sessions):"
    for f in userID anonymousId firstStartTime claudeCodeFirstTokenDate \
             oauthAccount s1mAccessCache groveConfigCache passesEligibilityCache clientData; do
        if grep -q "\"$f\"" "$CLAUDE_JSON" 2>/dev/null; then
            result "  field $f" "PRESENT" "HIT"
        else
            result "  field $f" "absent" "OK"
        fi
    done
else
    result "~/.claude.json" "not present" "OK"
fi

SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
    h=$(grep -inE 'proxy|base_url|anthropic_' "$SETTINGS" 2>/dev/null || true)
    if [ -n "$h" ]; then
        result "settings.json" "matches found" "HIT"
        echo "$h" | while read -r l; do add "       $l"; done
    else
        result "settings.json" "clean" "OK"
    fi
else
    result "settings.json" "not present" "INFO"
fi

# macOS Keychain
if [ "$(uname -s)" = "Darwin" ] && have security; then
    add ""
    add "  Keychain entries:"
    for svc in claude-code claude-code-credentials claude-desktop; do
        if security find-generic-password -s "$svc" >/dev/null 2>&1; then
            result "  keychain $svc" "PRESENT" "HIT"
        else
            result "  keychain $svc" "absent" "OK"
        fi
    done
fi

# Desktop app data
if [ "$(uname -s)" = "Darwin" ]; then
    for p in "$HOME/Library/Application Support/Claude" "$HOME/Library/Logs/Claude" "$HOME/Library/Caches/com.anthropic.claudefordesktop"; do
        [ -e "$p" ] && result "desktop data" "$p" "HIT"
    done
else
    for p in "$HOME/.config/Claude" "$HOME/.cache/Claude"; do
        [ -e "$p" ] && result "desktop data" "$p" "HIT"
    done
fi

# ------------------------------------------------------------------ 8 egress
section "8. TERMINAL-SIDE EGRESS CHECK"

add "Browser IP is NOT terminal IP. Verify both separately."
add ""

if have curl; then
    body=$(curl -s --max-time 12 https://ipinfo.io 2>/dev/null || true)
    if [ -n "$body" ]; then
        add "$body"
    else
        add "curl returned nothing (proxy down / blocked / no network?)"
    fi
else
    add "curl not found. Install it or check manually."
fi

add ""
add "Cross-check the resulting IP on at least TWO of these:"
add "  https://scamalytics.com/          fraud score: want < 30"
add "  https://ipdata.co/                Threats: no Tor/Proxy/Abuser flags"
add "  https://www.abuseipdb.com/        abuse confidence: want 0%"
add "  https://ping0.cc/                 residential vs IDC"
add "  https://www.dnsleaktest.com/      click 'Extended test'"

# ------------------------------------------------------------------ 9 manual
section "9. MANUAL ITEMS THIS SCRIPT CANNOT CHECK"

add "  - fail-closed behaviour : unplug the node, confirm new requests are BLOCKED (not routed direct)"
add "  - client exit test      : quit the proxy app entirely, re-test. Most setups fail this one."
add "  - split-routing rules   : claude.ai / api.anthropic.com must not fall through to DIRECT"
add "  - sniff / domain restore: confirm the client resolves the domain, not just the IP"
add "  - VPS relay (if any)    : both ends must block fallback to the server's own egress"
add "  - web + desktop + CLI   : test all three surfaces separately"
add "  - browser storage       : clear claude.ai / anthropic.com cookies and site data"
add "  - browser isolation     : separate browser profile per account"
add "  - phone number          : supported location, NOT VoIP, max 3 accounts per number"
add "  - payment method        : stable, renewable, own name; no resold gift cards"
add "  - account behaviour     : no credential sharing, no automation on consumer tokens"
add "  - usage pacing          : do not run the weekly quota to the limit every week"

add ""
add "$(printf '=%.0s' {1..72})"
add "END OF REPORT"
add "$(printf '=%.0s' {1..72})"

printf '%s' "$REPORT"
printf '%s' "$REPORT" > "$OUT"
echo ""
echo "Report written to: $OUT"
