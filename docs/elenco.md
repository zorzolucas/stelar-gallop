# Galope Estelar — Elenco

> Versão 0.3 — 2026-11-14. Na v0.3 as garotas perderam o sobrenome (Lira Alazã → Lira). Na v0.2 todas foram renomeadas com nomes de estrelas: Nina → Nashira, Brisa → Mira, Vega → Capela, Tainá → Antares, Cora → Shaula, Estela → Polaris, Íris → Algol. Complementa o [GDD](GDD.md).
> Cada garota tem só o nome de uma **estrela ou constelação**, sem sobrenome (na v0.3 saíram as pelagens). Evitamos nomes usados em outros jogos do gênero (ex.: Vega, Sirius).
> Atributos iniciais e efeitos de habilidade são **(inicial)**, ou seja, valores para balancear.

## Visão geral

| # | Garota | Papel | Estilo (principal / secundário) | Melhor distância | Melhor piso |
|---|---|---|---|---|---|
| 1 | **Lira** | Inicial | Ponteira / — | Milha | Grama |
| 2 | **Nashira** | Inicial | Perseguidora / Arrancadora | Média | Grama |
| 3 | **Mira** | Inicial | Fechadora / — | Longa | Grama |
| 4 | **Capela** | Pool | Arrancadora / Perseguidora | Milha | Grama |
| 5 | **Antares** | Pool | Ponteira / Perseguidora | Sprint | Grama |
| 6 | **Shaula** | Pool | Fechadora / Arrancadora | Longa | Terra |
| R1 | **Polaris** | Rival (NPC) | Ponteira | Média | Grama |
| R2 | **Algol** | Rival (NPC) | Arrancadora | Sprint | Terra |

**Cobertura do circuito** (cada copa precisa de uma garota "Ótima" ou "Boa" diferente):

| Copa | Opção principal | Reserva |
|---|---|---|
| Sprint | Antares | Capela |
| Milha | Lira | Capela |
| Média | Nashira | Lira |
| Longa | Mira | Shaula |
| Terra (1200 / 1600 / 2400) | Antares nas curtas, Shaula na 2400 | — |

As 6 garotas cobrem as 5 copas e o Campeonato Final (5 garotas diferentes) sem sobra grande. Por isso a pool importa.

**Triângulo dos iniciais:** uma corre na frente (Lira), uma no meio (Nashira) e uma no fundo (Mira). Cada uma ensina um jeito de correr e de treinar.

---

## Iniciais

### 1. Lira — "a chama da largada"

**Personalidade:** competitiva, barulhenta, otimista. Odeia perder e odeia ainda mais esperar. Chama todo mundo pra apostar corrida até o refeitório.

**Estilo:** Ponteira

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| Boa | **Ótima** | Boa | Ruim | **Ótima** | Ok |

**Atributos iniciais:** Vel 110 · Est 95 · Pod 90 · Det 80 · Int 70

**Habilidade única — Chama da Largada:** na Largada, se ela estiver em 1º, ganha velocidade por alguns segundos e gasta menos fôlego no começo do Meio.

**Treino natural:** Velocidade e Estamina.

**Eventos únicos**
1. *Corrida até o refeitório*: aceitar o desafio (+Vel, −energia) ou recusar (+humor).
2. *Primeira derrota*: consolar (+humor, +afinidade com quem estiver junto) ou deixar treinar sozinha (+Det).
3. *Rival declarada*: encontro com Polaris, que abre a rivalidade das duas.

**Afinidades especiais:** amizade natural com **Antares** (as duas são ponteiras e se pegam no treino). Atrito com **Shaula**, porque se acham opostas.

---

### 2. Nashira — "a estrategista"

**Personalidade:** calma, observadora, anda sempre com um caderno de anotações sobre as outras corredoras. Parece fria, mas lembra o aniversário de todo mundo.

**Estilo:** Perseguidora / Arrancadora

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| Ok | Boa | **Ótima** | Boa | **Ótima** | Ok |

