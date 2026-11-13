class_name Corrida3D
extends Node3D
## Vista 3D da corrida feita com primitivas (placeholder): pista, cercas, arquibancada
## e corredoras de cápsula. Tem vários modos de câmera e um modo automático
## que troca de câmera conforme a fase da corrida.

enum Camera { AUTO, ACOMPANHAR, LATERAL, FRENTE, AEREA, TRIBUNA }
const CAMERA_NOME := ["Automática", "Acompanhar", "Lateral", "Frente", "Aérea", "Tribuna"]

const COR_GRAMA_PISTA := Color("#3f7f3c")
const COR_GRAMA_FORA := Color("#2d5e33")
const COR_CERCA := Color("#f2f2f2")
const COR_PELE := Color("#f1c9a5")

var cores: Array
var nomes: Array
var corredoras: Array = []  # Node3D por corredora
var camera: Camera3D
var modo := Camera.AUTO
var modo_efetivo := Camera.LATERAL
var _desloc_cam := Vector3.ZERO    # posição da câmera relativa à jogadora (suavizada)
var _desloc_olhar := Vector3.ZERO
var _passada := 0.0
var _primeiro_quadro := true


func _init(cores_: Array, nomes_: Array) -> void:
	cores = cores_
	nomes = nomes_


func _ready() -> void:
	_ambiente()
	_pista()
	_arquibancada()
	for i in cores.size():
		var c := _corredora(cores[i], nomes[i], i == 0)
		add_child(c)
		corredoras.append(c)
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.far = 2000.0
	add_child(camera)
	camera.make_current()


# ---------- cenário ----------

func _material(cor: Color, sem_culling := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.9
	if sem_culling:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("#3d6fb6")
	ceu.sky_horizon_color = Color("#b9d3ee")
	ceu.ground_horizon_color = Color("#b9d3ee")
	sky.sky_material = ceu
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	add_child(sol)
	# chão em volta
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(1400, 900)
	chao.mesh = plano
	chao.material_override = _material(COR_GRAMA_FORA)
	chao.position.y = -0.05
	add_child(chao)


## Faixa ao longo da pista entre dois deslocamentos (no chão) ou parede vertical (altura > 0).
func _faixa(d0: float, d1: float, cor: Color, y0 := 0.0, altura := 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 240
	for i in n:
		var s0 := PistaGeo.PERIMETRO * i / n
		var s1 := PistaGeo.PERIMETRO * (i + 1) / n
		var a: Vector3
		var b: Vector3
		var c: Vector3
		var d: Vector3
		if altura > 0.0:
			a = PistaGeo.em_3d(PistaGeo.ponto(s0, d0), y0)
			b = PistaGeo.em_3d(PistaGeo.ponto(s1, d0), y0)
			c = b + Vector3.UP * altura
			d = a + Vector3.UP * altura
		else:
			a = PistaGeo.em_3d(PistaGeo.ponto(s0, d0), y0)
			b = PistaGeo.em_3d(PistaGeo.ponto(s1, d0), y0)
			c = PistaGeo.em_3d(PistaGeo.ponto(s1, d1), y0)
			d = PistaGeo.em_3d(PistaGeo.ponto(s0, d1), y0)
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material(cor, true)
	return mi


func _pista() -> void:
	add_child(_faixa(-1.0, PistaGeo.LARGURA + 1.0, COR_GRAMA_PISTA, 0.0))
	# cercas interna e externa (barra branca sobre postes)
	add_child(_faixa(-1.0, 0.0, COR_CERCA, 1.0, 0.12))
	add_child(_faixa(PistaGeo.LARGURA + 1.0, 0.0, COR_CERCA, 1.0, 0.12))
	var poste := CylinderMesh.new()
	poste.top_radius = 0.05
	poste.bottom_radius = 0.05
	poste.height = 1.0
	var mat := _material(COR_CERCA)
	var s := 0.0
	while s < PistaGeo.PERIMETRO:
		for d in [-1.0, PistaGeo.LARGURA + 1.0]:
			var p := MeshInstance3D.new()
			p.mesh = poste
			p.material_override = mat
			p.position = PistaGeo.em_3d(PistaGeo.ponto(s, d), 0.5)
			add_child(p)
		s += 6.0
	# linha de chegada e marcos de distância
	var linha := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.5, 0.02, PistaGeo.LARGURA + 2.0)
	linha.mesh = caixa
	linha.material_override = _material(Color.WHITE)
	linha.position = PistaGeo.em_3d(PistaGeo.ponto(0.0, PistaGeo.LARGURA / 2.0), 0.02)
	add_child(linha)
	var arco := MeshInstance3D.new()
	var viga := BoxMesh.new()
	viga.size = Vector3(0.4, 0.4, PistaGeo.LARGURA + 4.0)
	arco.mesh = viga
	arco.material_override = _material(Color("#c23b3b"))
	arco.position = PistaGeo.em_3d(PistaGeo.ponto(0.0, PistaGeo.LARGURA / 2.0), 6.0)
	add_child(arco)
	for d in [-2.0, PistaGeo.LARGURA + 2.0]:
		var col := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.4, 6.0, 0.4)
		col.mesh = cb
		col.material_override = arco.material_override
		col.position = PistaGeo.em_3d(PistaGeo.ponto(0.0, d), 3.0)
		add_child(col)
	# placas a cada 200 m antes da chegada
	for m in range(200, 3400, 200):
		var placa := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.15, 1.6, 0.15)
		placa.mesh = pb
		placa.material_override = _material(Color("#c23b3b") if m == 400 else Color("#333333"))
		placa.position = PistaGeo.em_3d(PistaGeo.ponto(-float(m), -1.6), 0.8)
		add_child(placa)


