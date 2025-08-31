#!/bin/bash

# --- GrabText - Script de Instalação ---

# Cores e Funções de Log
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCESSO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[AVISO]${NC} $1"; }

info "Iniciando a instalação do GrabText..."

# 1. Instalar Dependências do Sistema (com libnotify adicionado)
info "Verificando seu sistema e instalando pacotes necessários..."
if command -v pacman &> /dev/null; then
    sudo pacman -Syu --needed --noconfirm flameshot tesseract tesseract-data-por xclip python-pip libnotify || error "Falha ao instalar pacotes."
elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y flameshot tesseract-ocr tesseract-ocr-por xclip python3-pip libnotify-bin || error "Falha ao instalar pacotes."
elif command -v dnf &> /dev/null; then
    sudo dnf install -y flameshot tesseract langpacks-por xclip python3-pip libnotify || error "Falha ao instalar pacotes."
else
    error "Seu gerenciador de pacotes não é suportado."
fi
success "Dependências do sistema instaladas."

# 2. Configurar Ambiente Virtual Python
info "Configurando ambiente Python em ./.venv..."
python3 -m venv .venv || error "Falha ao criar o ambiente virtual."
./.venv/bin/pip install -r requirements.txt || error "Falha ao instalar pacotes Python."
success "Dependências Python instaladas."

# 3. Configurar o Flameshot
CONFIG_DIR="$HOME/.config/flameshot"
info "Aplicando configuração personalizada do Flameshot..."
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG_DIR/flameshot.ini" ]; then mv "$CONFIG_DIR/flameshot.ini" "$CONFIG_DIR/flameshot.ini.bak"; fi
cp "./flameshot.ini" "$CONFIG_DIR/" || error "Falha ao copiar o arquivo de configuração."
success "Configuração do Flameshot aplicada."

# 4. Criar o Script de Lançamento
info "Criando o script de lançamento 'launch.sh'..."
cat > launch.sh << EOL
#!/bin/bash
SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_EXEC="\$SCRIPT_DIR/.venv/bin/python"
GRABTEXT_SCRIPT="\$SCRIPT_DIR/grabtext.py"
export PATH=/usr/bin:/bin:/usr/local/bin:\$HOME/.local/bin
if [ ! -f "\$PYTHON_EXEC" ] || [ ! -f "\$GRABTEXT_SCRIPT" ]; then
    notify-send "GrabText Erro" "Arquivos não encontrados. Execute o install.sh novamente."
    exit 1
fi
flameshot gui --raw | "\$PYTHON_EXEC" "\$GRABTEXT_SCRIPT"
EOL
success "Script de lançamento criado."

# 5. Tornar scripts executáveis
chmod +x grabtext.py
chmod +x launch.sh
success "Permissões dos scripts ajustadas."

# Função para escapar partes do caminho com espaços usando aspas simples
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
  # Remove a primeira barra extra se o caminho não for absoluto
  echo "${escaped_path#/}"
}

# 6. Configuração de Atalho Híbrida
echo ""
success "INSTALAÇÃO CONCLUÍDA!"
info "--- Configuração Automática de Atalho de Teclado ---"

EXEC_COMMAND_FOR_AUTOMATION="$PWD/launch.sh"
EXEC_COMMAND_FOR_AUTOMATION_ESCAPED=$(escape_path_with_single_quotes "$EXEC_COMMAND_FOR_AUTOMATION")
COMMAND_FOR_MANUAL_COPY="$EXEC_COMMAND_FOR_AUTOMATION_ESCAPED"

# Detecta o ambiente
if [ -n "$XDG_CURRENT_DESKTOP" ]; then DESKTOP_ENV="$XDG_CURRENT_DESKTOP"; elif [ -n "$GDMSESSION" ]; then DESKTOP_ENV="$GDMSESSION"; else DESKTOP_ENV="$DESKTOP_SESSION"; fi
DESKTOP_ENV=$(echo "$DESKTOP_ENV" | tr '[:upper:]' '[:lower:]')
info "Seu ambiente de desktop detectado é: ${DESKTOP_ENV:-'não detectado'}"

case "$DESKTOP_ENV" in
  *gnome*|*cinnamon*)
    info "Tentando configurar atalho para GNOME/Cinnamon..."
    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    
    OUTPUT1=$(gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEY_PATH']" 2>&1)
    OUTPUT2=$(gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name 'GrabText' 2>&1)
    OUTPUT3=$(gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command "$EXEC_COMMAND_FOR_AUTOMATION_ESCAPED" 2>&1)
    OUTPUT4=$(gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding 'Insert' 2>&1)
    FULL_OUTPUT="$OUTPUT1$OUTPUT2$OUTPUT3$OUTPUT4"

    if [[ "$FULL_OUTPUT" == *"failed"* || "$FULL_OUTPUT" == *"WARNING"* || "$FULL_OUTPUT" == *"Erro"* ]]; then
        warning "A configuração automática do atalho falhou. O sistema reportou o seguinte erro:"
        echo -e "${RED}$FULL_OUTPUT${NC}"
        info "\nPor favor, configure manualmente o atalho para a tecla [INSERT] com o comando:"
        echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    else
        success "Atalho 'GrabText' para a tecla [INSERT] configurado com sucesso!"
    fi
    ;;
  *xfce*)
    info "Tentando configurar atalho para XFCE..."
    if xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Insert -n -t string -s "$EXEC_COMMAND_FOR_AUTOMATION" ; then
        success "Atalho 'GrabText' para a tecla [INSERT] configurado com sucesso!"
    else
        warning "A configuração automática do atalho falhou."
        info "Por favor, configure manualmente o atalho para a tecla [INSERT] com o comando:"
        echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    fi
    ;;
  *)
    warning "Automação para seu ambiente não é suportada ou é arriscada."
    info "Por favor, configure o atalho manualmente para a tecla [INSERT] com o comando:"
    echo -e "${YELLOW}${COMMAND_FOR_MANUAL_COPY}${NC}"
    ;;
esac
echo ""