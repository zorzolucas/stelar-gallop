class_name Perfil
extends RefCounted
## Progresso que passa de uma carreira para outra: moeda, elenco (vínculo e versão salva
## de cada garota) e a pool semanal (GDD §2, §3.5, §4.8 e §6). Salvo em user://perfil.json.

## Os testes trocam o caminho para não mexer no perfil de verdade.
static var CAMINHO := "user://perfil.json"
const BAL := {
	"moeda_inicial": 300,      # dá para 3 tiragens no começo (GDD §8)
	"custo_tiragem": 100,
	"garantia": 10,            # tiragens sem a escolhida até ela vir garantida
	"tamanho_pool": 5,
	"mvp_na_pool": 2,          # quantas garotas completas (com eventos) entram em cada rotação
	"vinculo_max": 5,
}

var moeda := 0
var elenco := {}             # nome -> {vinculo: int, salva: Dictionary (vazio se ainda não correu)}
var pool := []               # nomes da rotação atual
var escolhida := ""          # garota marcada para a garantia
var sem_escolhida := 0       # tiragens seguidas sem a escolhida
var giro := 0                # quantas vezes a pool girou (= carreiras concluídas)
var semente := 0
var tiragens := 0


static func existe() -> bool:
	return FileAccess.file_exists(CAMINHO)


static func novo(inicial: String) -> Perfil:
	var p := Perfil.new()
	p.semente = randi()
	p.moeda = BAL.moeda_inicial
	p.elenco[inicial] = {"vinculo": 0, "salva": {}}
	p.girar_pool(false)
	p.salvar()
	return p


static func carregar() -> Perfil:
	if not existe():
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	if not d is Dictionary:
		return null
	var p := Perfil.new()
	p.moeda = int(d.get("moeda", 0))
	# saves antigos usavam nome e sobrenome ("Lira Alazã"); hoje é só o nome
	var elenco: Dictionary = d.get("elenco", {})
	for n in elenco:
		p.elenco[n.split(" ")[0]] = elenco[n]
	for n in p.elenco:
		p.elenco[n].vinculo = int(p.elenco[n].vinculo)
	p.pool = d.get("pool", []).map(func(n): return n.split(" ")[0])
	p.escolhida = d.get("escolhida", "").split(" ")[0]
	p.sem_escolhida = int(d.get("sem_escolhida", 0))
	p.giro = int(d.get("giro", 0))
	p.semente = int(str(d.get("semente", "0")))
	p.tiragens = int(d.get("tiragens", 0))
	return p


func salvar() -> void:
	var d := {"versao": 1, "moeda": moeda, "elenco": elenco, "pool": pool, "escolhida": escolhida,
		"sem_escolhida": sem_escolhida, "giro": giro, "semente": str(semente), "tiragens": tiragens}
	var f := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  ", false))


static func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO))


func _dados() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Dados")


# ---------- pool (GDD §6) ----------

## Sorteia a rotação nova: algumas garotas completas do MVP e o resto do elenco só-dados.
## A semana gira a cada carreira concluída, não pelo relógio real.
func girar_pool(contar := true) -> void:
	if contar:
		giro += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([semente, giro])
	var dados := _dados()
	var mvp := []
	var outras := []
	for g in dados.garotas:
		(mvp if g.get("mvp", false) else outras).append(g.nome)
	var nova := []
	for lista in [[mvp, BAL.mvp_na_pool], [outras, BAL.tamanho_pool - BAL.mvp_na_pool]]:
		var nomes: Array = lista[0].duplicate()
		for i in lista[1]:
			if nomes.is_empty():
				break
			nova.append(nomes.pop_at(rng.randi() % nomes.size()))
	pool = nova
	if not escolhida in pool:
		escolhida = pool[0]
		sem_escolhida = 0


func escolher(nome: String) -> void:
	if nome in pool and nome != escolhida:
		escolhida = nome
		sem_escolhida = 0
		salvar()


## Chances visíveis (GDD §6): todas iguais.
func chance(_nome: String) -> float:
	return 1.0 / max(1, pool.size())


func faltam_para_garantia() -> int:
	return BAL.garantia - sem_escolhida


func pode_tirar() -> bool:
	return moeda >= BAL.custo_tiragem and not pool.is_empty()


## Uma tiragem. Devolve {nome, nova: bool, vinculo, garantida: bool, vinculo_max: bool}.
func tirar() -> Dictionary:
	if not pode_tirar():
		return {}
	moeda -= BAL.custo_tiragem
	tiragens += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([semente, giro, tiragens])
	var garantida := sem_escolhida + 1 >= BAL.garantia
	var nome: String = escolhida if garantida else pool[rng.randi() % pool.size()]
	if nome == escolhida:
		sem_escolhida = 0
	else:
		sem_escolhida += 1
	var r := {"nome": nome, "garantida": garantida, "nova": false, "vinculo_max": false}
	if not elenco.has(nome):
		elenco[nome] = {"vinculo": 0, "salva": {}}
		r.nova = true
	elif elenco[nome].vinculo < BAL.vinculo_max:
		elenco[nome].vinculo += 1
	else:
		# vínculo já no máximo: devolve metade da moeda
		moeda += BAL.custo_tiragem / 2
		r.vinculo_max = true
	r.vinculo = elenco[nome].vinculo
	salvar()
	return r


# ---------- fim de carreira (GDD §4.8) ----------

## Recebe a moeda da carreira, guarda (ou não) a nova versão e gira a pool.
func concluir_carreira(c: Carreira, substituir: bool) -> void:
	moeda += c.moeda_total().total
	if substituir and elenco.has(c.nome):
		elenco[c.nome].salva = c.versao_salva()
	girar_pool()
	salvar()
