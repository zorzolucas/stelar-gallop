extends Node
## Autoload "Dados": carrega o elenco e as constantes de jogo dos arquivos em data/.

const APT := {"R": 0.90, "O": 0.95, "B": 1.00, "X": 1.05}
const APT_NOME := {"R": "Ruim", "O": "Ok", "B": "Boa", "X": "Ótima"}
const DISTANCIAS := {"sprint": 1200.0, "milha": 1600.0, "media": 2000.0, "longa": 3200.0}
const DIST_NOME := {"sprint": "Sprint", "milha": "Milha", "media": "Média", "longa": "Longa"}
const ESTILO_NOME := {"pon": "Ponteira", "per": "Perseguidora", "arr": "Arrancadora", "fec": "Fechadora"}
const ATTR_NOME := {"vel": "Velocidade", "est": "Estamina", "pod": "Poder", "det": "Determinação", "int": "Inteligência"}
const ATTR_CURTO := {"vel": "Vel", "est": "Est", "pod": "Pod", "det": "Det", "int": "Int"}

var garotas: Array = []
var iniciais: Array = []
var rivais: Array = []
var encontros: Dictionary = {}
var calendario: Dictionary = {}


func _ready() -> void:
	garotas = _ler_json("res://data/garotas.json")
	iniciais = _ler_json("res://data/iniciais.json")
	rivais = _ler_json("res://data/rivais.json")
	encontros = _ler_json("res://data/encontros.json")
	calendario = _ler_json("res://data/calendario.json")


func _ler_json(caminho: String) -> Variant:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		push_error("Não consegui abrir %s" % caminho)
		return null
	return JSON.parse_string(f.get_as_text())


func inicial(nome: String) -> Dictionary:
	for i in iniciais:
		if i.nome == nome:
			return i
	return {}


const DIST_ORDEM := ["sprint", "milha", "media", "longa"]
const PISO_ORDEM := ["grama", "terra"]


## Configuração de carreira de qualquer garota. As 6 do MVP vêm de data/iniciais.json;
## as outras 42 (só dados) usam a casa como corrida-alvo e os 2 maiores atributos como treinos naturais.
func config_carreira(nome: String) -> Dictionary:
	var ini := inicial(nome)
	if not ini.is_empty():
		return ini
	var g := garota(nome)
	if g.is_empty():
		return {}
	var keys: Array = SimCorrida.KEYS.duplicate()
	keys.sort_custom(func(a, b): return g.atributos[a] > g.atributos[b])
	return {
		"nome": nome,
		"apelido": "",
		"descricao": "%s especialista em %s na %s." % [ESTILO_NOME[g.estilo],
			DIST_NOME[DIST_ORDEM[int(g.casa[0])]], PISO_ORDEM[int(g.casa[1])]],
		"naturais": keys.slice(0, 2),
		"unica": "",
		"cor": cor_de(nome).to_html(false),
		"distancia": DIST_ORDEM[int(g.casa[0])],
		"piso": PISO_ORDEM[int(g.casa[1])],
		"inicial": false,
	}


## Cor estável a partir do nome, para as garotas sem cor definida.
static func cor_de(nome: String) -> Color:
	return Color.from_hsv(float(absi(hash(nome)) % 360) / 360.0, 0.55, 0.85)


func garota(nome: String) -> Dictionary:
	for g in garotas:
		if g.nome == nome:
			return g
	return {}


## Nota geral (GDD §3.1) a partir da média dos atributos.
static func nota(attrs: Dictionary) -> String:
	var soma := 0.0
	for k in attrs:
		soma += attrs[k]
	var media := soma / maxf(1.0, attrs.size())
	var faixas := [[850, "S"], [700, "A"], [550, "B"], [400, "C"], [300, "D"], [200, "E"], [100, "F"]]
	for f in faixas:
		if media >= f[0]:
			return f[1]
	return "G"
