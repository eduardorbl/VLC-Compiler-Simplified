# 📖 Guia do Usuário — VLC Build Doctor

Este guia conduz qualquer pessoa — mesmo sem experiência prévia com build de
software — a verificar se o ambiente Windows está pronto para compilar o VLC.
Tudo é feito com um único script Python, sem instalações automáticas.

---

## 1. Preparação

- **Sistema:** Windows 10 ou 11 (64 bits).
- **Python:** versão 3.8 ou superior. Durante a instalação, marque a opção
  *“Add Python to PATH”*.
- **Permissões:** a auditoria não exige privilégios de administrador.

Se ainda não possui o Python instalado, baixe em <https://www.python.org/downloads/windows/>.

---

## 2. Executando a auditoria

1. Baixe/clonene o repositório do VLC Build Doctor.
2. Abra o PowerShell na pasta do projeto.
3. Execute:
   ```powershell
   python vlc_build_doctor.py
   ```
4. Aguarde alguns segundos. O script exibirá uma tabela semelhante a:

   ```
   Componente                 Status Versão   Local/Observação
   -----------------------------------------------------------
   Python                     OK     3.11.2  C:\Python311\python.exe
   Git                        OK     2.45.0  C:\Program Files\Git\bin\git.exe
   CMake                      FALHA  -       -
   ...
   ```

5. Logo abaixo é apresentado um resumo com totais de `OK`, `Avisos` e
   `Falhas`, seguido pela lista de recomendações.

---

## 3. Entendendo os status

| Status   | Significado                                                                 | Ação sugerida                                  |
|----------|------------------------------------------------------------------------------|------------------------------------------------|
| `OK`     | Dependência encontrada e pronta para uso.                                   | Nenhuma ação necessária.                       |
| `AVISO`  | Item opcional, versão antiga ou execução com saída incomum.                 | Leia a mensagem; atualize apenas se necessário.|
| `FALHA`  | Dependência ausente ou não executou corretamente.                           | Instale/configure o componente sugerido.       |

As mensagens sempre trazem um link ou comando recomendado para correção. Após
ajustar o ambiente, execute novamente o script para validar.

---

## 4. Gerando relatórios

Use estes parâmetros opcionais para compartilhar o diagnóstico com a equipe:

- **JSON estruturado** (apropriado para anexar em issues ou pipelines):
  ```powershell
  python vlc_build_doctor.py --json reports\auditoria.json
  ```
- **Markdown** (ótimo para copiar para wikis ou chats):
  ```powershell
  python vlc_build_doctor.py --markdown reports\auditoria.md
  ```
- **Checks específicos**:
  ```powershell
  python vlc_build_doctor.py --only python git meson
  ```
- **Lista de identificadores disponíveis**:
  ```powershell
  python vlc_build_doctor.py --list
  ```

Os arquivos são salvos com codificação UTF-8. Se a pasta `reports` não existir,
ela será criada automaticamente.

---

## 5. Checklist rápido de correções

| Dependência                  | Caminho recomendado / Dica                            |
|------------------------------|-------------------------------------------------------|
| Python                       | Instalar via Microsoft Store ou python.org            |
| Git                          | `https://git-scm.com/download/win`                    |
| CMake                        | `https://cmake.org/download/`                         |
| Ninja                        | Via MSYS2 (`pacman -S mingw-w64-x86_64-ninja`) ou zip |
| Meson                        | `pip install meson`                                   |
| pkg-config (opcional)        | Pacote MSYS2 `mingw-w64-x86_64-pkg-config`            |
| NASM                         | `winget install NASM.NASM` ou `choco install nasm`    |
| Perl                         | Strawberry Perl `https://strawberryperl.com/`         |
| MSYS2                        | `https://www.msys2.org/` (padrão `C:\msys64`)         |
| GCC (MinGW-w64)              | MSYS2 pacote `mingw-w64-x86_64-toolchain`             |
| Visual Studio Build Tools    | Instalar workload “Desktop development with C++”      |
| vcpkg (opcional)             | `https://github.com/microsoft/vcpkg`                  |

---

## 6. Dúvidas frequentes

- **Posso rodar em WSL ou Linux?** O script funciona, mas os resultados serão
  irrelevantes para compilar VLC no Windows. Execute sempre em um Windows real.
- **Preciso de privilégios de administrador?** Não. O script somente lê o
  ambiente.
- **Quão atualizado é o checklist?** Os valores de versão mínima seguem a
  documentação do VLC e podem ser ajustados em `vlc_build_doctor.py`.

---

## 7. Próximos passos

Depois de obter todos os itens como `OK`, siga o processo de compilação
oficial do VLC (Wiki: <https://wiki.videolan.org/Win32Compile/>) ou adapte o
pipeline interno da sua organização. O relatório gerado pelo Build Doctor deve
acompanhar qualquer solicitação de suporte técnico.

---

Se algo estiver faltando neste guia, abra uma issue ou envie um pull request.
Documentação clara é essencial para que novos contribuidores consigam montar o
ambiente com confiança.
