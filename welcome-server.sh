#!/usr/bin/env bash
# welcome-server.sh — server MOTD: standard welcome + recent-issue summary
# Source from ~/.bashrc:  source ~/git/mybashrc/welcome-server.sh

# Guard against double-sourcing
[[ -n "${_WELCOME_SERVER_LOADED}" ]] && return 0
_WELCOME_SERVER_LOADED=1

# ─── Print the standard welcome first ──────────────────────────────────────
# Resolve this script's directory and source the sibling welcome.sh so the
# normal greeting/rows render exactly as on a desktop, then we append below.
_WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${_WS_DIR}/welcome.sh" ]] && source "${_WS_DIR}/welcome.sh"
unset _WS_DIR

# User-configurable feature flags (set in .bashrc before sourcing to override)
: "${WELCOME_SHOW_ISSUES:=1}"        # the recent-issues section
: "${WELCOME_ISSUES_DISK_WARN:=90}"  # warn when / usage % >= this
: "${WELCOME_ISSUES_MEM_WARN:=90}"   # warn when memory % >= this

_welcome_server_show() {
    local RESET BOLD FG_BLUE FG_YELLOW FG_GREEN FG_RED TERM_WIDTH
    local FAILED FAILED_COLOR ERRORS ERRORS_COLOR
    local DISK_PCT DISK_COLOR MEM_TOTAL MEM_AVAIL MEM_PCT MEM_COLOR
    local NCPU LOAD1 LOAD_COLOR

    [[ "${WELCOME_SHOW_ISSUES}" != "1" ]] && return 0

    # This section is Linux/systemd only — skip cleanly on macOS et al.
    command -v systemctl &>/dev/null || return 0

    # ─── Colors (degrade gracefully) — welcome.sh's were local, so redefine ──
    if [[ "${WELCOME_COLOR:-1}" == "1" ]] && [[ -t 1 ]] \
        && command -v tput &>/dev/null \
        && (( $(tput colors 2>/dev/null || echo 0) >= 8 )); then
        RESET=$(tput sgr0)
        BOLD=$(tput bold)
        FG_BLUE=$(tput setaf 4)
        FG_YELLOW=$(tput setaf 3)
        FG_GREEN=$(tput setaf 2)
        FG_RED=$(tput setaf 1)
    else
        RESET="" BOLD="" FG_BLUE="" FG_YELLOW="" FG_GREEN="" FG_RED=""
    fi

    TERM_WIDTH=$(tput cols 2>/dev/null || echo 72)

    # ─── Aligned label/value helper (mirrors welcome.sh) ──────────────────────
    _row() {
        printf "  ${FG_BLUE}%-12s${RESET} %s%s%s\n" "${1}:" "${3:-}" "${2}" "${RESET}"
    }
    _sep() {
        printf "%s\n" "$(printf '%*s' "${TERM_WIDTH}" '' | tr ' ' '─')"
    }

    # ─── Failed systemd units (current boot) ──────────────────────────────────
    FAILED=$(systemctl --failed --no-legend 2>/dev/null | grep -c .)
    if (( FAILED > 0 )); then FAILED_COLOR="${FG_RED}"; else FAILED_COLOR="${FG_GREEN}"; fi

    # ─── Journal errors since boot (priority err and above) ───────────────────
    ERRORS=$(journalctl -p 3 -b --no-pager -q 2>/dev/null | grep -c .)
    if   (( ERRORS >= 10 )); then ERRORS_COLOR="${FG_RED}"
    elif (( ERRORS >  0 )); then ERRORS_COLOR="${FG_YELLOW}"
    else                          ERRORS_COLOR="${FG_GREEN}"
    fi

    # ─── Resource pressure: disk / memory / load ──────────────────────────────
    DISK_PCT=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    DISK_PCT=${DISK_PCT:-0}
    if (( DISK_PCT >= WELCOME_ISSUES_DISK_WARN )); then DISK_COLOR="${FG_RED}"
    else                                                DISK_COLOR="${FG_GREEN}"
    fi

    if [[ -r /proc/meminfo ]]; then
        MEM_TOTAL=$(awk '/^MemTotal:/     {print $2}' /proc/meminfo)
        MEM_AVAIL=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    fi
    if [[ -n "$MEM_TOTAL" && "$MEM_TOTAL" -gt 0 ]]; then
        MEM_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
    else
        MEM_PCT=0
    fi
    if (( MEM_PCT >= WELCOME_ISSUES_MEM_WARN )); then MEM_COLOR="${FG_RED}"
    else                                              MEM_COLOR="${FG_GREEN}"
    fi

    NCPU=$(nproc 2>/dev/null || echo 1)
    LOAD1=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)
    LOAD1=${LOAD1:-0}
    LOAD_COLOR=$(awk -v l="${LOAD1}" -v n="${NCPU}" \
        -v red="${FG_RED}" -v yel="${FG_YELLOW}" -v grn="${FG_GREEN}" \
        'BEGIN {
            ratio = l / n
            if      (ratio >= 1.0) print red
            else if (ratio >= 0.7) print yel
            else                   print grn
        }')

    # ─── Render ───────────────────────────────────────────────────────────────
    printf "  %s%sRecent Issues%s (since boot)\n" "${BOLD}" "${FG_BLUE}" "${RESET}"
    echo

    if (( FAILED > 0 )); then
        _row "Failed units" "${FAILED}" "${FAILED_COLOR}"
    else
        _row "Failed units" "none" "${FAILED_COLOR}"
    fi
    _row "Log errors" "${ERRORS}"      "${ERRORS_COLOR}"
    _row "Disk (/)"   "${DISK_PCT}%"   "${DISK_COLOR}"
    _row "Memory"     "${MEM_PCT}%"    "${MEM_COLOR}"
    _row "Load"       "${LOAD1}"       "${LOAD_COLOR}"

    echo
    _sep
    echo

    unset -f _row _sep
}

_welcome_server_show
unset -f _welcome_server_show
