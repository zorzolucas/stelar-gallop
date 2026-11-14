class_name Calendario
extends RefCounted
## Regras do calendário da carreira (docs/calendario.md): datas, trechos, mapa de rotas,
## clima, objetivos sorteados e corridas geradas. Tudo sai da semente da carreira, com
## fluxos separados por contexto (§6), então o mesmo save repete os mesmos sorteios.
## Funções estáticas que recebem os dados (data/calendario.json) e a semente.

const TURNOS := 48
const OBJETIVOS_FIXOS := {4: "estreia", 24: "gp1", 48: "gp2"}
const TURNOS_OBJETIVO := [4, 12, 24, 36, 48]


static func cal() -> Dictionary:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Dados").calendario


## Gerador com semente própria para um contexto (ex.: ["mapa", 2] ou ["treino", turno]).
static func rng(semente: int, contexto: Array) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([semente] + contexto)
	return r


static func sortear_peso(r: RandomNumberGenerator, pesos: Dictionary) -> String:
	var total := 0.0
	for k in pesos:
		total += pesos[k]
	var x := r.randf() * total
	for k in pesos:
		x -= pesos[k]
		if x < 0.0:
			return k
	return pesos.keys()[-1]


# ---------- datas ----------

static func mes_idx(turno: int) -> int:
	return (turno - 1) / 2


static func data_texto(turno: int) -> String:
	var m := mes_idx(turno)
	return "Ano %d · %s · %s" % [m / 12 + 1, cal().meses[m % 12], "Início" if (turno - 1) % 2 == 0 else "Fim"]


static func estacao(turno: int) -> String:
	return cal().estacoes[mes_idx(turno) % 12]


## Índice do trecho cujo mapa cobre este turno, ou -1.
static func trecho_de(turno: int) -> int:
	var trechos: Array = cal().trechos
	for i in trechos.size():
		if turno >= trechos[i].turnos[0] and turno <= trechos[i].turnos[1]:
			return i
	return -1


## Linha do mapa (mês dentro do trecho) para este turno.
static func linha_do_mapa(turno: int, trecho: int) -> int:
	return mes_idx(turno) - mes_idx(int(cal().trechos[trecho].turnos[0]))


static func e_ferias(turno: int) -> bool:
	for t in cal().trechos:
		if t.has("ferias") and turno >= t.ferias[0] and turno <= t.ferias[1]:
			return true
	return false


static func e_vespera(turno: int) -> bool:
	return cal().trechos.any(func(t): return int(t.vespera) == turno)


# ---------- clima (§4.4) ----------

static func clima(semente: int, turno: int) -> String:
	var m := mes_idx(turno)
	var r := rng(semente, ["clima", m])
	if e_ferias(turno):
		return "calor" if r.randf() < 0.4 else "bom"
	return sortear_peso(r, cal().chance_clima[estacao(turno)])


# ---------- mapa de rotas (§4) ----------

## Mapa de um trecho: lista de linhas (meses), cada uma com 3 nós {tipo, foco?}.
## Cada nó liga ao de baixo e às diagonais. Todo caminho passa por pelo menos 1 Circuito:
## depois do sorteio, cada caminho sem Circuito ganha um, num nó escolhido ao acaso.
static func gerar_mapa(semente: int, trecho: int) -> Array:
	var c := cal()
	var n_linhas: int = c.trechos[trecho].nos
	var r := rng(semente, ["mapa", trecho])
	var pesos := {}
	for tipo in c.nos:
		if tipo == "desafio" and trecho == 0:
			continue
		pesos[tipo] = float(c.nos[tipo].peso)
	var linhas := []
	var desafios := 0
	for i in n_linhas:
		var linha := []
		for col in 3:
			var tipo := sortear_peso(r, pesos)
			if tipo == "desafio":
				desafios += 1
				if desafios > 1:  # no máximo 1 Desafio por trecho
					tipo = "foco"
			linha.append(_no(tipo, r))
		if linha[0].tipo == linha[1].tipo and linha[1].tipo == linha[2].tipo:
			linha[r.randi() % 3] = _no("recuperacao" if linha[0].tipo != "recuperacao" else "foco", r)
		linhas.append(linha)
	if not _caminho_sem_circuito(linhas).is_empty():
		# o menor "corte" possível: 2 Circuitos numa linha e os 2 do lado oposto na seguinte
		# (ex.: colunas 0-1 e depois 1-2). Qualquer caminho passa por um deles.
		var i := r.randi() % (n_linhas - 1)
		var cols_a: Array = [0, 1] if r.randf() < 0.5 else [1, 2]
		var cols_b: Array = [1, 2] if cols_a[0] == 0 else [0, 1]
		for col in cols_a:
			linhas[i][col] = _no("circuito", r)
		for col in cols_b:
			linhas[i + 1][col] = _no("circuito", r)
		# a 3ª coluna dessas linhas não pode ser Circuito (cada linha precisa de 2 tipos)
		for par in [[i, cols_a], [i + 1, cols_b]]:
			for col in 3:
				if not col in par[1] and linhas[par[0]][col].tipo == "circuito":
					linhas[par[0]][col] = _no("foco", r)
	return linhas


