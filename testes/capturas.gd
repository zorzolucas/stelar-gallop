extends SceneTree
## Abre o jogo, passa pelas telas sozinho e salva capturas em testes/capturas/.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas.gd

var main: Node
var passo := 0
var espera := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)


func _salvar(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)


func _process(_delta: float) -> bool:
	espera += 1
	if espera < 20:
		return false
	espera = 0
	match passo:
		0:
			_salvar("1_escolha")
			main._comecar_carreira(root.get_node("Dados").iniciais[0])
		1:
			main.carreira.treinar("vel")
			main.carreira.treinar("vel")
			main.carreira.treinar("est")
			main.carreira.treinar("pod")
			main.carreira.treinar("vel")
			main.carreira.afinidade["Antares Zaina"] = 35
			main.carreira.duplas = {"pod": "Antares Zaina"}
			for e in root.get_node("Dados").encontros.encontros:
				if e.id == "lira_refeitorio":
					main.carreira._abrir_encontro(e)
			main.mostrar_carreira("Treino de Velocidade: +41 Vel, +15 Pod.")
		2:
			_salvar("2a_encontro")
			main.mostrar_carreira(main.carreira.escolher(0))
		3:
			_salvar("2_carreira")
			while main.carreira.corrida_do_turno().is_empty():
				if main.carreira.energia < 45:
					main.carreira.descansar()
				else:
					main.carreira.treinar(["vel", "est", "pod"][main.carreira.turno % 3])
			main.carreira.encontro_pendente = {}
			main.mostrar_carreira("")
		4:
			_salvar("3_antes_da_corrida")
			main.mostrar_corrida()
			main.tela.velocidade = 2.0
		5, 6, 7, 8, 10, 12, 14, 16, 18, 20:
			pass
		9:
			_salvar("4a_camera_auto")
			main.tela._usar_camera(1)
		11:
			_salvar("4b_camera_acompanhar")
			main.tela._usar_camera(2)
		13:
			_salvar("4c_camera_lateral")
			main.tela._usar_camera(3)
		15:
			_salvar("4d_camera_frente")
			main.tela._usar_camera(4)
		17:
			_salvar("4e_camera_aerea")
			main.tela._usar_camera(0)
		19:
			_salvar("4_corrida")
		21:
			main.tela._pular()
		22:
			_salvar("5_chegada")
			main.tela._continuar()
		23:
			_salvar("6_depois_da_corrida")
			main.carreira.terminou = true
			main.mostrar_carreira("Fim de teste.")
		24:
			_salvar("7_fim")
			return true
	passo += 1
	return false
