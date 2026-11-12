# Galope Estelar — Calendário da Carreira

> Versão 0.2 — 2026-11-12. Complementa o [GDD](GDD.md) §4.
> Na v0.2 o calendário virou **roguelike**: entre os objetivos, cada carreira sorteia um mapa de rotas (§4), objetivos cumpridos dão amuletos (§5) e uma semente fixa guarda os sorteios (§6).
> Valores marcados com **(inicial)** são pontos de partida para balanceamento.

## 1. Tempo

- A carreira tem **48 turnos** em **2 anos**.
- **1 turno = meio mês**: cada mês tem 2 turnos, **Início** e **Fim**. Assim 12 meses × 2 = 24 turnos por ano, e a conta fecha (com 1 turno por semana, 2 anos dariam 104 turnos).
- O ano da academia segue o ano letivo: começa em **março** e termina em **fevereiro**. As **férias de verão** caem em **janeiro**.
- A tela mostra a data assim: *Ano 1 · Abril · Fim*.

| Mês | Mar | Abr | Mai | Jun | Jul | Ago | Set | Out | Nov | Dez | **Jan** | Fev |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Turnos (ano 1) | 1–2 | 3–4 | 5–6 | 7–8 | 9–10 | 11–12 | 13–14 | 15–16 | 17–18 | 19–20 | **21–22** | 23–24 |
| Turnos (ano 2) | 25–26 | 27–28 | 29–30 | 31–32 | 33–34 | 35–36 | 37–38 | 39–40 | 41–42 | 43–44 | **45–46** | 47–48 |

## 2. Categorias de corrida

Toda corrida tem uma **categoria**. Ela define a força das adversárias, o prêmio e a fama exigida para entrar.

| Categoria | Força das NPCs (média dos atributos, inicial) | Fama para entrar (inicial) | Quando aparece |
|---|---|---|---|
| **Estreia** | 150 | — | Só no turno 4 (a primeira corrida dela) |
| **Aberta** | 250 | 0 | A partir do turno 5 |
| **Prata** | 400 | 600 | A partir do turno 13 |
| **Ouro** | 550 | 1500 | A partir do turno 25 |
| **Grande Prêmio** | Ano 1: 450 · Ano 2: 700 | Por convite (objetivo) | Turnos 24 e 48 |

- A força das NPCs varia ±10% de uma corredora para outra, para o pelotão não ser uniforme.
- No Grande Prêmio, a **rival com nome** da casa corre com +15% sobre a força da categoria.

### 2.1 Curva esperada da jogadora

Para as categorias fazerem sentido, a garota do jogador precisa crescer mais ou menos assim. É o **alvo** para calibrar os ganhos de treino (próxima etapa do GDD):

| Turno | 4 | 12 | 24 | 36 | 48 |
|---|---|---|---|---|---|
| Média dos atributos (inicial) | ~150 | ~280 | ~450 | ~600 | ~750 |

Uma jogadora que treina bem chega acima disso, e uma que descansa demais ou se lesiona chega abaixo. Os objetivos pedem top 3 ou top 5 justamente para dar margem. Amuletos e rotas boas também empurram a curva para cima, então a força das NPCs deve ser calibrada com uma carreira "média" sem amuletos raros.

## 3. Objetivos

São **5 objetivos**, sempre na **casa** da garota (sua melhor distância e piso, ver [elenco](elenco.md)). Falhou um, a carreira acaba ali, mas a garota pode ser salva como estava (GDD §4.8).

| # | Turno | Data | Corrida | Meta |
|---|---|---|---|---|
| 1 | 4 | Ano 1 · Abr · Fim | **Estreia** na casa | Top 5 |
| 2 | 12 | Ano 1 · Ago · Fim | **Aberta** na casa | Top 3 |
| 3 | 24 | Ano 1 · Fev · Fim | **Grande Prêmio** do ano 1 | Top 5 |
| 4 | 36 | Ano 2 · Ago · Fim | **Ouro** na casa | Top 3 (precisa de 1500 de fama para entrar) |
| 5 | 48 | Ano 2 · Fev · Fim | **Grande Prêmio** do ano 2 | Top 3 |

