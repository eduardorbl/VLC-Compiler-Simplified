#!/bin/bash
#
# VLC 4.x Build Script para Windows
# =================================
# 
# Script otimizado para compilação do VLC 4.x com interface Qt6 no Windows 10/11
# Aplica automaticamente todas as correções necessárias para compatibilidade.
#
# Autor: Sistema de Build VLC Automatizado
# Versão: 2.0
# Data: Novembro 2025

set -e

# === CONFIGURAÇÕES ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Determinar diretório do código-fonte do VLC com várias opções de fallback
BUILD_DIR="build-mingw"
if [ -d "$PROJECT_ROOT/vlc" ]; then
    VLC_SOURCE_DIR="$PROJECT_ROOT/vlc"
elif [ -d "$PROJECT_ROOT/vlc-source" ]; then
    VLC_SOURCE_DIR="$PROJECT_ROOT/vlc-source"
elif [ -n "$USERNAME" ] && [ -d "/c/Users/$USERNAME/vlc-source" ]; then
    VLC_SOURCE_DIR="/c/Users/$USERNAME/vlc-source"
else
    # Fallback: prefer cloning into the project root
    VLC_SOURCE_DIR="$PROJECT_ROOT/vlc"
fi

# Diretório de instalação (prefira pasta no perfil se existir username)
if [ -n "$USERNAME" ]; then
    INSTALL_PREFIX="/c/Users/$USERNAME/vlc-test"
else
    INSTALL_PREFIX="$PROJECT_ROOT/vlc-test"
fi

# === FUNÇÕES UTILITÁRIAS ===
print_header() {
    echo ""
    echo "=================================================================="
    echo "  $1"
    echo "=================================================================="
}

print_step() {
    echo ""
    echo "[$1/$2] $3..."
}

print_success() {
    echo ""
    echo "✅ $1"
}

print_warning() {
    echo ""
    echo "⚠️  $1"
}

print_error() {
    echo ""
    echo "❌ ERRO: $1"
}

# === APLICAR CORREÇÕES AUTOMÁTICAS ===
apply_patches() {
    echo "🔧 Aplicando correções automáticas..."
    
    # 1. D3D12MemAlloc.h header
    local d3d_target="/c/msys64/ucrt64/include/D3D12MemAlloc.h"
    local d3d_source="$PROJECT_ROOT/resources/third_party/D3D12MemAlloc.h"
    
    if [ -f "$d3d_source" ]; then
        if [ ! -f "$d3d_target" ] || grep -q "Stub header" "$d3d_target" 2>/dev/null; then
            echo "  📋 Instalando D3D12MemAlloc.h..."
            install -D "$d3d_source" "$d3d_target"
        else
            echo "  ✓ D3D12MemAlloc.h já atualizado"
        fi
    else
        print_warning "D3D12MemAlloc.h não encontrado, a compilação pode falhar"
    fi
    
    # 2. Correções Qt 6.10+
    if [ -f "$PROJECT_ROOT/scripts/fix_qt_compatibility.py" ]; then
        echo "  🛠️ Aplicando patches Qt 6.10+..."
        python3 "$PROJECT_ROOT/scripts/fix_qt_compatibility.py"
    fi
    
    # 3. Aplicar patch de compatibilidade Qt RHI
    local patch_file="$PROJECT_ROOT/patches/fix_qt_rhi_compatibility.patch"
    if [ -f "$patch_file" ]; then
        echo "  🔧 Aplicando patch fix_qt_rhi_compatibility.patch..."
        cd "$VLC_SOURCE" || exit 1
        if patch -p1 --dry-run -N -s < "$patch_file" > /dev/null 2>&1; then
            patch -p1 -N < "$patch_file"
            echo "  ✓ Patch aplicado com sucesso"
        else
            echo "  ℹ️ Patch já aplicado ou não necessário"
        fi
        cd "$PROJECT_ROOT" || exit 1
    fi
    
    # 4. Instalar perl se necessário
    if ! command -v perl &> /dev/null; then
        echo "  📦 Instalando Perl..."
        pacman -S --noconfirm --needed perl
    fi
    
    print_success "Todas as correções aplicadas"
}

