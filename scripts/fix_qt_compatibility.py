#!/usr/bin/env python3
"""
VLC Qt 6.10+ Compatibility Patch
================================
Corrige problemas de compatibilidade com Qt 6.10+ no compositor DirectComposition.
Este script aplica patches automáticos necessários para compilar o VLC 4.x.
"""

import os
import sys
import re

def find_vlc_source():
    """Encontra o diretório do código fonte do VLC"""
    # Procura em vários locais: pasta `vlc` no repositório, antigo `vlc-source` no perfil
    # e caminhos WSL/Cygwin (/c/Users/...)
    username = os.environ.get('USERNAME', None)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, '..'))

    candidates = []
    # Prefer a pasta `vlc` junto ao repositório (atual layout deste projeto)
    candidates.append(os.path.join(repo_root, 'vlc'))
    # Legacy name used por alguns scripts/users
    candidates.append(os.path.join(repo_root, 'vlc-source'))

    # Home-user common locations
    if username:
        candidates.append(f"C:/Users/{username}/vlc-source")
        candidates.append(f"/c/Users/{username}/vlc-source")

    # Verificar candidates
    for path in candidates:
        if path and os.path.exists(path):
            return path

    print("❌ ERRO: Código fonte do VLC não encontrado!")
    print("   Coloque o fonte em 'vlc/' na raiz deste repositório ou execute: .\\Build-VLC.ps1")
    return None

def apply_compositor_patch():
    """Aplica patch de compatibilidade no compositor DirectComposition"""
    vlc_source = find_vlc_source()
    if not vlc_source:
        return False
    
    compositor_file = os.path.join(vlc_source, "modules/gui/qt/maininterface/compositor_dcomp.cpp")
    
    if not os.path.exists(compositor_file):
        print(f"❌ ERRO: Arquivo não encontrado: {compositor_file}")
        return False
    
    # Ler arquivo
    with open(compositor_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Verificar se patch já foi aplicado
    if 'QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)' in content:
        print("✅ Patch Qt 6.10+ já aplicado!")
        return True
    
    print("🔧 Aplicando patch de compatibilidade Qt 6.10+...")
    
    # Backup
    backup_file = compositor_file + ".backup"
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Aplicar patches nas linhas problemáticas
    fixes = [
        # Linha 108: Início da função init() - adicionar check de versão
        (
            r'(bool CompositorDirectComposition::init\(\)\s*\{)',
            r'\1\n#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)\n    // DirectComposition not supported with Qt 6.10+ due to QRhi API changes\n    msg_Warn(m_intf, "DirectComposition disabled for Qt 6.10+, using Win7 compositor fallback");\n    return false;\n#else'
        ),
        
        # Linha 177: Remover chamada para implementation()
        (
            r'QRhiImplementation\* const rhiImplementation = rhi->implementation\(\);',
            r'// Removed for Qt 6.10+ compatibility - see init() method'
        ),
        
        # Últimas linhas da função init - fechar #else
        (
            r'(m_videoVisual->SetOffsetY\(m_videoPosition\.y\(\)\);\s*return true;)',
            r'\1\n#endif'
        )
    ]
    
    # Aplicar todas as correções
    for pattern, replacement in fixes:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
    
    # Escrever arquivo corrigido
    with open(compositor_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Patch aplicado com sucesso!")
    print(f"📄 Backup salvo em: {backup_file}")
    return True

def main():
    print("=" * 60)
    print("🛠️  VLC Qt 6.10+ Compatibility Patcher")
    print("=" * 60)
    
    if apply_compositor_patch():
        print("\n✅ SUCESSO: Todos os patches aplicados!")
        print("   Agora você pode executar a compilação normalmente.")
        return 0
    else:
        print("\n❌ ERRO: Falha ao aplicar patches!")
        return 1

if __name__ == "__main__":
    sys.exit(main())