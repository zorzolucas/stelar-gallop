class_name Carreira
extends RefCounted
## Estado e regras da carreira (GDD §4 e docs/calendario.md): 48 turnos de meio mês,
## 5 objetivos, mapa de rotas por trecho, corridas opcionais, fama, clima e férias.
## Todo sorteio sai da semente da carreira, por contexto (Calendario.rng), então
## recarregar o save e repetir a ação dá o mesmo resultado.
## Os números de BAL são (inicial): pontos de partida para balancear.

const BAL := {
	"turnos": 48,
	"ganho_principal": 75.0,
	"ganho_secundario": 28.0,
	"bonus_nivel": 0.10,       # por nível de treino acima do 1
	# ganho cai conforme o atributo sobe: x(retorno_base - retorno_queda * atributo/limite)
	"retorno_base": 1.15,
	"retorno_queda": 0.45,
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
	# corridas (calendario.md §7)
	"energia_corrida": 15,
	"energia_seguidas": 10,    # extra na 3ª corrida em 3 turnos seguidos
	"humor_seguidas": 0.3,
	# moeda (GDD §6.1)
	"moeda_por_fama": 5,       # 1 moeda a cada 5 de fama ganha numa corrida
	"moeda_base": 80,          # por terminar a carreira (mesmo falhando)
	"moeda_objetivo": 50,      # por objetivo cumprido
	"moeda_gp": 80,            # extra por vencer o Grande Prêmio final
	"moeda_fama_final": 100,   # +1 moeda a cada 100 de fama no fim
	# encontros e afinidade (GDD §4.7)
	"chance_encontro": 0.22,
	"chance_encontro_sair": 0.6,
	"afinidade_dupla": 30,     # afinidade mínima para aparecer no treino
	"chance_dupla": 0.35,
	"bonus_dupla": 0.25,
	"afinidade_por_dupla": 4,
	# nós e férias (calendario.md §4.2 e §8)
	"festival_treino": 0.9,
	"descanso_extra": 1.5,     # Recuperação e férias
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

var semente := 0
var attrs := {}
var energia := 100
var humor := 2
var lesionada := false
var turno := 1
var usos_treino := {"vel": 0, "est": 0, "pod": 0, "det": 0, "int": 0}
var fama := 0
var objetivos: Array = []    # os 5 objetivos (Calendario.objetivos)
var mapas: Array = []        # mapa de cada trecho
var rota := [[], [], [], []] # coluna escolhida em cada linha de cada trecho
var acampamentos := {}       # ano -> "serra" ou "praia"
var resultados: Array = []   # [{turno, nome, cat, posicao, objetivo (0 = opcional), ok, fama}]
var turnos_com_corrida: Array = []
var corrida_atual := {}      # corrida escolhida e ainda não corrida
var desafios_feitos: Array = []
var serra := false           # Mistério "Treino na serra" pendente
var unico_garantido := false # Mistério "Noite sem dormir"
var terminou := false
var falhou_objetivo := false
var afinidade := {}          # colega -> -20..100
var vistos: Array = []       # ids de encontros únicos já vistos
var ultimo_encontro := ""
var ultima_corrida := ""     # "vitoria", "derrota" ou "" (consumido pelos encontros)
var duplas := {}             # treino -> colega que aparece nele neste turno
var encontro_pendente := {}  # {id, tipo: "encontro"|"misterio"|"vespera", outra}
var vinculo := 0
var limite := 1000.0
var moeda_corridas := 0      # prêmios das corridas desta carreira
var pontos := 0              # pontos de habilidade (GDD §3.4)
var habilidades: Array = []  # ids das genéricas compradas (data/habilidades.json)
var amuletos: Array = []     # ids dos amuletos equipados (data/amuletos.json)
var oferta_amuleto: Array = []  # amuletos oferecidos, esperando a escolha
var estrela_usada := false


func _init(g: Dictionary, ini: Dictionary, semente_: int = 0, vinculo_: int = 0) -> void:
	semente = semente_ if semente_ != 0 else randi()
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
	habilidades = Dados.habilidades.get("iniciais", []).duplicate()
	objetivos = Calendario.objetivos(semente, aptidao, distancia, piso)
	for i in Dados.calendario.trechos.size():
		mapas.append(Calendario.gerar_mapa(semente, i))
	_sortear_duplas()


func _rng(contexto: String) -> RandomNumberGenerator:
	return Calendario.rng(semente, [contexto, turno])


func _primeiro_nome() -> String:
	return nome.split(" ")[0]


static func _curto(n: String) -> String:
	return n.split(" ")[0]


# ---------- contexto do turno ----------

func clima() -> String:
	return Calendario.clima(semente, turno)


func trecho() -> int:
	return Calendario.trecho_de(turno)


## Nó do mapa em que ela está neste mês, ou {} (fora de trecho ou ainda sem escolha).
func no_atual() -> Dictionary:
	var t := trecho()
	if t < 0:
		return {}
	var linha := Calendario.linha_do_mapa(turno, t)
	if rota[t].size() <= linha:
		return {}
	return mapas[t][linha][rota[t][linha]]


func tipo_no() -> String:
	return no_atual().get("tipo", "")


func objetivo_do_turno() -> Dictionary:
	for o in objetivos:
		if o.turno == turno:
			return o
	return {}


func proximo_objetivo() -> Dictionary:
	for o in objetivos:
		if o.turno >= turno:
			return o
	return {}


func em_ferias() -> bool:
	return Calendario.e_ferias(turno)


func acampamento() -> String:
	return acampamentos.get(str(Calendario.mes_idx(turno) / 12), "")


## O que a tela precisa resolver antes das ações normais deste turno:
## "encontro", "amuleto", "mapa", "ferias", "corrida", "objetivo", "sem_fama" ou "" (ações).
func pendencia() -> String:
	if not encontro_pendente.is_empty():
		return "encontro"
	if not oferta_amuleto.is_empty():
		return "amuleto"
	if not corrida_atual.is_empty():
		return "corrida"
	var t := trecho()
	if t >= 0 and rota[t].size() <= Calendario.linha_do_mapa(turno, t):
		return "mapa"
	if em_ferias() and acampamento() == "":
		return "ferias"
	var o := objetivo_do_turno()
	if not o.is_empty():
		return "sem_fama" if fama < int(o.get("fama_min", 0)) else "objetivo"
	return ""


## Colunas que ela pode escolher na próxima linha do mapa do trecho atual.
func opcoes_mapa() -> Array:
	var t := trecho()
	var feitas: Array = rota[t]
	if feitas.is_empty():
		return [0, 1, 2]
	return Calendario.vizinhos(feitas[-1])


func escolher_no(col: int) -> String:
	var t := trecho()
	rota[t].append(col)
	var no := no_atual()
	var info: Dictionary = Dados.calendario.nos[no.tipo]
	var txt := "Rota escolhida: %s." % info.nome
	if no.tipo == "misterio":
		_abrir_misterio()
	return txt


func escolher_acampamento(qual: String) -> String:
	acampamentos[str(Calendario.mes_idx(turno) / 12)] = qual
	if qual == "serra":
		return "Acampamento na serra: treinos de Estamina e Determinação contam 1 nível acima."
	return "Acampamento na praia: treinos de Velocidade e Poder contam 1 nível acima."


# ---------- treino ----------

func nivel_treino(t: String) -> int:
	return mini(5, 1 + usos_treino[t] / BAL.usos_por_nivel)


## Nível que vale neste turno, com os bônus de nó, clima, férias e Mistério.
func nivel_efetivo(t: String) -> int:
	var n := nivel_treino(t)
	var no := no_atual()
	if no.get("tipo", "") == "foco" and no.get("foco", "") == t:
		n += 1
	if no.get("tipo", "") == "biblioteca" and t == "int":
		n += 1
	match clima():
		"chuva": n += 1 if t == "pod" else 0
		"frio": n += 1 if t == "det" else 0
	match acampamento() if em_ferias() else "":
		"serra": n += 1 if t in ["est", "det"] else 0
		"praia": n += 1 if t in ["vel", "pod"] else 0
	if serra and t in ["est", "det"]:
		n += 1
	if _efeito("nivel").has(t):
		n += 1
	return mini(5, n)


func chance_falha(t: String = "") -> float:
	if energia >= BAL.limite_falha:
		return 0.0
	var c: float = BAL.falha_max * float(BAL.limite_falha - energia) / BAL.limite_falha
	if serra and t in ["est", "det"]:
		c *= 2.0
	return minf(c, 0.95)


func custo(t: String) -> int:
	var c: int = BAL.custo_energia_int if t == "int" else BAL.custo_energia
	if clima() == "calor":
		c += 5
	c += int(_soma("custo_treino"))
	return c


func ganho_previsto(t: String) -> Dictionary:
	var m: float = (1.0 + BAL.bonus_nivel * (nivel_efetivo(t) - 1)) * HUMOR_TREINO[humor]
	if t in naturais:
		m *= 1.0 + (_soma("natural") if tem_efeito("natural") else BAL.bonus_natural)
	m *= 1.0 + _soma("ganho_todos")
	if lesionada:
		m *= BAL.corte_lesao
	if duplas.has(t):
		m *= 1.0 + BAL.bonus_dupla
	if tipo_no() == "festival":
		m *= BAL.festival_treino
	match clima():
		"chuva": m *= 0.9 if t == "vel" and not tem_efeito("capa_chuva") else 1.0
		"vento": m *= 1.1 if t == "int" else 1.0
	var tr: Dictionary = TREINOS[t]
	var extra := {}  # bônus por atributo (ex.: Ferradura de Bronze, +5% de Velocidade)
	for a in amuletos:
		var ganhos: Dictionary = Dados.amuleto(a).get("efeito", {}).get("ganho", {})
		for k in ganhos:
			extra[k] = extra.get(k, 0.0) + float(ganhos[k])
	return {tr.principal: BAL.ganho_principal * m * _retorno(tr.principal) * (1.0 + extra.get(tr.principal, 0.0)),
		tr.secundario: BAL.ganho_secundario * m * _retorno(tr.secundario) * (1.0 + extra.get(tr.secundario, 0.0))}


## Retorno decrescente: quanto maior o atributo, menos o treino rende (curva do calendário §2.1).
func _retorno(k: String) -> float:
	return maxf(0.3, BAL.retorno_base - BAL.retorno_queda * attrs[k] / limite)


func _mudar_humor(d: int) -> void:
	humor = clampi(humor + d, 0, 4)


func _limitar() -> void:
	for k in attrs:
		attrs[k] = clampf(attrs[k], 0.0, limite)


## Cada ação devolve um texto curto do que aconteceu.
func treinar(t: String) -> String:
	var r := _rng("treino:" + t)
	var falha := r.randf() < chance_falha(t)
	var era_serra := serra and t in ["est", "det"]
	energia = maxi(0, energia - custo(t))
	if era_serra:
		serra = false
	var salvou_estrela := false
	if falha and tem_efeito("estrela") and not estrela_usada:
		falha = false
		estrela_usada = true
		salvou_estrela = true
	if falha:
		attrs[t] -= BAL.perda_falha
		var outro: String = SimCorrida.KEYS[r.randi() % 5]
		attrs[outro] -= BAL.perda_falha * 0.5
		var txt := "O treino de %s falhou! %s perdeu atributos." % [Dados.ATTR_NOME[t], _primeiro_nome()]
		if tipo_no() != "recuperacao":
			_mudar_humor(-1)
			txt += " Ela ficou chateada."
		if r.randf() < BAL.chance_lesao:
			lesionada = true
			txt += " Ela se machucou de leve."
		_limitar()
		_fim_turno()
		return txt
	var g := ganho_previsto(t)
	var var_ := r.randf_range(0.85, 1.15)
	var partes := []
	for k in g:
		var v: float = round(g[k] * var_)
		attrs[k] += v
		partes.append("+%d %s" % [v, Dados.ATTR_CURTO[k]])
	usos_treino[t] += 1
	var txt := "Treino de %s: %s." % [Dados.ATTR_NOME[t], ", ".join(partes)]
	if salvou_estrela:
		txt = "O treino ia falhar, mas a Estrela Cadente brilhou! " + txt
	if duplas.has(t):
		var colega: String = duplas[t]
		_mudar_afinidade(colega, BAL.afinidade_por_dupla)
		txt += " Treino em dupla com %s!" % _curto(colega)
	_limitar()
	_fim_turno()
	return txt


func descanso_previsto() -> int:
	var d: float = BAL.descanso
	if tipo_no() == "recuperacao" or em_ferias():
		d *= BAL.descanso_extra
	if clima() == "frio":
		d *= 0.9
	for a in amuletos:
		d *= float(Dados.amuleto(a).get("efeito", {}).get("descanso_mult", 1.0))
	d += _soma("descanso")
	return roundi(d)


func descansar() -> String:
	energia = mini(100, energia + descanso_previsto())
	var txt := "%s descansou e recuperou energia." % _primeiro_nome()
	if lesionada:
		lesionada = false
		txt += " A lesão sarou."
	_fim_turno()
	return txt


func sair() -> String:
	energia = mini(100, energia + BAL.sair_energia)
	_mudar_humor(1)
	var sempre := tipo_no() == "festival" or em_ferias()
	_fim_turno(1.0 if sempre else BAL.chance_encontro_sair)
	return "%s saiu para passear e voltou de bom humor." % _primeiro_nome()


func enfermaria() -> String:
	lesionada = false
	energia = mini(100, energia + 10)
	if tipo_no() == "recuperacao":
		return "Tratamento na enfermaria. A lesão sarou, e na Recuperação isso não gasta o turno."
	_fim_turno()
	return "Tratamento na enfermaria. A lesão sarou."


# ---------- corridas ----------

## Corridas opcionais deste turno (só em Circuito e no 2º turno do Desafio).
func corridas_opcionais() -> Array:
	if not objetivo_do_turno().is_empty() or em_ferias() or Calendario.e_vespera(turno):
		return []
	var tipo := tipo_no()
	var lista := []
	if tipo == "circuito":
		lista = Calendario.corridas_do_circuito(semente, turno, distancia, piso)
	elif tipo == "desafio" and (turno - 1) % 2 == 1 and not turno in desafios_feitos:
		lista = [Calendario.corrida_desafio(semente, turno, distancia, piso)]
	return lista


func pode_entrar(c: Dictionary) -> bool:
	return fama >= int(Dados.calendario.categorias[c.cat].fama_entrada)


func fama_prevista(c: Dictionary, posicao: int = 1) -> int:
	var cal: Dictionary = Dados.calendario
	var base: float = cal.categorias[c.cat].fama
	var mult: float = cal.fama_por_posicao[posicao - 1] if posicao <= cal.fama_por_posicao.size() else cal.fama_resto
	return roundi(base * mult * (1.0 + _soma("fama")))


func pontos_previstos(c: Dictionary, posicao: int = 1) -> int:
	var h: Dictionary = Dados.habilidades
	var mult: float = h.pontos_por_posicao[posicao - 1] if posicao <= h.pontos_por_posicao.size() else h.pontos_resto
	return roundi(float(h.pontos_por_categoria[c.cat]) * mult)


func energia_corrida() -> int:
	return maxi(0, BAL.energia_corrida + int(_soma("energia_corrida")))


func escolher_corrida(c: Dictionary) -> void:
	corrida_atual = c


func _corrida_seguida() -> bool:
	return (turno - 1) in turnos_com_corrida and (turno - 2) in turnos_com_corrida


## Monta a corrida: a jogadora + 11 adversárias do elenco (com a rival, se houver).
func montar_corrida(elenco: Array) -> Dictionary:
	var c := corrida_atual if not corrida_atual.is_empty() else objetivo_do_turno()
	var cal: Dictionary = Dados.calendario
	var forca: float = cal.categorias[c.cat].forca
	if c.get("desafio", false):
		forca *= cal.forca_desafio
	var r := _rng("corrida:" + c.get("id", "x"))
	var field := [{
		"nome": nome, "estilo": estilo, "attrs": attrs.duplicate(),
		"mult": Dados.APT[aptidao[c.dist]] * Dados.APT[aptidao[c.piso]] * HUMOR_CORRIDA[humor],
		"unica": unica, "jogadora": true,
		"habilidades": habilidades.map(func(id): return Dados.habilidade(id)),
		"amuletos": efeitos_de_corrida(),
	}]
	var pool := elenco.filter(func(g): return g.nome != nome)
	# embaralha com a semente, para repetir no mesmo save
	for i in range(pool.size() - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var vagas := 11
	var rival: String = c.get("rival", "")
	if rival != "":
		for rv in Dados.rivais:
			if rv.nome == rival:
				field.append(_adversaria(rv, forca * cal.forca_rival, rv.get("unica", ""), c))
				vagas -= 1
	elif c.cat.begins_with("gp"):
		# campeã da casa gerada (calendario.md §3.1)
		var campea: Dictionary = pool.pop_back()
		var adv := _adversaria(campea, forca * cal.forca_rival, "", c)
		field.append(adv)
		vagas -= 1
	var v: float = cal.variacao_npc
	for g in pool.slice(0, vagas):
		field.append(_adversaria(g, forca * r.randf_range(1.0 - v, 1.0 + v), "", c))
	return {"nome": c.nome, "objetivo": int(c.get("meta", 0)), "distancia": Calendario.metros(c),
		"field": field, "clima": clima(), "seed": hash([semente, turno, c.get("id", "x")])}


## Adversária com o perfil da garota escalado para a média pedida.
func _adversaria(g: Dictionary, media: float, unica_: String, c: Dictionary) -> Dictionary:
	var soma := 0.0
	for k in SimCorrida.KEYS:
		soma += g.atributos[k]
	var escala := media * 5.0 / soma
	var a := {}
	for k in SimCorrida.KEYS:
		a[k] = g.atributos[k] * escala
	return {
		"nome": g.nome, "estilo": g.estilo, "attrs": a,
		"mult": Dados.APT[g.aptidao[c.dist]] * Dados.APT[g.aptidao[c.piso]],
		"unica": unica_, "jogadora": false,
	}


func registrar_corrida(posicao: int) -> String:
	var obj := objetivo_do_turno()
	var c := corrida_atual if not corrida_atual.is_empty() else obj
	var e_obj := corrida_atual.is_empty()
	corrida_atual = {}
	var ganho_fama := fama_prevista(c, posicao)
	fama += ganho_fama
	var premio := ganho_fama / BAL.moeda_por_fama
	moeda_corridas += premio
	var ganho_pontos := pontos_previstos(c, posicao)
	pontos += ganho_pontos
	var custo_e: int = energia_corrida()
	var seguida := _corrida_seguida()
	if seguida:
		custo_e += BAL.energia_seguidas
	energia = maxi(0, energia - custo_e)
	turnos_com_corrida.append(turno)
	var txt := "%s terminou em %dº na %s. +%d de fama, +%d pontos de habilidade, %d moedas." % [
		_primeiro_nome(), posicao, c.nome, ganho_fama, ganho_pontos, premio]
	if seguida and _rng("seguidas").randf() < BAL.humor_seguidas:
		_mudar_humor(-1)
		txt += " Três corridas seguidas pesaram no humor."
	ultima_corrida = "vitoria" if posicao == 1 else "derrota"
	var ok := true
	var meta := 0
	if e_obj:
		meta = int(obj.meta)
		ok = posicao <= meta
		if obj.has("maratona"):
			var boas := resultados.filter(func(x): return x.turno >= 5 and x.posicao <= 5).size()
			ok = boas + (1 if posicao <= 5 else 0) >= int(obj.maratona)
	var coracao := tem_efeito("coracao")
	if posicao == 1:
		_mudar_humor(2 if coracao else 1)
	elif coracao and posicao > 3:
		_mudar_humor(-2)
	elif e_obj and not ok:
		_mudar_humor(-1)
	if c.get("desafio", false):
		desafios_feitos.append(turno)
		if posicao <= 3:
			oferecer_amuleto(3, false)
			txt += " Top 3 no Desafio: escolha um amuleto!"
		else:
			_mudar_humor(-1)
			txt += " Ficou fora do top 3 no Desafio e o humor caiu."
	resultados.append({"turno": turno, "nome": c.nome, "cat": c.cat, "posicao": posicao,
		"objetivo": meta, "ok": ok, "fama": ganho_fama})
	if e_obj and not ok:
		falhou_objetivo = true
		terminou = true
		return txt + " O objetivo era: %s. A carreira acaba aqui." % obj.texto.to_lower()
	if e_obj and turno < BAL.turnos:
		# objetivos 1 a 4 dão um amuleto; os difíceis oferecem 4, com pelo menos 1 incomum ou raro
		var dificil: bool = obj.get("dificil", false)
		oferecer_amuleto(4 if dificil else 3, dificil)
		txt += " Objetivo cumprido! Escolha um amuleto."
		_fim_turno(BAL.chance_encontro)
		return txt
	_fim_turno(BAL.chance_encontro)
	return txt + (" Objetivo cumprido!" if e_obj else "")


## Objetivo 4 sem a fama mínima: a carreira acaba sem correr.
func falhar_por_fama() -> String:
	var o := objetivo_do_turno()
	resultados.append({"turno": turno, "nome": o.nome, "cat": o.cat, "posicao": 0,
		"objetivo": int(o.meta), "ok": false, "fama": 0})
	falhou_objetivo = true
	terminou = true
	return "%s não tinha os %d de fama para entrar na %s. A carreira acaba aqui." % [_primeiro_nome(), o.fama_min, o.nome]


# ---------- passagem de turno ----------

func _fim_turno(chance_encontro: float = BAL.chance_encontro) -> void:
	turno += 1
	if turno > BAL.turnos:
		terminou = true
		return
	var r := _rng("humor")
	var x := r.randf()
	if x < 0.07:
		_mudar_humor(-1)
	elif x < 0.12:
		_mudar_humor(1)
	if (turno - 1) % 2 == 0 and clima() == "estrelas":
		_mudar_humor(1)
	_sortear_duplas()
	if Calendario.e_vespera(turno):
		_abrir_vespera()
	elif objetivo_do_turno().is_empty():
		_sortear_encontro(chance_encontro)
	ultima_corrida = ""


func _sortear_duplas() -> void:
	duplas = {}
	var r := _rng("duplas")
	var livres := TREINOS.keys()
	for colega in afinidade:
		if afinidade[colega] >= BAL.afinidade_dupla and r.randf() < BAL.chance_dupla and not livres.is_empty():
			var t: String = livres[r.randi() % livres.size()]
			livres.erase(t)
			duplas[t] = colega


# ---------- encontros (GDD §4.7), Mistério e véspera ----------

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
	var r := _rng("encontro")
	if ultima_corrida != "":
		for e in lista:
			var q: Dictionary = e.get("quando", {})
			var de_corrida := q.has("apos_derrota") or q.has("apos_vitoria")
			if e.garota == nome and not e.id in vistos and de_corrida and _condicoes_ok(e):
				_abrir_encontro(e, r)
				return
	if r.randf() >= chance:
		return
	var unicos := lista.filter(func(e): return e.garota == nome and not e.id in vistos and _condicoes_ok(e))
	var genericos := lista.filter(func(e): return e.garota == null and e.id != ultimo_encontro and _condicoes_ok(e))
	var escolhido: Dictionary
	if not unicos.is_empty() and (unico_garantido or genericos.is_empty() or r.randf() < 0.5):
		escolhido = unicos[r.randi() % unicos.size()]
		unico_garantido = false
	elif not genericos.is_empty():
		escolhido = genericos[r.randi() % genericos.size()]
	else:
		return
	_abrir_encontro(escolhido, r)


func _abrir_encontro(e: Dictionary, r: RandomNumberGenerator) -> void:
	var colegas := afinidade.keys()
	var outra: String = colegas[r.randi() % colegas.size()] if not colegas.is_empty() else ""
	encontro_pendente = {"id": e.id, "tipo": "encontro", "outra": outra}
	ultimo_encontro = e.id
	if e.garota != null:
		vistos.append(e.id)


func _abrir_misterio() -> void:
	var r := _rng("misterio")
	var lista: Array = Dados.calendario.misterios
	var e: Dictionary = lista[r.randi() % lista.size()]
	var colegas := afinidade.keys()
	encontro_pendente = {"id": e.id, "tipo": "misterio", "outra": colegas[r.randi() % colegas.size()]}


func _abrir_vespera() -> void:
	var o := proximo_objetivo()
	if o.get("rival", "") == "":
		return
	encontro_pendente = {"id": "vespera", "tipo": "vespera", "outra": "", "rival": o.rival}


func encontro_atual() -> Dictionary:
	if encontro_pendente.is_empty():
		return {}
	match encontro_pendente.get("tipo", "encontro"):
		"misterio":
			for e in Dados.calendario.misterios:
				if e.id == encontro_pendente.id:
					return e
		"vespera":
			return Dados.calendario.vespera
		_:
			for e in Dados.encontros.get("encontros", []):
				if e.id == encontro_pendente.id:
					return e
	return {}


## Troca {nome}, {outra} e {rival} nos textos do encontro.
func texto(t: String) -> String:
	return t.replace("{nome}", _primeiro_nome()).replace("{outra}", _curto(encontro_pendente.get("outra", ""))) \
		.replace("{rival}", encontro_pendente.get("rival", ""))


func _mult_afinidade() -> float:
	var m := 1.0 + _soma("afinidade")
	if tipo_no() == "festival":
		m *= 2.0
	if clima() == "estrelas":
		m *= 1.5
	return m


## Aplica a escolha i do encontro pendente e devolve o texto do resultado.
func escolher(i: int) -> String:
	var e := encontro_atual()
	var esc: Dictionary = e.escolhas[i]
	var r := _rng("escolha:" + str(encontro_pendente.id))
	var deu_certo := not esc.has("chance") or r.randf() < float(esc.chance)
	var ef: Dictionary = esc.efeitos if deu_certo else esc.get("efeitos_falha", esc.efeitos)
	var resultado := texto(esc.resultado if deu_certo else esc.get("resultado_falha", esc.resultado))
	var outra: String = encontro_pendente.get("outra", "")
	var partes := []
	var faltou_pontos := false
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
					var d := roundi(int(v) * _mult_afinidade())
					_mudar_afinidade(outra, d)
					partes.append("afinidade com %s %+d" % [_curto(outra), d])
			"nivel_treino":
				var mais := "vel"
				for t in usos_treino:
					if usos_treino[t] > usos_treino[mais]:
						mais = t
				usos_treino[mais] += BAL.usos_por_nivel * int(v)
				partes.append("treino de %s nível %+d" % [Dados.ATTR_NOME[mais], v])
			"fama":
				fama += int(v)
				partes.append("fama %+d" % v)
			"serra":
				serra = true
			"pontos":
				if pontos + int(v) < 0:
					partes.append("sem pontos suficientes, nada mudou")
					faltou_pontos = true
					continue
				pontos += int(v)
				partes.append("pontos de habilidade %+d" % v)
			"habilidade":
				partes.append(_ganhar_habilidade(str(v)))
			"amuleto":
				if faltou_pontos:
					continue
				oferecer_amuleto(3, false)
				partes.append("escolha um amuleto")
			"unico_garantido":
				unico_garantido = true
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
		partes.append("o turno passou")
	if not partes.is_empty():
		resultado += " (%s)" % ", ".join(partes)
	return resultado


func _mudar_afinidade(colega: String, d: int) -> void:
	if afinidade.has(colega):
		afinidade[colega] = clampi(afinidade[colega] + d, -20, 100)


# ---------- save (GDD §10: automático a cada turno, um slot) ----------

const CAMPOS_SAVE := ["attrs", "energia", "humor", "lesionada", "turno", "usos_treino", "fama",
	"rota", "acampamentos", "resultados", "turnos_com_corrida", "corrida_atual", "desafios_feitos",
	"serra", "unico_garantido", "terminou", "falhou_objetivo", "afinidade", "vistos",
	"ultimo_encontro", "ultima_corrida", "duplas", "encontro_pendente", "moeda_corridas",
	"pontos", "habilidades", "amuletos", "oferta_amuleto", "estrela_usada"]


## Salva também a carreira terminada: ela só é apagada depois que o jogador decide
## entre substituir e descartar, para não perder a moeda se o jogo fechar antes.
func salvar() -> void:
	var d := {"versao": 2, "nome": nome, "vinculo": vinculo, "semente": str(semente)}
	for campo in CAMPOS_SAVE:
		d[campo] = get(campo)
	var f := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  ", false))  # sem ordenar: a ordem das chaves importa


static func tem_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


static func apagar_save() -> void:
	if tem_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_SAVE))


