#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_EXEC="$SCRIPT_DIR/.venv/bin/python"
GRABTEXT_SCRIPT="$SCRIPT_DIR/grabtext.py"
export PATH=/usr/bin:/bin:/usr/local/bin:$HOME/.local/bin
if [ ! -f "$PYTHON_EXEC" ] || [ ! -f "$GRABTEXT_SCRIPT" ]; then
    notify-send "GrabText Erro" "Arquivos não encontrados. Execute o install.sh novamente."
    exit 1
fi
flameshot gui --raw | "$PYTHON_EXEC" "$GRABTEXT_SCRIPT"
