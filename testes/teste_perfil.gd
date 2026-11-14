extends SceneTree
## Testa a pool, a garantia, o vínculo e o save do perfil.
## Uso: Godot --headless --path . --script res://testes/teste_perfil.gd
# Carregados em tempo de execução: no modo --script, os autoloads (Dados) só existem
# depois que este script compila.
var PerfilS: GDScript
var CarreiraS: GDScript
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _initialize() -> void:
	PerfilS = load("res://scripts/perfil.gd")
	CarreiraS = load("res://scripts/carreira.gd")
	PerfilS.CAMINHO = "user://teste_perfil.json"
	var dados: Node = root.get_node("Dados")
	if dados.iniciais.is_empty():
		dados._ready()

	var p = PerfilS.novo("Lira Alazã")
	_checar(p.moeda == 300, "moeda inicial")
	_checar(p.pool.size() == 5, "pool com 5")
	var mvp: int = p.pool.filter(func(n): return dados.garota(n).get("mvp", false)).size()
	_checar(mvp == 2, "2 garotas completas na pool (veio %d)" % mvp)

	# garantia: a marcada vem em no máximo 10 tiragens
	p.moeda = 100000
	var alvo: String = p.pool[4]
	p.escolher(alvo)
	var maior_seca := 0
	var seca := 0
	for i in 300:
		var r: Dictionary = p.tirar()
		if r.nome == alvo:
			maior_seca = maxi(maior_seca, seca)
			seca = 0
		else:
			seca += 1
	_checar(maior_seca <= 9, "garantia (maior seca %d)" % maior_seca)
	_checar(p.elenco[alvo].vinculo == 5, "vínculo para no 5")
	for n in p.pool:
		_checar(p.elenco.has(n), "toda a pool entrou no elenco depois de 300 tiragens")

	# save e load
	p.salvar()
	var q = PerfilS.carregar()
	_checar(q.moeda == p.moeda and q.elenco.size() == p.elenco.size() and q.pool == p.pool
		and q.escolhida == p.escolhida and q.tiragens == p.tiragens, "save/load do perfil")

	# fim de carreira: moeda, versão salva e giro da pool
	var c = CarreiraS.new(dados.garota("Lira Alazã"), dados.config_carreira("Lira Alazã"), 7, 2)
	_checar(c.limite == 1080.0, "limite com vínculo 2")
	_checar(c.attrs.vel == 110.0 + 16.0, "atributos iniciais com vínculo 2")
	c.resultados.append({"turno": 12, "nome": "x", "posicao": 2, "objetivo": 5, "ok": true})
	c.moeda_corridas = 30
	var antes: int = q.moeda
	var pool_antes: Array = q.pool.duplicate()
	q.concluir_carreira(c, true)
	_checar(q.moeda == antes + 30 + 80 + 60, "moeda do fim de carreira")
	_checar(q.elenco["Lira Alazã"].salva.nota != "", "versão salva guardada")
	_checar(q.giro == 1 and q.pool != pool_antes, "pool girou")

	# garota só-dados também tem configuração de carreira
	var cfg: Dictionary = dados.config_carreira("Altair Castanha")
	_checar(cfg.distancia == "sprint" and cfg.piso == "grama" and cfg.naturais.size() == 2, "config de garota só-dados")

	PerfilS.apagar()
	print("PERFIL OK" if falhas.is_empty() else "PERFIL FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
