class_name TelaFim
extends Control
## Fim da carreira (GDD §4.8): moeda recebida e a escolha entre substituir a versão
## salva da garota ou descartar o resultado.

signal decidiu(substituir: bool)

var c: Carreira
var msg: String
var salva: Dictionary   # versão salva atual (vazio se ainda não tem)


func _init(carreira: Carreira, mensagem: String, salva_atual: Dictionary) -> void:
	c = carreira
	msg = mensagem
	salva = salva_atual


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
	for r in c.resultados:
		var cor := UI.OK if r.ok else UI.PERIGO
		pv.add_child(UI.label("Semana %d · %s: %dº (objetivo top %d)" % [r.turno, r.nome, r.posicao, r.objetivo], 17, cor))
	var m := c.moeda_total()
	pv.add_child(UI.label("Moeda: %d dos prêmios + %d de bônus por desempenho = %d" % [m.corridas, m.bonus, m.total], 18, UI.DESTAQUE))
	p.add_child(pv)
	v.add_child(p)

	# comparação entre a versão salva e a nova
	var comp := UI.painel()
	var grade := GridContainer.new()
	grade.columns = 7
	grade.add_theme_constant_override("h_separation", 22)
	for t in ["", "Nota", "Vel", "Est", "Pod", "Det", "Int"]:
		grade.add_child(UI.label(t, 15, UI.SUAVE))
	var nova := c.versao_salva()
	for linha in [["Nova", nova], ["Salva", salva]]:
		grade.add_child(UI.label(linha[0], 16))
		var d: Dictionary = linha[1]
		if d.is_empty():
			grade.add_child(UI.label("—", 16, UI.SUAVE))
			for k in SimCorrida.KEYS:
				grade.add_child(UI.label("—", 16, UI.SUAVE))
			continue
		grade.add_child(UI.label(d.nota, 16, UI.DESTAQUE))
		for k in SimCorrida.KEYS:
			var val: int = int(d.attrs[k])
			var cor := UI.TEXTO
			if linha[0] == "Nova" and not salva.is_empty():
				cor = UI.OK if val > int(salva.attrs[k]) else (UI.PERIGO if val < int(salva.attrs[k]) else UI.TEXTO)
			grade.add_child(UI.label(str(val), 16, cor))
	comp.add_child(grade)
	v.add_child(comp)

	v.add_child(UI.label("Fica uma versão salva por garota. Ela é a que vai correr nas copas do circuito (em breve). A moeda você recebe de qualquer jeito, e a pool gira.", 15, UI.SUAVE, true))
	var botoes := UI.hbox(12)
	botoes.add_child(UI.botao("Substituir a versão salva" if not salva.is_empty() else "Salvar esta versão", func(): decidiu.emit(true), 20))
	botoes.add_child(UI.botao("Descartar o resultado", func(): decidiu.emit(false), 20))
	v.add_child(botoes)
	add_child(UI.margem(v, 40))
