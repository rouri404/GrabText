#!/bin/bash

# --- GrabText - Script de Instalação ---

# Cores e Funções de Log
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCESSO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[AVISO]${NC} $1"; }

info "Iniciando a instalação do GrabText..."

# 1. Instalar Dependências do Sistema
info "Verificando seu sistema e instalando pacotes necessários..."
if command -v pacman &> /dev/null; then
    sudo pacman -Syu --needed flameshot tesseract tesseract-data-por xclip python-pip --noconfirm || error "Falha ao instalar pacotes."
elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y flameshot tesseract-ocr tesseract-ocr-por xclip python3-pip || error "Falha ao instalar pacotes."
elif command -v dnf &> /dev/null; then
    sudo dnf install -y flameshot tesseract langpacks-por xclip python3-pip || error "Falha ao instalar pacotes."
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
if [ -f "$CONFIG_DIR/flameshot.ini" ]; then
    mv "$CONFIG_DIR/flameshot.ini" "$CONFIG_DIR/flameshot.ini.bak"
    info "Configuração antiga do Flameshot salva como flameshot.ini.bak"
fi
cp "./flameshot.ini" "$CONFIG_DIR/" || error "Falha ao copiar o arquivo de configuração."
success "Configuração do Flameshot aplicada."

# 4. Tornar o script principal executável
chmod +x grabtext.py
success "Permissões do script ajustadas."

# 5. Instruções Finais Interativas
success "INSTALAÇÃO CONCLUÍDA!"
echo ""
read -p "Deseja ver as instruções para configurar o atalho da tecla INSERT? [s/N] " response
if [[ "$response" =~ ^([sS])$ ]]; then
    info "--- Configuração do Atalho de Teclado ---"
    PROJECT_PATH="$PWD"
    PYTHON_EXEC="$PROJECT_PATH/.venv/bin/python"
    SCRIPT_PATH="$PROJECT_PATH/grabtext.py"
    
    # Este é o comando final "autossuficiente" que funciona de forma confiável
    EXEC_COMMAND="export PATH=/usr/bin:/bin:/usr/local/bin:\$HOME/.local/bin; flameshot gui --raw | \\\"$PYTHON_EXEC\\\" \\\"$SCRIPT_PATH\\\""

    warning "Para garantir que o atalho funcione corretamente, você deve configurá-lo manualmente."
    info "Vá para as configurações de atalho do seu sistema (instruções na nossa conversa anterior)."
    info "Crie um novo atalho para a tecla [INSERT] e use o seguinte comando COMPLETO:"
    echo -e "${YELLOW}bash -c \"$EXEC_COMMAND\"${NC}"
    echo ""
    info "Copie e cole o comando acima. Ele foi projetado para ser robusto e funcionar fora do terminal."

else
    info "Ok, você pode configurar o atalho manualmente mais tarde se desejar."
fi
echo ""