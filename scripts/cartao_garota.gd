class_name CartaoGarota
extends RefCounted
## Cartão compacto de uma garota (retrato, nome, estilo, casa e vínculo), usado na
## academia e na pool. O VBox de conteúdo é o primeiro filho do painel devolvido,
## para quem chama acrescentar linhas e botões.


static func criar(nome: String, vinculo: int = -1) -> PanelContainer:
	var dados: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	var g: Dictionary = dados.garota(nome)
	var cfg: Dictionary = dados.config_carreira(nome)
	var p := UI.painel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 360
	var v := UI.vbox(6)
	p.add_child(v)
	var topo := UI.hbox(10)
	topo.add_child(UI.retrato(nome, Color(cfg.get("cor", "#999999")), 56))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(nome, 19))
	var completa := " · com eventos" if g.get("mvp", false) else ""
	tv.add_child(UI.label("%s · %s · %s%s" % [dados.ESTILO_NOME[g.estilo], dados.DIST_NOME[cfg.distancia],
		cfg.piso.capitalize(), completa], 13, UI.SUAVE))
	if vinculo >= 0:
		var estrelas := "★".repeat(vinculo) + "☆".repeat(Perfil.BAL.vinculo_max - vinculo)
		tv.add_child(UI.label("Vínculo %s" % estrelas, 14, UI.DESTAQUE))
	topo.add_child(tv)
	v.add_child(topo)
	return p
