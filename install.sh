#!/bin/bash

# --- GrabText - Installation Script ---

DETECTED_LANG=$(echo $LANG | cut -d'.' -f1 | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
LANG_FILE=""

if [ -n "$GRABTEXT_LANG" ]; then
    if [ -f "./lang/${GRABTEXT_LANG}.sh" ]; then
        LANG_FILE="./lang/${GRABTEXT_LANG}.sh"
    fi
elif [ -f "./lang/${DETECTED_LANG}.sh" ]; then
    LANG_FILE="./lang/${DETECTED_LANG}.sh"
elif [ -f "./lang/pt.sh" ]; then
    LANG_FILE="./lang/pt.sh"
else
    echo "ERROR: Language files (e.g., lang/pt.sh or lang/en.sh) not found." >&2
    exit 1
fi

source "$LANG_FILE"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

info "$MSG_INSTALL_START"

info "$MSG_CHECK_PACKAGES"
if command -v pacman &> /dev/null; then
    sudo pacman -Syu --needed --noconfirm flameshot tesseract tesseract-data-por tesseract-data-eng xclip python-pip libnotify || error "$MSG_INSTALL_FAIL"
elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y flameshot tesseract-ocr tesseract-ocr-por tesseract-ocr-eng xclip python3-pip libnotify-bin || error "$MSG_INSTALL_FAIL"
elif command -v dnf &> /dev/null; then
    sudo dnf install -y flameshot tesseract langpacks-por langpacks-eng xclip python3-pip libnotify || error "$MSG_INSTALL_FAIL"
elif command -v zypper &> /dev/null; then
    sudo zypper install -y flameshot tesseract-ocr tesseract-ocr-por tesseract-ocr-eng xclip python3-pip libnotify-tools || error "$MSG_INSTALL_FAIL"
else
    error "$MSG_PKG_MGR_NOT_SUPPORTED"
fi
success "$MSG_DEPS_INSTALLED"

info "$MSG_SETUP_PYTHON_ENV"
python3 -m venv .venv || error "$MSG_VENV_FAIL"
./.venv/bin/pip install -r requirements.txt || error "$MSG_PIP_FAIL"
success "$MSG_PYTHON_DEPS_INSTALLED"

CONFIG_DIR="$HOME/.config/flameshot"
info "$MSG_CONFIG_FLAMESHOT"
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG_DIR/flameshot.ini" ]; then mv "$CONFIG_DIR/flameshot.ini" "$CONFIG_DIR/flameshot.ini.bak"; fi
cp "./flameshot.ini" "$CONFIG_DIR/" || error "$MSG_COPY_CONFIG_FAIL"
success "$MSG_FLAMESHOT_CONFIG_APPLIED"

info "$MSG_CREATE_LAUNCH_SCRIPT"
cat > launch.sh << EOL
#!/bin/bash
SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_EXEC="\$SCRIPT_DIR/.venv/bin/python"
GRABTEXT_SCRIPT="\$SCRIPT_DIR/grabtext.py"
export PATH=/usr/bin:/bin:/usr/local/bin:\$HOME/.local/bin
export GRABTEXT_LANG="${DETECTED_LANG:-pt}" # Pass detected or default language to Python script
if [ ! -f "\$PYTHON_EXEC" ] || [ ! -f "\$GRABTEXT_SCRIPT" ]; then
    notify-send "GrabText Error" "$MSG_LAUNCH_ERROR_FILES_NOT_FOUND"
    exit 1
fi
flameshot gui --raw | "\$PYTHON_EXEC" "\$GRABTEXT_SCRIPT"
EOL
success "$MSG_LAUNCH_SCRIPT_CREATED"

chmod +x grabtext.py
chmod +x launch.sh
success "$MSG_PERMISSIONS_ADJUSTED"

escape_path_with_single_quotes() {
  local IFS='/'
  read -ra parts <<< "$1"
  local escaped_path=""
  for part in "${parts[@]}"; do
    if [[ "$part" =~ [[:space:]] ]]; then
      escaped_path+="/'$part'"
    else
      escaped_path+="/$part"
    fi
  done
  echo "${escaped_path#/}"
}

echo ""
success "$MSG_INSTALL_COMPLETE"
info "$MSG_AUTO_SHORTCUT_SETUP"

EXEC_COMMAND_FOR_AUTOMATION="$PWD/launch.sh"
EXEC_COMMAND_FOR_AUTOMATION_ESCAPED=$(escape_path_with_single_quotes "$EXEC_COMMAND_FOR_AUTOMATION")
COMMAND_FOR_MANUAL_COPY="$EXEC_COMMAND_FOR_AUTOMATION_ESCAPED"

if [ -n "$XDG_CURRENT_DESKTOP" ]; then DESKTOP_ENV="$XDG_CURRENT_DESKTOP"; elif [ -n "$GDMSESSION" ]; then DESKTOP_ENV="$GDMSESSION"; else DESKTOP_ENV="$DESKTOP_SESSION"; fi
DESKTOP_ENV=$(echo "$DESKTOP_ENV" | tr '[:upper:]' '[:lower:]')
info "$MSG_DETECTED_DESKTOP ${DESKTOP_ENV:-$MSG_NOT_DETECTED}"

case "$DESKTOP_ENV" in
  *gnome*|*cinnamon*)
    info "$MSG_ATTEMPT_GNOME_SHORTCUT"
    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

    CURRENT_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null)
    if [[ "$CURRENT_KEYBINDINGS" == *"custom0"* ]]; then
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'GrabText' &>/dev/null
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command "$EXEC_COMMAND_FOR_AUTOMATION_ESCAPED" &>/dev/null
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding 'Insert' &>/dev/null
    else
        if [ -z "$CURRENT_KEYBINDINGS" ] || [ "$CURRENT_KEYBINDINGS" == "@as []" ]; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEY_PATH']" &>/dev/null
        else
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(echo "$CURRENT_KEYBINDINGS" | sed "s/\[/\['$KEY_PATH', /")" &>/dev/null
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'GrabText' &>/dev/null
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command "$EXEC_COMMAND_FOR_AUTOMATION_ESCAPED" &>/dev/null
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding 'Insert' &>/dev/null
    fi

    if gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command &> /dev/null | grep -q "$EXEC_COMMAND_FOR_AUTOMATION"; then
        success "$MSG_SHORTCUT_SUCCESS"
    else
        warning "$MSG_AUTO_SHORTCUT_FAIL_GENERIC"
        gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name # This will output the error if any
        info "\n$MSG_MANUAL_SHORTCUT_PROMPT"
        echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    fi
    ;;
  *xfce*)
    info "$MSG_ATTEMPT_XFCE_SHORTCUT"
    if xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Insert -n -t string -s "$EXEC_COMMAND_FOR_AUTOMATION" ; then
        success "$MSG_SHORTCUT_SUCCESS"
    else
        warning "$MSG_AUTO_SHORTCUT_FAIL_GENERIC"
        info "$MSG_MANUAL_SHORTCUT_PROMPT"
        echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    fi
    ;;
  *)
    warning "$MSG_AUTOMATION_NOT_SUPPORTED"
    info "$MSG_MANUAL_SHORTCUT_PROMPT"
    echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    ;;
esac
echo ""