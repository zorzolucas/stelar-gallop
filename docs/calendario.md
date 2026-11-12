# Galope Estelar — Calendário da Carreira

> Versão 0.1 — 2026-11-12. Complementa o [GDD](GDD.md) §4.
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

Uma jogadora que treina bem chega acima disso, e uma que descansa demais ou se lesiona chega abaixo. Os objetivos pedem top 3 ou top 5 justamente para dar margem.

## 3. Objetivos

São **5 objetivos**, sempre na **casa** da garota (sua melhor distância e piso, ver [elenco](elenco.md)). Falhou um, a carreira acaba ali, mas a garota pode ser salva como estava (GDD §4.8).

| # | Turno | Data | Corrida | Meta |
|---|---|---|---|---|
| 1 | 4 | Ano 1 · Abr · Fim | **Estreia** na casa | Top 5 |
| 2 | 12 | Ano 1 · Ago · Fim | **Aberta** na casa | Top 3 |
| 3 | 24 | Ano 1 · Fev · Fim | **Grande Prêmio** do ano 1 | Top 5 |
| 4 | 36 | Ano 2 · Ago · Fim | **Ouro** na casa | Top 3 (precisa de 1500 de fama para entrar) |
| 5 | 48 | Ano 2 · Fev · Fim | **Grande Prêmio** do ano 2 | Top 3 |

- O **objetivo 4** é o que dá sentido às corridas opcionais: sem correr, ela não chega a 1500 de fama até o turno 36. A tela de objetivos avisa quanto falta.
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

## 4. Corridas opcionais

- Do turno 5 em diante, quase todo turno oferece **2 ou 3 corridas opcionais** de categorias e casas variadas. Elas não aparecem em turnos de objetivo nem nas férias.
- As opcionais são **geradas por modelo** (categoria × distância × piso, com nome sorteado de uma lista). Assim o MVP não precisa de dezenas de corridas escritas à mão.
- Correr gasta **15 de energia** (inicial) e não dá ganho de treino naquele turno.
- **Corridas seguidas:** a 3ª corrida em 3 turnos seguidos gasta +10 de energia e tem 30% de chance de baixar o humor 1 nível (inicial). Isso evita "só correr" como estratégia.
- Uma carreira típica deve ter **8 a 12 corridas** contando os objetivos.

## 5. Fama

A fama mede quantas pessoas acompanham a garota. Ela nunca diminui durante a carreira.

**Para que serve**
1. **Entrar em corridas** de categoria mais alta (tabela da §2).
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

## 6. Férias de verão

Turnos **21–22** (ano 1) e **45–46** (ano 2), em janeiro.

- **Sem corridas.**
- **Acampamento:** todo treino conta como **1 nível acima** (o nível máximo continua 5).
- **Sair** sempre gera um encontro.
- O descanso recupera mais energia (inicial: +50% sobre o normal).
- As férias do ano 2 ficam logo antes do Grande Prêmio final. É o último "fôlego" para a reta final.

## 7. Linha do tempo resumida

| Turnos | Fase | O que acontece |
|---|---|---|
| 1–3 | Chegada | Tutorial de treino. Sem corridas. Encontro de apresentação com as garotas do elenco. |
| **4** | Objetivo 1 | **Estreia** (top 5). |
| 5–11 | Primeiro semestre | Opcionais Aberta. Primeiros encontros únicos. |
| **12** | Objetivo 2 | **Aberta** na casa (top 3). |
| 13–20 | Segundo semestre | Liberam as Pratas. Corrida e fama começam a disputar com o treino. |
| 21–22 | Férias | Acampamento. |
| 23 | Véspera | Turno normal sem opcionais. Encontro com a rival do Grande Prêmio (quando houver). |
| **24** | Objetivo 3 | **Grande Prêmio** do ano 1 (top 5). |
| 25–35 | Ano 2 | Liberam as Ouros. Corrida atrás de fama para o objetivo 4. |
| **36** | Objetivo 4 | **Ouro** na casa (top 3, fama ≥ 1500). |
| 37–44 | Reta final | Opcionais de todas as categorias. |
| 45–46 | Férias | Acampamento. |
| 47 | Véspera | Turno normal sem opcionais. Encontro com a rival. |
| **48** | Objetivo 5 | **Grande Prêmio** do ano 2 (top 3). Fim da carreira. |

## 8. Corrida em nível baixo

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

## 9. Escopo do MVP

- O calendário completo de 48 turnos entra no MVP.
- **Corridas com nome escrito à mão:** a Estreia e os 2 Grandes Prêmios (contando as 8 casas como versões da mesma corrida). As opcionais e os objetivos 2 e 4 usam o gerador de corridas.
- Rivais com nome só nas casas da tabela §3.1.
