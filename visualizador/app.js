// Interface do visualizador. Regras da corrida ficam em sim.js.
const $ = s => document.querySelector(s);
const GAROTAS = window.GAROTAS;
const MAX = 12;
const FASES = ["Largada", "Meio", "Final", "Sprint"];
const ESTILO = { pon: "Ponteira", per: "Perseguidora", arr: "Arrancadora", fec: "Fechadora" };
const APT_NOME = { R: "Ruim", O: "Ok", B: "Boa", X: "Ótima" };
const HUMOR = [["Péssimo", 0.95], ["Mal", 0.975], ["Normal", 1.0], ["Bem", 1.025], ["Ótimo", 1.05]];

let campo = [];        // [{g, humor, nivel}]
let corrida = null;    // corrida em andamento (SIM.novaCorrida)
let nomes = [];        // garotas da corrida em andamento, pelo idx
let vel = 1, raf = 0, acc = 0, ultimo = 0;

const esc = s => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const num = (x, d = 1) => x.toFixed(d).replace(".", ",");
const tempo = t => { const m = Math.floor(t / 60); return (m ? m + ":" + (t % 60 < 10 ? "0" : "") : "") + num(t % 60); };
const ponto = g => `<span class="ponto ${g.estilo}" title="${ESTILO[g.estilo]}">${esc(g.nome[0])}</span>`;
const dist = () => +$("#dist").value, piso = () => +$("#piso").value;
const D = () => SIM.DIST[dist()][1];

// ---------- campo (corredoras) ----------
function carregarCasa() {
  campo = GAROTAS.filter(g => g.casa[0] === dist() && g.casa[1] === piso())
    .map(g => ({ g, humor: 1.0, nivel: 600 }));
  desenharCampo();
}

function desenharCampo() {
  const d = SIM.DIST[dist()][0], p = SIM.PISO[piso()];
  $("#campo tbody").innerHTML = campo.map(({ g, humor, nivel }, i) => `<tr>
    <td>${ponto(g)}${esc(g.nome)}</td>
    <td title="${SIM.DIST[dist()][0]}: ${APT_NOME[g.aptidao[d]]} · ${p}: ${APT_NOME[g.aptidao[p]]}">${g.aptidao[d]}/${g.aptidao[p]}</td>
    <td><select data-i="${i}" data-campo="humor">${HUMOR.map(([n, v]) =>
      `<option value="${v}"${v === humor ? " selected" : ""}>${n}</option>`).join("")}</select></td>
    <td><input data-i="${i}" data-campo="nivel" type="number" min="100" max="1500" step="50" value="${nivel}"></td>
    <td><button type="button" data-rm="${i}" title="Remover">✕</button></td></tr>`).join("");
  $("#contagem").textContent = `(${campo.length}/${MAX})`;
  const usadas = new Set(campo.map(c => c.g));
  $("#addSel").innerHTML = GAROTAS.map((g, i) => usadas.has(g) ? "" :
    `<option value="${i}">${esc(g.nome)} (${ESTILO[g.estilo]}) — ${SIM.DIST[g.casa[0]][0]} ${SIM.PISO[g.casa[1]]}</option>`).join("");
  $("#add").disabled = campo.length >= MAX;
  $("#iniciar").disabled = $("#lote").disabled = campo.length === 0;
  if (!corrida) desenhar();
}

$("#campo").addEventListener("change", e => {
  const el = e.target, i = +el.dataset.i;
  if (el.dataset.campo === "humor") campo[i].humor = +el.value;
  if (el.dataset.campo === "nivel") campo[i].nivel = Math.max(1, +el.value || 600);
});
$("#campo").addEventListener("click", e => {
  if (e.target.dataset.rm === undefined) return;
  campo.splice(+e.target.dataset.rm, 1);
  desenharCampo();
});
$("#add").onclick = () => {
  if (campo.length >= MAX || $("#addSel").value === "") return;
  campo.push({ g: GAROTAS[+$("#addSel").value], humor: 1.0, nivel: 600 });
  desenharCampo();
};
$("#casa").onclick = carregarCasa;
$("#sortear").onclick = () => {
  const n = campo.length || 6, pool = GAROTAS.slice();
  for (let i = pool.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [pool[i], pool[j]] = [pool[j], pool[i]]; }
  campo = pool.slice(0, n).map(g => ({ g, humor: 1.0, nivel: 600 }));
  desenharCampo();
};
$("#dist").onchange = $("#piso").onchange = desenharCampo;
$("#novaSemente").onclick = () => { $("#semente").value = Math.floor(Math.random() * 1e6); };

