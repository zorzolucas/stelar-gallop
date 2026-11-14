class_name PistaGeo
extends RefCounted
## Geometria da pista oval em metros, usada pela vista 3D e pelo minimapa.
## A linha de chegada fica em s = 0, no meio da reta principal. A corrida termina nela,
## então a largada fica D metros antes (pode dar mais de uma volta).

const RETA := 250.0
const RAIO := 79.577        # com a reta de 250 m, a volta (corda interna) tem 1000 m
const LARGURA := 14.0
const PERIMETRO := 2.0 * RETA + 2.0 * PI * RAIO


## Ponto no plano (x, y) para a posição s ao longo da volta, a "desloc" metros da cerca interna.
static func ponto(s: float, desloc: float) -> Vector2:
	var raio := RAIO + desloc
	var meia := RETA / 2.0
	s = fposmod(s, PERIMETRO)
	if s < meia:
		return Vector2(s, raio)
	s -= meia
	var arco := PI * RAIO
	if s < arco:
		var a := PI / 2.0 - s / RAIO
		return Vector2(meia, 0) + Vector2(cos(a), sin(a)) * raio
	s -= arco
	if s < RETA:
		return Vector2(meia - s, -raio)
	s -= RETA
	if s < arco:
		var a := -PI / 2.0 - s / RAIO
		return Vector2(-meia, 0) + Vector2(cos(a), sin(a)) * raio
	s -= arco
	return Vector2(-meia + s, raio)


## Direção do movimento (unitária) em s.
static func tangente(s: float) -> Vector2:
	return (ponto(s + 0.5, 0.0) - ponto(s - 0.5, 0.0)).normalized()


## Direção para fora da pista (unitária) em s.
static func normal(s: float) -> Vector2:
	return (ponto(s, 1.0) - ponto(s, 0.0)).normalized()


## Posição s na volta para quem já correu x metros de uma corrida de D metros.
static func s_da_corrida(x: float, dist: float) -> float:
	return minf(x, dist) - dist


static func em_3d(p: Vector2, altura: float = 0.0) -> Vector3:
	return Vector3(p.x, altura, p.y)