## Lê o save, ou devolve null se não houver, estiver inválido ou for de uma versão antiga.
static func carregar() -> Carreira:
	if not tem_save():
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_SAVE))
	if not d is Dictionary or not d.has("nome") or int(d.get("versao", 0)) != 2:
		return null
	# autoloads não podem ser usados direto numa função estática
	var dados: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	# saves antigos usavam nome e sobrenome ("Lira Alazã"); hoje é só o nome
	d.nome = d.nome.split(" ")[0]
	if d.has("afinidade"):
		var af := {}
		for k in d.afinidade:
			af[k.split(" ")[0]] = d.afinidade[k]
		d.afinidade = af
	if d.has("duplas"):
		for t in d.duplas:
			d.duplas[t] = d.duplas[t].split(" ")[0]
	if d.get("encontro_pendente", {}).has("outra"):
		d.encontro_pendente.outra = d.encontro_pendente.outra.split(" ")[0]
	if d.get("encontro_pendente", {}).has("rival"):
		d.encontro_pendente.rival = d.encontro_pendente.rival.split(" ")[0]
	var g: Dictionary = dados.garota(d.nome)
	var ini: Dictionary = dados.config_carreira(d.nome)
	if g.is_empty() or ini.is_empty():
		return null
	var c := Carreira.new(g, ini, int(str(d.semente)), int(d.get("vinculo", 0)))
	for campo in CAMPOS_SAVE:
		if d.has(campo):
			c.set(campo, d[campo])
	# o JSON devolve todos os números como float
	for campo in ["energia", "humor", "turno", "fama", "moeda_corridas", "pontos"]:
		c.set(campo, int(c.get(campo)))
	for t in c.usos_treino:
		c.usos_treino[t] = int(c.usos_treino[t])
	for k in c.afinidade:
		c.afinidade[k] = int(c.afinidade[k])
	for r in c.resultados:
		for k in ["turno", "posicao", "objetivo", "fama"]:
			r[k] = int(r[k])
	c.rota = c.rota.map(func(l): return l.map(func(x): return int(x)))
	c.turnos_com_corrida = c.turnos_com_corrida.map(func(x): return int(x))
	c.desafios_feitos = c.desafios_feitos.map(func(x): return int(x))
	return c


