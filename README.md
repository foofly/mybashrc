# mybashrc — welcome.sh

A system welcome/MOTD script sourced from `~/.bashrc` on login. Displays
a greeting, date, uptime, IP, load, memory, disk usage, and last login.
Supports Linux and macOS (bash or zsh).

## Install

Clone the repo, then run the installer:

    git clone https://github.com/foofly/mybashrc.git ~/git/mybashrc
    bash ~/git/mybashrc/install.sh

Open a new terminal — the welcome screen will appear automatically.
On macOS, `~/.zshrc` is preferred automatically.

### Headless / server install

On a headless server, use the server installer instead. It shows the normal
welcome plus a **Recent Issues (since boot)** health summary — failed systemd
units, journal errors, and disk / memory / load pressure:

    bash ~/git/mybashrc/install-server.sh

Use **either** `install.sh` **or** `install-server.sh`, not both — the server
installer refuses to run if the desktop source line is already present (two
installs would print the welcome screen twice). The issues section is Linux /
systemd only and is skipped cleanly elsewhere.

### Manual install

**Linux** — append to `~/.bashrc`:

    [[ -f ~/git/mybashrc/welcome.sh ]] && source ~/git/mybashrc/welcome.sh

**macOS** — append to `~/.zshrc`:

    [[ -f ~/git/mybashrc/welcome.sh ]] && source ~/git/mybashrc/welcome.sh

**Headless server** — source the server variant instead of `welcome.sh`:

    [[ -f ~/git/mybashrc/welcome-server.sh ]] && source ~/git/mybashrc/welcome-server.sh

Then reload your shell:

    source ~/.zshrc   # macOS
    source ~/.bashrc  # Linux

### Uninstall

Remove the source line from `~/.zshrc` (macOS) or `~/.bashrc` (Linux), then open a new terminal.

## ASCII Art / Custom Logo

Place your ASCII art in `/usr/share/.name` and it will be displayed above the
welcome output on every login:

    sudo nano /usr/share/.name

Example:

```
  __  __       _   _
 |  \/  |_   _| | | | ___  ___
 | |\/| | | | | |_| |/ _ \/ __|
 | |  | | |_| |  _  | (_) \__ \
 |_|  |_|\__, |_| |_|\___/|___/
          |___/
```

The file is optional — if it doesn't exist, the welcome screen appears as normal.

## Headless / Server Mode

On a headless server the useful thing to see on login isn't a greeting — it's
whether anything is broken. `welcome-server.sh` prints the normal welcome and
then appends a **Recent Issues (since boot)** health summary:

```
──────────────────────────────────────────────────────────────

  Recent Issues (since boot)

  Failed units: none
  Log errors:   18
  Disk (/):     17%
  Memory:       31%
  Load:         0.73

──────────────────────────────────────────────────────────────
```

Each row is color-coded green (OK) or red/yellow (needs attention):

| Row              | Source                                   | Turns red / yellow when                         |
|------------------|------------------------------------------|-------------------------------------------------|
| **Failed units** | `systemctl --failed`                     | red if any unit is in the failed state          |
| **Log errors**   | `journalctl -p 3 -b` (priority err+)     | yellow ≥ 1, red ≥ 10 errors this boot           |
| **Disk (/)**     | `df /`                                   | red at `WELCOME_ISSUES_DISK_WARN`% or above (default 90) |
| **Memory**       | `/proc/meminfo`                          | red at `WELCOME_ISSUES_MEM_WARN`% or above (default 90)  |
| **Load**         | `/proc/loadavg` vs. `nproc`              | yellow ≥ 70% of cores, red ≥ 100%               |

The window is the **current boot** — failed units and log errors reflect
everything since the machine last started. The section is Linux / systemd only;
on macOS or any host without `systemctl` it is skipped silently, so the same
script is safe to source anywhere.

Install it with the dedicated installer (use this **instead of** `install.sh`,
not alongside it):

    bash ~/git/mybashrc/install-server.sh

`install-server.sh` behaves exactly like `install.sh` — it detects your rc file,
backs it up, and is idempotent — but it refuses to run if the desktop welcome is
already installed, since sourcing both would print the login screen twice.

Set `WELCOME_SHOW_ISSUES=0` to source `welcome-server.sh` but suppress the issues
section (it then behaves like plain `welcome.sh`).

## Configuration

Set any of these variables in `~/.bashrc` **before** the source line:

| Variable                | Default | Description                              |
|-------------------------|---------|------------------------------------------|
| `WELCOME_SHOW_DISK`     | `1`     | Show disk usage for `/` (and `/home`)    |
| `WELCOME_SHOW_LASTLOGIN`| `1`     | Show last login timestamp                |
| `WELCOME_SHOW_USERS`    | `1`     | Show number of logged-in users           |
| `WELCOME_SHOW_UPDATES`  | `0`     | Show pending package updates — dnf, apt, or brew (slow) |
| `WELCOME_COMPACT`       | `0`     | Single-line output for frequent SSH      |
| `WELCOME_FORTUNE`       | `0`     | Print a fortune after the output         |
| `WELCOME_COLOR`         | `1`     | Enable color output via tput             |
| `WELCOME_SHOW_ISSUES`   | `1`     | Show the Recent Issues section (`welcome-server.sh` only) |
| `WELCOME_ISSUES_DISK_WARN` | `90` | Flag disk `/` usage red at this percent or above |
| `WELCOME_ISSUES_MEM_WARN`  | `90` | Flag memory red at this percent or above |

Example — disable disk info and enable compact mode for a jump host:

```bash
export WELCOME_SHOW_DISK=0
export WELCOME_COMPACT=1
source ~/git/mybashrc/welcome.sh
```

## Verification

```bash
# Basic run
bash --rcfile welcome.sh

# Check no variable leakage after sourcing
source welcome.sh
echo "${CURRENTDATE}"   # should be empty

# Degraded terminal (no color)
TERM=dumb bash --rcfile welcome.sh

# Compact mode
WELCOME_COMPACT=1 bash --rcfile welcome.sh

# No network (IP fallback)
# Disconnect or unplug, then open a new shell — should show "no IP"

# Double-source idempotency (output appears only once)
source welcome.sh; source welcome.sh

# macOS test (no install needed)
bash /path/to/mybashrc/welcome.sh
```

## Files

```
mybashrc/
  welcome.sh          — welcome/MOTD script
  welcome-server.sh   — server MOTD: welcome + recent-issues summary
  install.sh          — idempotent installer (desktop)
  install-server.sh   — idempotent installer (headless server)
  README.md           — this file
  LICENSE             — MIT License

/usr/share/.name    — optional ASCII art logo (not in repo)
```

## License

MIT License — free to use, modify, and distribute with attribution.
See [LICENSE](LICENSE) for full terms. Copyright © 2026 Bill Kav.
