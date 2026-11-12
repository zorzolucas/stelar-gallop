// Port fiel de race() e corredora() de tools/sim_corrida.py (docs/corrida.md §2–§7).
// Se mudar uma constante lá, mude aqui também.
(function () {
  const V0 = 20.0, A0 = 0.35, DT = 0.1;
  const K_VEL = 1.2, K_HP_D = 0.6, K_HP = 1.5;
  const K_INT_FINAL = 1.5;
  const K_DET_SPRINT = 7.0, K_DET_FINAL = 2.0, K_HP_SPRINT = 3.0;
  const BLOCK = 0.015;
  const SORTE = 0.025;
  const SKILL_BASE = 0.0, SKILL_INT = 1.2;
  const KEYS = ["vel", "est", "pod", "det", "int"];
  const W = {
    pon: { vel: 1.0, est: 1.0, pod: 0.95, det: 0.95, int: 1.1 },
    per: { vel: 1.0, est: 1.0, pod: 1.0, det: 1.0, int: 1.0 },
    arr: { vel: 1.0, est: 1.0, pod: 1.1, det: 1.0, int: 0.9 },
    fec: { vel: 1.0, est: 1.0, pod: 1.05, det: 1.1, int: 0.85 },
  };
  const PH = {
    // recalibrado para o teto de velocidade (v0.5)
    pon: [0.9943, 0.9694, 0.9843, 0.9893],
    per: [0.9877, 0.9678, 0.9927, 0.9977],
    arr: [0.9710, 0.9659, 1.0060, 1.0110],
    fec: [0.9568, 0.9669, 1.0122, 1.0525],
  };
  // (fase, tipo, valor, duração s)
  const SKILLS = [[1, "hp", 0.06, 0], [1, "vel", 0.8, 4.0], [2, "vel", 0.8, 4.0], [2, "hp", 0.04, 0], [3, "vel", 1.0, 4.0]];
  const APT = { R: 0.90, O: 0.95, B: 1.00, X: 1.05 };
  // Teto de velocidade (km/h) e escala de unidades. ESCALA multiplica todas as velocidades
  // (acelerações por ESCALA², durações por 1/ESCALA, gasto de fôlego por segundo por ESCALA),
  // então sem o teto a corrida seria a mesma, só mais lenta. Igual a TETO/ESCALA do sim_corrida.py.
  const cfg = { ESCALA: 0.66, TETO: [60, 65] };
  const DIST = [["sprint", 1200], ["milha", 1600], ["media", 2000], ["longa", 3200]];
  const PISO = ["grama", "terra"];

  // RNG com semente (mulberry32) + gauss por Box-Muller.
  // Não reproduz a sequência do random do Python, só a distribuição.
  function rng(seed) {
    let a = seed >>> 0;
    const random = () => {
      a = (a + 0x6D2B79F5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    const gauss = (mu, sigma) => {
      const u = 1 - random(), v = random();
      return mu + sigma * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
    };
    return { random, gauss };
  }

  function phase(x, D) {
    return x < D / 6 ? 0 : x < 0.6 * D ? 1 : x < D - 400 ? 2 : 3;
  }

  // field: lista de [estilo, atributos, multiplicador]. Avance com step() até done.
  function novaCorrida(field, D, seed) {
    const rnd = rng(seed);
    const k = cfg.ESCALA, v0 = V0 * k;
    const rs = field.map(([style, s, mult], idx) => {
      const e = {};
      for (const k of KEYS) e[k] = s[k] * W[style][k] * mult;
      const hpmax = K_HP_D * D + K_HP * e.est;
      const noise = rnd.gauss(0, SORTE * (1 - e.int / 2400));
      const chance = Math.min(0.9, SKILL_BASE + SKILL_INT * e.int / 1200);
      // teto: 60 km/h com Vel 0 até 65 km/h com Vel 1200 (linear)
      const vmax = cfg.TETO ? (cfg.TETO[0] + (cfg.TETO[1] - cfg.TETO[0]) * Math.min(Math.max(e.vel, 0), 1200) / 1200) / 3.6 : Infinity;
      return { idx, st: style, e, hp: hpmax, hpmax, vmax, v: 3.0 * k, x: 0.0, t: null,
               blk: 0.0, noise, chance, ph: -1, buff: 0.0, buff_t: 0.0 };
    });
    const corrida = { rs, D, t: 0.0, done: false };

    // Um passo de DT. Retorna as habilidades disparadas: [{idx, fase, tipo, val, dur}].
    corrida.step = function () {
      const ev = [];
      corrida.t += DT;
      const t = corrida.t;
      const order = rs.slice().sort((a, b) => b.x - a.x);
      for (let i = 0; i < order.length; i++) {
        const r = order[i];
        if (r.t !== null) continue;
        const e = r.e, p = phase(r.x, D);
        if (p !== r.ph) {
          r.ph = p;
          for (const [fase, tipo, val, dur] of SKILLS) {
            if (fase === p && rnd.random() < r.chance) {
              if (tipo === "hp") r.hp += val * r.hpmax;
              else { r.buff = val * k; r.buff_t = dur / k; }
              ev.push({ idx: r.idx, fase, tipo, val, dur });
            }
          }
        }
        let vt = (V0 + K_VEL * e.vel / 1000) * k * PH[r.st][p] * (1 + r.noise);
        if (p === 2) vt += k * (K_DET_FINAL * e.det + K_INT_FINAL * e.int) / 1000;
        if (p === 3) {
          const bonus = k * (K_DET_SPRINT * e.det / 1000 + K_HP_SPRINT * Math.max(r.hp, 0) / r.hpmax);
          const vf = vt + bonus;
          const need = 20 * k * (vf / v0) ** 2 * (1.1 - e.det / 2000) * (D - r.x) / vf;
          vt += bonus * Math.min(1.0, Math.max(r.hp, 0) / need);
        }
        if (r.hp <= 0) vt = v0 * (0.80 + 0.15 * e.det / 1000);
        if (r.buff_t > 0) { vt += r.buff; r.buff_t -= DT; }
        if (i > 0 && p >= 1) {
          const f = order[i - 1];
          if (0 < f.x - r.x && f.x - r.x < 2 && f.v < vt && r.blk <= 0) {
            if (rnd.random() < k * BLOCK * (1 - e.pod / 1500) * (1 - e.int / 2000)) r.blk = 1.0 / k;
          }
          if (r.blk > 0) { vt = Math.min(vt, f.v); r.blk -= DT; }
        }
        vt = Math.min(vt, r.vmax);
        const a = A0 * k * k * (0.8 + e.pod / 1000) * (p === 0 ? 5 : 1);
        r.v = r.v < vt ? Math.min(vt, r.v + a * DT) : Math.max(vt, r.v - 0.8 * k * k * DT);
        let cost = 20 * k * (r.v / v0) ** 2;
        if (p === 1) cost *= 1.2 - e.int / 1500;
        if (p === 3) cost *= 1.1 - e.det / 2000;
        r.hp -= cost * DT;
        r.x += r.v * DT;
        if (r.x >= D) r.t = t;
      }
      corrida.done = rs.every(r => r.t !== null);
      return ev;
    };

    // Índices na ordem de chegada (empate: ordem do field, como o sorted do Python).
    corrida.chegada = () => rs.slice().sort((a, b) => a.t - b.t).map(r => r.idx);
    return corrida;
  }

  function race(field, D, seed) {
    const c = novaCorrida(field, D, seed);
    while (!c.done) c.step();
    return c.chegada();
  }

  // Garota no formato do simulador: perfil escalado para a média, aptidão d × p e humor aplicados.
  function corredora(g, d, p, media = 600, humor = 1.0) {
    const soma = KEYS.reduce((acc, k) => acc + g.atributos[k], 0);
    const scale = media * KEYS.length / soma;
    const s = {};
    for (const k of KEYS) s[k] = g.atributos[k] * scale;
    return [g.estilo, s, APT[g.aptidao[DIST[d][0]]] * APT[g.aptidao[PISO[p]]] * humor];
  }

  const api = { cfg, PH, V0, DT, KEYS, APT, DIST, PISO, phase, novaCorrida, race, corredora };
  if (typeof module !== "undefined") module.exports = api;
  else window.SIM = api;
})();
