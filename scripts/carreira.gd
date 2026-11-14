class_name Carreira
extends RefCounted
## Estado e regras da carreira (GDD §4), versão curta do protótipo.
## Todos os números de BAL são (inicial): pontos de partida para balancear.

const BAL := {
	"turnos": 24,
	"corridas": {12: {"nome": "Taça de Outono", "objetivo": 5, "media_rivais": 170.0},
				 24: {"nome": "Grande Prêmio Estelar", "objetivo": 3, "media_rivais": 270.0}},
	"ganho_principal": 38.0,
	"ganho_secundario": 14.0,
	"bonus_nivel": 0.15,       # por nível de treino acima do 1
	"usos_por_nivel": 3,       # repetições para subir o nível do treino
	"bonus_natural": 0.10,
	"custo_energia": 22,
	"custo_energia_int": 5,
	"descanso": 55,
	"sair_energia": 12,
	"limite_falha": 40,
	"falha_max": 0.6,          # chance de falha com energia 0
	"perda_falha": 10.0,
	"chance_lesao": 0.35,
	"corte_lesao": 0.5,
	"limite_attr": 1000.0,
}
const TREINOS := {
	"vel": {"principal": "vel", "secundario": "pod"},
	"est": {"principal": "est", "secundario": "det"},
	"pod": {"principal": "pod", "secundario": "est"},
	"det": {"principal": "det", "secundario": "vel"},
	"int": {"principal": "int", "secundario": "vel"},
}
const HUMOR_NOME := ["Péssimo", "Mal", "Normal", "Bem", "Ótimo"]
const HUMOR_CORRIDA := [0.95, 0.975, 1.0, 1.025, 1.05]
const HUMOR_TREINO := [0.8, 0.9, 1.0, 1.1, 1.2]

var nome: String
var estilo: String
var aptidao: Dictionary
var naturais: Array
var unica: String
var cor: Color
var distancia: String
var piso: String

var attrs := {}
var energia := 100
var humor := 2
var lesionada := false
var turno := 1
var usos_treino := {"vel": 0, "est": 0, "pod": 0, "det": 0, "int": 0}
var resultados: Array = []   # [{turno, nome, posicao, objetivo, ok}]
var terminou := false
var falhou_objetivo := false
var rng := RandomNumberGenerator.new()


func _init(g: Dictionary, ini: Dictionary, seed: int = 0) -> void:
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	nome = g.nome
	estilo = g.estilo
	aptidao = g.aptidao
	for k in SimCorrida.KEYS:
		attrs[k] = float(g.atributos[k])
	naturais = ini.get("naturais", [])
	unica = ini.get("unica", "")
	cor = Color(ini.get("cor", "#ffffff"))
	distancia = ini.get("distancia", "media")
	piso = ini.get("piso", "grama")


func nivel_treino(t: String) -> int:
	return mini(5, 1 + usos_treino[t] / BAL.usos_por_nivel)


func chance_falha() -> float:
	if energia >= BAL.limite_falha:
		return 0.0
	return BAL.falha_max * float(BAL.limite_falha - energia) / BAL.limite_falha


func custo(t: String) -> int:
	return BAL.custo_energia_int if t == "int" else BAL.custo_energia


func ganho_previsto(t: String) -> Dictionary:
	var m: float = (1.0 + BAL.bonus_nivel * (nivel_treino(t) - 1)) * HUMOR_TREINO[humor]
	if t in naturais:
		m *= 1.0 + BAL.bonus_natural
	if lesionada:
		m *= BAL.corte_lesao
	var tr: Dictionary = TREINOS[t]
	return {tr.principal: BAL.ganho_principal * m, tr.secundario: BAL.ganho_secundario * m}


func corrida_do_turno() -> Dictionary:
	return BAL.corridas.get(turno, {})


func proxima_corrida() -> Array:
	for t in BAL.corridas.keys():
		if t >= turno:
			return [t, BAL.corridas[t]]
	return []


func _mudar_humor(d: int) -> void:
	humor = clampi(humor + d, 0, 4)


func _limitar() -> void:
	for k in attrs:
		attrs[k] = clampf(attrs[k], 0.0, BAL.limite_attr)