const montarField = () => campo.map(c => SIM.corredora(c.g, dist(), piso(), c.nivel, c.humor));
const semente = () => Math.trunc(+$("#semente").value) || 0;

// ---------- pista ----------
const cv = $("#pista"), ctx = cv.getContext("2d");
const CX = 400, CY = 220, H = 180, R_IN = 110, LARG = 82, RC = R_IN + LARG / 2;
const PER = 4 * H + 2 * Math.PI * RC; // perímetro pela linha central

// Ponto na pista: s em [0,1] (fração da corrida, chegada no centro da reta de baixo),
// off = distância a partir da cerca interna. Sentido anti-horário na tela.
function pontoPista(s, off) {
  const r = R_IN + off;
  let u = s * PER;
  const arco = Math.PI * RC;
  if (u < H) return [CX + u, CY + r];
  u -= H;
  if (u < arco) { const a = Math.PI / 2 - u / RC; return [CX + H + r * Math.cos(a), CY + r * Math.sin(a)]; }
  u -= arco;
  if (u < 2 * H) return [CX + H - u, CY - r];
  u -= 2 * H;
  if (u < arco) { const a = -Math.PI / 2 - u / RC; return [CX - H + r * Math.cos(a), CY + r * Math.sin(a)]; }
  u -= arco;
  return [CX - H + Math.min(u, H), CY + r];
}

function estadio(r) {
  ctx.beginPath();
  ctx.arc(CX + H, CY, r, -Math.PI / 2, Math.PI / 2);
  ctx.arc(CX - H, CY, r, Math.PI / 2, 3 * Math.PI / 2);
  ctx.closePath();
}

function desenhar(frac = 1) {
  const css = getComputedStyle(document.documentElement), cor = n => css.getPropertyValue(n).trim();
  ctx.clearRect(0, 0, cv.width, cv.height);
  ctx.fillStyle = cor(piso() === 0 ? "--grama" : "--terra");
  estadio(R_IN + LARG); ctx.fill();
  ctx.fillStyle = cor("--painel");
  estadio(R_IN); ctx.fill();
  ctx.strokeStyle = cor("--pista-borda"); ctx.lineWidth = 2;
  estadio(R_IN); ctx.stroke(); estadio(R_IN + LARG); ctx.stroke();

  // marcos de fase e chegada
  const d = corrida ? corrida.D : D();
  ctx.font = "12px system-ui"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
  [[d / 6, "Meio"], [0.6 * d, "Final"], [d - 400, "Sprint"], [0, "Chegada"]].forEach(([x, nome], k) => {
    const [x1, y1] = pontoPista(x / d, 0), [x2, y2] = pontoPista(x / d, LARG), [xt, yt] = pontoPista(x / d, -18);
    ctx.strokeStyle = k === 3 ? cor("--txt") : cor("--pista-borda"); ctx.lineWidth = k === 3 ? 4 : 1;
    ctx.setLineDash(k === 3 ? [] : [4, 4]);
    ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
    ctx.fillStyle = cor("--sutil"); ctx.fillText(nome, xt, yt);
  });
  ctx.setLineDash([]);
  ctx.fillStyle = cor("--sutil"); ctx.font = "600 15px system-ui";
  ctx.fillText(`${d} m · ${piso() === 0 ? "Grama" : "Terra"}`, CX, CY);

  // corredoras (de trás para frente, para a líder ficar por cima)
  const lista = corrida
    ? corrida.rs.map(r => ({ g: nomes[r.idx], i: r.idx, x: r.px + (r.x - r.px) * frac }))
    : campo.map((c, i) => ({ g: c.g, i, x: 0 }));
  lista.sort((a, b) => a.x - b.x).forEach(({ g, i, x }) => {
    const [px, py] = pontoPista(Math.min(x / d, 1), 8 + (i % MAX) * 6);
    ctx.beginPath(); ctx.arc(px, py, 9, 0, 2 * Math.PI);
    ctx.fillStyle = cor("--" + g.estilo); ctx.fill();
    ctx.strokeStyle = "#fff"; ctx.lineWidth = 1.5; ctx.stroke();
    ctx.fillStyle = "#fff"; ctx.font = "700 10px system-ui"; ctx.fillText(g.nome[0], px, py + 0.5);
  });
}

