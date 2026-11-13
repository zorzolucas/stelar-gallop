class_name SimCorrida
extends RefCounted
## Simulação da corrida, port de tools/sim_corrida.py e visualizador/sim.js.
## A referência das fórmulas é docs/corrida.md (§2–§7). Se mudar uma constante lá,
## mude aqui também. Não depende de tela: roda headless (ver testes/teste_sim.gd).

const V0 := 20.0
const A0 := 0.35
const DT := 0.1
const K_VEL := 1.2
const K_HP_D := 0.6
const K_HP := 1.5
const K_INT_FINAL := 1.5
const K_DET_SPRINT := 7.0
const K_DET_FINAL := 2.0
const K_HP_SPRINT := 3.0
const BLOCK := 0.015
const SORTE := 0.025
const ESCALA := 0.66
const TETO := [60.0, 65.0]  # km/h com Vel 0 e Vel 1200

const KEYS := ["vel", "est", "pod", "det", "int"]
const PESOS := {
	"pon": {"vel": 1.0, "est": 1.0, "pod": 0.95, "det": 0.95, "int": 1.1},
	"per": {"vel": 1.0, "est": 1.0, "pod": 1.0, "det": 1.0, "int": 1.0},
	"arr": {"vel": 1.0, "est": 1.0, "pod": 1.1, "det": 1.0, "int": 0.9},
	"fec": {"vel": 1.0, "est": 1.0, "pod": 1.05, "det": 1.1, "int": 0.85},
}
const RITMO := {
	"pon": [0.9943, 0.9694, 0.9843, 0.9893],
	"per": [0.9877, 0.9678, 0.9927, 0.9977],
	"arr": [0.9710, 0.9659, 1.0060, 1.0110],
	"fec": [0.9568, 0.9669, 1.0122, 1.0525],
}
## Habilidades genéricas de referência (corrida.md §7): [fase, tipo, valor, duração s].
const GENERICAS := [
	[1, "hp", 0.06, 0.0, "Fôlego Extra"],
	[1, "vel", 0.8, 4.0, "Passada Firme"],
	[2, "vel", 0.8, 4.0, "Curva Limpa"],
	[2, "hp", 0.04, 0.0, "Segundo Fôlego"],
	[3, "vel", 1.0, 4.0, "Reta Decisiva"],
]
## Habilidades únicas das iniciais, simplificadas para o protótipo (elenco.md).
## Cada uma tem a fase em que é testada e uma condição de posição.
const UNICAS := {
	"chama": {"nome": "Chama da Largada", "fase": 0, "val": 1.2, "dur": 6.0},
	"leitura": {"nome": "Leitura de Corrida", "fase": 2, "val": 1.2, "dur": 6.0},
	"vento": {"nome": "Vento de Cauda", "fase": 3, "val": 1.0, "dur": 5.0},
}

var D: float
var t := 0.0
var done := false
var rs: Array = []
var rng := RandomNumberGenerator.new()


## field: lista de Dictionary {nome, estilo, attrs: {vel..int}, mult, unica?}.
func _init(field: Array, distancia: float, seed: int = 0) -> void:
	D = distancia
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	var k := ESCALA
	for idx in field.size():
		var g: Dictionary = field[idx]
		var st: String = g.estilo
		var e := {}
		for key in KEYS:
			e[key] = float(g.attrs[key]) * PESOS[st][key] * float(g.get("mult", 1.0))
		var hpmax: float = K_HP_D * D + K_HP * e.est
		var noise := rng.randfn(0.0, SORTE * (1.0 - e.int / 2400.0))
		var chance := minf(0.9, e.int / 1000.0)
		var vmax: float = (TETO[0] + (TETO[1] - TETO[0]) * clampf(e.vel, 0.0, 1200.0) / 1200.0) / 3.6
		rs.append({
			"idx": idx, "st": st, "e": e, "hp": hpmax, "hpmax": hpmax, "vmax": vmax,
			"v": 3.0 * k, "x": 0.0, "t": -1.0, "blk": 0.0, "noise": noise,
			"chance": chance, "ph": -1, "buff": 0.0, "buff_t": 0.0,
			"unica": g.get("unica", ""),
		})


static func fase(x: float, dist: float) -> int:
	if x < dist / 6.0:
		return 0
	if x < 0.6 * dist:
		return 1
	if x < dist - 400.0:
		return 2
	return 3


