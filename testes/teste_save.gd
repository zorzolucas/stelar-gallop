extends SceneTree
# Carregada em tempo de execução: no modo --script, os autoloads (Dados) só existem
# depois que este script compila, e carreira.gd depende deles.
var CarreiraS: GDScript
## Salva uma carreira no meio, carrega de volta e confere se o estado é o mesmo.
## Uso: Godot --headless --path . --script res://testes/teste_save.gd


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_carreira.json"
	var dados: Node = root.get_node("Dados")
	if dados.iniciais.is_empty():
		dados._ready()
	var ini: Dictionary = dados.iniciais[1]
	var c = CarreiraS.new(dados.garota(ini.nome), ini, 42)
	for i in 7:
		if not c.encontro_atual().is_empty():
			c.escolher(0)
		elif c.energia < 45:
			c.descansar()
		else:
			c.sair() if i % 3 == 0 else c.treinar("int")
	c.salvar()
	var d = CarreiraS.carregar()
	var falhas := []
	for campo in CarreiraS.CAMPOS_SAVE:
		if str(c.get(campo)) != str(d.get(campo)):
			falhas.append("%s: %s != %s" % [campo, c.get(campo), d.get(campo)])
	if c.semente != d.semente:
		falhas.append("semente")
	# depois de carregar, as duas devem seguir iguais
	c.treinar("vel")
	d.treinar("vel")
	if str(c.attrs) != str(d.attrs):
		falhas.append("treino depois de carregar diverge")
	CarreiraS.apagar_save()
	print("SAVE OK" if falhas.is_empty() else "SAVE FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
