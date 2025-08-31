#!/usr/bin/env python3
# grabtext.py

import sys
import io
import subprocess
import pytesseract
from PIL import Image

def send_notification(title, message, icon_name="", expire_timeout=5000):
    """
    Envia uma notificação de desktop personalizável.
    icon_name: Nome de um ícone do tema de ícones do sistema (ex: 'edit-copy', 'dialog-information', 'dialog-error')
    expire_timeout: Tempo em milissegundos para a notificação desaparecer (0 para persistente)
    """

    cmd = ['notify-send', '-a', 'GrabText', title, message, '-t', str(expire_timeout)]
    if icon_name:
        cmd.extend(['-i', icon_name])
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print(f"Erro: 'notify-send' não encontrado. Não foi possível enviar a notificação: {title} - {message}", file=sys.stderr)
    except subprocess.CalledProcessError as e:
        print(f"Erro ao enviar notificação: {e}", file=sys.stderr)

def copy_to_clipboard(text):
    """Copia o texto para a área de transferência."""
    try:
        subprocess.run(['xclip', '-selection', 'clipboard'], input=text.encode('utf-8'), check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            subprocess.run(['wl-copy'], input=text.encode('utf-8'), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            send_notification(
                "GrabText: Erro",
                "Falha ao copiar texto para a área de transferência. Instale 'xclip' ou 'wl-copy'.",
                icon_name="dialog-error",
                expire_timeout=7000
            )
            print("Aviso: 'xclip' ou 'wl-copy' não encontrado(s).", file=sys.stderr)

def main():
    try:
        image_data = sys.stdin.buffer.read()

        if not image_data:
            return

        image_stream = io.BytesIO(image_data)
        img = Image.open(image_stream)
        
        extracted_text = pytesseract.image_to_string(img, lang='por')

        if extracted_text.strip():
            clean_text = extracted_text.strip()
            copy_to_clipboard(clean_text)
            
            preview = (clean_text[:100] + '...') if len(clean_text) > 100 else clean_text
            
            send_notification(
                "Texto exportado com sucesso!",
                f"Conteúdo:\n\"{preview}\"",
                icon_name="edit-copy",
                expire_timeout=6000
            )
        else:
            send_notification(
                "GrabText",
                "Nenhum texto detectado na imagem selecionada.",
                icon_name="dialog-information",
                expire_timeout=4000
            )

    except Exception as e:
        error_message = str(e)
        preview = (error_message[:100] + '...') if len(error_message) > 100 else error_message
        
        send_notification(
            "GrabText: Erro Inesperado",
            f"Ocorreu um problema: {preview}",
            icon_name="dialog-error",
            expire_timeout=8000
        )
        print(f"Ocorreu um erro inesperado: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()