class_name TelaCarreira
extends Control
## Tela de turno da carreira (GDD §4.2): atributos, energia, humor e ações.

signal ir_correr
signal atualizou(msg: String)

var c: Carreira
var msg: String


func _init(carreira: Carreira, mensagem: String) -> void:
	c = carreira
	msg = mensagem


func _ready() -> void:
	var raiz := UI.hbox(20)
	raiz.add_child(_painel_garota())
	raiz.add_child(_painel_acoes())
	add_child(UI.margem(raiz, 24))


func _painel_garota() -> Control:
	var p := UI.painel()
	p.custom_minimum_size.x = 430
	var v := UI.vbox(10)
	var topo := UI.hbox(12)
	topo.add_child(UI.retrato(c.nome, c.cor, 72))
	var nomes := UI.vbox(2)
	nomes.add_child(UI.label(c.nome, 24))
	nomes.add_child(UI.label("%s · Nota %s" % [Dados.ESTILO_NOME[c.estilo], Dados.nota(c.attrs)], 16, UI.DESTAQUE))
	topo.add_child(nomes)
	v.add_child(topo)

	for k in SimCorrida.KEYS:
		var h := UI.hbox(8)
		var l := UI.label(Dados.ATTR_NOME[k], 15)
		l.custom_minimum_size.x = 110
		h.add_child(l)
		h.add_child(UI.barra(c.attrs[k], c.limite, c.cor, 200))
		h.add_child(UI.label("%d" % c.attrs[k], 15))
		v.add_child(h)

	v.add_child(HSeparator.new())
	var he := UI.hbox(8)
	var le := UI.label("Energia", 15)
	le.custom_minimum_size.x = 110
	he.add_child(le)
	var cor_e := UI.OK if c.energia >= 60 else (UI.DESTAQUE if c.energia >= Carreira.BAL.limite_falha else UI.PERIGO)
	he.add_child(UI.barra(c.energia, 100, cor_e, 200))
	he.add_child(UI.label("%d" % c.energia, 15))
	v.add_child(he)
	var cor_h: Color = [UI.PERIGO, UI.DESTAQUE, UI.TEXTO, UI.OK, UI.OK][c.humor]
	v.add_child(UI.label("Humor: %s" % Carreira.HUMOR_NOME[c.humor], 16, cor_h))
	if c.lesionada:
		v.add_child(UI.label("Lesionada: o treino rende metade até descansar ou ir à enfermaria.", 15, UI.PERIGO, true))

	v.add_child(HSeparator.new())
	v.add_child(UI.label("Aptidões", 15, UI.SUAVE))
	var apt := []
	for d in ["sprint", "milha", "media", "longa"]:
		apt.append("%s %s" % [Dados.DIST_NOME[d], Dados.APT_NOME[c.aptidao[d]]])
	v.add_child(UI.label(" · ".join(apt), 14))
	v.add_child(UI.label("Grama %s · Terra %s" % [Dados.APT_NOME[c.aptidao.grama], Dados.APT_NOME[c.aptidao.terra]], 14))

	v.add_child(HSeparator.new())
	v.add_child(UI.label("Afinidade (%d+ treina em dupla)" % Carreira.BAL.afinidade_dupla, 15, UI.SUAVE))
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	for colega in c.afinidade:
		var h := UI.hbox(6)
		var l := UI.label(colega.split(" ")[0], 14)
		l.custom_minimum_size.x = 64
		h.add_child(l)
		var af: int = c.afinidade[colega]
		var cor := UI.PERIGO if af < 0 else (UI.OK if af >= Carreira.BAL.afinidade_dupla else Color("#b07cc6"))
		h.add_child(UI.barra(maxi(af, 0), 100, cor, 80))
		h.add_child(UI.label(str(af), 13, UI.SUAVE))
		grade.add_child(h)
	v.add_child(grade)
	p.add_child(v)
	return p


