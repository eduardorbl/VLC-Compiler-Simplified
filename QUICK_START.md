# QUICK START GUIDE - VLC Build System

## 🚀 Para Desenvolvedores da Equipe

### 1️⃣ Clone do Repositório

```powershell
# 1. Clone o projeto
git clone https://github.com/SEU_USUARIO/vlc-build-system.git
cd vlc-build-system

# 2. Verifique que está na pasta correta
ls # Deve mostrar: Build-VLC.ps1, Install-Environment.ps1, etc.
```

### 2️⃣ Instalação Automática (Como Administrador)

```powershell
# Abrir PowerShell como Administrador
# Navegar até a pasta do projeto
cd "C:\caminho\para\vlc-build-system"

# Executar instalação completa
.\Install-Environment.ps1

# ⏰ Aguardar ~15-30 minutos para download e instalação
```

### 3️⃣ Compilação do VLC

```powershell
# Em PowerShell normal (não precisa ser Admin)
.\Build-VLC.ps1

# ⏰ Primeira compilação: ~45-90 minutos
# ⏰ Compilações seguintes: ~15-30 minutos
```

### 4️⃣ Teste da Compilação

```powershell
# Executar suite de testes
.\scripts\Test-VLC.ps1

# Ver relatório em: VLC-Test-Report.html
```

---

## ✅ Verificação Rápida

Se tudo funcionou, você deve ter:

```powershell
# VLC compilado funcionando
& "C:\vlc-test\bin\vlc.exe" --version

# Saída esperada:
# VLC media player 4.0.0-dev (revision...)
# VideoLAN
```

---

## 🚨 Se Algo Deu Errado

### Problemas Comuns:

1. **"MSYS2 não encontrado"**
   ```powershell
   .\Install-Environment.ps1  # Executar como Admin
   ```

2. **"Espaço insuficiente"**
   - Libere pelo menos 8GB no drive C:
   - Limpe arquivos temporários

3. **"Qt implementation() erro"**
   - Sistema aplica patch automaticamente
   - Verifique: `python scripts\fix_qt_compatibility.py`

4. **Compilação falha**
   ```powershell
   python tools\vlc_build_doctor.py  # Diagnóstico completo
   ```

### Documentação Completa:

- 📖 **README.md** - Visão geral completa
- 🔧 **docs/TROUBLESHOOTING.md** - Soluções detalhadas
- 🎯 **CONTRIBUTING.md** - Guia de desenvolvimento

---

## 💻 Compatibilidade

### ✅ Testado em:
- Windows 10 (versão 1909+)
- Windows 11
- PowerShell 5.1+
- MSYS2 (instalado automaticamente)

### 📋 Requisitos:
- **Espaço em disco**: 8GB livres no drive C:
- **RAM**: 8GB (recomendado 16GB)
- **Tempo**: 1-2 horas para setup inicial completo

---

## 📞 Suporte

1. **Consultar**: docs/TROUBLESHOOTING.md
2. **Diagnosticar**: `python tools\vlc_build_doctor.py`
3. **Reportar**: Criar issue no GitHub com log completo

---

**🎯 Meta: Máximo 3 comandos para ter VLC funcionando em qualquer máquina Windows!**

```powershell
.\Install-Environment.ps1  # (como Admin)
.\Build-VLC.ps1
.\scripts\Test-VLC.ps1
```