"""Ajusta o ritmo de cada estilo até todos vencerem ~25% (docs/corrida.md §9).
Rode: python tools/ajustar_ritmo.py   -> imprime a tabela PH nova para colar em sim_corrida.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sim_corrida as S
from concurrent.futures import ProcessPoolExecutor

CASES = [(lv, D) for lv in (500, 800) for D in (1200, 1600, 2000, 3200)]


def evaluate(pool, n, ph):
    out = dict.fromkeys(S.W, 0.0)
    for lv, D in CASES:
        field = [(st, dict.fromkeys(S.KEYS, lv), 1.0) for st in S.W for _ in range(3)]
        wr = S.winrate(pool, field, D, n, seed=lv * 7 + D, ph=ph)
        for j, st in enumerate(S.W):
            out[st] += sum(wr[3 * j:3 * j + 3]) / len(CASES)
    return out


if __name__ == "__main__":
    off = dict.fromkeys(S.W, 0.0)
    with ProcessPoolExecutor() as pool:
        for it in range(10):
            ph = {st: tuple(x * (1 + off[st]) for x in S.PH[st]) for st in S.W}
            wr = evaluate(pool, 120, ph)
            print(it, {k: f"{v:.0%}" for k, v in wr.items()}, flush=True)
            # passo pequeno: 1% de ritmo muda a vitória em ~30 pontos
            for st in S.W:
                off[st] += 0.015 * (0.25 - wr[st])
            m = sum(off.values()) / len(off)
            off = {k: v - m for k, v in off.items()}
    for st, row in ph.items():
        print(f'    "{st}": ({", ".join(f"{x:.4f}" for x in row)}),')