# === FUNÇÃO PRINCIPAL ===
main() {
    print_header "VLC 4.x Build System - Versão Profissional"
    echo "Sistema de compilação automática para Windows 10/11"
    echo "Compatível com Qt 6.10+ e MSYS2 MinGW 64-bit"
    
    # Verificar ambiente
    if ! command -v meson &> /dev/null; then
        print_error "Meson não encontrado! Execute primeiro: pacman -S mingw-w64-x86_64-meson"
        exit 1
    fi
    
    # Aplicar patches
    apply_patches
    
    print_step "1" "5" "Verificando repositório VLC"
    if [ ! -d "$VLC_SOURCE_DIR" ] || [ -z "$(ls -A "$VLC_SOURCE_DIR" 2>/dev/null)" ]; then
        echo "  📦 Clonando VLC 4.x (~1GB, pode demorar)..."
        # Clonar preferencialmente dentro do repositório para layout consistente
        clone_dir="$PROJECT_ROOT"
        if [ -n "$USERNAME" ] && [ -d "/c/Users/$USERNAME" ]; then
            clone_dir="/c/Users/$USERNAME"
        fi
        cd "$clone_dir"
        git clone https://code.videolan.org/videolan/vlc.git "$(basename "$VLC_SOURCE_DIR")"
        cd "$(basename "$VLC_SOURCE_DIR")" || exit 1
        git switch master || true
        VLC_SOURCE_DIR=$(pwd)
    else
        echo "  ✓ Repositório encontrado em $VLC_SOURCE_DIR"
        cd "$VLC_SOURCE_DIR"
        echo "  🔄 Atualizando código..."
        git pull || print_warning "Não foi possível atualizar (pode já estar atualizado)"
    fi
    
    print_step "2" "5" "Preparando diretório de instalação"
    mkdir -p "$INSTALL_PREFIX"
    echo "  📁 Diretório: $INSTALL_PREFIX"
    
    print_step "3" "5" "Configurando build com Meson"
        # Garantir que estamos no diretório fonte do VLC antes de configurar o build
        cd "$VLC_SOURCE_DIR" || exit 1

        if [ -d "$BUILD_DIR" ]; then
                echo "  🗑️ Removendo build anterior..."
                rm -rf "$BUILD_DIR"
        fi

        echo "  ⚙️ Configuração otimizada para Windows..."
        # Chamar meson a partir do diretório fonte usando '.' como source dir
        meson setup "$BUILD_DIR" . \
            --prefix="$INSTALL_PREFIX" \
            --buildtype=release \
            -Dqt=enabled \
            -Dlibplacebo=disabled \
            -Dskins2=disabled \
            -Davcodec=disabled \
            -Ddbus=disabled \
            -Dncurses=disabled \
            --wrap-mode=nodownload
    
    print_success "Configuração concluída!"
    
    print_step "4" "5" "Compilando VLC (30-60 minutos)"
    echo "  🚀 Iniciando compilação..."
    echo "  ⏰ Início: $(date)"
    
    if meson compile -C "$BUILD_DIR"; then
        echo "  ⏰ Fim: $(date)"
        print_success "Compilação concluída!"
    else
        print_error "Falha na compilação! Verifique as mensagens acima."
        exit 1
    fi
    
    print_step "5" "5" "Instalando arquivos"
    if meson install -C "$BUILD_DIR"; then
        print_success "Instalação concluída!"
    else
        print_error "Falha na instalação!"
        exit 1
    fi
    
    # Resumo final
    print_header "COMPILAÇÃO CONCLUÍDA COM SUCESSO! 🎉"
    echo ""
    echo "📍 VLC instalado em:"
    echo "   $INSTALL_PREFIX/bin/vlc.exe"
    echo ""
    echo "🧪 Para testar a instalação:"
    echo "   scripts\\test_vlc_build.ps1"
    echo ""
    echo "🚀 Para executar o VLC:"
    echo "   & \"C:\\vlc-test\\bin\\vlc.exe\""
    echo ""
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi