class_name Carreira
extends RefCounted
## Estado e regras da carreira (GDD §4), versão curta do protótipo.
## Todos os números de BAL são (inicial): pontos de partida para balancear.

const BAL := {
	"turnos": 24,
	"corridas": {12: {"nome": "Taça de Outono", "objetivo": 5, "media_rivais": 180.0},
				 24: {"nome": "Grande Prêmio Estelar", "objetivo": 3, "media_rivais": 285.0, "rival": "Polaris Moura"}},
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
	"limite_attr": 1000.0,     # +40 por nível de vínculo (1200 no vínculo 5, GDD §3.5)
	"vinculo_limite": 40.0,
	"vinculo_attr": 8.0,       # atributos iniciais extras por nível de vínculo
	# moeda (GDD §6.1)
	"premio_corrida": [50, 30, 20, 10, 10],  # por posição, do 1º ao 5º
	"moeda_base": 80,          # por terminar a carreira (mesmo falhando)
	"moeda_objetivo": 60,      # por objetivo cumprido
	"moeda_gp": 60,            # extra por vencer o Grande Prêmio
	# encontros e afinidade (GDD §4.7)
	"chance_encontro": 0.22,
	"chance_encontro_sair": 0.6,
	"afinidade_dupla": 30,     # afinidade mínima para aparecer no treino
	"chance_dupla": 0.35,
	"bonus_dupla": 0.25,
	"afinidade_por_dupla": 4,
}
## Os testes trocam o caminho para não mexer no save de verdade.
static var CAMINHO_SAVE := "user://carreira.json"
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
var afinidade := {}          # colega -> -20..100
var vistos: Array = []       # ids de encontros únicos já vistos
var ultimo_encontro := ""
var ultima_corrida := ""     # "vitoria", "derrota" ou "" (consumido pelos encontros)
var duplas := {}             # treino -> colega que aparece nele nesta semana
var encontro_pendente := {}  # encontro sorteado para esta semana, ainda sem resposta
var vinculo := 0
var limite := 1000.0
var moeda_corridas := 0      # prêmios das corridas desta carreira
var rng := RandomNumberGenerator.new()


func _init(g: Dictionary, ini: Dictionary, seed: int = 0, vinculo_: int = 0) -> void:
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	nome = g.nome
	estilo = g.estilo
	aptidao = g.aptidao
	vinculo = vinculo_
	limite = BAL.limite_attr + BAL.vinculo_limite * vinculo
	for k in SimCorrida.KEYS:
		attrs[k] = float(g.atributos[k]) + BAL.vinculo_attr * vinculo
	naturais = ini.get("naturais", [])
	unica = ini.get("unica", "")
	cor = Color(ini.get("cor", "#ffffff"))
	distancia = ini.get("distancia", "media")
	piso = ini.get("piso", "grama")
	var enc: Dictionary = Dados.encontros
	var iniciais_af: Dictionary = enc.get("afinidade_inicial", {}).get(nome, {})
	for colega in enc.get("colegas", []):
		if colega != nome:
			afinidade[colega] = int(iniciais_af.get(colega, 0))
	_sortear_duplas()


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
	if duplas.has(t):
		m *= 1.0 + BAL.bonus_dupla
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
		attrs[k] = clampf(attrs[k], 0.0, limite)


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
	var txt := "Treino de %s: %s." % [Dados.ATTR_NOME[t], ", ".join(partes)]
	if duplas.has(t):
		var colega: String = duplas[t]
		_mudar_afinidade(colega, BAL.afinidade_por_dupla)
		txt += " Treino em dupla com %s!" % _curto(colega)
	_limitar()
	_fim_turno()
	return txt


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
	_fim_turno(BAL.chance_encontro_sair)
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
	var vagas := 11
	if c.has("rival"):
		for rv in Dados.rivais:
			if rv.nome == c.rival:
				field.append(_adversaria(rv, c.media_rivais * rv.forca, rv.get("unica", "")))
				vagas -= 1
	for g in pool.slice(0, vagas):
		field.append(_adversaria(g, c.media_rivais * rng.randf_range(0.9, 1.1), ""))
	return {"nome": c.nome, "objetivo": c.objetivo, "distancia": dist_m, "field": field}


## Adversária com o perfil da garota escalado para a média pedida.
func _adversaria(g: Dictionary, media: float, unica_: String) -> Dictionary:
	var soma := 0.0
	for k in SimCorrida.KEYS:
		soma += g.atributos[k]
	var escala := media * 5.0 / soma
	var a := {}
	for k in SimCorrida.KEYS:
		a[k] = g.atributos[k] * escala
	return {
		"nome": g.nome, "estilo": g.estilo, "attrs": a,
		"mult": Dados.APT[g.aptidao[distancia]] * Dados.APT[g.aptidao[piso]],
		"unica": unica_, "jogadora": false,
	}


func registrar_corrida(posicao: int) -> String:
	var c: Dictionary = corrida_do_turno()
	var ok: bool = posicao <= c.objetivo
	resultados.append({"turno": turno, "nome": c.nome, "posicao": posicao, "objetivo": c.objetivo, "ok": ok})
	if posicao == 1:
		_mudar_humor(1)
	elif not ok:
		_mudar_humor(-1)
	ultima_corrida = "vitoria" if posicao == 1 else "derrota"
	energia = maxi(0, energia - 15)
	var txt := "%s terminou em %dº na %s." % [_primeiro_nome(), posicao, c.nome]
	if posicao <= BAL.premio_corrida.size():
		var premio: int = BAL.premio_corrida[posicao - 1]
		moeda_corridas += premio
		txt += " Prêmio: %d moedas." % premio
	if not ok:
		falhou_objetivo = true
		terminou = true
		return txt + " O objetivo era o top %d. A carreira acaba aqui." % c.objetivo
	_fim_turno(BAL.chance_encontro)
	return txt + " Objetivo cumprido!"


func _fim_turno(chance_encontro: float = BAL.chance_encontro) -> void:
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
	_sortear_duplas()
	if corrida_do_turno().is_empty():
		_sortear_encontro(chance_encontro)
	ultima_corrida = ""


func _sortear_duplas() -> void:
	duplas = {}
	var livres := TREINOS.keys()
	for colega in afinidade:
		if afinidade[colega] >= BAL.afinidade_dupla and rng.randf() < BAL.chance_dupla and not livres.is_empty():
			var t: String = livres[rng.randi() % livres.size()]
			livres.erase(t)
			duplas[t] = colega


func _primeiro_nome() -> String:
	return nome.split(" ")[0]


static func _curto(n: String) -> String:
	return n.split(" ")[0]


# ---------- encontros (GDD §4.7) ----------

func _condicoes_ok(e: Dictionary) -> bool:
	var q: Dictionary = e.get("quando", {})
	if turno < int(q.get("turno_min", 0)):
		return false
	if q.get("apos_derrota", false) and ultima_corrida != "derrota":
		return false
	if q.get("apos_vitoria", false) and ultima_corrida != "vitoria":
		return false
	if q.has("energia_max") and energia > int(q.energia_max):
		return false
	return true


func _sortear_encontro(chance: float) -> void:
	var lista: Array = Dados.encontros.get("encontros", [])
	# eventos ligados à corrida que acabou de acontecer têm prioridade
	if ultima_corrida != "":
		for e in lista:
			var q: Dictionary = e.get("quando", {})
			var de_corrida := q.has("apos_derrota") or q.has("apos_vitoria")
			if e.garota == nome and not e.id in vistos and de_corrida and _condicoes_ok(e):
				_abrir_encontro(e)
				return
	if rng.randf() >= chance:
		return
	var unicos := lista.filter(func(e): return e.garota == nome and not e.id in vistos and _condicoes_ok(e))
	var genericos := lista.filter(func(e): return e.garota == null and e.id != ultimo_encontro and _condicoes_ok(e))
	var escolhido: Dictionary
	if not unicos.is_empty() and (genericos.is_empty() or rng.randf() < 0.5):
		escolhido = unicos[rng.randi() % unicos.size()]
	elif not genericos.is_empty():
		escolhido = genericos[rng.randi() % genericos.size()]
	else:
		return
	_abrir_encontro(escolhido)


func _abrir_encontro(e: Dictionary) -> void:
	var colegas := afinidade.keys()
	var outra: String = colegas[rng.randi() % colegas.size()] if not colegas.is_empty() else ""
	encontro_pendente = {"id": e.id, "outra": outra}
	ultimo_encontro = e.id
	if e.garota != null:
		vistos.append(e.id)


func encontro_atual() -> Dictionary:
	if encontro_pendente.is_empty():
		return {}
	for e in Dados.encontros.get("encontros", []):
		if e.id == encontro_pendente.id:
			return e
	return {}


## Troca {nome} e {outra} nos textos do encontro.
func texto(t: String) -> String:
	return t.replace("{nome}", _primeiro_nome()).replace("{outra}", _curto(encontro_pendente.get("outra", "")))


## Aplica a escolha i do encontro pendente e devolve o texto do resultado.
func escolher(i: int) -> String:
	var e := encontro_atual()
	var esc: Dictionary = e.escolhas[i]
	var deu_certo := not esc.has("chance") or rng.randf() < float(esc.chance)
	var ef: Dictionary = esc.efeitos if deu_certo else esc.get("efeitos_falha", esc.efeitos)
	var resultado := texto(esc.resultado if deu_certo else esc.get("resultado_falha", esc.resultado))
	var outra: String = encontro_pendente.get("outra", "")
	var partes := []
	for k in ef:
		var v = ef[k]
		match k:
			"humor":
				_mudar_humor(int(v))
				partes.append("humor %+d" % v)
			"energia":
				energia = clampi(energia + int(v), 0, 100)
				partes.append("energia %+d" % v)
			"afinidade":
				if outra != "":
					_mudar_afinidade(outra, int(v))
					partes.append("afinidade com %s %+d" % [_curto(outra), v])
			"nivel_treino":
				var mais := "vel"
				for t in usos_treino:
					if usos_treino[t] > usos_treino[mais]:
						mais = t
				usos_treino[mais] += BAL.usos_por_nivel * int(v)
				partes.append("treino de %s nível %+d" % [Dados.ATTR_NOME[mais], v])
			"perde_turno":
				pass
			_:
				if attrs.has(k):
					attrs[k] += float(v)
					partes.append("%+d %s" % [v, Dados.ATTR_CURTO[k]])
	_limitar()
	encontro_pendente = {}
	if ef.get("perde_turno", false):
		_fim_turno(0.0)
		partes.append("a semana passou")
	if not partes.is_empty():
		resultado += " (%s)" % ", ".join(partes)
	return resultado


func _mudar_afinidade(colega: String, d: int) -> void:
	if afinidade.has(colega):
		afinidade[colega] = clampi(afinidade[colega] + d, -20, 100)


# ---------- save (GDD §10: automático a cada turno, um slot) ----------

const CAMPOS_SAVE := ["attrs", "energia", "humor", "lesionada", "turno", "usos_treino", "resultados",
	"terminou", "falhou_objetivo", "afinidade", "vistos", "ultimo_encontro", "ultima_corrida",
	"duplas", "encontro_pendente", "moeda_corridas"]


## Salva também a carreira terminada: ela só é apagada depois que o jogador decide
## entre substituir e descartar, para não perder a moeda se o jogo fechar antes.
func salvar() -> void:
	var d := {"versao": 1, "nome": nome, "vinculo": vinculo, "rng": str(rng.state)}
	for campo in CAMPOS_SAVE:
		d[campo] = get(campo)
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  ", false))  # sem ordenar: a ordem das chaves importa para o RNG


static func tem_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


static func apagar_save() -> void:
	if tem_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_SAVE))


## Lê o save, ou devolve null se não houver ou estiver inválido.
static func carregar() -> Carreira:
	if not tem_save():
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_SAVE))
	if not d is Dictionary or not d.has("nome"):
		return null
	# autoloads não podem ser usados direto numa função estática
	var dados: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	var g: Dictionary = dados.garota(d.nome)
	var ini: Dictionary = dados.config_carreira(d.nome)
	if g.is_empty() or ini.is_empty():
		return null
	var c := Carreira.new(g, ini, 0, int(d.get("vinculo", 0)))
	for campo in CAMPOS_SAVE:
		if d.has(campo):
			c.set(campo, d[campo])
	# o JSON devolve todos os números como float
	c.energia = int(c.energia)
	c.humor = int(c.humor)
	c.turno = int(c.turno)
	c.moeda_corridas = int(c.moeda_corridas)
	for t in c.usos_treino:
		c.usos_treino[t] = int(c.usos_treino[t])
	for k in c.afinidade:
		c.afinidade[k] = int(c.afinidade[k])
	for r in c.resultados:
		r.turno = int(r.turno)
		r.posicao = int(r.posicao)
		r.objetivo = int(r.objetivo)
	c.rng.state = int(str(d.get("rng", "0")))
	return c


# ---------- fim de carreira (GDD §4.8) ----------

func objetivos_cumpridos() -> int:
	return resultados.filter(func(r): return r.ok).size()


func venceu_gp() -> bool:
	return resultados.any(func(r): return r.turno == BAL.turnos and r.posicao == 1)


## Moeda total da carreira: prêmios das corridas + bônus por desempenho.
func moeda_total() -> Dictionary:
	var bonus: int = BAL.moeda_base + BAL.moeda_objetivo * objetivos_cumpridos()
	if venceu_gp():
		bonus += BAL.moeda_gp
	return {"corridas": moeda_corridas, "bonus": bonus, "total": moeda_corridas + bonus}


## O que fica guardado no elenco se o jogador escolher substituir a versão salva.
func versao_salva() -> Dictionary:
	var a := {}
	for k in attrs:
		a[k] = roundi(attrs[k])
	return {"attrs": a, "nota": Dados.nota(attrs), "objetivos": objetivos_cumpridos(),
		"resultados": resultados.duplicate(true), "vinculo": vinculo}
