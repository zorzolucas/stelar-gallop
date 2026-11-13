# MCP do Blender

O `.mcp.json` da raiz também liga o Claude Code ao
[MCP for Blender](https://github.com/ahujasid/mcp-for-blender) (MIT, antigo `blender-mcp`,
versão fixada em `2.2.6`). Com ele o Claude consegue criar, editar e apagar objetos,
aplicar materiais, tirar capturas do viewport para conferir o resultado e rodar
Python dentro do Blender. Funciona junto com o MCP do Godot (ver `docs/mcp-godot.md`):
a ideia é modelar no Blender, exportar (glTF `.glb`) e importar no projeto Godot.

São duas peças:

1. **Servidor MCP** (`uvx mcp-for-blender`), que o Claude Code inicia sozinho pelo `.mcp.json`.
2. **Addon do Blender**, que abre um socket local (`localhost:9876`) dentro do Blender.
   O servidor fala com o Blender por esse socket, então **o Blender precisa estar aberto**.

## Requisitos

- Blender 3.0 ou mais novo
- [uv](https://docs.astral.sh/uv/) (o `uvx` vem junto). O próprio uv baixa o Python 3.11.
- Claude Code rodando na raiz deste repositório

## Instalação (Windows)

1. Instale o uv e abra um terminal novo:

   ```powershell
   winget install --id=astral-sh.uv -e
   ```

2. Instale o addon no Blender (use a mesma versão do `.mcp.json`):

   ```powershell
   uvx mcp-for-blender@2.2.6 install-addon
   ```

   Depois, no Blender: **Edit → Preferences → Add-ons**, ative **Interface: MCP for Blender**.

3. Abra o Blender. O addon sobe o servidor sozinho. Para conferir, aperte `N` no viewport
   3D, aba **MCP for Blender** (clique em **Start MCP Server** se não estiver rodando).

4. Abra o Claude Code na raiz do repo e aprove o servidor `blender` quando ele perguntar.
   Confira com `/mcp`. Um teste rápido: "o que tem na cena do Blender agora?".

Não use o instalador automático (`setup`) do projeto para este repo: ele grava a config
no nível do usuário, e aqui a config já vem no `.mcp.json` versionado.

## Escolhas do `.mcp.json`

- `cmd /c uvx`: no Windows o Claude Code nem sempre acha o `uvx` direto no PATH.
  Fora do Windows, troque por `"command": "uvx"` e tire o `"/c"` dos args.
- `--python 3.11` + `UV_PYTHON_PREFERENCE=only-managed`: evita conflito com outros
  Pythons instalados na máquina.
- `DISABLE_TELEMETRY=true`: desliga até o registro anônimo de uso que o projeto coleta por padrão.

## Cuidados

- A ferramenta `execute_blender_code` roda Python arbitrário no Blender.
  **Salve o arquivo `.blend` antes** de pedir mudanças grandes.
- O socket do addon não tem autenticação; ele só escuta em `localhost`. Não mude o host.
- Rode só um cliente MCP por vez falando com o mesmo Blender (por exemplo, não deixe o
  Claude Desktop e o Claude Code conectados ao mesmo tempo).
- Poly Haven, Sketchfab e geração de modelos por IA vêm desligados ou pedem chave própria;
  ative no painel do addon só se for usar.

## Problemas comuns

- **`spawn uvx ENOENT` / servidor não conecta**: abra um terminal novo depois de instalar
  o uv, ou rode `uvx mcp-for-blender@2.2.6` direto para ver o erro.
- **"Could not connect to Blender"**: o Blender não está aberto ou o addon não está
  rodando (aba **MCP for Blender**, botão **Start MCP Server**). A porta padrão é 9876.
