# Delivery Salesforce com Agentes

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas por
consultores — o papel que uma estória de Jira teria em outros contextos, aqui é um registro
de demanda dentro deste repositório (veja `sfagents demanda --help`). Modelo: **humano +
agente em co-construção**. Agente nunca entrega sozinho.

## Regra de ouro
Toda demanda passa por **gates humanos bloqueantes**. O agente para e espera aprovação
explícita. Não existe "vou seguindo e depois você revisa".

## Fluxo canônico

| # | Etapa | Agente | Gate |
|---|-------|--------|------|
| 1 | Ler a demanda, refinar critérios de aceite | `ba-discovery` | Humano aprova o refinamento |
| 2 | Recon da org (o que já existe) | `org-recon` (skill) | — |
| 3 | Desenho da solução (declarativo vs código) | `arquiteto` | **BLOQUEANTE** — arquiteto humano aprova |
| 4 | Build em branch + sandbox | `builder-declarativo` / `dev-apex` | PR obrigatório |
| 5 | Testes em sandbox | `qa` | Humano homologa |
| 6 | Empacotamento e deploy sandbox/UAT | `release` | **Prod: proibido ao agente** |
| 7 | Documentação de entrega | `doc` | Spot check |

Antes da etapa 1 de todo cliente novo vem o **assessment da org** (`org-assessment`,
`run-assessment.yml`): diagnóstico read-only da saúde da org, que vira `assessment.md` +
`assessment.json` em `clients/<cliente>/` e o bloco "Saúde da org" no perfil do cliente no
Squad OS. Dispara sozinho quando a org de dev conecta pela primeira vez. Não é demanda —
não tem `status.yaml` nem gate; é o que evita desenhar solução numa org desconhecida.

Num cliente de **contrato de projeto**, as demandas não precisam ser digitadas uma a uma:
o agente `planejador` (`run-planejamento.yml`) lê os entregáveis contratados e propõe as
demandas que eles viram, que entram no quadro em `backlog`. Ele não toca em org nenhuma,
não decide declarativo vs. código e não materializa nada — quem decide o que vira esteira
continua sendo o humano.

O orquestrador (sessão principal) roteia entre agentes. Nunca pula etapa.

## Como a conta é vendida muda o que o time acompanha

O `Contrato` de cada cliente é **AMS** ou **projeto**, e a aba Contrato do Squad OS mostra
coisas diferentes porque as perguntas são diferentes:

- **AMS** — horas contratadas por ciclo, SLA por severidade, e o consumo mês a mês contra
  o contratado. A pergunta é "quanto do balde já foi?".
- **Projeto** — cadastro, entregáveis com peso e progresso ponderado. A pergunta é "quanto
  do escopo já saiu?". O peso existe porque "migrar 12 Flows" e "ajustar um layout"
  contariam igual numa média simples, e o progresso mentiria perto do fim.

As horas vêm dos `RegistroTempo` das demandas do cliente, agrupadas pelo mês em que o
trabalho aconteceu (`inicioEm`), não pelo mês do lançamento. Cronômetro ainda rodando não
entra: hora que não fechou não é hora gasta.

## O ciclo anda sozinho — e onde ele para

Ninguém abre o GitHub Actions pra mover uma demanda. `src/salesforce_agents/fluxo.py`
roda a etapa atual, avança até o próximo gate e devolve o controle; o sync de volta
(`/api/sync/demanda`) faz o quadro do Squad OS mostrar o gate esperando; quando alguém
aprova no card, a próxima etapa dispara sozinha. Detalhes em `docs/ativacao.md`.

