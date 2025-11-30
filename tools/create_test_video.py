#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cria um video de teste simples para validar o VLC compilado.
Usa apenas ffmpeg (ja disponivel no MSYS2) para criar um video curto.
"""

import subprocess
import sys
from pathlib import Path

def create_test_video(output_path: Path) -> bool:
    """Cria um video de teste de 5 segundos com cor solida e texto."""
    
    try:
        # Comando ffmpeg para gerar video de teste
        # - 5 segundos de duracao
        # - 1280x720 resolucao
        # - Background gradiente
        # - Texto "VLC TEST VIDEO"
        cmd = [
            "ffmpeg",
            "-f", "lavfi",
            "-i", "color=c=blue:s=1280x720:d=5",
            "-f", "lavfi", 
            "-i", "color=c=red:s=1280x720:d=5",
            "-filter_complex",
            "[0:v][1:v]blend=all_mode=addition:all_opacity=0.5,drawtext=text='VLC TEST VIDEO':fontsize=72:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2",
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-pix_fmt", "yuv420p",
            "-y",
            str(output_path)
        ]
        
        print(f"Criando video de teste em: {output_path}")
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            print(f"Erro ao criar video: {result.stderr}")
            return False
        
        if output_path.exists():
            size_mb = output_path.stat().st_size / (1024 * 1024)
            print(f"✓ Video criado com sucesso! ({size_mb:.2f} MB)")
            return True
        
        return False
        
    except FileNotFoundError:
        print("Erro: ffmpeg nao encontrado no PATH")
        return False
    except Exception as e:
        print(f"Erro inesperado: {e}")
        return False


def main():
    # Diretorio do projeto
    project_root = Path(__file__).parent.parent
    test_videos_dir = project_root / "test-videos"
    test_videos_dir.mkdir(exist_ok=True)
    
    output_file = test_videos_dir / "vlc-test-video.mp4"
    
    # Remover video antigo se existir
    if output_file.exists():
        print(f"Removendo video antigo: {output_file}")
        output_file.unlink()
    
    # Criar novo video
    success = create_test_video(output_file)
    
    if success:
        print(f"\n✓ Video de teste pronto para uso!")
        print(f"  Local: {output_file}")
        return 0
    else:
        print(f"\n✗ Falha ao criar video de teste")
        return 1


if __name__ == "__main__":
    sys.exit(main())
