#!/usr/bin/env python3
"""Patch compositor_dcomp.cpp para desabilitar DirectComposition no Qt 6.10+"""

import sys

filepath = "/c/Users/1edur/vlc-source/modules/gui/qt/maininterface/compositor_dcomp.cpp"

# Ler arquivo
with open(filepath.replace("/c/", "C:/"), 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Verificar se já foi aplicado
for line in lines:
    if 'QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)' in line:
        print("Patch já aplicado!")
        sys.exit(0)

# Encontrar linha 'bool CompositorDirectComposition::init()' e o primeiro '{'
in_init_function = False
brace_line = -1

for i, line in enumerate(lines):
    if 'bool CompositorDirectComposition::init()' in line:
        in_init_function = True
    elif in_init_function and '{' in line:
        brace_line = i
        break

if brace_line == -1:
    print("ERRO: Não consegui encontrar a função init()")
    sys.exit(1)

# Inserir patch logo após o '{'
patch_lines = [
    "#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)\n",
    "    // DirectComposition not supported with Qt 6.10+ due to QRhi API changes\n",
    "    msg_Warn(m_intf, \"DirectComposition compositor disabled for Qt 6.10+, using Win7 fallback\");\n",
    "    return false;\n",
    "#else\n"
]

# Inserir patch
lines[brace_line+1:brace_line+1] = patch_lines

# Encontrar o final da função init() - procurar pelo último 'return true;' antes do próximo 'bool'
return_line = -1
for i in range(brace_line, len(lines)):
    if 'return true;' in lines[i]:
        return_line = i
    elif i > brace_line + 10 and 'bool CompositorDirectComposition::make' in lines[i]:
        break

if return_line == -1:
    print("ERRO: Não consegui encontrar 'return true;' na função init()")
    sys.exit(1)

# Adicionar #endif após o return true;
lines[return_line+1:return_line+1] = ["#endif\n"]

# Escrever arquivo
with open(filepath.replace("/c/", "C:/"), 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Patch aplicado com sucesso!")
print(f"Adicionado na linha {brace_line+1}")
print(f"Fechado na linha {return_line+2}")
