class_name TelaEscolha
extends Control
## Escolha de 1 entre 3 garotas iniciais (GDD §8).

signal escolheu(inicial: Dictionary)


func _ready() -> void:
	var v := UI.vbox(18)
	v.add_child(UI.label("Galope Estelar", 40, UI.DESTAQUE))
	v.add_child(UI.label("Escolha a garota que você vai treinar.", 20, UI.SUAVE))
	var linha := UI.hbox(18)
	linha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for ini in Dados.iniciais:
		linha.add_child(_cartao(ini))
	v.add_child(linha)
	add_child(UI.margem(v, 32))


func _cartao(ini: Dictionary) -> Control:
	var g := Dados.garota(ini.nome)
	var p := UI.painel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(10)
	var topo := UI.hbox(12)
	topo.add_child(UI.retrato(ini.nome, Color(ini.cor), 80))
	var nomes := UI.vbox(2)
	nomes.add_child(UI.label(ini.nome, 24))
	nomes.add_child(UI.label("“%s”" % ini.apelido, 15, UI.SUAVE, true))
	nomes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(nomes)
	v.add_child(topo)
	v.add_child(UI.label(ini.descricao, 16, UI.TEXTO, true))
	v.add_child(UI.label("Estilo: %s" % Dados.ESTILO_NOME[g.estilo], 16, UI.DESTAQUE))
	v.add_child(UI.label("Corrida-alvo: %s (%d m), %s" % [
		Dados.DIST_NOME[ini.distancia], Dados.DISTANCIAS[ini.distancia], ini.piso.capitalize()], 15, UI.SUAVE))
	for k in SimCorrida.KEYS:
		var h := UI.hbox(8)
		var l := UI.label(Dados.ATTR_CURTO[k], 15)
		l.custom_minimum_size.x = 40
		h.add_child(l)
		h.add_child(UI.barra(g.atributos[k], 150, Color(ini.cor), 180))
		h.add_child(UI.label(str(int(g.atributos[k])), 15, UI.SUAVE))
		v.add_child(h)
	var nat: Array = ini.naturais.map(func(k): return Dados.ATTR_NOME[k])
	v.add_child(UI.label("Treinos naturais: %s" % " e ".join(nat), 15, UI.SUAVE))
	var habil: String = SimCorrida.UNICAS[ini.unica].nome
	v.add_child(UI.label("Habilidade única: %s" % habil, 15, UI.SUAVE))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	v.add_child(UI.botao("Escolher %s" % ini.nome.split(" ")[0], func(): escolheu.emit(ini), 20))
	p.add_child(v)
	return p