static func _no(tipo: String, r: RandomNumberGenerator) -> Dictionary:
	var no := {"tipo": tipo}
	if tipo == "foco":
		no.foco = SimCorrida.KEYS[r.randi() % 5]
	return no


static func vizinhos(col: int) -> Array:
	return range(maxi(0, col - 1), mini(2, col + 1) + 1)


## Um caminho (coluna por linha) que não passa por nenhum Circuito, ou [] se não houver.
static func _caminho_sem_circuito(linhas: Array) -> Array:
	# de_onde[i][col] = coluna anterior de um caminho sem Circuito que chega em (i, col), ou -2
	var de_onde := []
	for i in linhas.size():
		var linha := [-2, -2, -2]
		for col in 3:
			if linhas[i][col].tipo == "circuito":
				continue
			if i == 0:
				linha[col] = -1
				continue
			for v in vizinhos(col):
				if de_onde[i - 1][v] != -2:
					linha[col] = v
					break
		de_onde.append(linha)
	var ultima: Array = de_onde[-1]
	for col in 3:
		if ultima[col] != -2:
			var caminho := []
			var atual := col
			for i in range(linhas.size() - 1, -1, -1):
				caminho.push_front(atual)
				atual = de_onde[i][atual]
			return caminho
	return []


# ---------- objetivos (§3) ----------

static func distancia_vizinha(aptidao: Dictionary, distancia: String) -> String:
	var ordem: Array = ["sprint", "milha", "media", "longa"]
	var i := ordem.find(distancia)
	var opcoes := []
	for j in [i - 1, i + 1]:
		if j >= 0 and j < 4:
			opcoes.append(ordem[j])
	opcoes.sort_custom(func(a, b): return Dados_APT(aptidao[a]) > Dados_APT(aptidao[b]))
	return opcoes[0]


static func Dados_APT(letra: String) -> float:
	return {"R": 0.90, "O": 0.95, "B": 1.00, "X": 1.05}[letra]


static func outro_piso(piso: String) -> String:
	return "terra" if piso == "grama" else "grama"


## Os 5 objetivos da carreira. Os objetivos 2 e 4 são sorteados (§3.2).
static func objetivos(semente: int, aptidao: Dictionary, distancia: String, piso: String) -> Array:
	var c := cal()
	var lista := []
	var nome_gp: Array = c.nome_gp
	lista.append({"turno": 4, "cat": "estreia", "dist": distancia, "piso": piso, "meta": 5,
		"nome": c.nome_estreia, "texto": "Top 5 na Estreia"})
	lista.append(_sortear_objetivo(semente, 12, c.objetivos_2, aptidao, distancia, piso))
	lista.append({"turno": 24, "cat": "gp1", "dist": distancia, "piso": piso, "meta": 5,
		"nome": nome_gp[0], "texto": "Top 5 no %s" % nome_gp[0]})
	var o4 := _sortear_objetivo(semente, 36, c.objetivos_4, aptidao, distancia, piso)
	o4.fama_min = int(c.fama_objetivo_4)
	lista.append(o4)
	lista.append({"turno": 48, "cat": "gp2", "dist": distancia, "piso": piso, "meta": 3,
		"nome": nome_gp[1], "texto": "Top 3 no %s" % nome_gp[1]})
	for o in lista:
		o.id = "obj%d" % o.turno
		if o.cat.begins_with("gp"):
			var rival: String = c.rivais_gp.get("%s_%s" % [o.dist, o.piso], "")
			o.rival = rival
	return lista


