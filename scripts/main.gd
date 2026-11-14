extends Control
## Controla o fluxo do jogo:
## primeira garota → academia ⇄ pool; academia → carreira ⇄ corrida → fim → academia.
## A carreira é salva a cada mudança de estado e o perfil (moeda, elenco, pool) a cada
## tiragem e fim de carreira (GDD §10).

var perfil: Perfil
var carreira: Carreira
var tela: Control


func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = UI.FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	perfil = Perfil.carregar()
	if perfil == null:
		mostrar_escolha()
	else:
		mostrar_academia()


func _trocar(nova: Control) -> void:
	if tela:
		tela.queue_free()
	tela = nova
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tela)


func mostrar_escolha() -> void:
	var t := TelaEscolha.new()
	t.escolheu.connect(_primeira_garota)
	_trocar(t)


func _primeira_garota(ini: Dictionary) -> void:
	perfil = Perfil.novo(ini.nome)
	mostrar_academia("%s entrou para a academia! Você tem %d moedas para conhecer outras garotas na pool." % [
		ini.nome, perfil.moeda])


func mostrar_academia(msg: String = "") -> void:
	var t := TelaAcademia.new(perfil, msg)
	t.treinar.connect(_comecar_carreira)
	t.continuar.connect(_continuar_carreira)
	t.abrir_pool.connect(mostrar_pool)
	_trocar(t)


func mostrar_pool() -> void:
	var t := TelaPool.new(perfil)
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t)


func _comecar_carreira(nome: String) -> void:
	var ini := Dados.config_carreira(nome)
	carreira = Carreira.new(Dados.garota(nome), ini, 0, perfil.elenco[nome].vinculo)
	var extra := ""
	if carreira.vinculo > 0:
		extra = " Vínculo %d: +%d em cada atributo e limite de %d." % [
			carreira.vinculo, Carreira.BAL.vinculo_attr * carreira.vinculo, carreira.limite]
	mostrar_carreira("Começa a carreira de %s! 24 semanas até o Grande Prêmio Estelar.%s" % [carreira.nome, extra])


func _continuar_carreira() -> void:
	carreira = Carreira.carregar()
	if carreira == null:
		Carreira.apagar_save()
		mostrar_academia("Não consegui ler a carreira salva.")
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
	var salva: Dictionary = perfil.elenco.get(carreira.nome, {}).get("salva", {})
	var t := TelaFim.new(carreira, msg, salva)
	t.decidiu.connect(_concluir)
	_trocar(t)


func _concluir(substituir: bool) -> void:
	var m := carreira.moeda_total()
	perfil.concluir_carreira(carreira, substituir)
	Carreira.apagar_save()
	var txt := "Você recebeu %d moedas. " % m.total
	txt += "A nova versão de %s foi salva. " % carreira.nome if substituir else "O resultado foi descartado. "
	txt += "A pool girou: há garotas novas na rotação."
	carreira = null
	mostrar_academia(txt)
