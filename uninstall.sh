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
    warning "\n--- Remoção Automática de Atalho de Teclado ---"
    read -p "Deseja que este script tente remover o atalho da tecla [INSERT] automaticamente? [s/N] " remove_shortcut
    if [[ "$remove_shortcut" =~ ^([sS])$ ]]; then
        DESKTOP_ENV=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
        info "Detectado ambiente: $DESKTOP_ENV. Tentando remover o atalho..."
        case "$DESKTOP_ENV" in
          *gnome*|*cinnamon*)
            KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding
            success "Atalho para GNOME/Cinnamon resetado."
            ;;
          *xfce*)
            xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Insert -r
            success "Atalho para XFCE removido."
            ;;
          *)
            warning "Não foi possível remover o atalho automaticamente. Por favor, remova-o manualmente."
            ;;
        esac
    fi

    # 2. Restaurar configuração do Flameshot
    CONFIG_DIR="$HOME/.config/flameshot"
    if [ -f "$CONFIG_DIR/flameshot.ini.bak" ]; then
        mv "$CONFIG_DIR/flameshot.ini.bak" "$CONFIG_DIR/flameshot.ini"
        success "Configuração antiga do Flameshot foi restaurada."
    else
        rm -f "$CONFIG_DIR/flameshot.ini"
    fi

    # 3. Remover ambiente virtual
    rm -rf .venv
    success "Ambiente virtual Python removido."
    
    # 4. Instruções Finais
    warning "\nLembrete: Os pacotes de sistema não são removidos automaticamente."
    info "Se desejar, remova-os com 'sudo pacman -Rsn ...' ou 'sudo apt remove ...'"
    
    echo ""
    read -p "Deseja apagar a pasta do projeto GrabText agora? [s/N] " del_response
    if [[ "$del_response" =~ ^([sS])$ ]]; then
        PROJECT_DIR_NAME=${PWD##*/} 
        info "Removendo a pasta '$PROJECT_DIR_NAME'..."
        cd .. && rm -rf "$PROJECT_DIR_NAME"
        success "Pasta do projeto removida."
    fi
    echo ""
    success "Desinstalação concluída."

else
    info "Desinstalação cancelada."
fi