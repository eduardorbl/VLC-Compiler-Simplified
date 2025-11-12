# 🛠️ Compilar VLC (build de testes com interface Qt)

Este roteiro descreve uma compilação de referência do VLC 4.x no Windows 10/11
com suporte à interface Qt. Os passos foram organizados para aproveitar o
VLC Build Doctor como checklist de ambiente e reduzir surpresas durante o
processo.

> **Importante:** Execute os comandos exatamente nos shells indicados. Todos
> os caminhos usam a barra invertida (`\`) padrão do Windows.

---

## 0. Compilação automatizada (recomendado)

Antes de seguir o passo a passo manual, considere usar os scripts que já automatizam
todo o processo e garantem que dependências como o `D3D12MemAlloc.h` estejam corretas.

### PowerShell (Windows 10/11)

```powershell
.\compile_vlc.ps1
```

O script:
- Detecta o MSYS2 automaticamente;
- Baixa/clona `vlc-source` caso não exista;
- Recria `build-mingw` e executa `meson setup` com os parâmetros recomendados
  (`-Dqt=enabled`, `-Ddbus=disabled`, `-Dncurses=disabled`, etc.);
- Copia o header oficial do **D3D12 Memory Allocator** para `C:\msys64\mingw64\include`
  quando encontra o stub minimalista (causa comum do erro em `qrhid3d12_p.h`);
- Aplica automaticamente o patch `patches/fix_qt_rhi_compatibility.patch`, necessário
  quando o MSYS2 entrega o Qt 6.10+ (sem `QRhi::implementation()`).
- Chama `meson compile` e `meson install`.

### Shell dentro do MSYS2 MinGW 64-bit

```bash
chmod +x ./compile_vlc.sh
./compile_vlc.sh
```

> Ambos os scripts geram a instalação em `C:\Users\<usuario>\vlc-test`. Após o término,
> execute `.\test_vlc_build.ps1` para validar a build.

Se preferir seguir manualmente, lembre-se de **executar todos os comandos de build
de dentro do repositório oficial do VLC** (ex.: `C:\Users\<usuario>\vlc-source`).
Executar `meson configure build-mingw` na pasta do Build Doctor resultará no erro
“Directory … is neither a Meson build directory nor a project source directory”.

---

## 1. Validar o ambiente

1. Abra o **PowerShell**.
2. Vá até a pasta do VLC Build Doctor e execute:
   ```powershell
   python vlc_build_doctor.py
   ```
3. Garanta que todos os itens essenciais estejam com status `OK`.  
   - Se `Visual Studio Build Tools` aparecer como `AVISO` ou `FALHA`, instale o
     **Visual Studio Build Tools 2022** com o workload *Desktop development
     with C++*. O instalador está em
     <https://visualstudio.microsoft.com/downloads/>.

---

## 2. Preparar o MSYS2 (shell MinGW de 64 bits)

1. Abra o menu iniciar e execute **"MSYS2 MinGW 64-bit"**.
2. Atualize o sistema e os pacotes básicos:
   ```bash
   pacman -Syu
   # Ao finalizar, feche a janela e abra novamente o "MSYS2 MinGW 64-bit".
   pacman -Syu
   ```
3. Instale as ferramentas necessárias:
   ```bash
   pacman -S --needed \
     git \
     base-devel \
     mingw-w64-x86_64-toolchain \
     mingw-w64-x86_64-cmake \
     mingw-w64-x86_64-ninja \
     mingw-w64-x86_64-python \
     mingw-w64-x86_64-meson \
     mingw-w64-x86_64-qt6-base \
     mingw-w64-x86_64-qt6-tools \
     mingw-w64-x86_64-qt6-svg \
     mingw-w64-x86_64-qt6-declarative \
     mingw-w64-x86_64-qt6-5compat \
     mingw-w64-x86_64-pkg-config \
     nasm \
     yasm
   ```

> Recomenda-se também instalar `ccache` (`pacman -S mingw-w64-x86_64-ccache`)
> para builds mais rápidas em recompilações.

---

## 3. Clonar o repositório VLC

Dentro do shell **MSYS2 MinGW 64-bit**:

```bash
cd "/c/Users/$USERNAME"
git clone https://code.videolan.org/videolan/vlc.git vlc-source
cd vlc-source
```

> `$USERNAME` é preenchido automaticamente pelo MSYS2, portanto o comando
> funciona em qualquer perfil do Windows. Ajuste o caminho se preferir
> trabalhar em outra unidade ou pasta.
>
> **Atenção:** todos os próximos comandos (`meson`, `ninja`, `meson configure`)
> devem ser executados *já dentro* de `vlc-source`. Se estiver na pasta errada,
> o Meson acusará que `build-mingw` “não é um diretório de build”.

Se necessário, limite o clone ao branch principal ou a um commit estável:

```bash
git switch master    # branch 4.x em desenvolvimento
```

---

## 4. Configurar o build com Meson

Defina uma pasta dedicada para a instalação resultante (ex.: `C:\vlc-test`):

```bash
export INSTALL_PREFIX="/c/Users/$USERNAME/vlc-test"
mkdir -p "$INSTALL_PREFIX"

meson setup build-mingw \
  --prefix="$INSTALL_PREFIX" \
  --buildtype=release \
  -Dqt=enabled \
  -Dlibplacebo=disabled \
  -Dskins2=disabled
```

- `-Dqt=enabled` ativa a interface Qt.
- Alguns módulos opcionais são desabilitados para reduzir falhas por
  dependências externas difíceis de satisfazer no Windows.

Caso a configuração falhe, revise os logs em `build-mingw/meson-log.txt`.

---

## 5. Compilar e instalar

```bash
meson compile -C build-mingw
meson install -C build-mingw
```

O executável do VLC ficará em:

```
C:\vlc-test\bin\vlc.exe
```

Após finalizar, teste no Windows:

```powershell
& "C:\vlc-test\bin\vlc.exe"
```

---

## 6. Verificações pós-build

### 6.1 Teste automatizado completo (RECOMENDADO)

Execute o script de teste que valida todos os componentes críticos:

```powershell
# Teste completo com reprodução de vídeo
.\test_vlc_build.ps1

# Teste sem reprodução de vídeo (mais rápido)
.\test_vlc_build.ps1 -SkipVideoTest

# Teste com informações detalhadas
.\test_vlc_build.ps1 -Verbose

# Testar instalação em caminho personalizado
.\test_vlc_build.ps1 -VlcPath "D:\custom-vlc\bin\vlc.exe"
```

O script valida automaticamente:
- ✓ Existência do executável
- ✓ Plugins instalados (deve ter 50+ DLLs)
- ✓ Dependências principais (libvlc.dll, libvlccore.dll)
- ✓ Execução básica (--version)
- ✓ Módulos carregados
- ✓ Reprodução de vídeo real (baixa e reproduz um clipe de teste)
- ✓ Suporte à interface Qt

**Resultado esperado**: 100% de testes aprovados (ou 6/6 se usar `-SkipVideoTest`).

### 6.2 Testes manuais (opcional)

Se preferir validar manualmente:

1. **Interface Qt**: ao iniciar, a janela padrão do VLC deve aparecer com a GUI.
   ```powershell
   & "C:\vlc-test\bin\vlc.exe"
   ```

2. **Plugins**: verifique a quantidade de DLLs:
   ```powershell
   (Get-ChildItem "C:\vlc-test\lib\vlc\plugins\*.dll" -Recurse).Count
   # Esperado: 100+ plugins
   ```

3. **Relatório do Build Doctor**: rode novamente o script para registrar o
   estado final:
   ```powershell
   python vlc_build_doctor.py --markdown reports\auditoria-pos-build.md
   ```

4. **Reprodução de vídeo**: confirme que a interface realmente exibe mídia.
   ```powershell
   $sample = "$env:TEMP\vlc-sample.mp4"
   Invoke-WebRequest https://download.samplelib.com/mp4/sample-5s.mp4 -OutFile $sample
   & "C:\vlc-test\bin\vlc.exe" $sample --play-and-exit
   ```
   Observe se a janela abre e fecha automaticamente após a reprodução. Remova
   o arquivo assim que terminar (`Remove-Item $sample`).

---

## 7. Troubleshooting rápido

| Sintoma | Possíveis causas | Ação sugerida |
|---------|------------------|---------------|
| `Meson` reclama de dependência ausente | Pacote não instalado no `pacman` ou caminho fora do `PATH` | Reexecute a lista de pacotes do passo 2 e confirme se está no shell MinGW |
| Falha ao encontrar Qt/QMake | Pacotes Qt não instalados ou versão 32 bits | Verifique se instalou os pacotes `mingw-w64-x86_64-qt6-*` |
| `ninja: build stopped` | Erro durante compilação | Inspecione o log exibido imediatamente antes da falha e aplique a correção (às vezes falta de memória/tempo) |
| VLC inicia sem interface | Configure o parâmetro `-Dqt=enabled` e confirme se a instalação foi feita com `meson install` |
| Falta de Visual Studio Build Tools | Necessário para alguns componentes auxiliares | Abra o instalador do VS Build Tools e marque o workload C++ |
| `Directory .../build-mingw is neither a Meson build directory nor a project source directory` | Comando executado fora do repositório `vlc-source` ou `build-mingw` ainda não foi criado | Execute `cd C:\Users\SeuUsuario\vlc-source` e rode novamente `meson setup build-mingw ...` (ou simplesmente `.\compile_vlc.ps1` para recriar do zero). |
| Erros em `qrhid3d12_p.h` mencionando `D3D12MA::Allocation/Budget` | Versão stub de `D3D12MemAlloc.h` instalada no MSYS2 | Rode `.\compile_vlc.ps1` que copia o header oficial automaticamente ou substitua manualmente por `third_party/D3D12MemAlloc.h`. |
| `error: 'class QRhi' has no member named 'implementation'` ou falha em `compositor_dcomp.cpp` | Qt 6.10+ removeu `QRhi::implementation()` | Rode `.\compile_vlc.ps1` (aplica o patch automaticamente) ou execute `./fix_qt610_compositor.sh` dentro do MSYS2 para aplicar `patches/fix_qt_rhi_compatibility.patch` antes de compilar. |

---

## 8. Automatizando (opcional)

Para reproduzir os passos em lote, crie um arquivo `build-vlc-gui.sh` dentro do
MSYS2 com as etapas 3–5 e execute:

```bash
bash build-vlc-gui.sh
```

Ainda assim, recomenda-se rodar manualmente na primeira vez para entender cada
etapa e solucionar eventuais problemas específicos da máquina.

---

## 9. Próximos passos

- Ajustar `meson setup` com opções adicionais (`-Dlibdvdcss=enabled`, etc.) caso
  deseje módulos extras.
- Configurar `ccache` e variáveis `PKG_CONFIG_PATH`/`PATH` para builds contínuos.
- Integrar o Build Doctor no pipeline para garantir que o ambiente continue
  válido antes de cada compilação.
