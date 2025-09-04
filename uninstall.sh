#!/bin/bash

# --- GrabText - Script de Desinstalação ---

# Cores e Funções de Log
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCESSO]${NC} $1"; }
warning() { echo -e "${YELLOW}[AVISO]${NC} $1"; }

info "Iniciando a desinstalação do GrabText."
read -p "Você tem certeza que deseja continuar? [s/N] " response
if [[ "$response" =~ ^([sS])$ ]]; then
    
    # 1. Remover Atalho de Teclado
    info "\n--- Tentando remover atalho de teclado automaticamente ---"
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then DESKTOP_ENV="$XDG_CURRENT_DESKTOP"; elif [ -n "$GDMSESSION" ]; then DESKTOP_ENV="$GDMSESSION"; else DESKTOP_ENV="$DESKTOP_SESSION"; fi
    DESKTOP_ENV=$(echo "$DESKTOP_ENV" | tr '[:upper:]' '[:lower:]')

    case "$DESKTOP_ENV" in
      *gnome*|*cinnamon*)
        KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        if gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name &> /dev/null | grep -q "GrabText"; then
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name &> /dev/null
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command &> /dev/null
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding &> /dev/null
            success "Atalho para GNOME/Cinnamon resetado."
        else
            warning "Nenhum atalho do GrabText encontrado para remover automaticamente."
        fi
        ;;
      *xfce*)
        if xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Insert &> /dev/null; then
            xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Insert -r
            success "Atalho para XFCE removido."
        else
             warning "Nenhum atalho do GrabText encontrado para remover automaticamente."
        fi
        ;;
      *)
        warning "Não foi possível remover o atalho automaticamente. Por favor, remova-o manualmente."
        ;;
    esac

    # 2. Restaurar configuração do Flameshot, remover venv, etc.
    CONFIG_DIR="$HOME/.config/flameshot"
    if [ -f "$CONFIG_DIR/flameshot.ini.bak" ]; then mv "$CONFIG_DIR/flameshot.ini.bak" "$CONFIG_DIR/flameshot.ini"; success "Configuração antiga do Flameshot restaurada."; else rm -f "$CONFIG_DIR/flameshot.ini"; fi
    rm -rf .venv
    rm -f launch.sh
    success "Ambiente virtual e script de lançamento removidos."
    
    # 3. Instruções para remoção de pacotes
    warning "\nLembrete: Os pacotes de sistema não são removidos automaticamente."
    info "Se desejar, remova os pacotes que foram instalados com um dos comandos abaixo:"
    
    # Detecta o gerenciador de pacotes e mostra o comando de remoção apropriado
    if command -v pacman &> /dev/null; then
        echo -e "${YELLOW}   sudo pacman -Rsn flameshot tesseract tesseract-data-por xclip python-pip libnotify${NC}"
    elif command -v apt &> /dev/null; then
        echo -e "${YELLOW}   sudo apt remove --purge flameshot tesseract-ocr tesseract-ocr-por xclip python3-pip libnotify-bin${NC}"
    elif command -v dnf &> /dev/null; then
        echo -e "${YELLOW}   sudo dnf remove flameshot tesseract tesseract-langpack-por xclip python3-pip libnotify${NC}"
    elif command -v zypper &> /dev/null; then
        echo -e "${YELLOW}   sudo zypper remove flameshot tesseract-ocr tesseract-ocr-por xclip python3-pip libnotify-tools${NC}"
    fi
    
    echo ""
    read -p "Deseja apagar a pasta do projeto GrabText agora? [s/N] " del_response
    if [[ "$del_response" =~ ^([sS])$ ]]; then
        PROJECT_DIR_NAME=${PWD##*/} 
        info "Removendo a pasta '$PROJECT_DIR_NAME'..."
        cd .. && rm -rf "$PROJECT_DIR_NAME"
        success "Pasta do projeto removida."
    fi
    success "\nDesinstalação concluída."

else
    info "Desinstalação cancelada."
fi