**Atributos iniciais:** Vel 105 · Est 95 · Pod 85 · Det 85 · Int 100

*v0.2: Vel +10, Det +5, Int −15. O perfil antigo concentrava tudo em Inteligência, e ela vencia só 12% na Média, que é a distância "Ótima" dela. Agora vence 21% e é a melhor do elenco ali ([corrida.md](corrida.md) §8.4).*

**Habilidade única — Leitura de Corrida:** no Final, se ela estiver entre 2º e 4º, ganha uma chance maior de achar espaço (bônus de Poder pra sair do pelotão) e acelera.

**Treino natural:** Inteligência e Estamina.

**Eventos únicos**
1. *O caderno perdido*: devolver sem ler (+afinidade grande) ou dar uma olhada (+Int, −humor dela se descobrir).
2. *Plano perfeito*: ela propõe um cronograma. Seguir dá +nível de treino, ignorar dá +humor.
3. *Quando o plano falha*: depois de uma derrota, ajudar a improvisar (+Det) ou refazer o plano (+Int).

**Afinidades especiais:** respeita **Capela** (o talento que ela não consegue prever) e cuida de **Mira**.

---

### 3. Mira — "a última a sair, a primeira a chegar"

**Personalidade:** tímida, sonhadora, distraída. Gosta de olhar as nuvens e se perde no caminho do treino. Quando a corrida aperta, vira outra pessoa.

**Estilo:** Fechadora

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| Ruim | Ok | Boa | **Ótima** | **Ótima** | Ok |

**Atributos iniciais:** Vel 85 · Est 110 · Pod 100 · Det 100 · Int 65

**Habilidade única — Vento de Cauda:** no Sprint, se ela estiver da metade do pelotão pra trás, ganha uma aceleração forte que fica maior quanto mais corredoras ela tiver à frente.

**Treino natural:** Estamina e Poder.

**Eventos únicos**
1. *Perdida no caminho*: ir buscá-la (+afinidade, −1 ação de treino) ou deixar ela chegar sozinha (+Int dela, −humor).
2. *Nuvem em forma de cavalo*: sentar junto e olhar (+humor grande, −energia leve) ou puxar de volta pro treino (+Est).
3. *A outra Mira*: depois da primeira vitória de virada, ela confessa que gosta de correr no fundo. Isso destrava um bônus de Det.

**Afinidades especiais:** protegida por **Nashira**. Admira **Shaula** em segredo.

---

## Pool

### 4. Capela — "a estrela do palco"

**Personalidade:** carismática, vaidosa, sonha em ser ídolo além de corredora. Treina pouco quando não tem plateia, e muito quando tem.

**Estilo:** Arrancadora / Perseguidora

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| Boa | **Ótima** | Ok | Ruim | **Ótima** | Ruim |

**Atributos iniciais:** Vel 101 · Est 84 · Pod 96 · Det 90 · Int 79

**Habilidade única — Holofote:** no Final, se ela passar uma adversária, ganha velocidade. Se passar duas ou mais na mesma fase, o bônus dobra.

**Treino natural:** Velocidade e Poder.

**Eventos únicos**
1. *Ensaio secreto*: assistir ao ensaio de dança (+humor dela, +Pod) ou fingir que não viu (+afinidade mais tarde).
2. *Fã-clube*: ela quer faltar ao treino pra um evento. Liberar (+humor grande, perde um turno) ou insistir (+Vel, −humor).
3. *Sem plateia*: corrida com chuva e arquibancada vazia. Incentivar dá +Det.

**Afinidades especiais:** amizade-rivalidade com **Nashira**. Arrasta **Mira** para os ensaios.

---

### 5. Antares — "a pancada"

**Personalidade:** direta, durona, esportista. Fala pouco, treina muito, ri alto quando ganha. Acorda antes de todo mundo pra correr.