Toda rota `/api/sync/*` autentica por bearer token (`lib/sync-auth.ts`), comparado em tempo
constante — e, desde o achado do council de 2026-10-01, por **cliente**: um token único e
global (`SQUAD_OS_SYNC_TOKEN`) comprometia os 6 clientes ao mesmo tempo se vazasse (igual
aprovar qualquer gate de qualquer cliente remotamente, sem passar por nenhum dos guardrails
de produção, que pressupõem aprovação humana legítima antes de chegar neles). Um cliente
migrado pra `SQUAD_OS_SYNC_TOKEN_<CLIENTE>` deixa de aceitar o token global pra ele —
migração real, não mais uma chave que também abre a porta (passo a passo em
`docs/conexoes-e-setup.md`). `run-planejamento.yml` ainda fica de fora dessa segmentação —
é o único workflow de propósito sem GitHub Environment (não toca em org), e Environment é
o mecanismo que torna o token por cliente possível do lado do Actions.

Isso **não afrouxa a regra de ouro**: toda etapa de agente continua sendo seguida por um
gate humano bloqueante — essa invariante tem teste (`tests/test_fluxo.py`). O que ficou
automático é a borda: agente→humano (o gate aparece pra quem precisa ver) e humano→agente
(aprovar aciona). O que era manual antes era o transporte, não a decisão.

O fluxo falha alto em vez de contornar quando o agente não produz o artefato da etapa
(`ArtifactAusenteError`) e quando a etapa cai em org diferente da que o job autenticou.

Antes de falhar, porém, ele **cobra**. Uma sessão de agente aqui é um tiro só: roda num job
de CI e termina quando o modelo para de responder — não há turno seguinte nem ninguém
lendo o chat. O modelo não sabe disso por padrão, e conversa admite "já volto". Achado real
(Konecta, 2026-09-13): o primeiro assessment de uma org de verdade encerrou com o agente
dizendo que seguia "rodando em background" e que avisaria quando terminasse. Não avisou —
a sessão morreu na frase, `assessment.json` nunca existiu, e a tela seguiu mostrando "ainda
não avaliada", igual a nunca ter tentado. `src/salesforce_agents/sessao.py` fecha isso:
confere o disco com a sessão ainda aberta, recobra o agente dizendo que não existe depois
(e que "não consegui medir X" é resposta válida, mas inventar não é), e só então desiste.
Vale para o assessment e para as 7 etapas de demanda.

## Guardrails inegociáveis

1. **Produção é proibida.** Nenhum agente executa deploy, DML ou anonymous Apex em org
   de produção. A esteira tem dois ambientes e só dois: **dev** (`sbx-<cliente>-dev`) e
   **qa** (`sbx-<cliente>-qa`). Build e tudo antes acontece em dev; a partir da etapa `qa`
   a demanda já vive na sandbox de QA, onde o roteiro roda, o humano homologa e o release
   entrega — e o agente para ali. Quem sabe dessa regra é
   `src/salesforce_agents/ambientes.py`, que recusa qualquer ambiente fora de
   `("dev", "qa")` antes de montar comando `sf` nenhum; os workflows perguntam pra ele
   (`sfagents demanda ambiente`) em vez de repetirem a condição em YAML.

   A checagem acontece em **três camadas, e as três respondem perguntas diferentes**:

   - `ambientes.alias_permitido` — **allowlist** de formato: só `sbx-<cliente>-dev|qa`.
   - `.claude/hooks/guard-prod.sh` — PreToolUse do Bash, mesma allowlist, para o `sf`
     que o agente digita no terminal.
   - `src/salesforce_agents/guarda.py` — pergunta à própria org (`Organization.IsSandbox`)
     antes de qualquer escrita, e recusa se ela não se declarar sandbox.

   As duas primeiras conferem o **nome**; a terceira confere o **destino**. Achado do
   council de 2026-09-11: até ali o guardrail era um denylist (`prod|prd|production` no
   texto do comando) registrado só no hook do Bash — e as ferramentas `sf_*` chamam `sf`
   por subprocess de dentro do Python, onde PreToolUse do Bash nunca dispara. Uma org de
   produção autenticada como `sbx-acxya-dev` passava limpo pelas duas pontas. Não
   substitua nenhuma das três pelas outras: um denylist responde "esse nome parece
   produção?", e a pergunta certa sempre foi "essa org é sandbox?".

   O agente `qa` testa a UI Lightning de verdade com um navegador (`qa_browser_*` em
   `tools.py`), não com o servidor MCP oficial do Playwright. Motivo: `--allowed-origins`
   daquele servidor é documentado como "não é um limite de segurança e não afeta
   redirect" — não segurava o guardrail #1 sozinho. `qa_browser_open` é o único ponto
   que decide pra onde o navegador vai, e só chega lá depois de `guarda.url_de_login`
   fazer as mesmas perguntas 1 e 2 de cima; as ferramentas seguintes (click/fill/
   screenshot) operam dentro da sessão já aberta e não aceitam URL. Vale o guardrail #2
   aqui também: nunca screenshotar um registro real de cliente.