func _por_posicao() -> Array:
	var order := rs.duplicate()
	order.sort_custom(func(a, b): return a.x > b.x)
	return order


func _tenta_unica(r: Dictionary, p: int, pos: int, n: int, ev: Array) -> void:
	if r.unica == "" or not UNICAS.has(r.unica):
		return
	var u: Dictionary = UNICAS[r.unica]
	if u.fase != p:
		return
	var ok := false
	var val: float = u.val
	match r.unica:
		"chama": ok = pos == 0
		"leitura": ok = pos >= 1 and pos <= 3
		"vento":
			ok = pos >= n / 2
			val += 0.1 * pos
	if ok and rng.randf() < minf(0.95, r.chance + 0.2):
		r.buff = val * ESCALA
		r.buff_t = u.dur / ESCALA
		ev.append({"idx": r.idx, "nome": u.nome, "unica": true})


## Avança um passo de DT. Retorna as habilidades disparadas: [{idx, nome, unica}].
func step() -> Array:
	var ev := []
	t += DT
	var k := ESCALA
	var v0 := V0 * k
	var order := _por_posicao()
	for i in order.size():
		var r: Dictionary = order[i]
		if r.t >= 0.0:
			continue
		var e: Dictionary = r.e
		var p := fase(r.x, D)
		if p != r.ph:
			r.ph = p
			for s in GENERICAS:
				if s[0] == p and rng.randf() < r.chance:
					if s[1] == "hp":
						r.hp += s[2] * r.hpmax
					else:
						r.buff = s[2] * k
						r.buff_t = s[3] / k
					ev.append({"idx": r.idx, "nome": s[4], "unica": false})
			_tenta_unica(r, p, i, order.size(), ev)
		var vt: float = (V0 + K_VEL * e.vel / 1000.0) * k * RITMO[r.st][p] * (1.0 + r.noise)
		if p == 2:
			vt += k * (K_DET_FINAL * e.det + K_INT_FINAL * e.int) / 1000.0
		if p == 3:
			var hp := maxf(r.hp, 0.0)
			var bonus: float = k * (K_DET_SPRINT * e.det / 1000.0 + K_HP_SPRINT * hp / r.hpmax)
			var vf := vt + bonus
			var need: float = 20.0 * k * pow(vf / v0, 2) * (1.1 - e.det / 2000.0) * (D - r.x) / vf
			vt += bonus * minf(1.0, hp / need)
		if r.hp <= 0.0:
			vt = v0 * (0.80 + 0.15 * e.det / 1000.0)
		if r.buff_t > 0.0:
			vt += r.buff
			r.buff_t -= DT
		if i > 0 and p >= 1:
			var f: Dictionary = order[i - 1]
			var gap: float = f.x - r.x
			if gap > 0.0 and gap < 2.0 and f.v < vt and r.blk <= 0.0:
				if rng.randf() < k * BLOCK * (1.0 - e.pod / 1500.0) * (1.0 - e.int / 2000.0):
					r.blk = 1.0 / k
			if r.blk > 0.0:
				vt = minf(vt, f.v)
				r.blk -= DT
		vt = minf(vt, r.vmax)
		var a: float = A0 * k * k * (0.8 + e.pod / 1000.0) * (5.0 if p == 0 else 1.0)
		if r.v < vt:
			r.v = minf(vt, r.v + a * DT)
		else:
			r.v = maxf(vt, r.v - 0.8 * k * k * DT)
		var cost: float = 20.0 * k * pow(r.v / v0, 2)
		if p == 1:
			cost *= 1.2 - e.int / 1500.0
		if p == 3:
			cost *= 1.1 - e.det / 2000.0
		r.hp -= cost * DT
		r.x += r.v * DT
		if r.x >= D:
			r.t = t
	done = rs.all(func(r): return r.t >= 0.0)
	return ev


## Ordem atual: chegadas primeiro (por tempo), depois quem ainda corre (por distância).
func classificacao() -> Array:
	var order := rs.duplicate()
	order.sort_custom(func(a, b):
		if a.t >= 0.0 and b.t >= 0.0:
			return a.t < b.t
		if a.t >= 0.0 or b.t >= 0.0:
			return a.t >= 0.0
		return a.x > b.x)
	return order.map(func(r): return r.idx)


func rodar_ate_o_fim() -> Array:
	while not done:
		step()
	return classificacao()
