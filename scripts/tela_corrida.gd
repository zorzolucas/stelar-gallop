class_name TelaCorrida
extends Control
## Tela da corrida: vista 3D com troca de câmera (Corrida3D), minimapa, ranking ao vivo,
## avisos de habilidade e botões 1x / 2x / pular. O jogador só assiste.

signal terminou(posicao: int)

## Passos de simulação (0,1 s) por segundo real em 1x. 20 = corrida 2x mais rápida que o tempo real.
const PASSOS_1X := 20.0
const CORES := ["#c9a227", "#8e6cc9", "#c9568e", "#4fa3a5", "#b0764a", "#7f8fa6",
				"#a3b14f", "#d07a4a", "#5c7fb8", "#9a5bb0", "#6aa86a"]

var dados: Dictionary
var cor_jogadora: Color
var sim: SimCorrida
var cores: Array = []
var velocidade := 1.0
var acumulado := 0.0
var acabou := false
var emitiu := false   # evita registrar a corrida duas vezes (botão + Enter)
var avisos: Array = []   # [{idx, texto, vida}]
var linhas: Array = []   # [ColorRect, Label] por posição do ranking

var pista: Pista
var mundo: Corrida3D
var x_antes: Array = []   # posição de cada corredora no passo anterior (para interpolar)
var botao_camera: Button
var faixa_aviso: Label
var aviso_vida := 0.0
var ranking: VBoxContainer
var info: Label
var feed: VBoxContainer
var botoes: HBoxContainer
var continuar: Button
var resultado: PanelContainer
var resultado_txt: Label


func _init(d: Dictionary, cor: Color) -> void:
	dados = d
	cor_jogadora = cor
	sim = SimCorrida.new(d.field, d.distancia, d.get("seed", 0), d.get("clima", ""))
	for r in sim.rs:
		x_antes.append(r.x)
	var n := 0
	for g in d.field:
		if g.jogadora:
			cores.append(cor)
		else:
			cores.append(Color(CORES[n % CORES.size()]))
			n += 1


