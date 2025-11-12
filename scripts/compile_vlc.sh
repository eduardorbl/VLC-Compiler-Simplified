#!/bin/bash
# Script automatizado de compilacao do VLC 4.x
# Execute este script dentro do MSYS2 MinGW 64-bit

set -e  # Para na primeira falha

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_d3d12_allocator() {
    local target="/c/msys64/mingw64/include/D3D12MemAlloc.h"
    local source="$SCRIPT_DIR/third_party/D3D12MemAlloc.h"

    if [ ! -f "$source" ]; then
        echo "  [AVISO] Arquivo de referencia não encontrado: $source"
        echo "          Prossiga, mas a compilação pode falhar em qrhid3d12."
        return
    fi

    if [ ! -f "$target" ] || grep -q "Stub header" "$target" 2>/dev/null; then
        echo "  Atualizando D3D12MemAlloc.h (necessário para o backend D3D12/Qt)..."
        install -D "$source" "$target"
    fi
}

echo "=================================================================="

apply_qt_rhi_patch() {
    local source_file="$VLC_SOURCE_DIR/modules/gui/qt/maininterface/compositor_dcomp.cpp"
    
    # Verifica se o patch já foi aplicado
    if grep -q "QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)" "$source_file" 2>/dev/null; then
        echo "  Patch Qt RHI já aplicado."
        return
    fi
    
    echo "  Aplicando patch de compatibilidade Qt 6.10+ RHI..."
    
    # Backup do arquivo original
    cp "$source_file" "$source_file.bak"
    
    # Aplica a correção diretamente
    sed -i '171s|.*|#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)\n    const QRhiNativeHandles *nativeHandles = rhi->nativeHandles();\n    const QRhiD3D11NativeHandles *d3d11Handles = static_cast<const QRhiD3D11NativeHandles*>(nativeHandles);\n    ID3D11Device* d3dDevice = d3d11Handles->dev;\n#else\n    QRhiImplementation* const rhiImplementation = rhi->implementation();|' "$source_file"
}

apply_qt_rhi_patch() {
    local patch_file="$SCRIPT_DIR/patches/fix_qt_rhi_compatibility.patch"
    local target="$VLC_SOURCE_DIR/modules/gui/qt/maininterface/compositor_dcomp.cpp"

    if [ ! -f "$patch_file" ] || [ ! -f "$target" ]; then
        echo "  [AVISO] Patch Qt 6.10+ não encontrado (arquivo ou destino ausente)."
        return
    fi

    if grep -q "QRhiNativeHandles" "$target" 2>/dev/null; then
        echo "  Patch Qt 6.10+ já aplicado em compositor_dcomp.cpp"
        return
    fi

    echo "  Aplicando patch de compatibilidade Qt 6.10+ (QRhiNativeHandles)..."
    if (cd "$VLC_SOURCE_DIR" && patch -N -p1 < "$patch_file"); then
        echo "  Patch aplicado com sucesso."
    else
        echo "  [AVISO] Não foi possível aplicar o patch automaticamente. Consulte fix_qt610_compositor.sh."
    fi
}

echo "=================================================================="
echo "  Compilacao Automatizada do VLC 4.x para Windows"
echo "=================================================================="
echo ""

# Variaveis de configuracao
VLC_SOURCE_DIR="/c/Users/$USERNAME/vlc-source"
INSTALL_PREFIX="/c/Users/$USERNAME/vlc-test"
BUILD_DIR="build-mingw"

echo "Verificando dependencias extras..."
ensure_d3d12_allocator

# Aplica patch Qt 6.10+ (desabilita DirectComposition)
if [ -f "$SCRIPT_DIR/patch_dcomp_qt610.py" ]; then
    echo "Aplicando patch de compatibilidade Qt 6.10+..."
    python3 "$SCRIPT_DIR/patch_dcomp_qt610.py"
fi
echo ""

# Passo 1: Verificar se o repositorio ja foi clonado
echo "Passo 1/5: Verificando repositorio do VLC..."
if [ ! -d "$VLC_SOURCE_DIR" ]; then
    echo "  Clonando repositorio do VLC..."
    cd "/c/Users/$USERNAME"
    git clone https://code.videolan.org/videolan/vlc.git vlc-source
    cd vlc-source
    echo "  Mudando para branch master..."
    git switch master
else
    echo "  Repositorio ja existe em $VLC_SOURCE_DIR"
    cd "$VLC_SOURCE_DIR"
    echo "  Atualizando repositorio..."
    git pull || echo "  Aviso: Nao foi possivel atualizar (pode ja estar atualizado)"
fi
echo ""

# Passo 2: Criar diretorio de instalacao
echo "Passo 2/5: Preparando diretorio de instalacao..."
mkdir -p "$INSTALL_PREFIX"
echo "  Diretorio criado: $INSTALL_PREFIX"
echo ""

# Passo 3: Configurar build com Meson
echo "Passo 3/5: Configurando build com Meson..."
if [ -d "$BUILD_DIR" ]; then
    echo "  Removendo build anterior..."
    rm -rf "$BUILD_DIR"
fi

echo "  Executando meson setup..."
meson setup "$BUILD_DIR" \
  --prefix="$INSTALL_PREFIX" \
  --buildtype=release \
  -Dqt=enabled \
  -Dlibplacebo=disabled \
  -Dskins2=disabled \
  -Davcodec=disabled \
  -Ddbus=disabled \
  -Dncurses=disabled

echo "  Configuracao concluida!"
echo ""

# Passo 4: Compilar
echo "Passo 4/5: Compilando o VLC (isso pode demorar 30-60 minutos)..."
echo "  Inicio: $(date)"
meson compile -C "$BUILD_DIR"
echo "  Fim: $(date)"
echo "  Compilacao concluida!"
echo ""

# Passo 5: Instalar
echo "Passo 5/5: Instalando arquivos..."
meson install -C "$BUILD_DIR"
echo "  Instalacao concluida!"
echo ""

# Resumo final
echo "=================================================================="
echo "  COMPILACAO CONCLUIDA COM SUCESSO!"
echo "=================================================================="
echo ""
echo "Executavel instalado em:"
echo "  $INSTALL_PREFIX/bin/vlc.exe"
echo ""
echo "Para testar no PowerShell do Windows:"
echo "  & \"C:\\vlc-test\\bin\\vlc.exe\""
echo ""
echo "Para executar os testes automatizados:"
echo "  .\\test_vlc_build.ps1"
echo ""