- O **objetivo 4** é o que dá sentido às corridas opcionais: sem passar por Circuitos, ela não chega a 1500 de fama até o turno 36. A tela de objetivos avisa quanto falta.
- Vencer o Grande Prêmio do ano 2 não é obrigatório, mas dá o maior bônus de fim de carreira.
- Os turnos de objetivo são fixos. Nesses turnos a única ação disponível é **Correr**. Se ela estiver lesionada, ela corre assim mesmo, porque a lesão só corta ganho de treino (GDD §4.5).

### 3.1 Grande Prêmio

No turno do Grande Prêmio acontecem **8 corridas ao mesmo tempo**, uma por casa (4 distâncias × 2 pisos). O objetivo usa a da casa da garota. As rivais com nome ficam onde combinam:

| Casa | Rival do Grande Prêmio |
|---|---|
| Média Grama, Longa Grama | **Polaris Moura** |
| Sprint Terra, Milha Terra | **Algol Baia** |
| Outras | Uma NPC "campeã da casa" gerada (sem encontros no MVP) |

Distâncias do Grande Prêmio (inicial): Sprint 1200 m · Milha 1600 m · Média 2400 m · Longa 3200 m.

## 4. Mapa de rotas

Os objetivos são os "chefes" da carreira e ficam sempre no mesmo turno. **Entre um objetivo e outro**, o caminho é um mapa sorteado para cada carreira.

### 4.1 Trechos e nós

A carreira é dividida em **trechos**, um antes de cada objetivo. Cada trecho tem um mapa de **nós**. **Cada nó dura 1 mês (2 turnos).**

| Trecho | Turnos | Nós a escolher | Fixos no fim do trecho | Chefe |
|---|---|---|---|---|
| Chegada | 1–3 | — (tutorial, sem mapa) | — | Objetivo 1 (turno 4) |
| 1 | 5–10 | **3** | Véspera (11) | Objetivo 2 (turno 12) |
| 2 | 13–20 | **4** | Férias (21–22), Véspera (23) | Objetivo 3 (turno 24) |
| 3 | 25–34 | **5** | Véspera (35) | Objetivo 4 (turno 36) |
| 4 | 37–44 | **4** | Férias (45–46), Véspera (47) | Objetivo 5 (turno 48) |

São **16 nós escolhidos** por carreira.

- **Formato do mapa:** 3 colunas, uma linha por mês. Cada nó liga ao nó logo abaixo e aos vizinhos de diagonal, então de um nó saem 2 ou 3 caminhos. O jogador vê o **trecho inteiro** antes de começar, e é isso que permite planejar a rota.
- **Véspera:** turno normal, sem opcionais, com encontro com a rival do próximo objetivo (quando houver).
- **Dentro do nó** o jogador continua escolhendo a ação de cada turno (Treinar, Descansar, Sair, Correr, Enfermaria). O nó só muda o **contexto**: quais corridas existem, quais bônus valem, que eventos podem aparecer. O pilar "treino é dilema" fica intacto.

### 4.2 Tipos de nó

