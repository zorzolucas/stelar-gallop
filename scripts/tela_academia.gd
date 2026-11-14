class_name TelaAcademia
extends Control
## Hub entre carreiras: moeda, elenco (vínculo e versão salva) e acesso à pool (GDD §2).

signal treinar(nome: String)
signal continuar
signal abrir_pool

var perfil: Perfil
var msg: String


func _init(p: Perfil, mensagem: String = "") -> void:
	perfil = p
	msg = mensagem


func _ready() -> void:
	var v := UI.vbox(14)
	var topo := UI.hbox(12)
	var titulo := UI.label("Academia Estelar", 34, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(UI.label("%d moedas" % perfil.moeda, 24, UI.DESTAQUE))
	topo.add_child(UI.botao("Pool semanal", func(): abrir_pool.emit(), 18))
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(Color("#2a3150"))
		pm.add_child(UI.label(msg, 16, UI.TEXTO, true))
		v.add_child(pm)

	var salvo := Carreira.carregar() if Carreira.tem_save() else null
	if salvo:
		var pc := UI.painel(Color("#25402f"))
		var h := UI.hbox(12)
		var txt := "Carreira em andamento: %s, semana %d de %d." % [salvo.nome, salvo.turno, Carreira.BAL.turnos]
		if salvo.terminou:
			txt = "A carreira de %s terminou. Falta decidir se a nova versão fica salva." % salvo.nome
		var l := UI.label(txt, 18, UI.TEXTO, true)
		h.add_child(l)
		h.add_child(UI.botao("Continuar carreira", func(): continuar.emit(), 18))
		pc.add_child(h)
		v.add_child(pc)

	v.add_child(UI.label("Elenco (%d)  ·  escolha quem vai treinar%s" % [
		perfil.elenco.size(), ". Começar outra carreira apaga a que está em andamento." if salvo else ""], 16, UI.SUAVE, true))
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grade := GridContainer.new()
	grade.columns = 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for nome in perfil.elenco:
		grade.add_child(_cartao(nome))
	rolagem.add_child(grade)
	v.add_child(rolagem)
	add_child(UI.margem(v, 28))


func _cartao(nome: String) -> Control:
	var info: Dictionary = perfil.elenco[nome]
	var p := CartaoGarota.criar(nome, info.vinculo)
	var v: VBoxContainer = p.get_child(0)
	var salva: Dictionary = info.salva
	if salva.is_empty():
		v.add_child(UI.label("Ainda sem versão salva", 14, UI.SUAVE))
	else:
		var a: Dictionary = salva.attrs
		v.add_child(UI.label("Versão salva: nota %s · %d objetivo(s)" % [salva.nota, salva.objetivos], 14, UI.OK))
		v.add_child(UI.label("Vel %d · Est %d · Pod %d · Det %d · Int %d" % [a.vel, a.est, a.pod, a.det, a.int], 13, UI.SUAVE))
	v.add_child(UI.botao("Treinar %s" % nome.split(" ")[0], func(): treinar.emit(nome), 16))
	return p
