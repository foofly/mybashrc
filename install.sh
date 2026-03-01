#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WELCOME="$SCRIPT_DIR/welcome.sh"
SOURCE_LINE='[[ -f ~/git/mybashrc/welcome.sh ]] && source ~/git/mybashrc/welcome.sh'

# Ensure welcome.sh is present in the same directory
if [[ ! -f "$WELCOME" ]]; then
    echo "Error: welcome.sh not found in $SCRIPT_DIR" >&2
    echo "Run install.sh from inside the cloned mybashrc repo." >&2
    exit 1
fi

# Detect rc file
if [[ -f "$HOME/.bashrc" ]]; then
    RC_FILE="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    RC_FILE="$HOME/.zshrc"
else
    echo "Error: no ~/.bashrc or ~/.zshrc found." >&2
    exit 1
fi

# Idempotency check
if grep -qF 'mybashrc/welcome.sh' "$RC_FILE"; then
    echo "Already installed — source line found in $RC_FILE."
    exit 0
fi

# Back up rc file
BACKUP="${RC_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$RC_FILE" "$BACKUP"
echo "Backed up $RC_FILE → $BACKUP"

# Append source line
{
    echo ''
    echo '# mybashrc welcome'
    echo "$SOURCE_LINE"
} >> "$RC_FILE"

echo "Installed. Open a new terminal or run: source $RC_FILE"
