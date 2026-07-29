#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WELCOME="$SCRIPT_DIR/welcome-server.sh"
SOURCE_LINE='[[ -f ~/git/mybashrc/welcome-server.sh ]] && source ~/git/mybashrc/welcome-server.sh'

# Ensure welcome-server.sh is present in the same directory
if [[ ! -f "$WELCOME" ]]; then
    echo "Error: welcome-server.sh not found in $SCRIPT_DIR" >&2
    echo "Run install-server.sh from inside the cloned mybashrc repo." >&2
    exit 1
fi

# Detect rc file (macOS defaults to zsh; Linux defaults to bash)
_OS=$(uname -s)
if [[ "$_OS" == "Darwin" ]]; then
    if   [[ -f "$HOME/.zshrc"  ]]; then RC_FILE="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then RC_FILE="$HOME/.bashrc"
    else echo "Error: no ~/.zshrc or ~/.bashrc found." >&2; exit 1
    fi
else
    if   [[ -f "$HOME/.bashrc" ]]; then RC_FILE="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc"  ]]; then RC_FILE="$HOME/.zshrc"
    else echo "Error: no ~/.bashrc or ~/.zshrc found." >&2; exit 1
    fi
fi

# Idempotency check
if grep -qF 'mybashrc/welcome-server.sh' "$RC_FILE"; then
    echo "Already installed — server source line found in $RC_FILE."
    exit 0
fi

# Refuse to stack on top of the desktop install (would print the MOTD twice)
if grep -qF 'mybashrc/welcome.sh' "$RC_FILE"; then
    echo "Error: the desktop welcome (mybashrc/welcome.sh) is already installed in $RC_FILE." >&2
    echo "Installing both would print the welcome screen twice on login." >&2
    echo "Remove the desktop source line first, then re-run install-server.sh." >&2
    exit 1
fi

# Back up rc file
BACKUP="${RC_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$RC_FILE" "$BACKUP"
echo "Backed up $RC_FILE → $BACKUP"

# Append source line
{
    echo ''
    echo '# mybashrc welcome (server)'
    echo "$SOURCE_LINE"
} >> "$RC_FILE"

echo "Installed. Open a new terminal or run: source $RC_FILE"
