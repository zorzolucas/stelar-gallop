extends SceneTree
## Teste headless de balanceamento: joga carreiras completas (48 turnos) com um bot simples
## e mede quantas cumprem cada objetivo, a curva de atributos e a fama.
## Uso: Godot --headless --path . --script res://testes/balanco.gd [-- N [garota]]
# Carreira é carregada em tempo de execução: no modo --script, os autoloads (Dados) só
# existem depois que este script compila, e carreira.gd depende deles.
var CarreiraS: GDScript
var dd: Node

const PESO_ALVO := {"vel": 1.2, "est": 1.0, "pod": 0.9, "det": 0.8, "int": 0.7}
const MARCOS := [4, 12, 24, 36, 48]


func _media(c) -> float:
	var s := 0.0
	for k in c.attrs:
		s += c.attrs[k]
	return s / 5.0


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_balanco.json"
	var n := 100
	var so := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.size() > 1:
		so = args[1]
	var dados: Node = root.get_node("Dados")
	dd = dados
	if dados.iniciais.is_empty():
		dados._ready()
	for ini in dados.iniciais:
		if so != "" and not ini.nome.begins_with(so):
			continue
		var passou := [0, 0, 0, 0, 0]
		var curva := [0.0, 0.0, 0.0, 0.0, 0.0]
		var fama36 := 0
		var corridas := 0
		var falta_fama := 0
		var amuletos := 0
		var habs := 0
		for i in n:
			var c = CarreiraS.new(dados.garota(ini.nome), ini, i + 1)
			var peso := PESO_ALVO.duplicate()
			if c.distancia in ["media", "longa"]:
				peso.est = 1.3
			var guard := 0
			var _habs_antes := 0
			while not c.terminou and guard < 400:
				guard += 1
				var t0: int = c.turno
				var p: String = c.pendencia()
				if OS.has_environment("TRACE") and i == 0:
					print("t%d %s e%d m%.0f fama%d no=%s" % [c.turno, p, c.energia, _media(c), c.fama, c.tipo_no()])
				if p == "objetivo" and MARCOS.has(c.turno):
					curva[MARCOS.find(c.turno)] += _media(c)
				match p:
					"encontro":
						c.escolher(hash([i, c.turno]) % c.encontro_atual().escolhas.size())
					"amuleto":
						amuletos += 1
						if c.amuletos.size() < 6:
							c.escolher_amuleto(c.oferta_amuleto[0])
						else:
							c.escolher_amuleto(c.oferta_amuleto[0], c.amuletos[0])
					"mapa":
						c.escolher_no(_melhor_no(c))
					"ferias":
						c.escolher_acampamento("serra" if c.distancia in ["media", "longa"] else "praia")
					"corrida", "objetivo":
						if p == "objetivo" and c.turno == 36:
							fama36 += c.fama
						var corrida = c.montar_corrida(dados.garotas)
						var sim := SimCorrida.new(corrida.field, corrida.distancia, corrida.seed, corrida.clima)
						var pos: int = sim.rodar_ate_o_fim().find(0) + 1
						var obj: Dictionary = c.objetivo_do_turno() if p == "objetivo" else {}
						c.registrar_corrida(pos)
						corridas += 1
						if not obj.is_empty() and not c.falhou_objetivo:
							passou[MARCOS.find(t0)] += 1
					"sem_fama":
						falta_fama += 1
						c.falhar_por_fama()
					_:
						_acao(c, peso)
		var linha := []
		for j in 5:
			pass
		for j in 5:
			linha.append("%3d%%" % (100 * passou[j] / n))
		var cv := []
		for j in 5:
			var chegaram: int = passou[j - 1] if j > 0 else n
			cv.append("%d" % (curva[j] / maxi(1, chegaram)))
		print("%-17s obj %s | média nos objetivos %s | fama no t36 %d | %.1f corridas | %.1f amuletos | sem fama %d" % [
			ini.nome, " ".join(linha), "/".join(cv), fama36 / maxi(1, passou[2]), float(corridas) / n, float(amuletos) / n, falta_fama])
	quit()


func _melhor_no(c) -> int:
	var t: int = c.trecho()
	var linha: int = c.rota[t].size()
	var melhor := -1
	var nota := -INF
	for col in c.opcoes_mapa():
		var no: Dictionary = c.mapas[t][linha][col]
		var quer_fama: bool = c.fama < 1700 and t <= 2
		var v: float = {"circuito": 3.0 if quer_fama else 1.5, "foco": 2.5, "recuperacao": 1.0, "festival": 1.0,
			"biblioteca": 1.0, "desafio": 1.5, "misterio": 1.2}[no.tipo]
		if no.tipo == "recuperacao" and c.energia < 50:
			v += 1.5
		# olha uma linha à frente: preferir quem leva a um Circuito
		if linha + 1 < c.mapas[t].size():
			for viz in Calendario.vizinhos(col):
				if c.mapas[t][linha + 1][viz].tipo == "circuito":
					v += 0.3
		if v > nota:
			nota = v
			melhor = col
	return melhor


func _acao(c, peso: Dictionary) -> void:
	# compra habilidades quando dá (primeiro as de referência, depois as outras)
	for h in dd.habilidades.lista:
		if c.pode_comprar(h.id):
			c.comprar_habilidade(h.id)
	if c.lesionada:
		c.enfermaria()
		if c.lesionada == false and c.tipo_no() == "recuperacao":
			return
		return
	var media := _media(c)
	if c.energia >= 50:
		var melhor := {}
		for cr in c.corridas_opcionais():
			var forca: float = dd.calendario.categorias[cr.cat].forca
			if cr.get("desafio", false):
				forca *= 1.2
			var apt: float = dd.APT[c.aptidao[cr.dist]] * dd.APT[c.aptidao[cr.piso]]
			# corre quando a corrida é acessível; depois de ter fama para o objetivo 4, só as bem fáceis
			var folga := 0.95 if c.fama < 1700 or c.turno > 36 else 1.15
			if c.pode_entrar(cr) and media * apt >= forca * folga:
				if melhor.is_empty() or c.fama_prevista(cr) > c.fama_prevista(melhor):
					melhor = cr
		if not melhor.is_empty():
			c.escolher_corrida(melhor)
			return
	if c.energia < 45:
		if c.humor <= 1:
			c.sair()
		else:
			c.descansar()
		return
	var escolhido := "vel"
	var menor := INF
	for t in CarreiraS.TREINOS:
		var r: float = c.attrs[t] / peso[t] / (1.0 + 0.15 * (c.nivel_efetivo(t) - c.nivel_treino(t)))
		if r < menor:
			menor = r
			escolhido = t
	c.treinar(escolhido)
