class_name UI
extends RefCounted
## Atalhos para montar a interface placeholder em código.

const FUNDO := Color("#141824")
const PAINEL := Color("#1f2536")
const TEXTO := Color("#e9ecf5")
const SUAVE := Color("#9aa3b8")
const DESTAQUE := Color("#f2c14e")
const PERIGO := Color("#e5534b")
const OK := Color("#4caf7d")


## Rótulo de uma linha. Use quebra = true para textos longos (ocupa a largura disponível).
static func label(texto: String, tamanho: int = 16, cor: Color = TEXTO, quebra: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if quebra:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 120
	return l


static func botao(texto: String, acao: Callable, tamanho: int = 16) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tamanho)
	b.pressed.connect(acao)
	b.focus_mode = Control.FOCUS_NONE
	return b


static func painel(cor: Color = PAINEL, margem: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(margem)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func barra(valor: float, maximo: float, cor: Color, largura: float = 220.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(largura, 16)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#2b3247")
	fundo.set_corner_radius_all(4)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	cheio.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", fundo)
	b.add_theme_stylebox_override("fill", cheio)
	return b


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margem(filho: Control, m: int = 24) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, m)
	mc.add_child(filho)
	return mc


## Retrato placeholder: círculo com a inicial.
static func retrato(nome: String, cor: Color, tamanho: float = 72.0) -> Control:
	var c := Retrato.new()
	c.letra = nome.substr(0, 1)
	c.cor = cor
	c.custom_minimum_size = Vector2(tamanho, tamanho)
	return c


class Retrato extends Control:
	var letra := "?"
	var cor := Color.WHITE

	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0
		draw_circle(size / 2.0, r, cor)
		draw_circle(size / 2.0, r * 0.82, cor.darkened(0.35))
		var f := get_theme_default_font()
		var fs := int(r)
		var ts := f.get_string_size(letra, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, size / 2.0 + Vector2(-ts.x / 2.0, fs * 0.35), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