func _arquibancada() -> void:
	var mat := _material(Color("#8a8f99"))
	var mat_teto := _material(Color("#3c5a8a"))
	for degrau in 6:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(220, 1.2, 3.0)
		b.mesh = bm
		b.material_override = mat
		var p := PistaGeo.ponto(0.0, PistaGeo.LARGURA + 8.0 + degrau * 3.0)
		b.position = Vector3(p.x, 0.6 + degrau * 1.2, p.y)
		add_child(b)
	var teto := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(230, 0.5, 22)
	teto.mesh = tm
	teto.material_override = mat_teto
	var pt := PistaGeo.ponto(0.0, PistaGeo.LARGURA + 16.0)
	teto.position = Vector3(pt.x, 14.0, pt.y)
	add_child(teto)
	# uma "plateia" de cubinhos coloridos
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cubo := BoxMesh.new()
	cubo.size = Vector3(0.6, 0.9, 0.6)
	for i in 500:
		var c := MeshInstance3D.new()
		c.mesh = cubo
		c.material_override = _material(Color.from_hsv(rng.randf(), 0.5, 0.9))
		var degrau := rng.randi_range(0, 5)
		var p := PistaGeo.ponto(0.0, PistaGeo.LARGURA + 8.0 + degrau * 3.0)
		c.position = Vector3(p.x + rng.randf_range(-105, 105), 1.65 + degrau * 1.2, p.y)
		add_child(c)


func _corredora(cor: Color, nome: String, jogadora: bool) -> Node3D:
	var raiz := Node3D.new()
	var corpo := Node3D.new()
	corpo.name = "Corpo"
	raiz.add_child(corpo)
	var tronco := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.25
	tronco.mesh = cap
	tronco.material_override = _material(cor)
	tronco.position.y = 0.95
	corpo.add_child(tronco)
	var cabeca := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 0.22
	esf.height = 0.44
	cabeca.mesh = esf
	cabeca.material_override = _material(COR_PELE)
	cabeca.position.y = 1.78
	corpo.add_child(cabeca)
	# orelhas e rabo (cones e cápsula) para ler como "garota cavalo"
	var cabelo := _material(cor.darkened(0.45))
	for lado in [-1.0, 1.0]:
		var orelha := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.07
		cone.height = 0.2
		orelha.mesh = cone
		orelha.material_override = cabelo
		orelha.position = Vector3(lado * 0.12, 2.0, 0.0)
		corpo.add_child(orelha)
	var rabo := MeshInstance3D.new()
	var rc := CapsuleMesh.new()
	rc.radius = 0.08
	rc.height = 0.7
	rabo.mesh = rc
	rabo.material_override = cabelo
	rabo.position = Vector3(0, 0.85, 0.33)
	rabo.rotation_degrees.x = 35.0
	corpo.add_child(rabo)
	var etiqueta := Label3D.new()
	etiqueta.text = nome.split(" ")[0]
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = jogadora
	etiqueta.font_size = 48 if jogadora else 32
	etiqueta.pixel_size = 0.01
	etiqueta.outline_size = 10
	etiqueta.modulate = UI.DESTAQUE if jogadora else Color.WHITE
	etiqueta.position.y = 2.5
	if not jogadora:
		etiqueta.visibility_range_end = 22.0  # nomes das outras só de perto
	raiz.add_child(etiqueta)
	if jogadora:
		var anel := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 0.45
		toro.outer_radius = 0.6
		anel.mesh = toro
		anel.material_override = _material(UI.DESTAQUE)
		anel.position.y = 0.03
		anel.scale.y = 0.1
		raiz.add_child(anel)
	return raiz


