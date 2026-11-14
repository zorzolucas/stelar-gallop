"""Gera data/garotas.json: 48 garotas, 6 especialistas por (distância × piso).
As 6 do MVP são fixas (docs/elenco.md); as outras 42 saem de modelos por estilo e distância.
Rode: python tools/gerar_elenco.py   (imprime a tabela em Markdown para o docs/elenco.md)"""
import json, os, random

DIST = ["sprint", "milha", "media", "longa"]
PISO = ["grama", "terra"]
KEYS = ["vel", "est", "pod", "det", "int"]
TOTAL = 460  # soma dos atributos iniciais

# MVP: nome, estilo, atributos, aptidões (Sprint Milha Média Longa | Grama Terra), combinação-casa
MVP = [
    ("Lira",       "pon", (110, 95, 90, 80, 70),  "BXBR", "XO", (1, 0)),
    ("Nashira", "per", (105, 95, 85, 85, 100), "OBXB", "XO", (2, 0)),
    ("Mira",       "fec", (85, 110, 100, 100, 65), "ROBX", "XO", (3, 0)),
    ("Capela",   "arr", (101, 84, 96, 90, 79), "BXOR", "XR", (1, 0)),
    ("Antares",    "pon", (107, 78, 106, 86, 73), "XBRR", "BX", (0, 1)),
    ("Shaula",    "fec", (90, 105, 95, 110, 75), "ROBX", "BX", (3, 1)),
]
NOMES = ["Altair", "Spica", "Adara", "Alcione", "Electra", "Maia", "Mérope", "Celeno", "Bellatrix",
         "Mintaka", "Andrômeda", "Cassiopeia", "Carina", "Vela", "Auriga", "Columba", "Fênix", "Hidra",
         "Tucana", "Corona", "Zaniah", "Alya", "Alhena", "Mizar", "Alcor", "Dubhe", "Deneb", "Albireo",
         "Achernar", "Mimosa", "Hamal", "Mirach", "Almach", "Nunki", "Ankaa", "Zosma", "Elnath", "Saiph",
         "Naos", "Avior", "Atria", "Alnair"]
# pelagens: os nomes não têm mais sobrenome, mas elas ainda servem de semente dos perfis
PELAGENS = ["Castanha", "Gateada", "Ruana", "Oveira", "Melada", "Tobiana", "Douradilha", "Picaça",
            "Preta", "Branca", "Tostada", "Sebruna", "Colorada", "Malacara", "Pangaré", "Bragada"]

# 6 vagas por combinação: os 4 estilos + 2 extras pela distância (dá 12 de cada estilo no total)
EXTRAS = {0: ["pon", "arr"], 1: ["per", "arr"], 2: ["per", "fec"], 3: ["fec", "pon"]}
# ênfase do perfil (somada a uma base igual e depois normalizada para TOTAL)
ENF_DIST = {0: dict(vel=15, est=-20, pod=15, det=0, int=-10),
            1: dict(vel=10, est=-10, pod=5, det=0, int=-5),
            2: dict(vel=0, est=5, pod=-5, det=5, int=-5),
            3: dict(vel=-10, est=20, pod=-15, det=0, int=5)}
ENF_EST = {"pon": dict(vel=5, est=0, pod=0, det=-5, int=0),
           "per": dict(vel=3, est=0, pod=0, det=5, int=-3),
           "arr": dict(vel=0, est=0, pod=0, det=0, int=0),
           "fec": dict(vel=5, est=0, pod=0, det=0, int=-5)}  # Det vale menos com o teto de velocidade
# ajustes manuais depois dos testes (docs/corrida.md §8.4): nome -> soma em cada atributo
AJUSTES = {"Mintaka": dict(vel=4, pod=3, est=-4, int=-3), "Electra": dict(pod=3, int=-3),
           "Corona": dict(vel=3, det=3, est=-3, int=-3), "Hidra": dict(pod=-3, est=3),
           "Tucana": dict(det=-3, est=3)}
APT_LETRA = {0: "X", 1: "B", 2: "O", 3: "R"}  # pela distância até a casa


def perfil(d, st, rnd):
    raw = {k: 100 + ENF_DIST[d][k] + ENF_EST[st][k] + rnd.randint(-4, 4) for k in KEYS}
    s = sum(raw.values())
    return [round(raw[k] * TOTAL / s) for k in KEYS]


def gerar():
    garotas, nomes, pel = [], iter(NOMES), 0
    for nome, st, at, ad, ap, casa in MVP:
        garotas.append(dict(nome=nome, estilo=st, atributos=dict(zip(KEYS, at)),
                            aptidao=dict(zip(DIST + PISO, ad + ap)), casa=casa, mvp=True))
    for d in range(4):
        for p in range(2):
            vagas = ["pon", "per", "arr", "fec"] + EXTRAS[d]
            for g in garotas:
                if tuple(g["casa"]) == (d, p):
                    vagas.remove(g["estilo"])
            for st in vagas:
                nome = next(nomes)
                # a semente do perfil ainda usa o nome antigo com a pelagem, para os
                # atributos continuarem os mesmos de antes da retirada dos sobrenomes
                rnd = random.Random(f"{nome} {PELAGENS[pel % len(PELAGENS)]}")
                pel += 1
                at = perfil(d, st, rnd)
                for k, v in AJUSTES.get(nome.split()[0], {}).items():
                    at[KEYS.index(k)] += v
                apt = {DIST[k]: APT_LETRA[abs(k - d)] for k in range(4)}
                apt.update({PISO[p]: "X", PISO[1 - p]: "O"})
                garotas.append(dict(nome=nome, estilo=st, atributos=dict(zip(KEYS, at)),
                                    aptidao=apt, casa=(d, p), mvp=False))
    return garotas


if __name__ == "__main__":
    gs = gerar()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.makedirs(os.path.join(root, "data"), exist_ok=True)
    with open(os.path.join(root, "data", "garotas.json"), "w", encoding="utf-8") as f:
        json.dump(gs, f, ensure_ascii=False, indent=1)
    from collections import Counter
    assert len(gs) == 48 and len({g["nome"] for g in gs}) == 48
    assert Counter(tuple(g["casa"]) for g in gs) == Counter({(d, p): 6 for d in range(4) for p in range(2)})
    assert Counter(g["estilo"] for g in gs) == Counter(pon=12, per=12, arr=12, fec=12)
    NOME_EST = dict(pon="Ponteira", per="Perseguidora", arr="Arrancadora", fec="Fechadora")
    NOME_APT = dict(X="Ótima", B="Boa", O="Ok", R="Ruim")
    print("| Garota | Casa | Estilo | Vel | Est | Pod | Det | Int | Sprint | Milha | Média | Longa | Grama | Terra |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for g in sorted(gs, key=lambda g: (g["casa"][1], g["casa"][0])):
        d, p = g["casa"]
        casa = f"{['Sprint', 'Milha', 'Média', 'Longa'][d]} {['Grama', 'Terra'][p]}"
        nome = f"**{g['nome']}**" if g["mvp"] else g["nome"]
        a = g["aptidao"]
        print(f"| {nome} | {casa} | {NOME_EST[g['estilo']]} | " + " | ".join(str(g["atributos"][k]) for k in KEYS)
              + " | " + " | ".join(NOME_APT[a[k]] for k in DIST + PISO) + " |")