| Nó | Efeito durante o mês (inicial) | Peso no sorteio |
|---|---|---|
| **Treino focado** (atributo X) | O treino de X conta **1 nível acima** (máximo 5). O mapa mostra qual atributo. | Alto |
| **Circuito** | Cada turno oferece **2 corridas opcionais**. O mapa mostra a categoria e a casa de cada uma. **Fora do Circuito não há opcionais.** | Alto |
| **Festival** | **Sair** sempre gera encontro, e encontros dão o dobro de afinidade. Treinos rendem −10%. | Médio |
| **Recuperação** | Descanso rende +50%, a Enfermaria não gasta o turno e o humor não cai por falha. | Médio |
| **Biblioteca** | Habilidades genéricas custam −30% de pontos. O treino de Inteligência conta 1 nível acima. | Baixo |
| **Desafio** | No 2º turno há uma corrida contra uma **NPC de elite** (força da categoria +20%). Top 3 dá **1 amuleto** (§5). Fora do top 3, o humor cai 1 nível. Correr é opcional. | No máximo 1 por trecho, a partir do trecho 2 |
| **Mistério** | No 1º turno, sorteia um evento especial de risco e recompensa (§4.3). | Baixo |

Regras do sorteio:
- Cada linha do mapa tem pelo menos 2 tipos diferentes de nó.
- **Todo caminho possível** do trecho passa por pelo menos **1 Circuito**, para ninguém ficar sem corrida por azar.
- No trecho 3, os Circuitos oferecem Ouro com mais frequência, porque o objetivo 4 pede 1500 de fama.

### 4.3 Eventos de Mistério (exemplos)

- **Treino na serra:** +1 nível no próximo treino de Estamina ou Determinação, mas a chance de falha dobra nesse treino.
- **Treinadora visitante:** escolher 1 entre 2 habilidades genéricas de graça.
- **Aposta no refeitório:** uma corrida-relâmpago contra uma garota do elenco. Vencer dá humor e afinidade, perder tira humor.
- **Noite sem dormir:** −20 de energia, mas o próximo encontro é um evento único garantido.
- **Mercado de pulgas:** trocar 50 pontos de habilidade por um amuleto sorteado.
- **Nada demais:** um passeio tranquilo, +1 humor.

No MVP: **6 eventos de Mistério**.

## 5. Amuletos

Amuletos são modificadores que valem **até o fim da carreira**. Eles criam "builds" diferentes a cada carreira.

- **Como ganhar:** ao cumprir os objetivos 1 a 4, o jogador escolhe **1 entre 3** amuletos sorteados. O nó Desafio e alguns eventos de Mistério também dão amuletos.
- **Limite:** 6 amuletos equipados. Ao ganhar o 7º, troca um ou descarta o novo.
- Uma carreira típica termina com **4 a 6 amuletos**.
- **Não passam para a garota salva.** A versão salva leva só atributos, habilidades e aptidões.

### 5.1 Tipos

| Tipo | Ideia | Frequência |
|---|---|---|
| **Simples** | Bônus pequeno, sem custo | Comum |
| **Troca** | Bônus grande com um custo | Comum |
| **Estilo** | Só funciona com um estilo de corrida | Incomum |
| **Raro** | Muda uma regra do jogo | Raro |

### 5.2 Exemplos (inicial)

| Amuleto | Tipo | Efeito |
|---|---|---|
| Ferradura de Bronze | Simples | Ganho de Velocidade +5% |
| Fita Azul | Simples | +10% de fama em toda corrida |
| Garrafinha | Simples | Descanso recupera +10 de energia |
| Sino de Vento | Troca | Treino de Poder conta 1 nível acima, mas Descansar recupera −20% |
| Coração de Fogo | Troca | Vitória sobe o humor 2 níveis, derrota (fora do top 3) derruba 2 |
| Mapa Velho | Troca | Vê o mapa do trecho seguinte, mas cada trecho tem 1 Circuito a menos |
| Lenço da Ponta | Estilo (Ponteira) | Na Largada, +5% de velocidade se estiver no top 3 |
| Espora de Prata | Estilo (Fechadora) | No Sprint, gasta 10% menos fôlego |
| Bússola | Estilo (Perseguidora) | Chance de bloqueio −30% |
| Trevo Torto | Estilo (Arrancadora) | Habilidades do Final disparam com +15% de chance |
| Estrela Cadente | Raro | Uma vez por carreira, uma falha de treino vira sucesso |
| Constelação | Raro | Os 2 treinos naturais da garota rendem +20% em vez de +10% |

