extends Control
## Controla o fluxo do protótipo: escolha → carreira ⇄ corrida → fim.
## Salva a carreira automaticamente a cada mudança de estado (GDD §10).

var carreira: Carreira
var tela: Control


func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = UI.FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	mostrar_escolha()


func _trocar(nova: Control) -> void:
	if tela:
		tela.queue_free()
	tela = nova
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tela)


func mostrar_escolha() -> void:
	var t := TelaEscolha.new()
	t.escolheu.connect(_comecar_carreira)
	t.continuar.connect(_continuar_carreira)
	_trocar(t)


func _comecar_carreira(ini: Dictionary) -> void:
	carreira = Carreira.new(Dados.garota(ini.nome), ini)
	mostrar_carreira("Começa a carreira de %s! 24 semanas até o Grande Prêmio Estelar." % carreira.nome)


func _continuar_carreira() -> void:
	carreira = Carreira.carregar()
	if carreira == null:
		Carreira.apagar_save()
		mostrar_escolha()
		return
	mostrar_carreira("Carreira carregada. Bem-vinda de volta, %s!" % carreira.nome.split(" ")[0])


func mostrar_carreira(msg: String = "") -> void:
	carreira.salvar()
	if carreira.terminou:
		mostrar_fim(msg)
		return
	var t := TelaCarreira.new(carreira, msg)
	t.ir_correr.connect(mostrar_corrida)
	t.atualizou.connect(func(m): mostrar_carreira(m))
	_trocar(t)


func mostrar_corrida() -> void:
	var dados := carreira.montar_corrida(Dados.garotas)
	var t := TelaCorrida.new(dados, carreira.cor)
	t.terminou.connect(func(pos): mostrar_carreira(carreira.registrar_corrida(pos)))
	_trocar(t)


func mostrar_fim(msg: String) -> void:
	var t := TelaFim.new(carreira, msg)
	t.recomecar.connect(mostrar_escolha)
	_trocar(t)
