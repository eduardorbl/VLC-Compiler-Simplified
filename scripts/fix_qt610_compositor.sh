#!/bin/bash
# Script para corrigir compatibilidade com Qt 6.10+ no compositor DirectComposition

VLC_SOURCE_DIR="/c/Users/$USERNAME/vlc-source"
TARGET_FILE="$VLC_SOURCE_DIR/modules/gui/qt/maininterface/compositor_dcomp.cpp"

if [ ! -f "$TARGET_FILE" ]; then
    echo "Erro: Arquivo não encontrado: $TARGET_FILE"
    exit 1
fi

# Verifica se o patch já foi aplicado
if grep -q "QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)" "$TARGET_FILE" 2>/dev/null; then
    echo "Patch Qt 6.10+ já aplicado em compositor_dcomp.cpp"
    exit 0
fi

echo "Aplicando patch de compatibilidade Qt 6.10+ em compositor_dcomp.cpp..."

# Backup
cp "$TARGET_FILE" "$TARGET_FILE.bak"

# Usa sed para fazer a substituição
# Encontra a linha 171 e substitui
sed -i '171 {
    s|.*|    // Qt 6.10+ compatibility: implementation() was removed|
    a\    #if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)\
    const QRhiNativeHandles *nativeHandles = rhi->nativeHandles();\
    const QRhiD3D11NativeHandles *d3d11Handles = static_cast<const QRhiD3D11NativeHandles*>(nativeHandles);\
    ID3D11Device* d3dDevice = d3d11Handles->dev;\
    #else\
    QRhiImplementation* const rhiImplementation = rhi->implementation();
}' "$TARGET_FILE"

# Adiciona o fechamento do #else na próxima linha onde rhiImplementation é usado
sed -i '/rhiImplementation->getD3DDevice/ {
    s|.*|    #if QT_VERSION < QT_VERSION_CHECK(6, 10, 0)\
    rhiImplementation->getD3DDevice(\&d3dDevice);\
    #endif|
}' "$TARGET_FILE"

echo "Patch aplicado com sucesso!"
echo "Backup salvo em: $TARGET_FILE.bak"