No MVP: **~15 amuletos**.

### 5.3 Progressão entre carreiras

Cada carreira concluída (chegando ao objetivo 5, vencendo ou não) **libera novos amuletos e eventos de Mistério** no sorteio. É uma progressão lenta, que soma com o vínculo e a pool (GDD §3.5 e §6).

## 6. Semente

- Cada carreira tem uma **semente** sorteada no turno 1.
- O mapa de todos os trechos sai da semente logo no início (o jogador só vê o trecho atual).
- Os sorteios usam fluxos separados, cada um calculado por `hash(semente, turno, contexto)`:
  - **mapa** e **amuletos oferecidos**;
  - **treino** (falha, lesão), com a ação escolhida no contexto;
  - **encontros** e **Mistério**;
  - **corrida**, com o id da corrida no contexto.
- Assim, **recarregar o save e repetir a mesma ação dá o mesmo resultado**. Trocar a ação pode mudar o resultado daquele turno, mas nunca reembaralha o mapa nem os turnos seguintes.
- A semente aparece na tela de fim de carreira, para quem quiser compartilhar uma carreira boa.

## 7. Fama e corridas opcionais

A fama mede quantas pessoas acompanham a garota. Ela nunca diminui durante a carreira.

**Para que serve**
1. **Entrar em corridas** de categoria mais alta (tabela da §2). Como as opcionais só aparecem nos nós Circuito (§4.2), quem quer fama precisa escolher rotas com corridas.
2. **Bônus de moeda** no fim da carreira (inicial: +1 moeda a cada 100 de fama; o valor da moeda fica para a etapa de economia).
3. **Encontros com torcedoras**: alguns encontros genéricos só aparecem com fama alta (conteúdo futuro).

**Quanto dá** (inicial)

| Categoria | 1º lugar |
|---|---|
| Estreia | 100 |
| Aberta | 200 |
| Prata | 400 |
| Ouro | 800 |
| Grande Prêmio | 1500 |

Por colocação: 2º = 50% · 3º = 30% · 4º e 5º = 15% · 6º em diante = 5%.

*Exemplo:* uma garota que faz 2º na Estreia (50), vence o objetivo da Aberta (200), vence 2 Abertas opcionais (400) e faz 3º em uma Prata (120) chega ao Grande Prêmio do ano 1 com 770. Com o 4º lugar no Grande Prêmio (225) e mais duas Pratas boas no começo do ano 2, ela passa de 1500 antes do turno 36.

### 7.1 Corridas opcionais

- Só aparecem nos nós **Circuito** (e no Desafio). Elas são **geradas por modelo** (categoria × distância × piso, com nome sorteado de uma lista), então o MVP não precisa de dezenas de corridas escritas à mão.
- Correr gasta **15 de energia** (inicial) e não dá ganho de treino naquele turno.
- **Corridas seguidas:** a 3ª corrida em 3 turnos seguidos gasta +10 de energia e tem 30% de chance de baixar o humor 1 nível (inicial). Um Circuito seguido de outro Circuito cai nessa regra.
- Uma carreira típica deve ter **8 a 12 corridas** contando os objetivos.

## 8. Férias de verão

Turnos **21–22** (ano 1) e **45–46** (ano 2), em janeiro. É um nó fixo no fim dos trechos 2 e 4.

- **Sem corridas.**
- O jogador escolhe 1 entre 2 acampamentos:
  - **Serra:** treinos de Estamina e Determinação contam 1 nível acima.
  - **Praia:** treinos de Velocidade e Poder contam 1 nível acima.
- **Sair** sempre gera um encontro.
- O descanso recupera mais energia (inicial: +50% sobre o normal).
- As férias do ano 2 ficam logo antes do Grande Prêmio final. É o último "fôlego" para a reta final.

