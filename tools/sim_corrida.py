"""Protótipo da corrida (docs/corrida.md). Rode: python tools/sim_corrida.py [N]"""
import random, sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor

# ---- constantes (inicial) -------------------------------------------------
V0, A0, DT = 20.0, 0.35, 0.1
K_VEL, K_HP_D, K_HP = 1.2, 0.6, 1.5
K_INT_FINAL = 1.5
K_DET_SPRINT, K_DET_FINAL, K_HP_SPRINT = 7.0, 2.0, 3.0
BLOCK = 0.015
SORTE = float(__import__("os").environ.get("SORTE", 0.025))  # desvio da sorte por corrida
SKILL_BASE, SKILL_INT = 0.0, 1.2  # chance = base + int_coef * Int/1200
# Teto de velocidade: 60 km/h (Vel 0) a 65 km/h (Vel 1200), linear. None desliga.
TETO = (60.0, 65.0)
# Escala de unidades: multiplica todas as velocidades (acelerações por ESCALA², durações por
# 1/ESCALA, gasto de fôlego por segundo por ESCALA). Sem teto, a corrida é a mesma, só mais lenta.
# Com 0,66 os picos ficam em ~58–63 km/h, logo abaixo do teto.
ESCALA = 0.66
KEYS = ["vel", "est", "pod", "det", "int"]
W = {  # pesos por estilo
    "pon": dict(vel=1.0, est=1.0, pod=0.95, det=0.95, int=1.1),
    "per": dict(vel=1.0, est=1.0, pod=1.0, det=1.0, int=1.0),
    "arr": dict(vel=1.0, est=1.0, pod=1.1, det=1.0, int=0.9),
    "fec": dict(vel=1.0, est=1.0, pod=1.05, det=1.1, int=0.85),
}
PH = {  # ritmo por fase: largada, meio, final, sprint
    "pon": (0.9943, 0.9694, 0.9843, 0.9893),
    "per": (0.9877, 0.9678, 0.9927, 0.9977),
    "arr": (0.9710, 0.9659, 1.0060, 1.0110),
    "fec": (0.9568, 0.9669, 1.0122, 1.0525),
}
# habilidades genéricas que toda corredora leva no teste: (fase, tipo, valor, duração s)
SKILLS = [(1, "hp", 0.06, 0), (1, "vel", 0.8, 4.0), (2, "vel", 0.8, 4.0), (2, "hp", 0.04, 0), (3, "vel", 1.0, 4.0)]


def phase(x, D):
    return 0 if x < D / 6 else 1 if x < 0.6 * D else 2 if x < D - 400 else 3


def race(field, D, seed, ph=None):
    """field: lista de (estilo, atributos, multiplicador). Retorna índices na ordem de chegada."""
    rnd = random.Random(seed)
    ph = ph or PH
    k, v0 = ESCALA, V0 * ESCALA
    rs = []
    for idx, (style, s, mult) in enumerate(field):
        e = {k: s[k] * W[style][k] * mult for k in KEYS}
        hpmax = K_HP_D * D + K_HP * e["est"]
        noise = rnd.gauss(0, SORTE * (1 - e["int"] / 2400))
        chance = min(0.9, SKILL_BASE + SKILL_INT * e["int"] / 1200)
        vmax = (TETO[0] + (TETO[1] - TETO[0]) * min(max(e["vel"], 0), 1200) / 1200) / 3.6 if TETO else float("inf")
        rs.append(dict(idx=idx, st=style, e=e, hp=hpmax, hpmax=hpmax, vmax=vmax, v=3.0 * k, x=0.0, t=None,
                       blk=0.0, noise=noise, chance=chance, ph=-1, buff=0.0, buff_t=0.0))
    t = 0.0
    while any(r["t"] is None for r in rs):
        t += DT
        order = sorted(rs, key=lambda r: -r["x"])
        for i, r in enumerate(order):
            if r["t"] is not None:
                continue
            e, p = r["e"], phase(r["x"], D)
            if p != r["ph"]:  # entrou numa fase nova: tenta disparar habilidades dela
                r["ph"] = p
                for fase, tipo, val, dur in SKILLS:
                    if fase == p and rnd.random() < r["chance"]:
                        if tipo == "hp":
                            r["hp"] += val * r["hpmax"]
                        else:
                            r["buff"], r["buff_t"] = val * k, dur / k
            vt = (V0 + K_VEL * e["vel"] / 1000) * k * ph[r["st"]][p] * (1 + r["noise"])
            if p == 2:  # última curva: briga (Det) e escolha de faixa (Int)
                vt += k * (K_DET_FINAL * e["det"] + K_INT_FINAL * e["int"]) / 1000
            if p == 3:  # sprint dosado: só acelera o quanto o fôlego aguenta até a chegada
                bonus = k * (K_DET_SPRINT * e["det"] / 1000 + K_HP_SPRINT * max(r["hp"], 0) / r["hpmax"])
                vf = vt + bonus
                need = 20 * k * (vf / v0) ** 2 * (1.1 - e["det"] / 2000) * (D - r["x"]) / vf
                vt += bonus * min(1.0, max(r["hp"], 0) / need)
            if r["hp"] <= 0:
                vt = v0 * (0.80 + 0.15 * e["det"] / 1000)
            if r["buff_t"] > 0:
                vt += r["buff"]
                r["buff_t"] -= DT
            # bloqueio simples: alguém logo à frente e mais lento
            if i > 0 and p >= 1:
                f = order[i - 1]
                if 0 < f["x"] - r["x"] < 2 and f["v"] < vt and r["blk"] <= 0:
                    if rnd.random() < k * BLOCK * (1 - e["pod"] / 1500) * (1 - e["int"] / 2000):
                        r["blk"] = 1.0 / k
                if r["blk"] > 0:
                    vt = min(vt, f["v"])
                    r["blk"] -= DT
            vt = min(vt, r["vmax"])  # teto de velocidade
            a = A0 * k * k * (0.8 + e["pod"] / 1000) * (5 if p == 0 else 1)
            r["v"] = min(vt, r["v"] + a * DT) if r["v"] < vt else max(vt, r["v"] - 0.8 * k * k * DT)
            cost = 20 * k * (r["v"] / v0) ** 2
            if p == 1:  # ritmo bem dosado no Meio
                cost *= 1.2 - e["int"] / 1500
            if p == 3:
                cost *= 1.1 - e["det"] / 2000
            r["hp"] -= cost * DT
            r["x"] += r["v"] * DT
            if r["x"] >= D:
                r["t"] = t
    return [r["idx"] for r in sorted(rs, key=lambda r: r["t"])]


