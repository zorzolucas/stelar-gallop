# MCP do Godot

O repositório já traz um `.mcp.json` que liga o Claude Code ao servidor
[godot-mcp](https://github.com/Coding-Solo/godot-mcp) (MIT, versão fixada em `0.1.1`).
Com ele o Claude consegue abrir o editor, rodar o projeto em modo debug, ler a saída
de erros, criar cenas e adicionar nós.

O servidor roda **na máquina onde o Godot está instalado** (o PC Windows), não na nuvem.

## Requisitos

- Godot 4.x (o GDD fixa Godot 4 + GDScript)
- Node.js 18 ou mais novo (`node -v`)
- Claude Code rodando nesta pasta do repositório

## Passo 0: instalar o Godot 4 (Windows)

Se o Godot ainda não está na máquina:

- **Opção A, manual:** baixe a versão estável mais recente do Godot 4 (a padrão,
  não a .NET) em <https://godotengine.org/download/windows/>. É um `.zip` com um
  `.exe` portátil. Extraia numa pasta fixa, por exemplo `C:\Tools\Godot\`.
- **Opção B, winget:** `winget install GodotEngine.GodotEngine`. Depois descubra o
  caminho do executável com `where.exe godot` ou no atalho do menu Iniciar.

Use sempre a mesma versão 4.x em todas as máquinas do projeto, porque o Godot
atualiza o formato dos arquivos `.tscn`/`.tres` ao salvar.

## Instalação do MCP (Windows)

1. Defina a variável `GODOT_PATH` apontando para o executável do Godot (uma vez só):

   ```powershell
   setx GODOT_PATH "C:\caminho\para\Godot_v4.x-stable_win64.exe"
   ```

   Feche e abra o terminal depois do `setx`.

2. Abra o Claude Code na raiz do repositório. Na primeira vez ele pergunta se você
   confia no servidor `godot` do `.mcp.json`. Aprove.

3. Confira com `/mcp` dentro do Claude Code. O servidor `godot` deve aparecer como
   conectado. Um teste rápido é pedir "qual a versão do Godot?" (ferramenta
   `get_godot_version`).

O `npx -y` baixa o pacote na primeira execução; não há instalação global.

## Ferramentas disponíveis

`launch_editor`, `run_project`, `get_debug_output`, `stop_project`,
`get_godot_version`, `list_projects`, `get_project_info`, `create_scene`,
`add_node`, `load_sprite`, `export_mesh_library`, `save_scene`, `get_uid`,
`update_project_uids`.

## Problemas comuns

- **Servidor não conecta**: rode `npx -y @coding-solo/godot-mcp@0.1.1` num terminal
  para ver o erro direto.
- **"Godot not found"**: `GODOT_PATH` não está definido no ambiente em que o Claude
  Code foi aberto. Abra um terminal novo depois do `setx`.
- **Fora do Windows**: troque `"command": "cmd"` e `"args": ["/c", "npx", ...]` por
  `"command": "npx"` e `"args": ["-y", "@coding-solo/godot-mcp@0.1.1"]`.
