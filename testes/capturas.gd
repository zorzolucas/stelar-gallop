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
			main.mostrar_carreira(main.carreira.treinar("vel"))
		2:
			_salvar("2_carreira")
			while main.carreira.corrida_do_turno().is_empty():
				if main.carreira.energia < 45:
					main.carreira.descansar()
				else:
					main.carreira.treinar(["vel", "est", "pod"][main.carreira.turno % 3])
			main.mostrar_carreira("")
		3:
			_salvar("3_antes_da_corrida")
			main.mostrar_corrida()
			main.tela.velocidade = 2.0
		4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19:
			pass
		20:
			_salvar("4_corrida")
			main.tela._pular()
		21:
			_salvar("5_chegada")
			main.tela._continuar()
		22:
			_salvar("6_depois_da_corrida")
			main.carreira.terminou = true
			main.mostrar_carreira("Fim de teste.")
		23:
			_salvar("7_fim")
			return true
	passo += 1
	return false
