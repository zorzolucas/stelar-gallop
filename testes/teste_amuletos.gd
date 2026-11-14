extends SceneTree
## Testa oferta e limite de amuletos, alguns efeitos e a loja de habilidades.
## Uso: Godot --headless --path . --script res://testes/teste_amuletos.gd
var CarreiraS: GDScript
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	var dados: Node = root.get_node("Dados")
	if dados.iniciais.is_empty():
		dados._ready()
	var lira: Dictionary = dados.garota("Lira Alazã")
	var c = CarreiraS.new(lira, dados.config_carreira("Lira Alazã"), 11)

	# oferta: 3 diferentes, nenhum de estilo errado (Lira é Ponteira)
	c.oferecer_amuleto(3, false)
	_checar(c.oferta_amuleto.size() == 3, "oferta com 3")
	for id in c.oferta_amuleto:
		var a: Dictionary = dados.amuleto(id)
		_checar(not a.has("estilo") or a.estilo == "pon", "amuleto de estilo errado: %s" % id)
	_checar(c.pendencia() == "amuleto", "pendência de amuleto")
	# difícil: garante incomum ou raro
	for s in 30:
		var d = CarreiraS.new(lira, dados.config_carreira("Lira Alazã"), 100 + s)
		d.oferecer_amuleto(4, true)
		_checar(d.oferta_amuleto.any(func(id): return dados.amuleto(id).tipo in ["estilo", "raro"]), "oferta difícil sem raro")

	# limite de 6 e troca
	c.oferta_amuleto = []
	c.amuletos = ["ferradura", "fita_azul", "garrafinha", "capa_chuva", "sapatilha", "laco"]
	c.escolher_amuleto("constelacao", "laco")
	_checar(c.amuletos.size() == 6 and "constelacao" in c.amuletos and not "laco" in c.amuletos, "troca no limite")
	c.escolher_amuleto("estrela_cadente", "")
	_checar(not "estrela_cadente" in c.amuletos, "descartar o novo no limite")

	# efeitos
	var base = CarreiraS.new(lira, dados.config_carreira("Lira Alazã"), 11)
	var g0: float = base.ganho_previsto("vel").vel
	base.amuletos = ["ferradura"]
	var g1: float = base.ganho_previsto("vel").vel
	_checar(absf(g1 / g0 - 1.05) < 0.001, "Ferradura +5%% (%.3f)" % (g1 / g0))
	var d0: int = base.descanso_previsto()
	base.amuletos = ["garrafinha"]
	_checar(base.descanso_previsto() == d0 + 10, "Garrafinha +10")
	base.amuletos = ["constelacao"]
	var g2: float = base.ganho_previsto("vel").vel
	_checar(absf(g2 / g0 - 1.2 / 1.1) < 0.001, "Constelação +20%% nos naturais")
	base.amuletos = ["sapatilha"]
	_checar(base.energia_corrida() == 10, "Sapatilha -5 de energia")

	# Estrela Cadente: com energia 0 a falha vira sucesso uma vez
	var e = CarreiraS.new(lira, dados.config_carreira("Lira Alazã"), 3)
	e.amuletos = ["estrela_cadente"]
	e.energia = 0
	var vel0: float = e.attrs.vel
	var txt: String = ""
	for i in 20:
		e.encontro_pendente = {}
		e.energia = 0
		txt = e.treinar("vel")
		if e.estrela_usada:
			break
	_checar(e.estrela_usada, "Estrela Cadente nunca disparou")

	# loja
	var f = CarreiraS.new(lira, dados.config_carreira("Lira Alazã"), 5)
	_checar(f.habilidades.size() == 2, "começa com 2 habilidades")
	_checar(not f.pode_comprar("curva_limpa"), "sem pontos não compra")
	f.pontos = 1000
	f.comprar_habilidade("curva_limpa")
	_checar("curva_limpa" in f.habilidades and f.pontos == 880, "compra desconta pontos")
	for h in dados.habilidades.lista:
		f.comprar_habilidade(h.id)
	_checar(f.habilidades.size() == 6, "limite de 6 habilidades (%d)" % f.habilidades.size())
	var corrida = f.montar_corrida(dados.garotas) if not f.objetivo_do_turno().is_empty() else {}
	print("AMULETOS OK" if falhas.is_empty() else "AMULETOS FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
