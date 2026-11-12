# Visualizador da corrida

Ferramenta de design para **ver** uma corrida rodando e conferir a simulação. Não é o jogo.

## Abrir

Dê dois cliques em `index.html` (abre via `file://`, funciona offline, sem servidor nem build).

- Escolha distância e piso e clique **Casa** para carregar as 6 especialistas, ou **🎲 Sortear** para pegar garotas aleatórias do elenco todo (mesma quantidade da lista atual, ou 6). Adicione/remova até 12.
- Humor e nível (média dos atributos, padrão 600) são por garota.
- **▶ Correr** anima a corrida com a semente indicada (mesma semente = mesma corrida). 1x é tempo real.
- **Rodar lote** roda N corridas sem animação (sementes `semente … semente+N−1`) e mostra a % de vitória.

- **Log de corridas**: cada corrida e cada lote ficam registrados (até 200, guardados no navegador). **↻ Rever** restaura as garotas, a pista e a semente e roda de novo, com o mesmo resultado.

## Atualizar os dados

Sempre que `data/garotas.json` mudar:

```bash
python visualizador/atualizar_dados.py
```

Isso regera `garotas.js` (o navegador não consegue fazer `fetch` em `file://`).

## Regras da corrida

`sim.js` é um port fiel de `race()` e `corredora()` de `tools/sim_corrida.py` (regras em `docs/corrida.md` v0.5, incluindo o teto de velocidade de 60–65 km/h). Se mudar uma constante ou fórmula lá, copie a mudança para cá.

O RNG é outro (mulberry32), então a mesma semente não dá a mesma corrida que o Python, só a mesma distribuição.

Conferência rápida do port (6 especialistas de Sprint Grama, 4000 corridas, compare com os números do Python no topo do arquivo):

```bash
node visualizador/teste_lote.js
```