**Estilo:** Ponteira / Perseguidora

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| **Ótima** | Boa | Ruim | Ruim | Boa | **Ótima** |

**Atributos iniciais:** Vel 107 · Est 78 · Pod 106 · Det 86 · Int 73

**Habilidade única — Largada Explosiva:** na Largada, ganha uma aceleração muito forte nos primeiros segundos. Se a corrida for Sprint, o efeito dura mais.

**Treino natural:** Poder e Velocidade.

**Eventos únicos**
1. *Treino às 5h*: acompanhar (+Pod, −energia) ou dormir (+energia, −afinidade).
2. *Lanche proibido*: dividir o lanche (+humor de ambas) ou entregar à treinadora (+Det, −humor dela).
3. *Distância demais*: ela tenta uma Média e passa mal. Apoiar dá +Est e libera uma habilidade genérica de fôlego.

**Afinidades especiais:** parceira de treino de **Lira**. Rivalidade com **Algol** na Terra.

---

### 6. Shaula — "a sombra"

**Personalidade:** sombria, sarcástica, teimosa. Diz que não liga pra nada, mas é a última a sair da pista toda noite. Tem um passado de corridas de terra em uma cidade pequena.

**Estilo:** Fechadora / Arrancadora

| Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|
| Ruim | Ok | Boa | **Ótima** | Boa | **Ótima** |

**Atributos iniciais:** Vel 90 · Est 105 · Pod 95 · Det 110 · Int 75

*v0.3: perfil mais equilibrado e Grama Boa (era Ok). Antes, ela perdia até para NPCs genéricas na Longa.*

**Habilidade única — Nunca Desisto:** no Sprint, se o fôlego dela estiver baixo, ela perde menos velocidade e ganha Det temporária.

**Treino natural:** Determinação e Estamina.

**Eventos únicos**
1. *Última na pista*: ficar até tarde com ela (+Det, −energia) ou mandar descansar (+energia, −humor).
2. *Carta de casa*: ela recebe notícias da cidade natal. Perguntar (+afinidade grande) ou respeitar o silêncio (+humor leve).
3. *Lira de novo*: briga com Lira. Mediar (+afinidade das duas) ou deixar resolverem na pista (corrida de treino que dá +Vel pra vencedora).

**Afinidades especiais:** atrito que vira amizade com **Lira**. Finge não perceber a admiração de **Mira**.

---

## Rivais (NPC)

Não entram no elenco do jogador no MVP. Elas aparecem nas corridas grandes e têm encontros próprios.

### R1. Polaris — "a campeã"

**Personalidade:** elegante, educada e implacável. Campeã do ano anterior. Nunca provoca ninguém, porque nem precisa.

**Estilo:** Ponteira · **Melhor:** Média, Grama

**Papel:** chefe das corridas de fim de ano. Atributos acima da média da categoria. Rival principal de **Lira**.

**Habilidade — Coroa:** na Largada, se ela estiver em 1º, as adversárias logo atrás gastam um pouco mais de fôlego.

### R2. Algol — "a provocadora"

**Personalidade:** debochada, rápida, adora irritar as novatas. Vem do circuito de terra.

**Estilo:** Arrancadora · **Melhor:** Sprint, Terra

**Papel:** chefe da Copa Terra e de algumas corridas Sprint. Rival principal de **Antares**.

**Habilidade — Poeira na Cara:** no Final, se ela passar uma adversária, essa adversária perde um pouco de velocidade por alguns segundos.

---

## Notas de design

- **Soma dos atributos iniciais:** ~445–475 por garota. O "talento" de cada uma está no perfil, não no total.
- Os **eventos únicos** estão com nome e efeito resumido. O texto dos diálogos fica para a fase de conteúdo.
- As **afinidades especiais** são um bônus de afinidade inicial (inicial: +20 numa escala de 0 a 100) ou um atrito (−10), que muda com encontros.
- Cada garota tem **2 treinos naturais**, que ganham um bônus pequeno (inicial: +10%). Isso reforça a identidade dela sem travar o jogador.