func _painel_acoes() -> Control:
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var topo := UI.painel()
	var tv := UI.vbox(4)
	tv.add_child(UI.label("Semana %d de %d" % [c.turno, Carreira.BAL.turnos], 26, UI.DESTAQUE))
	var prox := c.proxima_corrida()
	if not prox.is_empty():
		var faltam: int = prox[0] - c.turno
		var quando := "nesta semana" if faltam == 0 else "em %d semana%s" % [faltam, "s" if faltam > 1 else ""]
		tv.add_child(UI.label("Próxima corrida: %s (%s %d m), %s. Objetivo: top %d." % [
			prox[1].nome, Dados.DIST_NOME[c.distancia], Dados.DISTANCIAS[c.distancia], quando, prox[1].objetivo], 16, UI.TEXTO, true))
	topo.add_child(tv)
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(Color("#2a3150"))
		pm.add_child(UI.label(msg, 16, UI.TEXTO, true))
		v.add_child(pm)

	if not c.encontro_atual().is_empty():
		v.add_child(_painel_encontro(c.encontro_atual()))
		return v

	if not c.corrida_do_turno().is_empty():
		var b := UI.botao("Ir para a corrida: %s" % c.corrida_do_turno().nome, func(): ir_correr.emit(), 24)
		b.custom_minimum_size.y = 70
		v.add_child(b)
		return v

	v.add_child(UI.label("Treinar", 18, UI.SUAVE))
	var grade := GridContainer.new()
	grade.columns = 5
	grade.add_theme_constant_override("h_separation", 8)
	for t in Carreira.TREINOS:
		grade.add_child(_botao_treino(t))
	v.add_child(grade)

	v.add_child(UI.label("Outras ações", 18, UI.SUAVE))
	var h := UI.hbox(8)
	h.add_child(_botao_acao("Descansar\n+%d energia" % Carreira.BAL.descanso, c.descansar))
	h.add_child(_botao_acao("Sair\n+humor, +%d energia" % Carreira.BAL.sair_energia, c.sair))
	if c.lesionada:
		h.add_child(_botao_acao("Enfermaria\ncura a lesão", c.enfermaria))
	v.add_child(h)
	return v


## Encontro da semana: diálogo curto com 2 ou 3 escolhas (GDD §4.7).
func _painel_encontro(e: Dictionary) -> Control:
	var p := UI.painel(Color("#2b2440"), 20)
	var v := UI.vbox(12)
	var topo := UI.hbox(12)
	var outra: String = c.encontro_pendente.get("outra", "")
	var quem: String = c.nome if e.garota != null else outra
	var ini := Dados.config_carreira(quem)
	topo.add_child(UI.retrato(quem, Color(ini.get("cor", "#b07cc6")), 64))
	var tv := UI.vbox(2)
	tv.add_child(UI.label("Encontro", 14, UI.SUAVE))
	tv.add_child(UI.label(e.titulo, 24, UI.DESTAQUE))
	topo.add_child(tv)
	v.add_child(topo)
	v.add_child(UI.label(c.texto(e.texto), 18, UI.TEXTO, true))
	for i in e.escolhas.size():
		var idx: int = i
		var b := UI.botao(c.texto(e.escolhas[i].texto), func(): atualizou.emit(c.escolher(idx)), 18)
		b.custom_minimum_size.y = 52
		v.add_child(b)
	p.add_child(v)
	return p


func _botao_treino(t: String) -> Button:
	var g := c.ganho_previsto(t)
	var linhas := ["%s  Nv %d%s" % [Dados.ATTR_NOME[t], c.nivel_treino(t), " ★" if t in c.naturais else ""]]
	if c.duplas.has(t):
		linhas.append("com %s!" % c.duplas[t].split(" ")[0])
	for k in g:
		linhas.append("+%d %s" % [round(g[k]), Dados.ATTR_CURTO[k]])
	linhas.append("−%d energia" % c.custo(t))
	var falha := c.chance_falha()
	linhas.append("Falha %d%%" % round(falha * 100))
	var b := _botao_acao("\n".join(linhas), func(): return c.treinar(t))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if falha > 0.0:
		b.add_theme_color_override("font_color", UI.PERIGO if falha >= 0.25 else UI.DESTAQUE)
	return b


func _botao_acao(texto: String, acao: Callable) -> Button:
	var b := UI.botao(texto, func(): atualizou.emit(acao.call()), 15)
	b.custom_minimum_size = Vector2(150, 120)
	return b
