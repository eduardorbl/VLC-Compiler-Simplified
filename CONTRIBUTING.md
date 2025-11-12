# Contribuindo para o Projeto VLC Build System

## 🎯 Como Contribuir

Agradecemos seu interesse em contribuir! Este projeto visa facilitar a compilação do VLC no Windows.

### 📋 Pré-requisitos

- Windows 10/11
- PowerShell 5.1+
- Git (para contribuições)
- Conhecimento básico de: PowerShell, Bash, Python

---

## 🚀 Configuração do Ambiente de Desenvolvimento

### 1. Fork e Clone

```powershell
# Fork no GitHub, então:
git clone https://github.com/SEU_USUARIO/vlc-build-system.git
cd vlc-build-system
```

### 2. Instalar Ambiente

```powershell
# Executar como Administrador
.\Install-Environment.ps1
```

### 3. Testar Setup

```powershell
# Validar que tudo funciona
.\Build-VLC.ps1 -TestBuild
.\scripts\Test-VLC.ps1
```

---

## 📁 Estrutura do Projeto

### Diretórios Importantes

```
.
├── scripts/           # Scripts principais de build
├── tools/            # Utilitários de diagnóstico  
├── docs/             # Documentação completa
├── resources/        # Arquivos de recursos
├── tests/            # Testes automatizados
├── Build-VLC.ps1     # Entry point principal
└── Install-Environment.ps1  # Instalador automático
```

### Responsabilidades

| Arquivo | Propósito | Linguagem |
|---------|-----------|-----------|
| `Build-VLC.ps1` | Interface principal | PowerShell |
| `scripts/build_vlc.sh` | Motor de compilação | Bash |
| `scripts/fix_qt_compatibility.py` | Patches Qt | Python |
| `tools/vlc_build_doctor.py` | Diagnósticos | Python |
| `scripts/Test-VLC.ps1` | Sistema de testes | PowerShell |

---

## 🔄 Fluxo de Contribuição

### 1. Issues

**Reportar Problemas:**
```markdown
**Sistema:**
- OS: Windows [versão]
- MSYS2: [versão]

**Problema:**
[Descrição clara]

**Reprodução:**
1. Passo 1
2. Passo 2

**Log:**
```
[Log do erro]
```
```

**Sugerir Funcionalidades:**
- Use template "Feature Request"
- Explique o caso de uso
- Proponha implementação

### 2. Pull Requests

**Processo:**
1. Criar branch feature: `git checkout -b feature/nome-descritivo`
2. Fazer alterações
3. Testar extensivamente
4. Commit seguindo padrões
5. Push e criar PR

**Checklist do PR:**
- [ ] Código testado
- [ ] Documentação atualizada
- [ ] Mensagens de commit claras
- [ ] Sem breaking changes (ou justificadas)

---

## 🧪 Testando Alterações

### Testes Obrigatórios

```powershell
# 1. Teste básico de build
.\Build-VLC.ps1 -TestBuild

# 2. Suite completa de testes
.\scripts\Test-VLC.ps1 -Verbose

# 3. Teste de diagnóstico
python tools\vlc_build_doctor.py --test

# 4. Teste em ambiente limpo
.\tests\Test-CleanInstall.ps1
```

### Ambientes de Teste

- ✅ **Windows 10 (1909+)**
- ✅ **Windows 11**  
- ✅ **MSYS2 atualizado**
- ✅ **Qt 6.8-6.10+**

### Casos de Teste Críticos

1. **Instalação Fresh**: Sistema sem MSYS2
2. **Atualização**: Ambiente existente
3. **Diferentes versões Qt**: 6.8, 6.9, 6.10+
4. **Espaço limitado**: <10GB disponível
5. **Configurações especiais**: Proxy, antivírus

---

## 📝 Padrões de Código

### PowerShell

```powershell
# ✅ BOM: Funções com verbo aprovado
function Test-Prerequisites {
    param(
        [string]$Path,
        [switch]$Verbose
    )
    
    # Validação de parâmetros
    if (-not $Path) {
        throw "Path é obrigatório"
    }
    
    # Lógica clara e comentada
    Write-Host "Testando pré-requisitos..." -ForegroundColor Yellow
    
    return $true
}

# ❌ RUIM: Função sem padrão
function checkstuff($p) {
    # sem documentação
    # lógica confusa
}
```

### Python

```python
#!/usr/bin/env python3
"""
Módulo para correções de compatibilidade Qt.

Este script aplica patches necessários para compatibilidade
com diferentes versões do Qt.
"""

def apply_compositor_patch(file_path: str) -> bool:
    """
    Aplica patch para compositor DirectComposition.
    
    Args:
        file_path: Caminho para compositor_dcomp.cpp
        
    Returns:
        True se patch aplicado com sucesso
        
    Raises:
        FileNotFoundError: Se arquivo não existe
    """
    # Implementação clara e documentada
    pass
```

