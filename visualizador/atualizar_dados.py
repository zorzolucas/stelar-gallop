"""Gera garotas.js a partir de ../data/garotas.json. Rode de novo sempre que o JSON mudar."""
import json, pathlib

aqui = pathlib.Path(__file__).resolve().parent
garotas = json.loads((aqui.parent / "data" / "garotas.json").read_text(encoding="utf-8"))
(aqui / "garotas.js").write_text(
    "// Gerado por atualizar_dados.py; não edite à mão.\nwindow.GAROTAS = "
    + json.dumps(garotas, ensure_ascii=False) + ";\n", encoding="utf-8")
print(f"garotas.js: {len(garotas)} garotas")
