#!/usr/bin/env python3
# grabtext.py

import sys
import io
import subprocess
import pytesseract
from PIL import Image
import os
import logging

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
LOG_FILE = os.path.join(SCRIPT_DIR, 'grabtext.log')
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

current_lang_code = os.environ.get('GRABTEXT_LANG', 'pt').lower()
tesseract_lang_code = 'por'

MESSAGES = {
    'pt': {
        'error_notify_send_not_found': "Erro: 'notify-send' não encontrado. Não foi possível enviar notificação: {title} - {message}",
        'error_sending_notification': "Erro ao enviar notificação: {e}",
        'error_clipboard_install': "Falha ao copiar texto para a área de transferência. Por favor, instale 'xclip' ou 'wl-copy'.",
        'warning_clipboard_not_found': "Aviso: 'xclip' ou 'wl-copy' não encontrados.",
        'grabtext_error_title': "GrabText: Erro",
        'grabtext_session_started': "Sessão GrabText iniciada.",
        'no_image_data_received': "Nenhum dado de imagem recebido do stdin.",
        'text_extracted_title': "Texto extraído com sucesso!",
        'text_extracted_content': "Conteúdo:\n\"{preview}\"",
        'no_text_detected_title': "GrabText",
        'no_text_detected_content': "Nenhum texto detectado na área selecionada.",
        'unexpected_error_title': "GrabText: Erro Inesperado",
        'unexpected_error_content': "Ocorreu um problema: {preview}",
    },
    'en': {
        'error_notify_send_not_found': "Error: 'notify-send' not found. Could not send notification: {title} - {message}",
        'error_sending_notification': "Error sending notification: {e}",
        'error_clipboard_install': "Failed to copy text to clipboard. Please install 'xclip' or 'wl-copy'.",
        'warning_clipboard_not_found': "Warning: 'xclip' or 'wl-copy' not found.",
        'grabtext_error_title': "GrabText: Error",
        'grabtext_session_started': "GrabText session started.",
        'no_image_data_received': "No image data received from stdin.",
        'text_extracted_title': "Text successfully extracted!",
        'text_extracted_content': "Content:\n\"{preview}\"",
        'no_text_detected_title': "GrabText",
        'no_text_detected_content': "No text detected in the selected area.",
        'unexpected_error_title': "GrabText: Unexpected Error",
        'unexpected_error_content': "An issue occurred: {preview}",
    }
}

if current_lang_code == 'en':
    tesseract_lang_code = 'eng'

def get_message(key, **kwargs):
    return MESSAGES.get(current_lang_code, MESSAGES['pt']).get(key, MESSAGES['pt'][key]).format(**kwargs)

def send_notification(title, message, icon_name="", expire_timeout=5000):
    """
    Sends a customizable desktop notification.
    """
    cmd = ['notify-send', '-a', 'GrabText', title, message, '-t', str(expire_timeout)]
    if icon_name:
        cmd.extend(['-i', icon_name])
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        log_msg = get_message('error_notify_send_not_found', title=title, message=message)
        print(log_msg, file=sys.stderr)
        logging.error(log_msg)
    except subprocess.CalledProcessError as e:
        log_msg = get_message('error_sending_notification', e=e)
        print(log_msg, file=sys.stderr)
        logging.error(log_msg)

def copy_to_clipboard(text):
    """Copies text to the clipboard."""
    try:
        subprocess.run(['xclip', '-selection', 'clipboard'], input=text.encode('utf-8'), check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            subprocess.run(['wl-copy'], input=text.encode('utf-8'), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            error_msg = get_message('error_clipboard_install')
            send_notification(
                get_message('grabtext_error_title'),
                error_msg,
                icon_name="dialog-error",
                expire_timeout=7000
            )
            logging.error(error_msg)
            print(get_message('warning_clipboard_not_found'), file=sys.stderr)

def main():
    logging.info(get_message('grabtext_session_started'))
    try:
        image_data = sys.stdin.buffer.read()

        if not image_data:
            logging.warning(get_message('no_image_data_received'))
            return

        image_stream = io.BytesIO(image_data)
        img = Image.open(image_stream)
        
        extracted_text = pytesseract.image_to_string(img, lang=tesseract_lang_code)

        if extracted_text.strip():
            clean_text = extracted_text.strip()
            copy_to_clipboard(clean_text)
            
            preview = (clean_text[:100] + '...') if len(clean_text) > 100 else clean_text
            
            send_notification(
                get_message('text_extracted_title'),
                get_message('text_extracted_content', preview=preview),
                icon_name="edit-copy",
                expire_timeout=6000
            )
            logging.info(f"Successfully extracted and copied text: \"{preview}\" (Lang: {tesseract_lang_code})")
        else:
            send_notification(
                get_message('no_text_detected_title'),
                get_message('no_text_detected_content'),
                icon_name="dialog-information",
                expire_timeout=4000
            )
            logging.info(get_message('no_text_detected_content'))

    except Exception as e:
        error_message = str(e)
        preview = (error_message[:100] + '...') if len(error_message) > 100 else error_message
        
        send_notification(
            get_message('unexpected_error_title'),
            get_message('unexpected_error_content', preview=preview),
            icon_name="dialog-error",
            expire_timeout=8000
        )
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)
        print(f"An unexpected error occurred: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()