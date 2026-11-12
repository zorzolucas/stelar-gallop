// Confere o port: 6 especialistas de Sprint Grama, 4000 corridas. Rode: node visualizador/teste_lote.js
// Esperado (docs/corrida.md §8.4): cada uma entre ~13% e ~21%. Python com 4000:
// Altair 16,0 · Spica 16,8 · Adara 16,6 · Alcione 13,8 · Electra 20,3 · Maia 16,6
const SIM = require("./sim.js");
global.window = {};
require("./garotas.js");
const casa = window.GAROTAS.filter(g => g.casa[0] === 0 && g.casa[1] === 0);
const field = casa.map(g => SIM.corredora(g, 0, 0));
const N = 4000, wins = new Array(field.length).fill(0);
for (let k = 0; k < N; k++) wins[SIM.race(field, 1200, k)[0]]++;
casa.forEach((g, i) => console.log(`${g.nome.padEnd(18)} ${g.estilo} ${(100 * wins[i] / N).toFixed(1)}%`));
const ok = wins.every(w => w / N > 0.12 && w / N < 0.22);
console.log(ok ? "OK" : "FORA DA FAIXA");
process.exit(ok ? 0 : 1);
