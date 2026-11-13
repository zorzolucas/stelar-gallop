extends SceneTree
# Carregada em tempo de execução: no modo --script, os autoloads (Dados) só existem
# depois que este script compila, e carreira.gd depende deles.
var CarreiraS: GDScript
## Teste headless de balanceamento: joga carreiras com um bot simples e mede
## quantas cumprem cada objetivo.
## Uso: Godot --headless --path . --script res://testes/balanco.gd [-- N]

const PESO_ALVO := {"vel": 1.2, "est": 1.0, "pod": 0.9, "det": 0.8, "int": 0.7}


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	var n := 200
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var dados: Node = root.get_node_or_null("Dados")
	if dados == null:
		dados = load("res://scripts/dados.gd").new()
		dados.name = "Dados"
		root.add_child(dados)
	if dados.iniciais.is_empty():
		dados._ready()
	for ini in dados.iniciais:
		var ok1 := 0
		var ok2 := 0
		var vitorias := 0
		var encontros := 0
		var af_max := 0
		var soma := {}
		for k in SimCorrida.KEYS:
			soma[k] = 0.0
		for i in n:
			var c = CarreiraS.new(dados.garota(ini.nome), ini, i + 1)
			var peso := PESO_ALVO.duplicate()
			if c.distancia == "longa":
				peso.est = 1.4
			while not c.terminou:
				if not c.encontro_atual().is_empty():
					encontros += 1
					c.escolher(c.rng.randi() % c.encontro_atual().escolhas.size())
				elif not c.corrida_do_turno().is_empty():
					var corrida = c.montar_corrida(dados.garotas)
					var sim := SimCorrida.new(corrida.field, corrida.distancia, i * 7 + c.turno)
					var pos: int = sim.rodar_ate_o_fim().find(0) + 1
					var turno_corrida = c.turno
					c.registrar_corrida(pos)
					if pos <= CarreiraS.BAL.corridas[turno_corrida].objetivo:
						if turno_corrida == 12:
							ok1 += 1
						else:
							ok2 += 1
						if pos == 1 and turno_corrida == 24:
							vitorias += 1
				elif c.lesionada:
					c.enfermaria()
				elif c.energia < 45:
					if c.humor <= 1:
						c.sair()
					else:
						c.descansar()
				else:
					var melhor := "vel"
					var menor := INF
					for t in CarreiraS.TREINOS:
						var r: float = c.attrs[t] / peso[t]
						if r < menor:
							menor = r
							melhor = t
					c.treinar(melhor)
			for k in SimCorrida.KEYS:
				soma[k] += c.attrs[k]
			af_max += c.afinidade.values().max()
		var medias := []
		for k in SimCorrida.KEYS:
			medias.append("%s %d" % [k, soma[k] / n])
		print("%-18s objetivo 1: %3d%%  objetivo 2: %3d%%  vence o GP: %3d%%  |  %s  |  %.1f encontros, maior afinidade %d" % [
			ini.nome, 100 * ok1 / n, 100 * ok2 / n, 100 * vitorias / n, ", ".join(medias), float(encontros) / n, af_max / n])
	quit()
