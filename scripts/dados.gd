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


func _ready() -> void:
	garotas = _ler_json("res://data/garotas.json")
	iniciais = _ler_json("res://data/iniciais.json")


func _ler_json(caminho: String) -> Array:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		push_error("Não consegui abrir %s" % caminho)
		return []
	var dados = JSON.parse_string(f.get_as_text())
	return dados if dados is Array else []


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
