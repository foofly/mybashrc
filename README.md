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

### Manual install

If you prefer to add the line yourself, append to `~/.bashrc`:

    [[ -f ~/git/mybashrc/welcome.sh ]] && source ~/git/mybashrc/welcome.sh

### Uninstall

Remove the source line from `~/.bashrc`, then open a new terminal.

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
  welcome.sh        — welcome/MOTD script
  install.sh        — idempotent installer
  README.md         — this file
  LICENSE           — MIT License

/usr/share/.name    — optional ASCII art logo (not in repo)
```

## License

MIT License — free to use, modify, and distribute with attribution.
See [LICENSE](LICENSE) for full terms. Copyright © 2026 Bill Kav.
