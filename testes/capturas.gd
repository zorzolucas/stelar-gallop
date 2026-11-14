extends SceneTree
## Abre o jogo, passa pelas telas sozinho e salva capturas em testes/capturas/.
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas.gd

var main: Node
var dados: Node
var passo := 0
var espera := 0
var passos: Array[Callable] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://captura_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://captura_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	dados = root.get_node("Dados")
	passos = [
		func():
			_salvar("1_escolha")
			main._primeira_garota(dados.iniciais[0]),
		func():
			_salvar("1b_academia")
			main.mostrar_pool(),
		func():
			main.tela._tirar()
			main.tela._tirar(),
		func():
			_salvar("1c_pool")
			main._comecar_carreira("Lira")
			var c = main.carreira
			for t in ["vel", "est", "vel"]:
				c.encontro_pendente = {}
				c.treinar(t)
			c.afinidade["Antares"] = 35
			c.duplas = {"pod": "Antares"}
			for e in dados.encontros.encontros:
				if e.id == "lira_refeitorio":
					c._abrir_encontro(e, RandomNumberGenerator.new())
			main.mostrar_carreira("Treino de Velocidade: +60 Vel, +22 Pod."),
		func():
			_salvar("2a_encontro")
			main.mostrar_carreira(main.carreira.escolher(0)),
		func():
			_salvar("2_objetivo_estreia")
			main.mostrar_corrida()
			main.tela.velocidade = 2.0,
		func(): pass,
		func(): pass,
		func():
			_salvar("4a_camera_auto")
			main.tela._usar_camera(1),
		func(): pass,
		func():
			_salvar("4b_camera_acompanhar")
			main.tela._usar_camera(4),
		func(): pass,
		func():
			_salvar("4e_camera_aerea")
			main.tela._pular(),
		func():
			_salvar("5_chegada")
			main.tela._continuar(),
		func():
			_resolver_encontro()
			main.mostrar_carreira(""),
		func():
			_salvar("5b_amuleto")
			var c = main.carreira
			if not c.oferta_amuleto.is_empty():
				c.escolher_amuleto(c.oferta_amuleto[0])
			c.pontos += 300
			main.mostrar_carreira(""),
		func():
			_salvar("6_mapa")
			var c = main.carreira
			var cols: Array = c.opcoes_mapa()
			var escolha: int = cols[0]
			for col in cols:
				if c.mapas[c.trecho()][0][col].tipo == "circuito":
					escolha = col
			main.mostrar_carreira(c.escolher_no(escolha))
			_resolver_encontro()
			main.mostrar_carreira(""),
		func():
			_salvar("7_turno_com_rota")
			_avancar_ate(21)
			main.mostrar_carreira(""),
		func():
			_salvar("8_ferias")
			main.carreira.terminou = true
			main.mostrar_carreira("Fim de teste."),
		func():
			_salvar("9_fim")
			main._concluir(true),
		func():
			_salvar("10_academia_depois"),
	]


func _resolver_encontro() -> void:
	var c = main.carreira
	while not c.encontro_pendente.is_empty():
		c.escolher(0)


## Joga sozinho (sem tela) até o turno pedido, para chegar às férias.
func _avancar_ate(alvo: int) -> void:
	var c = main.carreira
	var guard := 0
	while c.turno < alvo and not c.terminou and guard < 300:
		guard += 1
		match c.pendencia():
			"encontro": c.escolher(0)
			"mapa": c.escolher_no(c.opcoes_mapa()[0])
			"ferias": c.escolher_acampamento("praia")
			"corrida", "objetivo":
				var d = c.montar_corrida(dados.garotas)
				var sim := SimCorrida.new(d.field, d.distancia, d.seed, d.clima)
				var pos: int = sim.rodar_ate_o_fim().find(0) + 1
				c.registrar_corrida(maxi(1, pos - 4))  # empurra para cumprir os objetivos
			"amuleto": c.escolher_amuleto(c.oferta_amuleto[0], c.amuletos[0] if c.amuletos.size() >= 6 else "")
			"sem_fama": c.fama = 2000
			_:
				if c.energia < 45:
					c.descansar()
				else:
					c.treinar(["vel", "est", "pod"][c.turno % 3])


func _salvar(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)


func _process(_delta: float) -> bool:
	espera += 1
	if espera < 20:
		return false
	espera = 0
	if passo >= passos.size():
		load("res://scripts/perfil.gd").apagar()
		load("res://scripts/carreira.gd").apagar_save()
		return true
	passos[passo].call()
	passo += 1
	return false