# ---------- quadro a quadro ----------

## Faixa lateral (metros da cerca interna) de cada corredora: fixa por índice.
static func faixa(idx: int) -> float:
	return 1.0 + float(idx) * 1.0


## xs: distância percorrida (interpolada) de cada corredora. fase: fase da líder.
func atualizar(xs: Array, dist: float, vel: Array, fase: int, lider: int, delta: float, chegou: bool) -> void:
	_passada += delta
	for i in corredoras.size():
		var s := PistaGeo.s_da_corrida(xs[i], dist)
		var p := PistaGeo.ponto(s, faixa(i))
		var t := PistaGeo.tangente(s)
		var n: Node3D = corredoras[i]
		n.position = PistaGeo.em_3d(p)
		n.look_at(n.position + PistaGeo.em_3d(t), Vector3.UP)
		# balanço da passada: mais rápido quanto maior a velocidade
		var corpo: Node3D = n.get_node("Corpo")
		var freq: float = 2.2 + float(vel[i]) * 0.12
		corpo.position.y = absf(sin((_passada * freq + i * 0.37) * PI)) * 0.12
		corpo.rotation_degrees.x = -12.0 if vel[i] > 1.0 else 0.0
	_camera(xs, dist, fase, lider, delta, chegou)


func _camera(xs: Array, dist: float, fase: int, lider: int, delta: float, chegou: bool) -> void:
	modo_efetivo = modo
	if modo == Camera.AUTO:
		# troca de câmera estilo transmissão de TV, conforme a fase
		modo_efetivo = [Camera.LATERAL, Camera.AEREA, Camera.FRENTE, Camera.ACOMPANHAR][fase]
		if chegou:
			modo_efetivo = Camera.TRIBUNA
	var s_j := PistaGeo.s_da_corrida(xs[0], dist)
	var s_l := PistaGeo.s_da_corrida(xs[lider], dist)
	var pj := PistaGeo.em_3d(PistaGeo.ponto(s_j, faixa(0)))
	var t := PistaGeo.em_3d(PistaGeo.tangente(s_j))
	var nrm := PistaGeo.em_3d(PistaGeo.normal(s_j))
	var pos: Vector3
	var olhar: Vector3
	match modo_efetivo:
		Camera.ACOMPANHAR:
			pos = pj - t * 7.0 + Vector3.UP * 3.0 + nrm * 1.5
			olhar = pj + t * 6.0 + Vector3.UP * 1.2
		Camera.LATERAL:
			pos = pj + nrm * (PistaGeo.LARGURA + 14.0) + Vector3.UP * 5.0 + t * 2.0
			olhar = pj + Vector3.UP * 1.0
		Camera.FRENTE:
			var pl := PistaGeo.em_3d(PistaGeo.ponto(s_l, PistaGeo.LARGURA / 2.0))
			var tl := PistaGeo.em_3d(PistaGeo.tangente(s_l))
			pos = pl + tl * 16.0 + Vector3.UP * 3.0
			olhar = (pl + pj) / 2.0 + Vector3.UP * 1.0
		Camera.AEREA:
			pos = pj - t * 25.0 + Vector3.UP * 40.0 + nrm * 10.0
			olhar = pj + t * 10.0
		Camera.TRIBUNA:
			var chegada := PistaGeo.em_3d(PistaGeo.ponto(0.0, PistaGeo.LARGURA / 2.0))
			pos = PistaGeo.em_3d(PistaGeo.ponto(-25.0, -18.0), 7.0)  # do lado de dentro, olhando a chegada e a arquibancada
			olhar = chegada + Vector3.UP * 1.0
	# suaviza a posição relativa à jogadora, para a câmera não ficar para trás
	var k := 1.0 - exp(-delta * 3.0)
	if _primeiro_quadro:
		k = 1.0
		_primeiro_quadro = false
	_desloc_cam = _desloc_cam.lerp(pos - pj, k)
	_desloc_olhar = _desloc_olhar.lerp(olhar - pj, k)
	camera.position = pj + _desloc_cam
	var alvo := pj + _desloc_olhar
	if camera.position.distance_to(alvo) > 0.1:
		camera.look_at(alvo, Vector3.UP)


func proxima_camera() -> void:
	modo = ((modo + 1) % CAMERA_NOME.size()) as Camera