2. **Dados reais não entram no contexto.** Nunca rodar SOQL que retorne dados de cliente
   (CPF, e-mail, telefone, valores). Só metadata e contagens agregadas. LGPD.

   O copiloto (`apps/squad-os/app/api/copilot/chat`, `lib/copilot/`) segue este guardrail por
   construção, não por instrução: ele não tem nenhuma ferramenta que fale com Salesforce —
   só lê do mesmo Postgres que a tela já expõe (demandas no vocabulário `ESTADOS_CLIENTE`,
   contrato somente leitura, financeiro só leitura), nas mesmas funções de
   `lib/data.ts`/`lib/contrato.ts`/`lib/contas-data.ts`/`lib/ops.ts` que a UI usa.
   `criar_demanda` é a única ferramenta de escrita de todas (cliente, consultor e admin), e
   chama a mesma `criarDemanda()` que a API — sempre em `backlog`, nunca aprova gate nem
   materializa; as financeiras (`consultar_painel_financeiro`, `consultar_contas_a_pagar`,
   `consultar_divergencias`, `consultar_horas_por_cliente`) não escrevem nada. Existe pra
   todo papel, mas o conjunto de ferramentas muda por quem está perguntando e por onde
   (`app/api/copilot/chat/route.ts` monta o conjunto a cada request, nunca o modelo): cliente
   só vê o próprio cliente; consultor só vê o cliente cuja página está aberta (sem
   ferramenta nenhuma fora de uma página de cliente); admin soma isso com o financeiro,
   sempre; financeiro só vê o financeiro, nunca demanda ou cliente. O `clientId` em escopo
   nunca é um argumento que o modelo escolhe — pro cliente vem sempre da sessão; pra
   consultor/admin vem da página de cliente aberta no navegador (`ClientDetail.tsx` passa o
   id pro componente, que manda no corpo da requisição) e a rota ainda confere
   `canAccessClient` antes de aceitar. Mesmo que a pessoa injete instrução via conversa, não
   existe caminho pra pedir dado de outro cliente — a pergunta nunca chega a existir pra ele.
   Aprovação de gate, pagamento de conta e decisão de divergência continuam exigindo o fluxo
   de confirmação na tela; o copiloto explicitamente recusa qualquer uma das três pelo chat,
   pra qualquer papel.

   RAG interno por cliente (`src/salesforce_agents/rag.py`, `apps/squad-os/lib/rag.ts`,
   `/api/sync/rag*`) — decisão explícita (2026-09-29): **só o pipeline de agentes Python
   consulta**, nunca o copiloto acima, de nenhum papel. O corpus é todo `.md` de
   `clients/<cliente>/` (CLAUDE.md de conta, demanda.md, os artefatos das 7 etapas,
   gates.md, assessment.md) — dado interno de delivery, já sujeito ao guardrail #2 desde
   que foi escrito (nenhum desses arquivos deveria ter CPF/e-mail/telefone/valor de
   cliente; a ingestão não filtra isso de novo, herda a disciplina de quem escreveu). O que
   é novo aqui: os trechos saem daqui pra um provedor de embeddings de terceiro (AI
   Gateway) antes de voltar pro Postgres — um processador a mais que não existia antes
   desta feature, vale saber que existe. `rag_consultar` é fechada por closure sobre o
   `client` que o orchestrator já resolveu pra sessão (nunca um argumento que o agente
   escolhe, mesmo padrão do copiloto) — não tem como pedir dado de outro cliente
   (guardrail #7). A tabela `rag_chunks` tem RLS ligado sem policy, como toda tabela nova
   deste banco (achado de 2026-09-09: sem isso o Supabase publica a linha inteira —
   `conteudo` incluído — via PostgREST pra qualquer um com a anon key).

   Curadoria desse corpus por Obsidian (local, opcional, pra gente — nunca pro pipeline
   de agentes) é `.mcp.json` + `docs/obsidian.md`.
3. **Não invente metadata.** Antes de referenciar qualquer objeto, campo, Flow ou classe,
   confirme via `sf` CLI contra a org. Se não confirmou, declare a incerteza.
4. **Git é obrigatório.** Todo build acontece em branch `feature/<DEMAND-ID>`. Nada é
   commitado direto na main. Todo merge passa por PR com revisor humano — `main` é
   protegida (push direto bloqueado) e exige os checks de CI abaixo passando. Vale pra
   sessão de agente inteira, não só pro build declarativo/Apex: `run-demand.yml` cria/
   reusa `feature/<DEMAND-ID>` (sem o sufixo de descrição — quem cria manualmente pode
   adicionar) e abre PR automaticamente na primeira etapa; `baseline-retrieve.yml` usa
   `baseline/<cliente>` do mesmo jeito. Achado real (ACXYA-1, 2026-09-07): antes dessa
   correção, `run-demand.yml` empurrava direto pra branch que disparou o workflow —
   funcionava só por acaso enquanto isso era uma branch não protegida; quebrou na
   primeira vez que rodou em `main`. `run-demand.yml` roda em dois jobs (`decidir` sem
   environment, `rodar` no `<cliente>-<ambiente>` que o primeiro apontou) porque um job
   do Actions declara um `environment:` só e a esteira atravessa dois.

   **`feature/<DEMAND-ID>` acumula commit a cada etapa — `assessment/<cliente>`,
   `plano/<cliente>` e `baseline/<cliente>` fazem o oposto: são substituídas inteiras a
   cada rodada.** As duas semânticas usam o mesmo "cria a branch se não existir, reusa se
   existir", e é fácil confundir uma com a outra na hora de reusar. Achado real
   (2026-10-02): as três branches de "substituir" reusavam resetando pro **tip remoto
   antigo da própria branch** (`git checkout -B $BRANCH origin/$BRANCH`) em vez de pro
   `main` que acabara de ser clonado no mesmo job — então uma rodada nova partia da foto
   de quando a branch nasceu, não da atual. `assessment/mais-polimeros` herdou assim um
   `main` de antes de `SOMOSAGILITY-2` existir e o PR resultante **deletava** a demanda
   de outro cliente — guardrail #7 quebrado sem ninguém escrever uma linha ruim, só
   porque "reusar" apontou pro lugar errado. Corrigido nos três workflows: a branch
   sempre reparte do checkout fresco (`git checkout -B $BRANCH`, sem start-point) e o
   push vira `--force-with-lease` — seguro aqui porque só o próprio job escreve nessas
   branches, nunca um commit humano por cima pra perder. `feature/<DEMAND-ID>` continua
   como estava: ali reusar o tip remoto é o comportamento certo, é isso que faz a
   demanda acumular etapa sobre etapa.

   - `ci-python.yml` — testes do orquestrador (`src/salesforce_agents/`)
   - `ci-squad-os.yml` — lint + build do Squad OS (`apps/squad-os/`)
   - `ci-salesforce-validate.yml` — `sf project deploy validate` (check-only, nunca
     deploy de verdade) contra a sandbox do cliente cujo `force-app` mudou no PR
5. **Estado em disco.** Cada demanda gera `clients/<cliente>/demandas/<DEMAND-ID>/` com os
   artefatos numerados. Se a sessão cair, o próximo agente lê a pasta e retoma de onde parou.
   `sfagents demanda avancar` **recusa avançar** um estágio de execução pra frente se o
   artefato que aquele estágio deveria ter produzido não existir em disco (`demands.py`,
   `ArtifactAusenteError`) — status.yaml não pode mais declarar um estágio que não aconteceu.
   Corrigir manualmente pra trás (reverter um status errado) sempre é permitido, sem exigir
   o artefato do estágio abandonado.
6. **Uma demanda por vez, por cliente.** Não paralelize builds na mesma sandbox sem alinhar
   com o humano.
7. **Nunca misture clientes.** Cada cliente vive isolado em `clients/<cliente>/`, com seu
   próprio org, seu próprio `CLAUDE.md` de briefing e seu próprio histórico de demandas.

## Convenções

- Branch: `feature/<DEMAND-ID>-descricao-curta`
- Commit: `<DEMAND-ID>: verbo no imperativo`
- Cobertura mínima de teste Apex: 85% por classe
- Toda classe tem classe de teste dedicada `<Classe>Test`
- Nomenclatura de campo/Flow/classe: ver skill `padrao-entrega` (convenção específica de
  cada cliente pode sobrepor a convenção padrão — confira o `CLAUDE.md` do cliente primeiro)

## Seleção de modelo por agente

Cada agente em `.claude/agents/*.md` declara `model:` no frontmatter — não roda mais tudo
no mesmo modelo default por acidente. Heurística aplicada (council de 2026-09-07, ver
`gates.md`/histórico de sessão — não repita a análise, ela já foi feita):

- **haiku** — `ba-discovery`, `doc`: extração e formatação de texto, sem decisão de risco.
- **sonnet** — `builder-declarativo`, `dev-apex`, `devops`, `qa`, `release`, `planejador`,
  `org-assessment`: trabalho
  estruturado com julgamento, mas revisado por PR ou gate antes de valer. Cavalo de batalha.
- **opus** — só `arquiteto`, e só pela decisão declarativo-vs-código em si: é o único gate
  humano bloqueante da doutrina, erro ali compõe nos 6 clientes, e já paga a latência de
  revisão humana de qualquer forma.

**Isso é hipótese reversível, não doutrina validada.** Ninguém tem sinal empírico de
custo/latência/taxa-de-retrabalho por agente ainda — nenhuma demanda completou o ciclo
inteiro. Antes de tratar esta tabela como padrão para os outros 5 clientes, rode pelo menos
um ciclo completo real (ACXYA-1) e confira se algum agente errou por estar num modelo
barato demais ou custou caro demais num modelo caro demais para o que fez. Ajuste com dado,
não com a heurística sozinha.

### Telemetria de custo

Segundo council de otimização de custo (2026-09-07): a variável que domina o custo deste
pipeline não é qual modelo cada agente usa — é o reprocessamento de `CLAUDE.md`/skills sem
cache em 7 etapas × 6 clientes × ciclo indefinido. Antes de mexer em cache, model routing ou
Batch API, é preciso medir. `src/salesforce_agents/orchestrator.py` agora loga cada sessão
de agente (`src/salesforce_agents/costs.py`) em `logs/custos_agentes/` — modelo, tokens
de input/output/cache, custo em USD, etapa, cliente, demanda. Só metadata e contagens, nunca
conteúdo da demanda (guardrail #2). Esse log é o pré-requisito pra qualquer decisão futura de
caching ou de revisão da tabela de modelo acima — sem ele, qualquer ajuste continua sendo
achismo.

`logs/custos_agentes/` **é versionado** (commitado pelo workflow `run-demand.yml`, mesmo
passo que commita os artefatos da demanda) — precisa sobreviver entre execuções de CI, que
rodam em runner efêmero. Achado real (ACXYA-1, 2026-09-07): a primeira sessão real de agente
gerou o log dentro do runner, mas como o arquivo estava no `.gitignore` e o commit só incluía
`clients/$CLIENT`, o dado se perdeu — corrigido depois desse incidente.

**Um arquivo por sessão, não um CSV único crescendo** (mudou em 2026-10-02, achado do
council daquele dia): o formato original era `logs/custos_agentes.csv`, um arquivo só que
toda sessão appendava. Cada demanda vive na própria branch `feature/<DEMAND-ID>` (guardrail
#4) — duas demandas de clientes diferentes, cada uma appendando no fim do mesmo arquivo,
geram PRs que conflitam entre si quando os dois tentam mesclar na mesma região do arquivo.
Aconteceu de verdade (somos-agility × eplast). `logs/custos_agentes.csv` (singular) continua
existindo só como arquivo **legado**, com o que foi gravado antes da mudança — nunca mais
escrito, só lido. Quem precisa do agregado usa
`salesforce_agents.costs.ler_todas_as_linhas()`, que junta os dois (ver skill
`revisar-custos`).

## Estrutura de artefatos por demanda

```
clients/<cliente>/demandas/<DEMAND-ID>/
  demanda.md         # a história enviada pelo consultor — entrada, não editar
  status.yaml        # estágio atual e histórico de transições (mantido pela CLI sfagents)
  01-analise.md      # BA: contexto, critérios de aceite, dúvidas
  02-recon.md        # o que já existe na org e será impactado
  03-design.md       # decisão declarativo vs código + justificativa
  04-plano-build.md  # passo a passo do que será criado/alterado
  05-testes.md       # roteiro + resultado
  06-entrega.md      # documentação final
  gates.md           # log de aprovações humanas — escrito por sfagents, não pelo agente
```

`gates.md` é **mecânico**: `src/salesforce_agents/gates.py` escreve o bloco no
momento em que o humano aprova, com o sha256 de cada artefato que estava na mesa.
Nenhum agente escreve nele — era instrução no prompt até 2026-09-11, e instrução
é a camada mais fraca que existe pro único rastro do gate bloqueante da doutrina.

O hash é o que transforma "fulano aprovou o design" em "fulano aprovou **este**
design": `sfagents demanda conferir-gates --client <cliente> <DEMAND-ID>` responde
se o que está em disco hoje ainda é o que foi aprovado, e sai diferente de zero
quando não é. Divergir não é erro — corrigir depois do gate às vezes é o certo.
O que não pode é ninguém conseguir saber.

## Escopo duplo: projeto e sustentação

- **Projeto (greenfield):** fluxo completo, etapas 1→7.
- **Sustentação (bug/melhoria):** etapas 1, 2, 3 (design enxuto), 4, 5, 7. Bug crítico
  ainda passa pelo gate do arquiteto — reduzido, mas existe.

## Antes de qualquer coisa

1. Confirme com `sf org list` qual org está conectada e **diga ao humano qual é** antes de
   tocar em qualquer coisa. Org errada é o erro mais caro dessa operação.
2. Confirme qual cliente e qual demanda está sendo tratada. O `CLAUDE.md` deste cliente
   (na raiz do workspace atual) é o briefing de conta — leia-o antes de desenhar qualquer
   solução, ele é fonte de verdade sobre quem é o cliente e como trabalhar por ele.

## Nota sobre permissões em execução headless

O orquestrador roda sessões sem humano para responder prompt de permissão, então
concede ferramentas inteiras (`Bash` incluído) via `allowed_tools` no próprio SDK —
isso torna a lista `allow` de `.claude/settings.json` redundante nesse modo, e o aviso
de "workspace não confiável" do Claude Code é sobre exatamente essa lista, nada além.
A rede de segurança real não depende dela: a lista `deny` (`git merge*`, `git push
--force*`, `sf org delete*`) e o hook `guard-prod.sh` continuam bloqueando
normalmente independente de o workspace estar marcado como confiável — verificado
empiricamente. O que o hook **não** cobre são as ferramentas `sf_*` do MCP, que não
passam pela ferramenta Bash: quem guarda aquele caminho é `guarda.py` (guardrail #1).
Não "resolva" esse aviso afrouxando permissão; ele não protege nada
que já não esteja protegido por hook ou pela lista `deny`.
