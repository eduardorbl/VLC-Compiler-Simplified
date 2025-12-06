#!/bin/bash
set -e

# === CONFIGURAÇÕES ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="build-mingw"
VLC_SOURCE_DIR="$PROJECT_ROOT/vlc"
INSTALL_PREFIX="$PROJECT_ROOT/vlc-test"

# === FUNÇÕES DE CORREÇÃO ===

clean_source_tree() {
    echo "🧹 Limpando código-fonte (Git Reset)..."
    cd "$VLC_SOURCE_DIR" || exit 1
    # Reseta o código para garantir pureza
    git reset --hard origin/master
    git clean -fdx --exclude="build-mingw"
}

apply_fixes() {
    echo "🔧 Aplicando correções (Qt 6.10 + Dependências)..."
    
    local dcomp_file="$VLC_SOURCE_DIR/modules/gui/qt/maininterface/compositor_dcomp.cpp"

    if [ -f "$dcomp_file" ]; then
        echo "  -> Patching compositor_dcomp.cpp (Qt Fix)..."
        
        # 1. Adiciona include qrhi.h
        if ! grep -q "#include <QtGui/qrhi.h>" "$dcomp_file"; then
            sed -i 's|#include <QQuickWindow>|#include <QQuickWindow>\n#include <QtGui/qrhi.h>|' "$dcomp_file"
        fi

        # 2. Substitui 'rhi->implementation()' por 'nullptr' (função removida no Qt 6.10)
        sed -i 's|rhi->implementation()|nullptr|g' "$dcomp_file"
    fi

    # Garante D3D12MemAlloc.h
    local d3d_target="/c/msys64/ucrt64/include/D3D12MemAlloc.h"
    local d3d_source="$PROJECT_ROOT/resources/third_party/D3D12MemAlloc.h"
    if [ ! -f "$d3d_target" ] && [ -f "$d3d_source" ]; then
        install -D "$d3d_source" "$d3d_target"
    fi
}

# === MAIN ===

echo -e "\n=== VLC BUILD SYSTEM (FINAL LINKER FIX) ==="

if ! command -v meson &> /dev/null; then
    echo "❌ Meson não encontrado!"
    exit 1
fi

# PASSO 1: Preparação
clean_source_tree
apply_fixes

# PASSO 2: Configuração
echo -e "\n⚙️  Configurando Meson..."
rm -rf "$BUILD_DIR"

cd "$VLC_SOURCE_DIR"

# MUDANÇA AQUI:
# Adicionado "-lwinmm" (Windows Multimedia) junto com "-lws2_32"
# Isso resolve o erro 'mciSendCommand'
meson setup "$BUILD_DIR" . \
    --prefix="$INSTALL_PREFIX" \
    --buildtype=release \
    -Dqt=enabled \
    -Dlibplacebo=disabled \
    -Dskins2=disabled \
    -Davcodec=disabled \
    -Ddbus=disabled \
    -Dncurses=disabled \
    -Dlua=disabled \
    --wrap-mode=nodownload \
    -Db_pch=false \
    -Dcpp_args="-D__USE_MINGW_ANSI_STDIO=1 -D_WIN32_WINNT=0x0A00 -Wno-error" \
    -Dc_args="-D__USE_MINGW_ANSI_STDIO=1 -Wno-error" \
    -Dc_link_args="-lws2_32 -lwinmm" \
    -Dcpp_link_args="-lws2_32 -lwinmm"

# PASSO 3: Compilação
echo -e "\n🔨 Compilando (Verbose)..."
meson compile -C "$BUILD_DIR" --verbose -j 1 || {
    echo -e "\n❌ FALHA NA COMPILAÇÃO"
    echo "Verifique o log acima."
    exit 1
}

# PASSO 4: Instalação
echo -e "\n📦 Instalando..."
meson install -C "$BUILD_DIR"

echo -e "\n✅ SUCESSO! VLC compilado em: $INSTALL_PREFIX"