#!/bin/bash
# Patch para compatibilidade Qt 6.10+ no VLC compositor DirectComposition

VLC_SOURCE="/c/Users/$USERNAME/vlc-source"
TARGET="$VLC_SOURCE/modules/gui/qt/maininterface/compositor_dcomp.cpp"

echo "Aplicando patch de compatibilidade Qt 6.10+ no compositor DirectComposition..."

if [ ! -f "$TARGET" ]; then
    echo "ERRO: Arquivo não encontrado: $TARGET"
    exit 1
fi

# Verifica se já foi aplicado
if grep -q "QT_VERSION_CHECK(6, 10, 0)" "$TARGET"; then
    echo "Patch já aplicado!"
    exit 0
fi

# Backup
cp "$TARGET" "$TARGET.backup"

# Criar arquivo temporário com o código corrigido
cat > /tmp/compositor_patch.cpp << 'ENDPATCH'
    const auto rhi = m_quickView->rhi();
    assert(rhi);
    assert(rhi->backend() == QRhi::D3D11);

    // Qt 6.10+ removed QRhiImplementation::implementation(), use nativeHandles() instead
    Microsoft::WRL::ComPtr<ID3D11Device> d3dDevice;
    
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
    const QRhiNativeHandles *nativeHandles = rhi->nativeHandles();
    if (nativeHandles)
    {
        const QRhiD3D11NativeHandles *d3d11Handles = 
            static_cast<const QRhiD3D11NativeHandles*>(nativeHandles);
        if (d3d11Handles && d3d11Handles->dev)
            d3dDevice = d3d11Handles->dev;
    }
#else
    QRhiImplementation* const rhiImplementation = rhi->implementation();
    assert(rhiImplementation);
    rhiImplementation->getD3DDevice(&d3dDevice);
#endif

    QRhiSwapChain* const rhiSwapChain = m_quickView->swapChain();
    assert(rhiSwapChain);

    assert(m_quickView->rhi()->backend() == QRhi::D3D11 || m_quickView->rhi()->backend() == QRhi::D3D12);
ENDPATCH

# Aplicar patch: substituir linhas 168-177
# Primeiro, salvar as linhas antes e depois
sed -n '1,167p' "$TARGET" > /tmp/compositor_new.cpp
cat /tmp/compositor_patch.cpp >> /tmp/compositor_new.cpp
sed -n '178,$p' "$TARGET" >> /tmp/compositor_new.cpp

# Substituir o arquivo
mv /tmp/compositor_new.cpp "$TARGET"

echo "Patch aplicado com sucesso!"
echo "Backup salvo em: $TARGET.backup"