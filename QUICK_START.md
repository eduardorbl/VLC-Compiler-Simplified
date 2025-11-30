# Quick Start Guide - VLC Build System

**Get VLC 4.x compiled in 3 steps!**

---

## 🚀 For Developers

### 1️⃣ Clone the Repository

```powershell
# Clone the project
git clone https://github.com/eduardorbl/VLC-Compiler-Simplified.git
cd VLC-Compiler-Simplified

# Verify you're in the right folder
ls  # Should show: Compile-VLC.ps1, Install-Environment.ps1, etc.
```

### 2️⃣ Build with ONE COMMAND! 🎯

```powershell
.\Compile-VLC.ps1
```

**That's all!** The script will:
- ✅ Check MSYS2 installation (offers auto-install if missing)
- ✅ Install all dependencies automatically
- ✅ Clone VLC source code
- ✅ Apply Qt 6.8+ compatibility patches
- ✅ Configure with Meson
- ✅ Compile VLC 4.x
- ✅ Validate the build

**Time:** 
- ⏰ First run: ~60-120 minutes (download + install + compile)
- ⏰ Subsequent builds: ~15-30 minutes (compile only)

### 3️⃣ (Optional) Manual Step-by-Step

If you prefer full control:

```powershell
# Step 1: Install environment (run as Administrator)
.\Install-Environment.ps1

# Step 2: Build VLC
.\Build-VLC.ps1

# Step 3: Validate
python tools\vlc_build_doctor.py
```

---

## ✅ Quick Verification

If everything worked, you should have VLC compiled:

```powershell
# Check version
& "C:\vlc-test\bin\vlc.exe" --version

# Expected output:
# VLC media player 4.0.0-dev Otto Chriek
# Copyright © 1996-2025 the VideoLAN team
```

---

## 🚨 Troubleshooting

### Common Issues:

**1. "MSYS2 not found"**
```powershell
# Run as Administrator
.\Install-Environment.ps1
```

**2. "Insufficient disk space"**
- Free at least 8GB on C: drive
- Run: `cleanmgr` to clean temporary files

**3. "Compilation fails"**
```powershell
# Run diagnostics
python tools\vlc_build_doctor.py

# Check recent errors
Get-Content "C:\Users\$env:USERNAME\vlc-source\build-mingw\meson-logs\meson-log.txt" -Tail 30
```

**4. "Qt errors during build"**
- System applies patches automatically
- For Qt 6.8+, DirectComposition is disabled (uses Win7 compositor instead)

### Full Documentation:

- 📖 **README.md** - Complete overview
- 🔧 **docs/TROUBLESHOOTING.md** - Detailed solutions
- 🎯 **CONTRIBUTING.md** - Development guide

---

## 💻 Compatibility

### ✅ Tested On:
- Windows 10 (version 1909+)
- Windows 11
- PowerShell 5.1+
- MSYS2 UCRT64

### 📋 Requirements:
- **Disk Space**: 8GB free on C:
- **RAM**: 8GB minimum (16GB recommended)
- **Internet**: Broadband connection
- **Time**: 1-2 hours for complete setup

---

## 📊 Build Output

After successful build, you'll have:

| Component | Location | Status |
|-----------|----------|--------|
| VLC Executable | `C:\vlc-test\bin\vlc.exe` | ✅ Ready |
| Libraries | `C:\vlc-test\lib\` | ✅ 2 core DLLs |
| Plugins | Build directory | ✅ 328 plugins |
| Source | `C:\Users\%USERNAME%\vlc-source\` | ✅ Complete |

---

## 🎯 What Gets Compiled

### Video Codecs:
✅ x264, x265, VP8/VP9 (vpx), AV1 (aom, dav1d, rav1e)

### Audio Codecs:
✅ opus, vorbis, theora, speex

### Containers:
✅ MP4, OGG, Matroska support

### Video Output:
✅ Direct3D 11, Direct3D 9, OpenGL

### Interface:
✅ Qt 6.8.0 (Win7 compositor mode for compatibility)

---

## 📞 Need Help?

1. **Documentation**: Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. **Diagnostics**: Run `python tools\vlc_build_doctor.py`
3. **Logs**: View `C:\Users\%USERNAME%\vlc-source\build-mingw\meson-logs\`
4. **Report Bug**: Create GitHub issue with full log output

---

## 🎓 Learning Resources

Want to understand what's happening?

- **Build Process**: See [docs/COMPILAR_VLC_GUI.md](docs/COMPILAR_VLC_GUI.md)
- **Technical Details**: See [docs/GUIA_TECNICO.md](docs/GUIA_TECNICO.md)
- **Scripts**: Explore `scripts/` and `tools/` directories

---

## 🎉 Success!

Once built, VLC is installed at:
```
C:\vlc-test\
├── bin\
│   ├── vlc.exe          # Main executable
│   ├── libvlc.dll       # Core library
│   └── libvlccore-9.dll # Core library
└── lib\
    └── vlc\plugins\     # All plugins
```

**Run VLC:**
```powershell
& "C:\vlc-test\bin\vlc.exe"
```

**Or double-click:** `C:\vlc-test\bin\vlc.exe` in Explorer

---

**🎯 One Command Philosophy: `.\Compile-VLC.ps1` does everything!**