## Cada ação devolve um texto curto do que aconteceu.
func treinar(t: String) -> String:
	var falha := rng.randf() < chance_falha()
	energia = maxi(0, energia - custo(t))
	if falha:
		attrs[t] -= BAL.perda_falha
		var outro: String = SimCorrida.KEYS[rng.randi() % 5]
		attrs[outro] -= BAL.perda_falha * 0.5
		_mudar_humor(-1)
		var txt := "O treino de %s falhou! %s perdeu atributos e ficou chateada." % [Dados.ATTR_NOME[t], _primeiro_nome()]
		if rng.randf() < BAL.chance_lesao:
			lesionada = true
			txt += " Ela se machucou de leve."
		_limitar()
		_fim_turno()
		return txt
	var g := ganho_previsto(t)
	var var_ := rng.randf_range(0.85, 1.15)
	var partes := []
	for k in g:
		var v: float = round(g[k] * var_)
		attrs[k] += v
		partes.append("+%d %s" % [v, Dados.ATTR_CURTO[k]])
	usos_treino[t] += 1
	_limitar()
	_fim_turno()
	return "Treino de %s: %s." % [Dados.ATTR_NOME[t], ", ".join(partes)]


func descansar() -> String:
	energia = mini(100, energia + BAL.descanso)
	var txt := "%s descansou e recuperou energia." % _primeiro_nome()
	if lesionada:
		lesionada = false
		txt += " A lesão sarou."
	_fim_turno()
	return txt


func sair() -> String:
	energia = mini(100, energia + BAL.sair_energia)
	_mudar_humor(1)
	_fim_turno()
	return "%s saiu para passear e voltou de bom humor." % _primeiro_nome()


func enfermaria() -> String:
	lesionada = false
	energia = mini(100, energia + 10)
	_fim_turno()
	return "Tratamento na enfermaria. A lesão sarou."


## Monta a corrida do turno: a jogadora + 11 adversárias do elenco.
func montar_corrida(elenco: Array) -> Dictionary:
	var c: Dictionary = corrida_do_turno()
	var dist_m: float = Dados.DISTANCIAS[distancia]
	var field := [{
		"nome": nome, "estilo": estilo, "attrs": attrs.duplicate(),
		"mult": Dados.APT[aptidao[distancia]] * Dados.APT[aptidao[piso]] * HUMOR_CORRIDA[humor],
		"unica": unica, "jogadora": true,
	}]
	var pool := elenco.filter(func(g): return g.nome != nome)
	pool.shuffle()
	for g in pool.slice(0, 11):
		var soma := 0.0
		for k in SimCorrida.KEYS:
			soma += g.atributos[k]
		var media: float = c.media_rivais * rng.randf_range(0.9, 1.1)
		var escala := media * 5.0 / soma
		var a := {}
		for k in SimCorrida.KEYS:
			a[k] = g.atributos[k] * escala
		field.append({
			"nome": g.nome, "estilo": g.estilo, "attrs": a,
			"mult": Dados.APT[g.aptidao[distancia]] * Dados.APT[g.aptidao[piso]],
			"unica": "", "jogadora": false,
		})
	return {"nome": c.nome, "objetivo": c.objetivo, "distancia": dist_m, "field": field}


func registrar_corrida(posicao: int) -> String:
	var c: Dictionary = corrida_do_turno()
	var ok: bool = posicao <= c.objetivo
	resultados.append({"turno": turno, "nome": c.nome, "posicao": posicao, "objetivo": c.objetivo, "ok": ok})
	if posicao == 1:
		_mudar_humor(1)
	elif not ok:
		_mudar_humor(-1)
	energia = maxi(0, energia - 15)
	var txt := "%s terminou em %dº na %s." % [_primeiro_nome(), posicao, c.nome]
	if not ok:
		falhou_objetivo = true
		terminou = true
		return txt + " O objetivo era o top %d. A carreira acaba aqui." % c.objetivo
	_fim_turno()
	return txt + " Objetivo cumprido!"


func _fim_turno() -> void:
	turno += 1
	if turno > BAL.turnos:
		terminou = true
		return
	# o humor oscila um pouco sozinho
	var r := rng.randf()
	if r < 0.07:
		_mudar_humor(-1)
	elif r < 0.12:
		_mudar_humor(1)


func _primeiro_nome() -> String:
	return nome.split(" ")[0]