// ---------- corrida animada ----------
function iniciar() {
  cancelAnimationFrame(raf);
  nomes = campo.map(c => c.g);
  corrida = SIM.novaCorrida(montarField(), D(), semente());
  corrida.rs.forEach(r => r.px = r.x);
  $("#avisos").innerHTML = "";
  $("#resultado").hidden = true; $("#ranking").hidden = false; $("#ladoTitulo").textContent = "Ranking";
  acc = 0; ultimo = performance.now();
  raf = requestAnimationFrame(quadro);
}

function passo() {
  corrida.rs.forEach(r => r.px = r.x);
  return corrida.step();
}

function quadro(agora) {
  acc += Math.min((agora - ultimo) / 1000, 0.25) * vel;
  ultimo = agora;
  while (acc >= SIM.DT && !corrida.done) { avisar(passo()); acc -= SIM.DT; }
  atualizar(corrida.done ? 1 : acc / SIM.DT);
  if (corrida.done) return mostrarResultado();
  raf = requestAnimationFrame(quadro);
}

function pular() {
  if (!corrida || corrida.done) return;
  cancelAnimationFrame(raf);
  while (!corrida.done) passo();
  atualizar(1);
  mostrarResultado();
}

function avisar(ev) {
  for (const { idx, tipo, val, dur } of ev) {
    const div = document.createElement("div");
    div.innerHTML = `✨ ${ponto(nomes[idx])}<b>${esc(nomes[idx].nome)}</b>: ` +
      (tipo === "hp" ? `+${Math.round(val * 100)}% fôlego` : `+${num(val * SIM.cfg.ESCALA * 3.6)} km/h por ${num(dur / SIM.cfg.ESCALA)} s`);
    $("#avisos").prepend(div);
    setTimeout(() => div.remove(), 3000);
  }
  while ($("#avisos").children.length > 4) $("#avisos").lastChild.remove();
}

function atualizar(frac) {
  desenhar(frac);
  const rs = corrida.rs;
  const chave = r => r.t !== null ? r.t - 1e6 : -r.x; // quem chegou primeiro, depois quem está mais longe
  const ordem = rs.slice().sort((a, b) => chave(a) - chave(b));
  const lider = ordem[0];
  $("#fase").textContent = corrida.done ? "Chegada" : FASES[SIM.phase(Math.min(lider.x, corrida.D - 1e-9), corrida.D)];
  $("#relogio").textContent = tempo(corrida.t) + " s";
  $("#ranking").innerHTML = ordem.map((r, k) => {
    const g = nomes[r.idx], f = Math.max(r.hp, 0) / r.hpmax;
    const info = r.t !== null ? tempo(r.t) + " s"
      : `${Math.round(r.x)} m · ${Math.round(r.v * 3.6)}/${Math.round(r.vmax * 3.6)} km/h${r.blk > 0 ? " · presa" : ""}${r.buff_t > 0 ? " · ✨" : ""}`;
    return `<li><span class="pos">${k + 1}</span><span>${ponto(g)}${esc(g.nome)}<span class="info">${info}</span></span>
      <span class="barra" title="Fôlego ${Math.round(f * 100)}%"><span class="${f < 0.15 ? "baixo" : ""}" style="width:${Math.min(f, 1) * 100}%"></span></span></li>`;
  }).join("");
}

function mostrarResultado() {
  const ch = corrida.chegada(), t0 = corrida.rs[ch[0]].t;
  registrar("corrida", ch.slice(0, 3).map((i, k) =>
    `${k + 1}º ${nomes[i].nome}${k ? "" : ` (${tempo(corrida.rs[i].t)} s)`}`).join(" · "));
  $("#ladoTitulo").textContent = "Resultado";
  $("#ranking").hidden = true;
  $("#resultado").hidden = false;
  $("#resultado").innerHTML = `<p>Semente ${semente()} · ${corrida.D} m</p><table>
    <thead><tr><th>#</th><th>Garota</th><th>Tempo</th></tr></thead><tbody>${ch.map((i, k) => {
      const t = corrida.rs[i].t;
      return `<tr><td>${k + 1}</td><td>${ponto(nomes[i])}${esc(nomes[i].nome)}</td>
        <td>${tempo(t)} s${k ? ` <small>(+${num(t - t0)})</small>` : ""}</td></tr>`;
    }).join("")}</tbody></table>`;
}