### Bash

```bash
#!/bin/bash
# Cabeçalho obrigatório com propósito

set -euo pipefail  # Strict mode

# Funções documentadas
apply_patches() {
    local vlc_source="$1"
    
    # Validação de parâmetros
    [[ -z "$vlc_source" ]] && {
        echo "❌ Erro: Caminho VLC source é obrigatório"
        return 1
    }
    
    echo "✅ Aplicando patches em: $vlc_source"
    # Lógica clara
}
```

---

## 📚 Documentação

### Atualizar Docs

**Quando documentar:**
- Nova funcionalidade adicionada
- Processo alterado
- Bug fix que afeta usuários
- Nova configuração necessária

**Onde documentar:**
- `README.md`: Visão geral e início rápido
- `docs/TROUBLESHOOTING.md`: Problemas e soluções
- `docs/TECHNICAL.md`: Detalhes técnicos
- Comentários no código: Lógica complexa

### Estilo da Documentação

- ✅ **Linguagem clara e objetiva**
- ✅ **Exemplos práticos**
- ✅ **Screenshots quando úteis**
- ✅ **Links para referências**
- ✅ **Emojis para seções (🎯 🔧 ⚠️)**

---

## 🔒 Segurança

### Considerações

- **Scripts PowerShell**: Sempre validar entrada
- **Downloads**: Verificar checksums
- **Execução**: Minimizar privilégios necessários
- **Paths**: Evitar path injection

### Práticas Seguras

```powershell
# ✅ BOM: Validação de entrada
param(
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$InstallPath = "C:\msys64"
)

# ✅ BOM: Escape de paths
$EscapedPath = [regex]::Escape($InstallPath)

# ❌ RUIM: Execução direta sem validação
Invoke-Expression $UserInput
```

---

## 🏗️ Arquitetura de Decisões

### Princípios

1. **Simplicidade**: Usuário executa um comando
2. **Robustez**: Funciona em diferentes configurações
3. **Transparência**: Logs claros do que está acontecendo
4. **Manutenibilidade**: Código fácil de entender e modificar

### Decisões Técnicas

| Decisão | Motivo | Alternativa Considerada |
|---------|--------|-------------------------|
| PowerShell como interface | Padrão Windows, bom handling de erros | Batch scripts (limitado) |
| Bash para build | Compatibilidade MSYS2/Unix | PowerShell puro (complexo) |
| Python para patches | Flexibilidade, regex avançado | Sed/awk (limitado) |
| Meson build | Padrão VLC moderno | Autotools (deprecated) |

---

## 🎯 Roadmap de Contribuições

### Prioridades Altas

- [ ] **CI/CD**: GitHub Actions para testes automáticos
- [ ] **GUI**: Interface gráfica opcional
- [ ] **Profiles**: Diferentes configurações de build (minimal, full, debug)
- [ ] **Cache**: Sistema de cache para builds incrementais

### Prioridades Médias

- [ ] **Docker**: Container para build isolado
- [ ] **Telemetria**: Coleta de métricas de sucesso (opt-in)
- [ ] **Update System**: Auto-update do build system
- [ ] **Plugin System**: Extensões para diferentes configurações

### Funcionalidades Futuras

- [ ] **Cross-compilation**: ARM64 support
- [ ] **Package Builder**: Criar instalador VLC
- [ ] **IDE Integration**: Plugin para VS Code
- [ ] **Cloud Build**: Build na nuvem para máquinas lentas

---

## 💡 Dicas para Novos Contribuidores

### Começar Pequeno

- 🎯 **Issues labeled "good first issue"**
- 🔧 **Melhorias na documentação**
- 🐛 **Correções de bugs menores**
- 🧪 **Adicionar testes**

### Buscar Ajuda

- 💬 **Discussions no GitHub**
- 🐛 **Issues para dúvidas técnicas**
- 📧 **Email dos maintainers**
- 📖 **Documentação existente**

### Manter Qualidade

- ⚡ **Testar thoroughly**
- 📝 **Documentar mudanças**
- 🔄 **Seguir padrões**
- 🤝 **Responder feedback**

---

## 🏆 Reconhecimento

### Hall of Fame

Contribuidores que fizeram diferença significativa serão listados aqui.

### Types de Contribuição

- 🔧 **Code**: Implementação de funcionalidades
- 📖 **Documentation**: Melhorias na docs
- 🐛 **Bug Reports**: Issues bem documentadas  
- 🎨 **Design**: UX/UI improvements
- 🧪 **Testing**: Testes e validação
- 💡 **Ideas**: Sugestões e feedback

---

**Obrigado por contribuir! 🎉**

*Juntos tornamos a compilação do VLC mais acessível para toda a comunidade Windows.*