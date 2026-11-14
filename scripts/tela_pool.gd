class_name TelaPool
extends Control
## Pool semanal (GDD §6): rotação de garotas, chances visíveis, garantia e vínculo.

signal voltar

var perfil: Perfil
var resultado := {}


func _init(p: Perfil) -> void:
	perfil = p


func _ready() -> void:
	_montar()


func _montar() -> void:
	for c in get_children():
		c.queue_free()
	var v := UI.vbox(14)
	var topo := UI.hbox(12)
	var titulo := UI.label("Pool semanal · rotação %d" % (perfil.giro + 1), 30, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(UI.label("%d moedas" % perfil.moeda, 24, UI.DESTAQUE))
	topo.add_child(UI.botao("Voltar à academia", func(): voltar.emit(), 18))
	v.add_child(topo)
	v.add_child(UI.label("Cada tiragem custa %d moedas e sempre traz uma destas garotas. Garota nova entra no elenco; repetida sobe o vínculo. A rotação muda a cada carreira concluída." % Perfil.BAL.custo_tiragem, 15, UI.SUAVE, true))
	v.add_child(UI.label("Marcada: %s. Ela vem garantida em no máximo %d tiragem(ns)." % [
		perfil.escolhida, perfil.faltam_para_garantia()], 16, UI.TEXTO, true))

	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for nome in perfil.pool:
		grade.add_child(_cartao(nome))
	v.add_child(grade)

	var acoes := UI.hbox(12)
	var b := UI.botao("Tirar 1 (%d moedas)" % Perfil.BAL.custo_tiragem, _tirar, 22)
	b.disabled = not perfil.pode_tirar()
	acoes.add_child(b)
	if not resultado.is_empty():
		acoes.add_child(_painel_resultado())
	v.add_child(acoes)
	add_child(UI.margem(v, 28))


func _cartao(nome: String) -> Control:
	var tem: bool = perfil.elenco.has(nome)
	var p := CartaoGarota.criar(nome, perfil.elenco[nome].vinculo if tem else -1)
	if nome == perfil.escolhida:
		var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
		sb.border_color = UI.DESTAQUE
		sb.set_border_width_all(3)
		p.add_theme_stylebox_override("panel", sb)
	var v: VBoxContainer = p.get_child(0)
	var status := "No elenco" if tem else "Nova"
	v.add_child(UI.label("Chance %d%% · %s" % [roundi(perfil.chance(nome) * 100), status], 14, UI.OK if not tem else UI.SUAVE))
	if nome != perfil.escolhida:
		v.add_child(UI.botao("Marcar para a garantia", func(): _marcar(nome), 14))
	else:
		v.add_child(UI.label("Marcada para a garantia", 14, UI.DESTAQUE))
	return p


func _painel_resultado() -> Control:
	var p := UI.painel(Color("#3a2f55"))
	var h := UI.hbox(10)
	var cfg := Dados.config_carreira(resultado.nome)
	h.add_child(UI.retrato(resultado.nome, Color(cfg.cor), 48))
	var txt: String
	if resultado.nova:
		txt = "%s entrou no elenco!" % resultado.nome
	elif resultado.vinculo_max:
		txt = "%s de novo! O vínculo já está no máximo, então voltaram %d moedas." % [resultado.nome, Perfil.BAL.custo_tiragem / 2]
	else:
		txt = "%s de novo! Vínculo subiu para %d." % [resultado.nome, resultado.vinculo]
	if resultado.garantida:
		txt += " (garantia)"
	h.add_child(UI.label(txt, 18, UI.TEXTO))
	p.add_child(h)
	return p


func _marcar(nome: String) -> void:
	perfil.escolher(nome)
	_montar()


func _tirar() -> void:
	resultado = perfil.tirar()
	_montar()