static func _sortear_objetivo(semente: int, turno: int, candidatos: Array, aptidao: Dictionary, distancia: String, piso: String) -> Dictionary:
	var r := rng(semente, ["objetivo", turno])
	var pesos := {}
	for i in candidatos.size():
		var cand: Dictionary = candidatos[i]
		if cand.onde == "outro_piso" and aptidao[outro_piso(piso)] == "R":
			continue
		pesos[str(i)] = float(cand.peso)
	var cand: Dictionary = candidatos[int(sortear_peso(r, pesos))]
	var o := {"turno": turno, "cat": cand.cat, "dist": distancia, "piso": piso, "meta": int(cand.meta),
		"texto": cand.texto, "tipo": cand.id, "dificil": cand.get("dificil", false)}
	match cand.onde:
		"vizinha": o.dist = distancia_vizinha(aptidao, distancia)
		"outro_piso": o.piso = outro_piso(piso)
	if cand.has("maratona"):
		o.maratona = int(cand.maratona)
	o.nome = _nome_corrida(r, cand.cat)
	return o


static func _nome_corrida(r: RandomNumberGenerator, cat: String) -> String:
	var nomes: Array = cal().nomes_corrida.get(cat, ["Corrida"])
	return nomes[r.randi() % nomes.size()]


# ---------- corridas opcionais (§7.1) ----------

## Categorias que podem aparecer num Circuito neste turno, com peso.
static func categorias_abertas(turno: int, trecho: int) -> Dictionary:
	var c := cal()
	var pesos := {}
	for cat in ["aberta", "prata", "ouro"]:
		if turno >= int(c.categorias[cat].desde):
			pesos[cat] = 1.0
	if pesos.has("ouro") and trecho == 2:
		pesos.ouro = 2.5  # trecho 3: Ouro com mais frequência, por causa do objetivo 4
	return pesos


## As 2 corridas opcionais de um turno de Circuito. Metade das vezes na casa da garota.
static func corridas_do_circuito(semente: int, turno: int, distancia: String, piso: String) -> Array:
	var r := rng(semente, ["circuito", turno])
	var pesos := categorias_abertas(turno, trecho_de(turno))
	var ordem: Array = ["sprint", "milha", "media", "longa"]
	var lista := []
	for slot in 2:
		var cat := sortear_peso(r, pesos)
		var d := distancia
		var p := piso
		if r.randf() < 0.5:
			d = ordem[r.randi() % 4]
			p = "grama" if r.randf() < 0.7 else "terra"
		lista.append({"id": "c%d_%d" % [turno, slot], "cat": cat, "dist": d, "piso": p, "nome": _nome_corrida(r, cat)})
	return lista


## A corrida de um nó Desafio: elite com +20% de força na categoria mais alta liberada.
static func corrida_desafio(semente: int, turno: int, distancia: String, piso: String) -> Dictionary:
	var r := rng(semente, ["desafio", turno])
	var cats := categorias_abertas(turno, trecho_de(turno)).keys()
	return {"id": "d%d" % turno, "cat": cats[-1], "dist": distancia, "piso": piso, "desafio": true,
		"nome": _nome_corrida(r, "desafio")}


## Distância em metros. Os Grandes Prêmios de Média correm 2400 m (§3.1).
static func metros(corrida: Dictionary) -> float:
	if corrida.cat.begins_with("gp"):
		return float(cal().distancia_gp[corrida.dist])
	return float({"sprint": 1200, "milha": 1600, "media": 2000, "longa": 3200}[corrida.dist])
