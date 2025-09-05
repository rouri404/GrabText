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
    format='%(asctime)s - %(levelname)s - [%(funcName)s] - %(message)s'
)

LOG_MESSAGES = {
    'SESSION_START': "Session started.",
    'NO_IMAGE_DATA': "No image data received from stdin.",
    'OCR_SUCCESS': "OCR success: lang={lang}, chars={chars}, preview=\"{preview}\"",
    'OCR_NO_TEXT': "OCR complete: No text detected.",
    'CLIPBOARD_ERROR': "Clipboard tool not found (xclip/wl-copy).",
    'NOTIFY_SEND_MISSING': "notify-send command not found.",
    'NOTIFY_SEND_ERROR': "notify-send command failed: {e}",
    'UNEXPECTED_ERROR': "Unexpected error: {e}",
}

current_lang_code = os.environ.get('GRABTEXT_LANG', 'pt').lower()
tesseract_lang_code = 'por' if current_lang_code == 'pt' else 'eng'

MESSAGES = {
    'pt': {
        'error_clipboard_install': "Falha ao copiar texto. Instale 'xclip' ou 'wl-copy'.",
        'grabtext_error_title': "GrabText: Erro",
        'text_extracted_title': "Texto extraído com sucesso!",
        'text_extracted_content': "Conteúdo:\n\"{preview}\"",
        'no_text_detected_title': "GrabText",
        'no_text_detected_content': "Nenhum texto detectado na área selecionada.",
        'unexpected_error_title': "GrabText: Erro Inesperado",
        'unexpected_error_content': "Ocorreu um problema: {preview}",
    },
    'en': {
        'error_clipboard_install': "Failed to copy text. Please install 'xclip' or 'wl-copy'.",
        'grabtext_error_title': "GrabText: Error",
        'text_extracted_title': "Text successfully extracted!",
        'text_extracted_content': "Content:\n\"{preview}\"",
        'no_text_detected_title': "GrabText",
        'no_text_detected_content': "No text detected in the selected area.",
        'unexpected_error_title': "GrabText: Unexpected Error",
        'unexpected_error_content': "An issue occurred: {preview}",
    }
}

def get_message(key, **kwargs):
    return MESSAGES.get(current_lang_code, MESSAGES['pt']).get(key).format(**kwargs)

def send_notification(title, message, icon_name="", expire_timeout=5000):
    cmd = ['notify-send', '-a', 'GrabText', title, message, '-t', str(expire_timeout)]
    if icon_name:
        cmd.extend(['-i', icon_name])
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        logging.error(LOG_MESSAGES['NOTIFY_SEND_MISSING'])
    except subprocess.CalledProcessError as e:
        logging.error(LOG_MESSAGES['NOTIFY_SEND_ERROR'].format(e=e))

def copy_to_clipboard(text):
    try:
        subprocess.run(['xclip', '-selection', 'clipboard'], input=text.encode('utf-8'), check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            subprocess.run(['wl-copy'], input=text.encode('utf-8'), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            logging.error(LOG_MESSAGES['CLIPBOARD_ERROR'])
            send_notification(
                get_message('grabtext_error_title'),
                get_message('error_clipboard_install'),
                icon_name="dialog-error",
                expire_timeout=7000
            )

def main():
    logging.info(LOG_MESSAGES['SESSION_START'])
    try:
        image_data = sys.stdin.buffer.read()

        if not image_data:
            logging.warning(LOG_MESSAGES['NO_IMAGE_DATA'])
            return

        image_stream = io.BytesIO(image_data)
        img = Image.open(image_stream)
        
        extracted_text = pytesseract.image_to_string(img, lang=tesseract_lang_code)

        if extracted_text.strip():
            clean_text = extracted_text.strip()
            copy_to_clipboard(clean_text)
            
            preview = (clean_text[:70]).replace("\n", " ")

            logging.info(LOG_MESSAGES['OCR_SUCCESS'].format(
                lang=tesseract_lang_code,
                chars=len(clean_text),
                preview=preview
            ))
            
            send_notification(
                get_message('text_extracted_title'),
                get_message('text_extracted_content', preview=preview),
                icon_name="edit-copy",
                expire_timeout=6000
            )
        else:
            logging.info(LOG_MESSAGES['OCR_NO_TEXT'])
            send_notification(
                get_message('no_text_detected_title'),
                get_message('no_text_detected_content'),
                icon_name="dialog-information",
                expire_timeout=4000
            )

    except Exception as e:
        logging.error(LOG_MESSAGES['UNEXPECTED_ERROR'].format(e=e), exc_info=True)
        
        error_message = str(e)
        preview = (error_message[:100] + '...') if len(error_message) > 100 else error_message
        
        send_notification(
            get_message('unexpected_error_title'),
            get_message('unexpected_error_content', preview=preview),
            icon_name="dialog-error",
            expire_timeout=8000
        )

if __name__ == "__main__":
    main()