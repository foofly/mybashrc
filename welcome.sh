#!/usr/bin/env bash
# welcome.sh — System welcome/MOTD script
# Source from ~/.bashrc:  source ~/git/mybashrc/welcome.sh

# Guard against double-sourcing
[[ -n "${_WELCOME_LOADED}" ]] && return 0
_WELCOME_LOADED=1

# User-configurable feature flags (set in .bashrc before sourcing to override)
: "${WELCOME_SHOW_DISK:=1}"
: "${WELCOME_SHOW_LASTLOGIN:=1}"
: "${WELCOME_SHOW_USERS:=1}"
: "${WELCOME_SHOW_UPDATES:=0}"   # off by default — dnf is slow
: "${WELCOME_COMPACT:=0}"        # single-line mode for frequent SSH
: "${WELCOME_FORTUNE:=0}"        # fortune -s if installed
: "${WELCOME_COLOR:=1}"

_welcome_show() {
    local CURRENTDATE UPTIME IP LOAD LOAD1 LOAD_COLOR NCPU GREETING LAST_LOGIN
    local RESET BOLD FG_CYAN FG_BLUE FG_YELLOW FG_GREEN FG_RED
    local TERM_WIDTH hour ACTIVE_IFACE
    local MEM MEM_TOTAL MEM_AVAIL MEM_USED MEM_PCT BAR BAR_FILLED BAR_EMPTY i
    local DISK_ROOT DISK_HOME USERS_COUNT SSH_IP UPDATES

    # ─── Colors (degrade gracefully) ──────────────────────────────────────────
    if [[ "${WELCOME_COLOR}" == "1" ]] && [[ -t 1 ]] \
        && command -v tput &>/dev/null \
        && (( $(tput colors 2>/dev/null || echo 0) >= 8 )); then
        RESET=$(tput sgr0)
        BOLD=$(tput bold)
        FG_CYAN=$(tput setaf 6)
        FG_BLUE=$(tput setaf 4)
        FG_YELLOW=$(tput setaf 3)
        FG_GREEN=$(tput setaf 2)
        FG_RED=$(tput setaf 1)
    else
        RESET="" BOLD="" FG_CYAN="" FG_BLUE="" FG_YELLOW="" FG_GREEN="" FG_RED=""
    fi

    # ─── Terminal width ────────────────────────────────────────────────────────
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 72)

    # ─── Aligned label/value helper ───────────────────────────────────────────
    # Usage: _row "Label" "value" ["color_prefix"]
    _row() {
        printf "  ${FG_BLUE}%-12s${RESET} %s%s%s\n" "${1}:" "${3:-}" "${2}" "${RESET}"
    }

    # ─── Full-width separator ──────────────────────────────────────────────────
    _sep() {
        printf "%s\n" "$(printf '%*s' "${TERM_WIDTH}" '' | tr ' ' '─')"
    }

    # ─── Gather data ──────────────────────────────────────────────────────────
    CURRENTDATE=$(date +"%A, %d %b %Y")

    UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || echo "unknown")

    # Primary IP via ip route — deterministic on multi-homed/VPN machines
    ACTIVE_IFACE=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')
    IP=$(ip -4 addr show "${ACTIVE_IFACE}" 2>/dev/null \
        | awk '/inet / {print $2}' | cut -d/ -f1)
    IP=${IP:-"no IP"}

    # Load average with color coding (red ≥ 100% cores, yellow ≥ 70%, green otherwise)
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
    LOAD=$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' || echo "unknown")

    # Memory bar from /proc/meminfo (uses MemAvailable for accuracy)
    if [[ -r /proc/meminfo ]]; then
        MEM_TOTAL=$(awk '/^MemTotal:/     {print $2}' /proc/meminfo)
        MEM_AVAIL=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
        MEM_USED=$(( MEM_TOTAL - MEM_AVAIL ))
        MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))
        BAR_FILLED=$(( MEM_PCT / 10 ))
        BAR_EMPTY=$(( 10 - BAR_FILLED ))
        BAR=""
        for (( i=0; i<BAR_FILLED; i++ )); do BAR+="█"; done
        for (( i=0; i<BAR_EMPTY;  i++ )); do BAR+="░"; done
        MEM="${BAR} ${MEM_PCT}%"
    else
        MEM="unknown"
    fi

    # Time-of-day greeting
    hour=$(date +%H)
    if   (( hour < 12 )); then GREETING="Good morning"
    elif (( hour < 17 )); then GREETING="Good afternoon"
    elif (( hour < 21 )); then GREETING="Good evening"
    else                        GREETING="Good night"
    fi

    # ─── Optional header (ASCII name/logo) ────────────────────────────────────
    if [[ -f /usr/share/.name && -r /usr/share/.name ]]; then
        cat /usr/share/.name
        echo
    fi

    # ─── Compact mode (single line for frequent SSH logins) ───────────────────
    if [[ "${WELCOME_COMPACT}" == "1" ]]; then
        printf "%s%s%s, %s%s | %s | up %s | %s\n" \
            "${BOLD}" "${FG_CYAN}" "${GREETING}" "${USER}" "${RESET}" \
            "${CURRENTDATE}" "${UPTIME}" "${IP}"
        unset -f _row _sep
        return
    fi

    # ─── Full output ──────────────────────────────────────────────────────────
    _sep
    echo
    printf "  %s%s%s, %s!%s\n" "${BOLD}" "${FG_CYAN}" "${GREETING}" "${USER}" "${RESET}"
    printf "  %s\n" "${CURRENTDATE}"
    echo

    _row "Uptime"  "${UPTIME}"
    _row "IP"      "${IP}"
    _row "Load"    "${LOAD}"  "${LOAD_COLOR}"
    _row "Memory"  "${MEM}"

    if [[ "${WELCOME_SHOW_DISK}" == "1" ]]; then
        DISK_ROOT=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        [[ -n "${DISK_ROOT}" ]] && _row "Disk (/)" "${DISK_ROOT}"
        # Only show /home if it's a separate mountpoint
        if mountpoint -q /home 2>/dev/null; then
            DISK_HOME=$(df -h /home 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
            [[ -n "${DISK_HOME}" ]] && _row "Disk (/home)" "${DISK_HOME}"
        fi
    fi

    if [[ "${WELCOME_SHOW_LASTLOGIN}" == "1" ]]; then
        LAST_LOGIN=$(last -n 2 "${USER}" 2>/dev/null \
            | awk 'NR==2 && NF>0 {print $3,$4,$5,$6,$7}')
        _row "Last login" "${LAST_LOGIN:-first login}"
    fi

    if [[ "${WELCOME_SHOW_USERS}" == "1" ]]; then
        USERS_COUNT=$(who 2>/dev/null | wc -l)
        _row "Users" "${USERS_COUNT} logged in"
    fi

    # SSH session origin notice
    if [[ -n "${SSH_CLIENT}" ]]; then
        SSH_IP=$(awk '{print $1}' <<< "${SSH_CLIENT}")
        _row "SSH from" "${SSH_IP}" "${FG_YELLOW}"
    fi

    if [[ "${WELCOME_SHOW_UPDATES}" == "1" ]]; then
        if command -v dnf &>/dev/null; then
            UPDATES=$(dnf check-update -q 2>/dev/null | grep -c '^[a-zA-Z]' || echo 0)
            _row "Updates" "${UPDATES} available"
        elif command -v apt-get &>/dev/null; then
            UPDATES=$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst' || echo 0)
            _row "Updates" "${UPDATES} available"
        fi
    fi

    echo
    _sep
    echo

    if [[ "${WELCOME_FORTUNE}" == "1" ]] && command -v fortune &>/dev/null; then
        fortune -s
        echo
    fi

    unset -f _row _sep
}

_welcome_show
unset -f _welcome_show