---

## Elenco completo (48)

Para o equilíbrio, existem **6 especialistas para cada combinação de distância × piso** (4 × 2 = 8 combinações). Toda garota é **Ótima** na distância e no piso da sua "casa". As outras aptidões caem com a distância: vizinha Boa, a 2 passos Ok, a 3 passos Ruim. O outro piso é Ok.

- As **6 do MVP** (em negrito) têm personalidade e eventos. As outras 42 por enquanto são **só dados** (estilo, atributos, aptidões) para a pool e para o simulador.
- Cada combinação tem os 4 estilos + 2 extras: Sprint +Ponteira/Arrancadora, Milha +Perseguidora/Arrancadora, Média +Perseguidora/Fechadora, Longa +Fechadora/Ponteira. No total são **12 garotas de cada estilo**.
- Todas somam ~460 de atributos iniciais.
- **Fonte da verdade:** [`data/garotas.json`](../data/garotas.json), gerado por [`tools/gerar_elenco.py`](../tools/gerar_elenco.py). Para mudar uma garota, edite o gerador (modelos por estilo/distância ou o dicionário `AJUSTES`) e rode de novo. Esta tabela é a saída do script.

| Garota | Casa | Estilo | Vel | Est | Pod | Det | Int | Sprint | Milha | Média | Longa | Grama | Terra |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Altair | Sprint Grama | Ponteira | 110 | 73 | 104 | 90 | 83 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| Spica | Sprint Grama | Perseguidora | 108 | 77 | 104 | 94 | 77 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| Adara | Sprint Grama | Arrancadora | 108 | 73 | 105 | 88 | 85 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| Alcione | Sprint Grama | Fechadora | 111 | 77 | 104 | 90 | 78 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| Electra | Sprint Grama | Ponteira | 115 | 71 | 111 | 86 | 78 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| Maia | Sprint Grama | Arrancadora | 108 | 71 | 106 | 93 | 82 | Ótima | Boa | Ok | Ruim | Ótima | Ok |
| **Lira** | Milha Grama | Ponteira | 110 | 95 | 90 | 80 | 70 | Boa | Ótima | Boa | Ruim | Ótima | Ok |
| **Capela** | Milha Grama | Arrancadora | 101 | 84 | 96 | 90 | 79 | Boa | Ótima | Ok | Ruim | Ótima | Ruim |
| Cassiopeia | Milha Grama | Perseguidora | 105 | 84 | 92 | 97 | 82 | Boa | Ótima | Boa | Ok | Ótima | Ok |
| Carina | Milha Grama | Fechadora | 107 | 82 | 98 | 91 | 82 | Boa | Ótima | Boa | Ok | Ótima | Ok |
| Vela | Milha Grama | Perseguidora | 106 | 82 | 97 | 93 | 82 | Boa | Ótima | Boa | Ok | Ótima | Ok |
| Auriga | Milha Grama | Arrancadora | 101 | 82 | 96 | 92 | 89 | Boa | Ótima | Boa | Ok | Ótima | Ok |
| **Nashira** | Média Grama | Perseguidora | 105 | 95 | 85 | 85 | 100 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| Alya | Média Grama | Ponteira | 95 | 93 | 85 | 96 | 91 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| Alhena | Média Grama | Arrancadora | 87 | 97 | 90 | 96 | 90 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| Mizar | Média Grama | Fechadora | 97 | 95 | 87 | 100 | 81 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| Alcor | Média Grama | Perseguidora | 95 | 94 | 84 | 102 | 84 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| Dubhe | Média Grama | Fechadora | 99 | 93 | 84 | 99 | 85 | Ok | Boa | Ótima | Boa | Ótima | Ok |
| **Mira** | Longa Grama | Fechadora | 85 | 110 | 100 | 100 | 65 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| Almach | Longa Grama | Ponteira | 86 | 108 | 78 | 89 | 99 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| Nunki | Longa Grama | Perseguidora | 85 | 106 | 79 | 96 | 94 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| Ankaa | Longa Grama | Arrancadora | 80 | 108 | 77 | 94 | 100 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| Zosma | Longa Grama | Fechadora | 87 | 112 | 78 | 93 | 90 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| Elnath | Longa Grama | Ponteira | 87 | 112 | 80 | 89 | 92 | Ruim | Ok | Boa | Ótima | Ótima | Ok |
| **Antares** | Sprint Terra | Ponteira | 107 | 78 | 106 | 86 | 73 | Ótima | Boa | Ruim | Ruim | Boa | Ótima |
| Mérope | Sprint Terra | Perseguidora | 107 | 71 | 103 | 100 | 79 | Ótima | Boa | Ok | Ruim | Ok | Ótima |
| Celeno | Sprint Terra | Arrancadora | 108 | 75 | 104 | 92 | 81 | Ótima | Boa | Ok | Ruim | Ok | Ótima |
| Bellatrix | Sprint Terra | Fechadora | 113 | 69 | 105 | 91 | 81 | Ótima | Boa | Ok | Ruim | Ok | Ótima |
| Mintaka | Sprint Terra | Ponteira | 110 | 73 | 109 | 87 | 81 | Ótima | Boa | Ok | Ruim | Ok | Ótima |
| Andrômeda | Sprint Terra | Arrancadora | 103 | 76 | 105 | 91 | 84 | Ótima | Boa | Ok | Ruim | Ok | Ótima |
| Columba | Milha Terra | Ponteira | 104 | 85 | 94 | 90 | 87 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Fênix | Milha Terra | Perseguidora | 100 | 85 | 96 | 92 | 86 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Hidra | Milha Terra | Arrancadora | 104 | 83 | 97 | 91 | 85 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Tucana | Milha Terra | Fechadora | 104 | 86 | 100 | 90 | 80 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Corona | Milha Terra | Perseguidora | 108 | 80 | 94 | 95 | 82 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Zaniah | Milha Terra | Arrancadora | 99 | 85 | 95 | 95 | 86 | Boa | Ótima | Boa | Ok | Ok | Ótima |
| Deneb | Média Terra | Ponteira | 98 | 94 | 84 | 94 | 90 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| Albireo | Média Terra | Perseguidora | 92 | 97 | 91 | 99 | 82 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| Achernar | Média Terra | Arrancadora | 92 | 97 | 87 | 96 | 88 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| Mimosa | Média Terra | Fechadora | 97 | 93 | 86 | 98 | 86 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| Hamal | Média Terra | Perseguidora | 91 | 99 | 88 | 102 | 80 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| Mirach | Média Terra | Fechadora | 98 | 95 | 89 | 97 | 82 | Ok | Boa | Ótima | Boa | Ok | Ótima |
| **Shaula** | Longa Terra | Fechadora | 90 | 105 | 95 | 110 | 75 | Ruim | Ok | Boa | Ótima | Boa | Ótima |
| Saiph | Longa Terra | Ponteira | 89 | 113 | 80 | 84 | 94 | Ruim | Ok | Boa | Ótima | Ok | Ótima |
| Naos | Longa Terra | Perseguidora | 85 | 109 | 78 | 93 | 96 | Ruim | Ok | Boa | Ótima | Ok | Ótima |
| Avior | Longa Terra | Arrancadora | 82 | 109 | 78 | 95 | 96 | Ruim | Ok | Boa | Ótima | Ok | Ótima |
| Atria | Longa Terra | Fechadora | 91 | 110 | 76 | 92 | 91 | Ruim | Ok | Boa | Ótima | Ok | Ótima |
| Alnair | Longa Terra | Ponteira | 85 | 106 | 81 | 89 | 99 | Ruim | Ok | Boa | Ótima | Ok | Ótima |