# ---------- fim de carreira (GDD §4.8) ----------

func objetivos_cumpridos() -> int:
	return resultados.filter(func(r): return r.objetivo > 0 and r.ok).size()


func venceu_gp() -> bool:
	return resultados.any(func(r): return r.turno == BAL.turnos and r.posicao == 1)


## Moeda total da carreira: prêmios das corridas + bônus por desempenho e fama.
func moeda_total() -> Dictionary:
	var bonus: int = BAL.moeda_base + BAL.moeda_objetivo * objetivos_cumpridos() + fama / BAL.moeda_fama_final
	if venceu_gp():
		bonus += BAL.moeda_gp
	return {"corridas": moeda_corridas, "bonus": bonus, "total": moeda_corridas + bonus}


## O que fica guardado no elenco se o jogador escolher substituir a versão salva.
func versao_salva() -> Dictionary:
	var a := {}
	for k in attrs:
		a[k] = roundi(attrs[k])
	return {"attrs": a, "nota": Dados.nota(attrs), "objetivos": objetivos_cumpridos(),
		"fama": fama, "habilidades": habilidades.duplicate(), "resultados": resultados.duplicate(true),
		"vinculo": vinculo, "semente": str(semente)}


# ---------- amuletos (calendario.md §5) ----------

func _efeito(chave: String) -> Array:
	var lista := []
	for a in amuletos:
		var ef: Dictionary = Dados.amuleto(a).get("efeito", {})
		if ef.has(chave):
			lista.append(ef[chave])
	return lista


