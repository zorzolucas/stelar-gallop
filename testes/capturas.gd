extends SceneTree
## Abre o jogo, passa pelas telas sozinho e salva capturas em testes/capturas/.
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas.gd

var main: Node
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
	var dados: Node = root.get_node("Dados")
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
			main._comecar_carreira("Lira Alazã")
			var c = main.carreira
			for t in ["vel", "vel", "est", "pod", "vel"]:
				c.treinar(t)
			c.afinidade["Antares Zaina"] = 35
			c.duplas = {"pod": "Antares Zaina"}
			for e in dados.encontros.encontros:
				if e.id == "lira_refeitorio":
					c._abrir_encontro(e)
			main.mostrar_carreira("Treino de Velocidade: +41 Vel, +15 Pod."),
		func():
			_salvar("2a_encontro")
			main.mostrar_carreira(main.carreira.escolher(0)),
		func():
			_salvar("2_carreira")
			var c = main.carreira
			while c.corrida_do_turno().is_empty():
				if c.energia < 45:
					c.descansar()
				else:
					c.treinar(["vel", "est", "pod"][c.turno % 3])
			c.encontro_pendente = {}
			main.mostrar_carreira(""),
		func():
			_salvar("3_antes_da_corrida")
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
			_salvar("6_depois_da_corrida")
			# pula direto para o fim da carreira
			main.carreira.terminou = true
			main.mostrar_carreira("Fim de teste."),
		func():
			_salvar("7_fim")
			main._concluir(true),
		func():
			_salvar("8_academia_depois"),
	]


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
