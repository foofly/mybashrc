# mybashrc — welcome.sh

A system welcome/MOTD script sourced from `~/.bashrc` on login. Displays
a greeting, date, uptime, IP, load, memory, disk usage, and last login.

## Install

```bash
git clone https://github.com/yourusername/mybashrc.git ~/git/mybashrc
```

Add to `~/.bashrc` (before the final line):

```bash
[[ -f ~/git/mybashrc/welcome.sh ]] && source ~/git/mybashrc/welcome.sh
```

## Configuration

Set any of these variables in `~/.bashrc` **before** the source line:

| Variable                | Default | Description                              |
|-------------------------|---------|------------------------------------------|
| `WELCOME_SHOW_DISK`     | `1`     | Show disk usage for `/` (and `/home`)    |
| `WELCOME_SHOW_LASTLOGIN`| `1`     | Show last login timestamp                |
| `WELCOME_SHOW_USERS`    | `1`     | Show number of logged-in users           |
| `WELCOME_SHOW_UPDATES`  | `0`     | Show pending package updates (slow)      |
| `WELCOME_COMPACT`       | `0`     | Single-line output for frequent SSH      |
| `WELCOME_FORTUNE`       | `0`     | Print a fortune after the output         |
| `WELCOME_COLOR`         | `1`     | Enable color output via tput             |

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
```

## Files

```
mybashrc/
  welcome.sh   — welcome/MOTD script
  README.md    — this file
  LICENSE      — license
```