func tem_efeito(chave: String) -> bool:
	return not _efeito(chave).is_empty()


func _soma(chave: String) -> float:
	var total := 0.0
	for v in _efeito(chave):
		total += float(v)
	return total


## Efeitos de corrida dos amuletos (os de estilo só são oferecidos para o estilo certo).
func efeitos_de_corrida() -> Array:
	return _efeito("corrida")


## Sorteia n amuletos que ela ainda não tem. Amuletos de estilo só saem para o estilo certo.
func oferecer_amuleto(n: int, garantir_raro: bool) -> void:
	var r := Calendario.rng(semente, ["amuleto", turno, amuletos.size()])
	var dados_a: Dictionary = Dados.amuletos
	var pool: Array = dados_a.lista.filter(func(a): return not a.id in amuletos and (not a.has("estilo") or a.estilo == estilo))
	var oferta := []
	for i in n:
		if pool.is_empty():
			break
		var pesos := {}
		for j in pool.size():
			pesos[str(j)] = float(dados_a.peso_tipo[pool[j].tipo])
		var escolhido: Dictionary = pool.pop_at(int(Calendario.sortear_peso(r, pesos)))
		oferta.append(escolhido.id)
	if garantir_raro and not oferta.any(func(id): return Dados.amuleto(id).tipo in ["estilo", "raro"]):
		var especiais := pool.filter(func(a): return a.tipo in ["estilo", "raro"])
		if not especiais.is_empty() and not oferta.is_empty():
			oferta[-1] = especiais[r.randi() % especiais.size()].id
	oferta_amuleto = oferta


