# Troubleshooting - VLC Build System

## 🚨 Problemas Comuns e Soluções

### 1. Erro: "MSYS2 não encontrado"

**Sintoma:**
```
❌ MSYS2 não encontrado! Instale de https://www.msys2.org/
```

**Soluções:**
```powershell
# Opção A: Instalação automática
.\Install-Environment.ps1

# Opção B: Instalação manual
# 1. Baixe de https://www.msys2.org/
# 2. Instale em C:\msys64
# 3. Execute: pacman -S mingw-w64-x86_64-toolchain
```

---

### 2. Erro: Qt `implementation()` não existe

**Sintoma:**
```
error: 'class QRhi' has no member named 'implementation'
```

**Solução:**
```powershell
# O patch é aplicado automaticamente
python scripts\fix_qt_compatibility.py
```

**Verificar:**
```bash
grep -n "QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)" /c/Users/$USERNAME/vlc-source/modules/gui/qt/maininterface/compositor_dcomp.cpp
```

---

### 3. Erro: Espaço insuficiente

**Sintoma:**
```
❌ Espaço insuficiente no drive C: 3.2 GB disponível, 8.0 GB necessário
```

**Soluções:**
```powershell
# Verificar espaço atual
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="Free(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}

# Limpar arquivos temporários
.\tools\cleanup-disk.ps1

# Mover MSYS2 para outro drive
.\Install-Environment.ps1 -InstallPath "D:\msys64"
```

---

### 4. Erro: Dependências faltando

**Sintoma:**
```
❌ Algumas ferramentas estão faltando no MSYS2
```

**Solução:**
```bash
# No MSYS2 MinGW 64-bit:
pacman -S mingw-w64-x86_64-toolchain \
          mingw-w64-x86_64-meson \
          mingw-w64-x86_64-ninja \
          mingw-w64-x86_64-cmake \
          mingw-w64-x86_64-qt6-base \
          mingw-w64-x86_64-qt6-tools \
          mingw-w64-x86_64-qt6-svg \
          mingw-w64-x86_64-qt6-declarative \
          mingw-w64-x86_64-qt6-5compat \
          git \
          python3
```

---

### 5. Erro: FFmpeg incompatibilidade

**Sintoma:**
```
error: 'FF_PROFILE_AAC_LOW' was not declared in this scope
```

**Solução:**
- ✅ **Automática**: Sistema desabilita `avcodec` automaticamente
- ℹ️ **Manual**: Adicione `-Davcodec=disabled` ao meson

---

### 6. Erro: Compilação falha com "ninja failed"

**Sintoma:**
```
ninja: build stopped: subcommand failed.
Exit Code: 1
```

**Diagnóstico:**
```powershell
# 1. Verificar logs detalhados
Get-Content "C:\Users\$env:USERNAME\vlc-source\build-mingw\meson-logs\meson-log.txt" | Select-Object -Last 50

# 2. Verificar ambiente
python tools\vlc_build_doctor.py

# 3. Limpar e recompilar
Remove-Item "C:\Users\$env:USERNAME\vlc-source\build-mingw" -Recurse -Force
.\Build-VLC.ps1
```

---

### 7. Erro: Teste de vídeo falha

**Sintoma:**
```
❌ Reprodução de vídeo MP4: Timeout ou erro na reprodução
```

**Soluções:**
```powershell
# Pular teste de vídeo
.\scripts\Test-VLC.ps1 -SkipVideoTest

# Testar manualmente
& "C:\vlc-test\bin\vlc.exe" --version

# Verificar codecs
& "C:\vlc-test\bin\vlc.exe" --list | Select-String "mp4"
```

---

## 🔍 Diagnóstico Avançado

### Logs Importantes

| Tipo | Localização | Descrição |
|------|-------------|-----------|
| **Meson** | `vlc-source\build-mingw\meson-logs\meson-log.txt` | Configuração do build |
| **Ninja** | Terminal output | Erros de compilação |
| **VLC Test** | `.\VLC-Test-Report.html` | Resultado dos testes |
| **MSYS2** | `C:\msys64\var\log\pacman.log` | Instalação de pacotes |

### Comandos de Diagnóstico

```powershell
# Verificar ambiente completo
python tools\vlc_build_doctor.py --verbose

# Testar MSYS2
C:\msys64\usr\bin\bash.exe -lc "pacman -Q | wc -l"

# Verificar Qt
C:\msys64\usr\bin\bash.exe -lc "pkg-config --modversion Qt6Core"

# Testar GCC
C:\msys64\usr\bin\bash.exe -lc "gcc --version"
```

---

## 🔧 Correções Manuais

### Resetar Ambiente Completamente

```powershell
# 1. Remover tudo
Remove-Item "C:\msys64" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Users\$env:USERNAME\vlc-source" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\vlc-test" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Reinstalar
.\Install-Environment.ps1

# 3. Recompilar
.\Build-VLC.ps1
```

### Forçar Atualização Qt

```bash
# No MSYS2:
pacman -Rns mingw-w64-x86_64-qt6-base
pacman -S mingw-w64-x86_64-qt6-base --needed
```

### Limpar Cache de Build

```powershell
# Limpar cache meson
Remove-Item "$env:LOCALAPPDATA\meson" -Recurse -Force -ErrorAction SilentlyContinue

# Limpar build VLC
Remove-Item "C:\Users\$env:USERNAME\vlc-source\build-mingw" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 📞 Quando Buscar Ajuda

### Informações para Incluir

Antes de pedir ajuda, colete:

```powershell
# 1. Informações do sistema
systeminfo | Select-String "OS Name|OS Version|Total Physical Memory"

# 2. Versão PowerShell
$PSVersionTable

# 3. Diagnóstico VLC
python tools\vlc_build_doctor.py > diagnostic.txt

# 4. Logs recentes
Get-Content "C:\Users\$env:USERNAME\vlc-source\build-mingw\meson-logs\meson-log.txt" | Select-Object -Last 100 > build-log.txt
```

### Template de Issue

```markdown
**Sistema:**
- OS: Windows [versão]
- MSYS2: [versão]
- Qt: [versão]

**Problema:**
[Descrição detalhada]

**Log de erro:**
```
[Cole aqui o log do erro]
```

**Já tentei:**
- [ ] Reinstalar ambiente
- [ ] Limpar cache
- [ ] Executar diagnóstico
```

---

## 🎯 Dicas de Prevenção

### Manutenção Regular

```powershell
# Atualizar MSYS2 mensalmente
C:\msys64\usr\bin\bash.exe -lc "pacman -Syu"

# Limpar cache de build
Remove-Item "build-mingw" -Recurse -Force -ErrorAction SilentlyContinue

# Verificar espaço em disco
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.FreeSpace -lt 10GB}
```

### Configuração Estável

```powershell
# Fixar versão Qt (se necessário)
C:\msys64\usr\bin\bash.exe -lc "pacman -S mingw-w64-x86_64-qt6-base=6.8.0"

# Backup da configuração
Copy-Item "C:\msys64" "D:\Backup\msys64-backup" -Recurse
```

---

**📝 Esta documentação é atualizada conforme novos problemas são identificados.**