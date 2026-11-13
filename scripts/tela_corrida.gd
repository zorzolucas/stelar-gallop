class_name TelaCorrida
extends Control
## Corrida top-down numa pista oval (GDD §5.4): ranking ao vivo, avisos de
## habilidade e botões 1x / 2x / pular. O jogador só assiste.

signal terminou(posicao: int)

## Passos de simulação (0,1 s) por segundo real em 1x. 40 = corrida 4x mais rápida que o tempo real.
const PASSOS_1X := 40.0
const CORES := ["#c9a227", "#8e6cc9", "#c9568e", "#4fa3a5", "#b0764a", "#7f8fa6",
				"#a3b14f", "#d07a4a", "#5c7fb8", "#9a5bb0", "#6aa86a"]

var dados: Dictionary
var cor_jogadora: Color
var sim: SimCorrida
var cores: Array = []
var velocidade := 1.0
var acumulado := 0.0
var acabou := false
var avisos: Array = []   # [{idx, texto, vida}]
var linhas: Array = []   # [ColorRect, Label] por posição do ranking

var pista: Pista
var ranking: VBoxContainer
var info: Label
var feed: VBoxContainer
var botoes: HBoxContainer
var continuar: Button


func _init(d: Dictionary, cor: Color) -> void:
	dados = d
	cor_jogadora = cor
	sim = SimCorrida.new(d.field, d.distancia)
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
	var titulo := UI.label("%s · %d m · objetivo top %d" % [dados.nome, dados.distancia, dados.objetivo], 22, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	botoes = UI.hbox(6)
	botoes.add_child(UI.botao("1x", func(): velocidade = 1.0))
	botoes.add_child(UI.botao("2x", func(): velocidade = 2.0))
	botoes.add_child(UI.botao("Pular", _pular))
	topo.add_child(botoes)
	raiz.add_child(topo)

	var meio := UI.hbox(16)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pista = Pista.new()
	pista.tela = self
	pista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_child(pista)

	var lado := UI.painel()
	lado.custom_minimum_size.x = 300
	var lv := UI.vbox(6)
	info = UI.label("", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(info)
	ranking = UI.vbox(2)
	lv.add_child(ranking)
	lv.add_child(HSeparator.new())
	lv.add_child(UI.label("Habilidades", 14, UI.SUAVE))
	feed = UI.vbox(2)
	lv.add_child(feed)
	lado.add_child(lv)
	meio.add_child(lado)
	raiz.add_child(meio)

	continuar = UI.botao("Continuar", _continuar, 20)
	continuar.visible = false
	raiz.add_child(continuar)
	add_child(UI.margem(raiz, 20))
	_atualizar_ranking()


func _process(delta: float) -> void:
	if not acabou:
		acumulado += delta * PASSOS_1X * velocidade
		while acumulado >= 1.0 and not sim.done:
			acumulado -= 1.0
			_registrar(sim.step())
		if sim.done:
			_finalizar()
		_atualizar_ranking()
	for a in avisos:
		a.vida -= delta
	avisos = avisos.filter(func(a): return a.vida > 0.0)
	pista.queue_redraw()


func _registrar(ev: Array) -> void:
	for e in ev:
		var g: Dictionary = dados.field[e.idx]
		avisos.append({"idx": e.idx, "texto": e.nome, "vida": 1.6})
		var txt := "%s: %s" % [g.nome.split(" ")[0], e.nome]
		var cor := UI.DESTAQUE if g.jogadora else UI.SUAVE
		if e.unica:
			txt += " ★"
		feed.add_child(UI.label(txt, 13, cor))
		while feed.get_child_count() > 8:
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


func posicao_jogadora() -> int:
	return sim.classificacao().find(0) + 1


func _continuar() -> void:
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


## Desenho da pista oval e das corredoras.
class Pista extends Control:
	var tela: TelaCorrida

	func _geom() -> Dictionary:
		var m := 40.0
		var w := size.x - 2.0 * m
		var h := size.y - 2.0 * m
		var raio := minf(h / 2.0, w / 3.0)
		var reta := w - 2.0 * raio
		return {"c": size / 2.0, "raio": raio, "reta": reta}

	## Ponto na pista para a fração u da volta (0 = linha de chegada, sentido anti-horário
	## na tela: reta de baixo da direita para a esquerda... aqui, da esquerda para a direita).
	func ponto(u: float, deslocamento: float) -> Vector2:
		var g := _geom()
		var c: Vector2 = g.c
		var raio: float = g.raio + deslocamento
		var reta: float = g.reta
		var perim: float = 2.0 * reta + 2.0 * PI * g.raio
		var s: float = fposmod(u, 1.0) * perim
		# começa no meio da reta de baixo, indo para a direita
		var meia := reta / 2.0
		if s < meia:
			return c + Vector2(s, raio)
		s -= meia
		var arco: float = PI * g.raio
		if s < arco:
			var a: float = PI / 2.0 - s / g.raio
			return c + Vector2(meia, 0) + Vector2(cos(a), sin(a)) * raio
		s -= arco
		if s < reta:
			return c + Vector2(meia - s, -raio)
		s -= reta
		if s < arco:
			var a: float = -PI / 2.0 - s / g.raio
			return c + Vector2(-meia, 0) + Vector2(cos(a), sin(a)) * raio
		s -= arco
		return c + Vector2(-meia + s, raio)

	func _draw() -> void:
		var g := _geom()
		var c: Vector2 = g.c
		var meia: float = g.reta / 2.0
		var largura := 70.0
		# gramado da pista
		var cor_pista := Color("#2f6b3a")
		_estadio(c, meia, g.raio + largura / 2.0, cor_pista)
		_estadio(c, meia, g.raio - largura / 2.0, UI.FUNDO.lightened(0.05))
		# linha de chegada
		var p1 := c + Vector2(0, g.raio - largura / 2.0)
		draw_line(p1, p1 + Vector2(0, largura), Color.WHITE, 3.0)
		# volta: a chegada fica na linha; a largada é recuada para que a distância feche nela
		var escala := 1000.0  # metros por volta desenhada (menor = pelotão mais espalhado na tela)
		var sim: SimCorrida = tela.sim
		var ordem := sim.classificacao()
		var pos_jog := Vector2.ZERO
		for i in range(ordem.size() - 1, -1, -1):
			var idx: int = ordem[i]
			var r: Dictionary = sim.rs[idx]
			var u := (minf(r.x, sim.D) - sim.D) / escala
			var pos := ponto(u, -largura / 2.0 + 8.0 + float(idx % 6) * 10.0)
			if tela.dados.field[idx].jogadora:
				pos_jog = pos
			else:
				draw_circle(pos, 7.0, tela.cores[idx])
		# a jogadora por cima de todas, com contorno e seta
		draw_circle(pos_jog, 12.0, Color.WHITE)
		draw_circle(pos_jog, 9.0, tela.cores[0])
		var u_jog := (minf(sim.rs[0].x, sim.D) - sim.D) / escala
		var ponta := ponto(u_jog, largura / 2.0 + 4.0)
		var base := ponto(u_jog, largura / 2.0 + 18.0)
		var lado := (ponta - base).orthogonal().normalized() * 7.0
		draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), UI.DESTAQUE)
		for a in tela.avisos:
			var r: Dictionary = sim.rs[a.idx]
			var u := (minf(r.x, sim.D) - sim.D) / escala
			var pos := ponto(u, -largura / 2.0 - 18.0) + Vector2(-80, 4)
			var f := get_theme_default_font()
			var cor := UI.DESTAQUE if tela.dados.field[a.idx].jogadora else Color(1, 1, 1, 0.75)
			cor.a = clampf(a.vida, 0.0, 1.0)
			draw_string(f, pos, a.texto, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, cor)

	func _estadio(c: Vector2, meia: float, raio: float, cor: Color) -> void:
		draw_rect(Rect2(c.x - meia, c.y - raio, 2.0 * meia, 2.0 * raio), cor)
		draw_circle(c + Vector2(meia, 0), raio, cor)
		draw_circle(c - Vector2(meia, 0), raio, cor)
