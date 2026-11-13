class_name TelaFim
extends Control
## Resumo do fim da carreira (GDD §4.8, sem pool e sem save no protótipo).

signal recomecar

var c: Carreira
var msg: String


func _init(carreira: Carreira, mensagem: String) -> void:
	c = carreira
	msg = mensagem


func _ready() -> void:
	var v := UI.vbox(14)
	var titulo := "Carreira encerrada" if c.falhou_objetivo else "Carreira concluída!"
	v.add_child(UI.label(titulo, 36, UI.PERIGO if c.falhou_objetivo else UI.DESTAQUE))
	if msg != "":
		v.add_child(UI.label(msg, 18, UI.TEXTO, true))
	var p := UI.painel()
	var pv := UI.vbox(8)
	var topo := UI.hbox(12)
	topo.add_child(UI.retrato(c.nome, c.cor, 72))
	var nomes := UI.vbox(2)
	nomes.add_child(UI.label(c.nome, 26))
	nomes.add_child(UI.label("Nota final %s" % Dados.nota(c.attrs), 20, UI.DESTAQUE))
	topo.add_child(nomes)
	pv.add_child(topo)
	var partes := []
	for k in SimCorrida.KEYS:
		partes.append("%s %d" % [Dados.ATTR_CURTO[k], c.attrs[k]])
	pv.add_child(UI.label(" · ".join(partes), 18))
	pv.add_child(HSeparator.new())
	for r in c.resultados:
		var cor := UI.OK if r.ok else UI.PERIGO
		pv.add_child(UI.label("Semana %d · %s: %dº (objetivo top %d)" % [r.turno, r.nome, r.posicao, r.objetivo], 17, cor))
	p.add_child(pv)
	v.add_child(p)
	v.add_child(UI.label("No jogo completo, aqui você decide se esta versão substitui a salva e ganha moeda para a pool.", 15, UI.SUAVE, true))
	var b := UI.botao("Nova carreira", func(): recomecar.emit(), 20)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b)
	add_child(UI.margem(v, 40))