func _ready() -> void:
	var raiz := UI.vbox(12)
	var topo := UI.hbox(12)
	var meta := "objetivo top %d" % dados.objetivo if dados.objetivo > 0 else "corrida opcional"
	var clima_txt := ""
	if dados.get("clima", "") != "":
		var cl: Dictionary = Dados.calendario.climas[dados.clima]
		clima_txt = " · %s %s" % [cl.icone, cl.nome]
	var titulo := UI.label("%s · %d m · %s%s" % [dados.nome, dados.distancia, meta, clima_txt], 22, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	botoes = UI.hbox(6)
	botoes.add_child(UI.botao("1x", func(): velocidade = 1.0))
	botoes.add_child(UI.botao("2x", func(): velocidade = 2.0))
	botoes.add_child(UI.botao("Pular", _pular))
	topo.add_child(botoes)
	# no fim, o Continuar fica no topo (no lugar dos botões de velocidade), sempre visível
	continuar = UI.botao("Continuar ▶", _continuar, 20)
	continuar.visible = false
	topo.add_child(continuar)
	raiz.add_child(topo)

	var meio := UI.hbox(16)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var area := Control.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.clip_contents = true
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.add_child(vista)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	vista.add_child(vp)
	mundo = Corrida3D.new(cores, dados.field.map(func(g): return g.nome))
	vp.add_child(mundo)
	meio.add_child(area)
	# por cima da vista 3D: câmeras e aviso de habilidade da jogadora
	var sobre := Control.new()
	sobre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sobre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(sobre)
	var cams := UI.hbox(6)
	cams.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cams.position = Vector2(12, -52)
	cams.grow_vertical = Control.GROW_DIRECTION_BEGIN
	botao_camera = UI.botao("", _proxima_camera, 16)
	cams.add_child(UI.label("Câmera (C):", 16))
	cams.add_child(botao_camera)
	for m in Corrida3D.CAMERA_NOME.size():
		var modo: int = m
		cams.add_child(UI.botao(str(m + 1), func(): _usar_camera(modo), 16))
	sobre.add_child(cams)
	faixa_aviso = UI.label("", 26, UI.DESTAQUE)
	faixa_aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	faixa_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faixa_aviso.position.y = 16
	faixa_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	faixa_aviso.add_theme_constant_override("outline_size", 8)
	faixa_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	sobre.add_child(faixa_aviso)
	# cartão de resultado no centro da vista 3D, com outro botão de continuar
	resultado = UI.painel(Color(0.08, 0.1, 0.16, 0.92), 20)
	resultado.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	resultado.grow_horizontal = Control.GROW_DIRECTION_BOTH
	resultado.grow_vertical = Control.GROW_DIRECTION_BOTH
	resultado.visible = false
	var rv := UI.vbox(12)
	resultado_txt = UI.label("", 26, UI.DESTAQUE)
	resultado_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(resultado_txt)
	var b := UI.botao("Continuar (Enter)", _continuar, 20)
	b.custom_minimum_size = Vector2(260, 48)
	rv.add_child(b)
	resultado.add_child(rv)
	sobre.add_child(resultado)

	var lado := UI.painel()
	lado.custom_minimum_size.x = 300
	lado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lv := UI.vbox(6)
	info = UI.label("", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(info)
	ranking = UI.vbox(2)
	lv.add_child(ranking)
	pista = Pista.new()
	pista.tela = self
	pista.custom_minimum_size = Vector2(0, 130)
	lv.add_child(pista)
	lv.add_child(UI.label("Habilidades", 14, UI.SUAVE))
	feed = UI.vbox(2)
	lv.add_child(feed)
	# o painel lateral rola se não couber, para nunca empurrar nada para fora da tela
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lv)
	lado.add_child(rolagem)
	meio.add_child(lado)
	raiz.add_child(meio)
	add_child(UI.margem(raiz, 20))
	_atualizar_ranking()


func _process(delta: float) -> void:
	if not acabou:
		acumulado += delta * PASSOS_1X * velocidade
		while acumulado >= 1.0 and not sim.done:
			acumulado -= 1.0
			for i in sim.rs.size():
				x_antes[i] = sim.rs[i].x
			_registrar(sim.step())
		if sim.done:
			_finalizar()
		_atualizar_ranking()
	for a in avisos:
		a.vida -= delta
	avisos = avisos.filter(func(a): return a.vida > 0.0)
	aviso_vida -= delta
	faixa_aviso.modulate.a = clampf(aviso_vida, 0.0, 1.0)
	_atualizar_3d(delta)
	pista.queue_redraw()


func _atualizar_3d(delta: float) -> void:
	var xs := []
	var vs := []
	var lider := 0
	for i in sim.rs.size():
		var r: Dictionary = sim.rs[i]
		var x: float = r.x if acabou else lerpf(x_antes[i], r.x, clampf(acumulado, 0.0, 1.0))
		xs.append(minf(x, sim.D))
		vs.append(0.0 if r.t >= 0.0 else r.v)
		if r.x > sim.rs[lider].x:
			lider = i
	var fase := SimCorrida.fase(minf(sim.rs[lider].x, sim.D - 0.01), sim.D)
	mundo.atualizar(xs, sim.D, vs, fase, lider, delta, sim.rs[0].t >= 0.0)
	var nome: String = Corrida3D.CAMERA_NOME[mundo.modo]
	if mundo.modo == Corrida3D.Camera.AUTO:
		nome += " · " + Corrida3D.CAMERA_NOME[mundo.modo_efetivo]
	botao_camera.text = nome


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if acabou and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_continuar()
		return
	if k.keycode == KEY_C:
		_proxima_camera()
	elif k.keycode >= KEY_1 and k.keycode < KEY_1 + Corrida3D.CAMERA_NOME.size():
		_usar_camera(k.keycode - KEY_1)


func _proxima_camera() -> void:
	mundo.proxima_camera()


func _usar_camera(m: int) -> void:
	mundo.modo = m as Corrida3D.Camera


func _registrar(ev: Array) -> void:
	for e in ev:
		var g: Dictionary = dados.field[e.idx]
		avisos.append({"idx": e.idx, "texto": e.nome, "vida": 1.6})
		var txt := "%s: %s" % [g.nome.split(" ")[0], e.nome]
		var cor := UI.DESTAQUE if g.jogadora else UI.SUAVE
		if e.unica:
			txt += " ★"
		if g.jogadora:
			faixa_aviso.text = "%s: %s%s" % [g.nome.split(" ")[0], e.nome, " ★" if e.unica else ""]
			aviso_vida = 2.0
		feed.add_child(UI.label(txt, 13, cor))
		while feed.get_child_count() > 6:
			var velho := feed.get_child(0)
			feed.remove_child(velho)
			velho.queue_free()


func _pular() -> void:
	while not sim.done:
		_registrar(sim.step())
	avisos.clear()
	_finalizar()
	_atualizar_ranking()


func _finalizar() -> void:
	if acabou:
		return
	acabou = true
	botoes.visible = false
	var pos := posicao_jogadora()
	info.text = "Chegada! %s terminou em %dº." % [dados.field[0].nome.split(" ")[0], pos]
	continuar.visible = true
	aviso_vida = 0.0
	var meta := ""
	if dados.objetivo > 0:
		meta = "
Objetivo cumprido!" if pos <= dados.objetivo else "
O objetivo era o top %d." % dados.objetivo
	resultado_txt.text = "%s terminou em %dº%s" % [dados.field[0].nome.split(" ")[0], pos, meta]
	resultado.visible = true


func posicao_jogadora() -> int:
	return sim.classificacao().find(0) + 1


func _continuar() -> void:
	if not acabou or emitiu:
		return
	emitiu = true
	terminou.emit(posicao_jogadora())


func _atualizar_ranking() -> void:
	if not acabou:
		var lider: float = 0.0
		for r in sim.rs:
			lider = maxf(lider, r.x)
		var fases := ["Largada", "Meio", "Final", "Sprint"]
		info.text = "%s · %.0f m restantes · %.0f s" % [
			fases[SimCorrida.fase(minf(lider, sim.D - 0.01), sim.D)], maxf(0.0, sim.D - lider), sim.t]
	if linhas.is_empty():
		for i in sim.rs.size():
			var h := UI.hbox(6)
			var bola := ColorRect.new()
			bola.custom_minimum_size = Vector2(12, 12)
			bola.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(bola)
			var l := UI.label("", 14)
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			h.add_child(l)
			ranking.add_child(h)
			linhas.append([bola, l])
	var ordem := sim.classificacao()
	for i in ordem.size():
		var idx: int = ordem[i]
		var g: Dictionary = dados.field[idx]
		var r: Dictionary = sim.rs[idx]
		var extra := ""
		if r.t >= 0.0:
			extra = "  %.1f s" % r.t
		elif r.hp <= 0.0:
			extra = "  sem fôlego"
		linhas[i][0].color = cores[idx]
		var l: Label = linhas[i][1]
		l.text = "%2dº %s · %s%s" % [i + 1, g.nome, g.estilo.to_upper(), extra]
		l.add_theme_color_override("font_color", UI.DESTAQUE if g.jogadora else UI.TEXTO)


## Minimapa: a pista vista de cima, com um ponto por corredora.
class Pista extends Control:
	var tela: TelaCorrida

	func _draw() -> void:
		var largura_m := PistaGeo.RETA + 2.0 * (PistaGeo.RAIO + PistaGeo.LARGURA)
		var altura_m := 2.0 * (PistaGeo.RAIO + PistaGeo.LARGURA)
		var esc := minf(size.x / largura_m, size.y / altura_m) * 0.95
		var c := size / 2.0
		var pts := PackedVector2Array()
		for i in 121:
			pts.append(c + PistaGeo.ponto(PistaGeo.PERIMETRO * i / 120.0, PistaGeo.LARGURA / 2.0) * esc)
		draw_polyline(pts, Color("#2f6b3a"), maxf(3.0, PistaGeo.LARGURA * esc))
		var chegada := PistaGeo.ponto(0.0, 0.0) * esc + c
		draw_line(chegada, chegada + Vector2(0, PistaGeo.LARGURA * esc), Color.WHITE, 2.0)
		var sim: SimCorrida = tela.sim
		for i in range(sim.rs.size() - 1, -1, -1):
			var s := PistaGeo.s_da_corrida(sim.rs[i].x, sim.D)
			var p := c + PistaGeo.ponto(s, Corrida3D.faixa(i)) * esc
			if i == 0:
				draw_circle(p, 6.0, Color.WHITE)
			draw_circle(p, 4.0, tela.cores[i])