## Equipa o amuleto escolhido. Com 6 equipados, troca pelo indicado em "no_lugar_de".
func escolher_amuleto(id: String, no_lugar_de: String = "") -> String:
	oferta_amuleto = []
	var nome_a: String = Dados.amuleto(id).nome
	if amuletos.size() < int(Dados.amuletos.limite):
		amuletos.append(id)
		return "%s equipou o amuleto %s." % [_primeiro_nome(), nome_a]
	var i := amuletos.find(no_lugar_de)
	if i < 0:
		return "O amuleto %s foi deixado de lado." % nome_a
	amuletos[i] = id
	return "%s trocou %s por %s." % [_primeiro_nome(), Dados.amuleto(no_lugar_de).nome, nome_a]


func descartar_oferta() -> String:
	oferta_amuleto = []
	return "Nenhum amuleto novo desta vez."


# ---------- habilidades (GDD §3.4) ----------

func custo_habilidade(id: String) -> int:
	var c: float = Dados.habilidade(id).custo
	if tipo_no() == "biblioteca":
		c *= 1.0 - float(Dados.habilidades.desconto_biblioteca)
	return roundi(c)


func pode_comprar(id: String) -> bool:
	return not id in habilidades and habilidades.size() < int(Dados.habilidades.limite) and pontos >= custo_habilidade(id)


func comprar_habilidade(id: String) -> String:
	if not pode_comprar(id):
		return ""
	pontos -= custo_habilidade(id)
	habilidades.append(id)
	return "%s aprendeu %s." % [_primeiro_nome(), Dados.habilidade(id).nome]


## Ganha uma habilidade de graça; se já tiver ou estiver no limite, vira pontos.
func _ganhar_habilidade(id: String) -> String:
	var h := Dados.habilidade(id)
	if id in habilidades or habilidades.size() >= int(Dados.habilidades.limite):
		pontos += int(h.custo)
		return "+%d pontos de habilidade" % h.custo
	habilidades.append(id)
	return "aprendeu %s" % h.nome

