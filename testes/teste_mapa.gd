extends SceneTree
## Gera 800 mapas e confere as regras do calendário (§4.2): todo caminho com Circuito,
## cada linha com 2 tipos, no máximo 1 Desafio por trecho e nenhum no trecho 1.
## Uso: Godot --headless --path . --script res://testes/teste_mapa.gd
func _initialize():
	var d = root.get_node("Dados")
	if d.calendario.is_empty(): d._ready()
	var C = load("res://scripts/calendario.gd")
	var ruins := 0
	var conta := {}
	for s in 200:
		for t in 4:
			var m = C.gerar_mapa(s + 1, t)
			if not C._caminho_sem_circuito(m).is_empty(): ruins += 1
			var des := 0
			for l in m:
				if l[0].tipo == l[1].tipo and l[1].tipo == l[2].tipo: ruins += 1
				for n in l:
					conta[n.tipo] = conta.get(n.tipo, 0) + 1
					if n.tipo == "desafio": des += 1
			if des > 1 or (t == 0 and des > 0): ruins += 1
	print("MAPA OK" if ruins == 0 else "MAPA FALHOU: %d inválidos" % ruins, "  tipos: ", conta)
	quit(0 if ruins == 0 else 1)