def winner(args):
    return race(*args)[0]


def winrate(pool, field, D, n, seed=0, ph=None):
    """Fração de vitórias por índice do field em n corridas."""
    wins = Counter(pool.map(winner, [(field, D, seed + k, ph) for k in range(n)], chunksize=20))
    return [wins[i] / n for i in range(len(field))]


def pct(x):
    return f"{round(100 * x):>3}%"


# ---- elenco (data/garotas.json, gerado por tools/gerar_elenco.py) ---------
APT = {"R": 0.90, "O": 0.95, "B": 1.00, "X": 1.05}  # Ruim, Ok, Boa, Ótima
DIST = [("sprint", 1200), ("milha", 1600), ("media", 2000), ("longa", 3200)]
PISO = ["grama", "terra"]


def carregar_elenco():
    import json, os
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "garotas.json")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def corredora(g, d, p, media=600):
    """Garota no formato do simulador, perfil escalado para a média dada, com aptidão aplicada."""
    scale = media * len(KEYS) / sum(g["atributos"].values())
    s = {k: v * scale for k, v in g["atributos"].items()}
    return (g["estilo"], s, APT[g["aptidao"][DIST[d][0]]] * APT[g["aptidao"][PISO[p]]])


def main(n, parts):
    flat = lambda v: dict.fromkeys(KEYS, v)
    with ProcessPoolExecutor() as pool:
      if "A" in parts:
        print(f"## A. Vitórias por estilo (3 de cada, atributos iguais, {n} corridas)")
        print("nível  dist |  pon  per  arr  fec")
        for lvl in (400, 700, 1000):
            field = [(st, flat(lvl), 1.0) for st in W for _ in range(3)]
            for D in (1200, 1600, 2000, 3200):
                wr = winrate(pool, field, D, n)
                by = [sum(wr[3 * j:3 * j + 3]) for j in range(4)]
                print(f"{lvl:>5} {D:>5} | " + " ".join(pct(x) for x in by))

      if "B" in parts:
        print(f"\n## B. +200 num atributo (1 com 800 vs 11 com 600; ~8% = sem efeito)")
        print(" dist |  vel  est  pod  det  int")
        for D in (1200, 2000, 3200):
            row = []
            for k in KEYS:
                field = [("per", flat(600), 1.0)] * 11 + [("per", dict(flat(600), **{k: 800}), 1.0)]
                row.append(winrate(pool, field, D, n)[-1])
            print(f"{D:>5} | " + " ".join(pct(x) for x in row))

      if "C" in parts:
        print(f"\n## C. Multiplicador (aptidão/humor) em 1 de 12 iguais, 2000 m")
        for m in (0.85, 0.95, 0.975, 1.025, 1.05):
            field = [("per", flat(600), 1.0)] * 11 + [("per", flat(600), m)]
            print(f"  x{m:<5} {pct(winrate(pool, field, 2000, n)[-1])}")

      if "D" in parts:
        print("\n## D. Especialistas por combinação (as 6 da casa correm juntas; ideal ~17% cada)")
        gs = carregar_elenco()
        todas = []
        for d, (dn, D) in enumerate(DIST):
            for p, pn in enumerate(PISO):
                casa = [g for g in gs if tuple(g["casa"]) == (d, p)]
                wr = winrate(pool, [corredora(g, d, p) for g in casa], D, n)
                todas += wr
                print(f"{dn:>6} {pn:<5} | " + "  ".join(
                    f"{g['nome'].split()[0][:9]:>9}({g['estilo']}) {pct(x)}" for g, x in zip(casa, wr)))
        print(f"faixa geral: {pct(min(todas))} a {pct(max(todas))}")


if __name__ == "__main__":
    # uso: python tools/sim_corrida.py [N corridas] [testes, ex.: AD]
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 400, sys.argv[2] if len(sys.argv) > 2 else "ABCD")