// ---------- lote ----------
function lote() {
  cancelAnimationFrame(raf);
  corrida = null;
  const n = Math.max(1, Math.trunc(+$("#loteN").value) || 1), s0 = semente();
  const field = montarField(), d = D(), gs = campo.map(c => c.g);
  const vit = new Array(field.length).fill(0);
  let k = 0;
  $("#ladoTitulo").textContent = "Lote";
  $("#ranking").hidden = true; $("#resultado").hidden = false;
  $("#lote").disabled = true;
  (function pedaco() {
    const fim = Math.min(n, k + 50);
    for (; k < fim; k++) vit[SIM.race(field, d, s0 + k)[0]]++;
    if (k < n) {
      $("#resultado").innerHTML = `<p>Rodando… ${k}/${n}</p>`;
      return setTimeout(pedaco, 0);
    }
    $("#lote").disabled = false;
    const linhas = gs.map((g, i) => [g, vit[i] / n]).sort((a, b) => b[1] - a[1]);
    registrar(`lote ${n}`, linhas.slice(0, 3).map(([g, p]) => `${g.nome} ${num(p * 100)}%`).join(" · "));
    $("#resultado").innerHTML = `<p>${n} corridas · ${d} m · sementes ${s0}…${s0 + n - 1}</p><table>
      <thead><tr><th>Garota</th><th>Vitórias</th></tr></thead><tbody>${linhas.map(([g, p]) =>
        `<tr><td>${ponto(g)}${esc(g.nome)}</td><td><span class="bar" style="width:${p * 120}px"></span>${num(p * 100)}%</td></tr>`
      ).join("")}</tbody></table>`;
    desenhar();
  })();
}

// ---------- log ----------
// Guarda a configuração de cada corrida para poder repetir. Fica no navegador (localStorage).
let log = [];
try { log = JSON.parse(localStorage.getItem("log") || "[]"); } catch (e) {}

function registrar(tipo, resumo) {
  log.push({ tipo, resumo, dist: dist(), piso: piso(), semente: semente(), quando: new Date().toLocaleTimeString("pt-BR"),
             campo: campo.map(c => [c.g.nome, c.humor, c.nivel]) });
  if (log.length > 200) log.shift();
  try { localStorage.setItem("log", JSON.stringify(log)); } catch (e) {}
  desenharLog();
}

function desenharLog() {
  $("#logVazio").hidden = log.length > 0;
  $("#log").innerHTML = log.map((l, i) => `<li value="${i + 1}"><b>${esc(l.tipo)}</b> · ${l.quando} ·
    ${esc(SIM.DIST[l.dist][1])} m ${l.piso ? "Terra" : "Grama"} · semente ${l.semente} · ${l.campo.length} garotas<br>
    ${esc(l.resumo)}<button type="button" data-rever="${i}">↻ Rever</button></li>`).reverse().join("");
}

$("#log").addEventListener("click", e => {
  const l = log[e.target.dataset.rever];
  if (!l) return;
  $("#dist").value = l.dist; $("#piso").value = l.piso; $("#semente").value = l.semente;
  campo = l.campo.map(([nome, humor, nivel]) => ({ g: GAROTAS.find(g => g.nome === nome), humor, nivel })).filter(c => c.g);
  desenharCampo();
  (l.tipo === "corrida" ? iniciar : lote)();
});
$("#limparLog").onclick = () => { log = []; try { localStorage.removeItem("log"); } catch (e) {} desenharLog(); };
desenharLog();

// ---------- controles ----------
$("#iniciar").onclick = iniciar;
$("#lote").onclick = lote;
$("#pular").onclick = pular;
document.querySelectorAll("[data-vel]").forEach(b => b.onclick = () => {
  vel = +b.dataset.vel;
  document.querySelectorAll("[data-vel]").forEach(x => x.classList.toggle("ativo", x === b));
});

function aplicarTema(t) {
  if (t) document.documentElement.dataset.theme = t;
  if (corrida) atualizar(1); else desenhar();
}
$("#tema").onclick = () => {
  const escuro = document.documentElement.dataset.theme
    ? document.documentElement.dataset.theme === "dark"
    : matchMedia("(prefers-color-scheme: dark)").matches;
  const t = escuro ? "light" : "dark";
  try { localStorage.setItem("tema", t); } catch (e) {}
  aplicarTema(t);
};
matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => aplicarTema());
try { aplicarTema(localStorage.getItem("tema")); } catch (e) {}

carregarCasa();