## 9. Linha do tempo resumida

| Turnos | Fase | O que acontece |
|---|---|---|
| 1–3 | Chegada | Tutorial de treino. Sem mapa e sem corridas. Encontro de apresentação. |
| **4** | Objetivo 1 | **Estreia** (top 5). Primeiro amuleto. |
| 5–10 | Trecho 1 | Mapa com 3 nós. Opcionais Aberta nos Circuitos. |
| 11 | Véspera | |
| **12** | Objetivo 2 | **Aberta** na casa (top 3). Amuleto. |
| 13–20 | Trecho 2 | Mapa com 4 nós. Liberam as Pratas. Primeiro Desafio possível. |
| 21–22 | Férias | Serra ou Praia. |
| 23 | Véspera | Encontro com a rival do Grande Prêmio. |
| **24** | Objetivo 3 | **Grande Prêmio** do ano 1 (top 5). Amuleto. |
| 25–34 | Trecho 3 | Mapa com 5 nós. Liberam as Ouros. Corrida atrás de fama. |
| 35 | Véspera | |
| **36** | Objetivo 4 | **Ouro** na casa (top 3, fama ≥ 1500). Amuleto. |
| 37–44 | Trecho 4 | Mapa com 4 nós. Opcionais de todas as categorias. |
| 45–46 | Férias | Serra ou Praia. |
| 47 | Véspera | Encontro com a rival. |
| **48** | Objetivo 5 | **Grande Prêmio** do ano 2 (top 3). Fim da carreira. |

## 10. Corrida em nível baixo

As primeiras corridas (Estreia e Aberta) acontecem com atributos entre 150 e 300. O simulador só tinha sido calibrado de 400 para cima ([corrida.md](corrida.md) §8.1). Um teste rápido (300 corridas, 3 de cada estilo, atributos iguais) mostra que os desvios do nível baixo continuam:

| Nível | 1200 | 1600 | 2000 | 3200 |
|---|---|---|---|---|
| **150** | 22 / 18 / 24 / **35** | 27 / 23 / 24 / 26 | 29 / 25 / 23 / 23 | **37** / 27 / 20 / 15 |
| **250** | 21 / 20 / 19 / **40** | 23 / 23 / 21 / **33** | 29 / 25 / 22 / 24 | **33** / 28 / 22 / 17 |

*Ponteira / Perseguidora / Arrancadora / Fechadora (%). Ideal 25%.*

No começo da carreira, a **Fechadora** é forte na Sprint e a **Ponteira** é forte na Longa. Isso pesa nos objetivos 1 e 2. Duas saídas possíveis:
- Recalibrar o ritmo também nos níveis 150–300 (o `ajustar_ritmo` hoje usa 500 e 800).
- Aceitar como "sabor" do começo de carreira e compensar com a meta (top 5 em vez de top 3).

Fica como pendência de balanceamento.

## 11. Escopo do MVP

**Entra**
- O calendário completo de 48 turnos, com os 5 objetivos fixos.
- Mapa de rotas com os **7 tipos de nó** e as regras de sorteio da §4.2.
- **6 eventos de Mistério** e **~15 amuletos**.
- Semente por carreira com fluxos separados (§6).
- **Corridas com nome escrito à mão:** a Estreia e os 2 Grandes Prêmios (contando as 8 casas como versões da mesma corrida). As opcionais, os Desafios e os objetivos 2 e 4 usam o gerador de corridas.
- Rivais com nome só nas casas da tabela §3.1.

**Fica para depois**
- **Clima do mês:** cada mês sorteia uma condição (chuva pesa a terra, calor gasta mais energia).
- **Objetivos 2 e 4 sorteados** de uma lista de candidatos.
- **Dificuldade crescente:** depois de vencer o Grande Prêmio final com uma garota, a próxima carreira dela pode ser jogada num nível mais difícil, com NPCs mais fortes e um amuleto negativo.
