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
        # Tenta usar xclip primeiro (mais comum em X11)
        subprocess.run(['xclip', '-selection', 'clipboard'], input=text.encode('utf-8'), check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        try:
            # Fallback para wl-copy (padrão em Wayland)
            subprocess.run(['wl-copy'], input=text.encode('utf-8'), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            # Se ambos falharem, o erro será capturado no final e notificado.
            # Apenas imprime um aviso no terminal para fins de depuração.
            print("Aviso: 'xclip' ou 'wl-copy' não encontrado(s).", file=sys.stderr)

def main():
    try:
        # 1. Lê os dados da imagem da entrada padrão (stdin)
        image_data = sys.stdin.buffer.read()

        # Se o flameshot for cancelado, não faz nada.
        if not image_data:
            return

        # 2. Abre a imagem em memória
        image_stream = io.BytesIO(image_data)
        img = Image.open(image_stream)
        
        # 3. Extrai o texto da imagem
        extracted_text = pytesseract.image_to_string(img, lang='por')

        if extracted_text.strip():
            # SUCESSO: Texto foi encontrado
            clean_text = extracted_text.strip()
            copy_to_clipboard(clean_text)
            
            # Notificação de Sucesso
            # Limita a pré-visualização para não criar uma notificação gigante
            preview = (clean_text[:75] + '...') if len(clean_text) > 75 else clean_text
            subprocess.run(['notify-send', 'GrabText: Texto Copiado!', preview])
        else:
            # FALHA: Nenhum texto foi detectado
            subprocess.run(['notify-send', 'GrabText', 'Nenhum texto foi detectado na imagem.'])

    except Exception as e:
        # ERRO: Ocorreu um problema inesperado no script
        error_message = str(e)
        preview = (error_message[:75] + '...') if len(error_message) > 75 else error_message
        subprocess.run(['notify-send', 'GrabText: Erro Inesperado', preview])
        print(f"Ocorreu um erro inesperado: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()