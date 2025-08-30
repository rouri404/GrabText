#!/usr/bin/env python3
# grabtext.py

import sys
import io
import subprocess
import pytesseract
from PIL import Image

def copy_to_clipboard(text):
    """Copia o texto para a área de transferência."""
    try:
        subprocess.run(['wl-copy'], input=text.encode('utf-8'), check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            subprocess.run(['xclip', '-selection', 'clipboard'], input=text.encode('utf-8'), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            print("Aviso: 'xclip' ou 'wl-copy' não encontrado(s). O texto não foi copiado.")

def main():
    try:
        # stdin
        image_data = sys.stdin.buffer.read()

        if not image_data:
            return

        image_stream = io.BytesIO(image_data)
        img = Image.open(image_stream)
        
        extracted_text = pytesseract.image_to_string(img, lang='por')

        if extracted_text.strip():
            copy_to_clipboard(extracted_text)
            print("Texto extraído e copiado para a área de transferência!")
            print("---")
            print(extracted_text.strip())
            print("---")
        else:
            print("Nenhum texto detectado na imagem.")

    except Exception as e:
        print(f"Ocorreu um erro inesperado: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()