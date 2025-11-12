# VLC 4.x Build System para Windows

![VLC](https://img.shields.io/badge/VLC-4.x-orange?style=for-the-badge&logo=vlc-media-player)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?style=for-the-badge&logo=windows)
![Qt](https://img.shields.io/badge/Qt-6.10+-green?style=for-the-badge&logo=qt)
![License](https://img.shields.io/badge/License-GPL--2.0-red?style=for-the-badge)

Sistema profissional de compilação automática do VLC 4.x para Windows 10/11 com interface Qt6. Projetado para facilitar o desenvolvimento e distribuição em ambientes corporativos.

## 🎯 Características

- ✅ **Instalação Totalmente Automática** - Script único instala todo o ambiente
- ✅ **Compatibilidade Qt 6.10+** - Patches automáticos para as versões mais recentes
- ✅ **Otimizado para Windows** - Configuração específica para Windows 10/11
- ✅ **Testes Abrangentes** - Validação automática da compilação
- ✅ **Documentação Didática** - Guias passo-a-passo para toda a equipe
- ✅ **Troubleshooting Integrado** - Diagnóstico automático de problemas

## 🚀 Início Rápido (Para Novos Desenvolvedores)

### Opção 1: Instalação Automática Completa

```powershell
# 1. Execute como Administrador:
.\Install-Environment.ps1

# 2. Compile o VLC:
.\Build-VLC.ps1

# 3. Teste a instalação:
.\scripts\Test-VLC.ps1
```

### Opção 2: Ambiente Existente

Se você já tem MSYS2 instalado:

```powershell
# Compile diretamente:
.\Build-VLC.ps1
```

## 📋 Pré-requisitos

| Componente | Versão Mínima | Observações |
|------------|---------------|-------------|
| Windows | 10/11 (64-bit) | Testado em versões recentes |
| PowerShell | 5.0+ | Incluído no Windows 10+ |
| Espaço em Disco | 8 GB | Para código fonte + build |
| RAM | 8 GB | Recomendado para compilação |
| Internet | Banda Larga | Para downloads (~3GB) |

## 🗂️ Estrutura do Projeto

```
vlc-build-system/
├── 📄 Build-VLC.ps1           # Script principal de compilação
├── 📄 Install-Environment.ps1  # Instalador automático do ambiente
├── 📁 scripts/                # Scripts especializados
│   ├── build_vlc.sh          # Engine de compilação (Bash)
│   ├── Test-VLC.ps1          # Sistema de testes
│   └── fix_qt_compatibility.py # Patches Qt 6.10+
├── 📁 tools/                  # Ferramentas de diagnóstico
│   └── vlc_build_doctor.py    # Diagnóstico do ambiente
├── 📁 resources/              # Recursos necessários
│   └── third_party/          # Headers e dependências
├── 📁 docs/                   # Documentação detalhada
│   ├── TROUBLESHOOTING.md     # Resolução de problemas
│   ├── DEVELOPER_GUIDE.md     # Guia para desenvolvedores
│   └── FAQ.md                 # Perguntas frequentes
└── 📁 examples/               # Exemplos de uso
```

## ⚙️ Compilação Detalhada

### 1. Preparação do Ambiente

O sistema instala automaticamente:

- **MSYS2 MinGW-w64**: Ambiente de compilação Unix-like para Windows
- **GCC 15.2+**: Compilador C/C++ otimizado
- **Meson + Ninja**: Sistema de build moderno
- **Qt 6.10.x**: Framework de interface gráfica
- **Git**: Controle de versão
- **Python 3**: Scripts de automação

### 2. Correções Automáticas

O sistema aplica automaticamente:

- **Patches Qt 6.10+**: Compatibilidade com APIs mais recentes
- **Headers D3D12**: Corrige problemas de Direct3D
- **Configuração Windows**: Otimizações específicas do SO
- **Módulos Desabilitados**: Remove dependências problemáticas

### 3. Processo de Build

```bash
# Etapas executadas automaticamente:
1. Clone do repositório VLC 4.x (~1GB)
2. Aplicação de patches de compatibilidade  
3. Configuração Meson otimizada
4. Compilação com GCC (30-60 minutos)
5. Instalação em C:\vlc-test\
6. Validação automática
```

## 🧪 Sistema de Testes

O sistema inclui testes abrangentes:

### Testes Automáticos

- ✅ **Executável**: Verifica se VLC foi compilado
- ✅ **Plugins**: Valida 50+ plugins necessários
- ✅ **Bibliotecas**: Testa libvlc.dll e dependências
- ✅ **Interface Qt**: Verifica GUI funcional
- ✅ **Codecs**: Testa reprodução de vídeo MP4
- ✅ **Módulos**: Lista funcionalidades disponíveis

### Executar Testes

```powershell
# Testes completos
.\scripts\Test-VLC.ps1

# Testes sem vídeo
.\scripts\Test-VLC.ps1 -SkipVideoTest

# Gerar relatório HTML
.\scripts\Test-VLC.ps1 -GenerateReport
```

## 🐛 Resolução de Problemas

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| "MSYS2 não encontrado" | Execute `.\Install-Environment.ps1` |
| "Erro Qt implementation()" | Script aplica patch automaticamente |
| "Falta de espaço" | Libere 8GB+ no drive C: |
| "Falha na compilação" | Execute `tools\vlc_build_doctor.py` |

### Diagnóstico Automático

```powershell
# Verificar ambiente completo
python tools\vlc_build_doctor.py

# Logs detalhados
.\Build-VLC.ps1 -Verbose
```

### Logs Importantes

- **Build**: `C:\Users\%USERNAME%\vlc-source\build-mingw\meson-logs\`
- **MSYS2**: `C:\msys64\var\log\`
- **VLC Test**: `.\VLC-Test-Report.html`

## 📚 Documentação Adicional

- [🔧 Troubleshooting Detalhado](docs/TROUBLESHOOTING.md)
- [👨‍💻 Guia do Desenvolvedor](docs/DEVELOPER_GUIDE.md)
- [❓ Perguntas Frequentes](docs/FAQ.md)
- [📝 Exemplos de Uso](examples/EXEMPLOS.md)

## 🤝 Para Equipes de Desenvolvimento

### Distribuição para Novos Funcionários

1. **Clone do repositório:**
   ```bash
   git clone [URL-DO-REPOSITORIO] vlc-build
   cd vlc-build
   ```

2. **Instalação automática:**
   ```powershell
   # Como Administrator
   .\Install-Environment.ps1
   ```

3. **Primeira compilação:**
   ```powershell
   .\Build-VLC.ps1
   ```

### Configuração de CI/CD

```yaml
# Exemplo GitHub Actions
- name: Setup VLC Build Environment
  run: .\Install-Environment.ps1 -Quiet
  
- name: Build VLC
  run: .\Build-VLC.ps1 -Quiet
  
- name: Test Build
  run: .\scripts\Test-VLC.ps1 -SkipVideoTest
```

## 📝 Configurações Avançadas

### Personalizar Instalação

```powershell
# Instalar em diretório customizado
.\Install-Environment.ps1 -InstallPath "D:\dev\msys2"

# Compilação com configurações específicas
.\Build-VLC.ps1 -ConfigOptions "-Dqt=enabled -Ddebug=true"
```

### Módulos VLC

O sistema desabilita automaticamente módulos problemáticos no Windows:

- `avcodec`: Incompatibilidade FFmpeg
- `dbus`: Linux-only
- `ncurses`: Missing wcswidth/wcwidth
- `directcomposition`: Qt 6.10+ incompatível

## 📊 Status do Projeto

- ✅ **Testado**: Windows 10/11, MSYS2 2024.01.13
- ✅ **Compatível**: Qt 6.10.x, GCC 15.2+
- ✅ **Produção**: Usado em ambiente corporativo
- ✅ **Manutenido**: Atualizações regulares

## 📞 Suporte

Para problemas técnicos:

1. Execute diagnóstico: `tools\vlc_build_doctor.py`
2. Consulte: `docs\TROUBLESHOOTING.md`
3. Verifique logs em `build-mingw\meson-logs\`
4. Abra issue com logs completos

## 📄 Licença

Este projeto segue a licença GPL-2.0, compatível com o VLC Media Player.

---

**Desenvolvido para facilitar a compilação do VLC em ambientes Windows corporativos** 🎬