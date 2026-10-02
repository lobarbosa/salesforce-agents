# Conexões, credenciais e mapa de execução

Adaptado do runbook original do squad — aqui o Jira foi substituído pelo **Squad OS**
(o app onde a demanda nasce e o briefing do cliente vive) mais o modelo de demanda
em arquivo (`clients/<cliente>/demandas/<ID>/`).

## 1. Matriz de conexões

| # | Conexão | Para quê | Onde vive | Bloqueia o quê |
|---|---|---|---|---|
| 1 | **Sandboxes dedicadas** (`sbx-<cliente>-dev`, `sbx-<cliente>-qa`) | Onde os agentes constroem (dev) e onde a demanda é testada e homologada (qa) | `sf` CLI local | Tudo |
| 2 | **Connected App + JWT** (por ambiente) | Autenticação do CI sem senha/MFA | GitHub Secrets | Pipeline |
| 3 | **GitHub + Actions** | Versionamento, PR, deploy determinístico | Repo do cliente | Deploy |
| 4 | **`ANTHROPIC_API_KEY`** | Autentica o orquestrador (Claude Agent SDK) | variável de ambiente onde `sfagents` roda | Todo o pipeline de agentes |
| 5 | **Squad OS** | Intake de demanda + briefing de cliente — substitui o Jira | claude.ai (artifact) hoje; `apps/squad-os/` (Next.js + Supabase) em migração — ver `apps/squad-os/README.md` | Início do ciclo |
| 6 | Sincronização OS → repositório | Materializa a demanda criada no OS como `demanda.md` + `status.yaml` | manual no artifact (ver §3, passo 7); automática em `apps/squad-os/` via GitHub API + `run-demand.yml` assim que estiver em produção | Início do ciclo de execução |
| 7 | **Slack MCP** (opcional) | Notificação de gate esperando humano | `claude mcp add` | Nada (opcional) |
| 8 | **Dev Hub** (opcional) | Scratch orgs por demanda | `sf org login` | Isolamento por demanda |
| 9 | ClickUp / Clockify | Horas e status comercial | — | Nada — fora do v1 |

## 2. Credenciais a provisionar

### Salesforce (repetir por ambiente: INT, UAT, PROD)
| Item | Como obter |
|---|---|
| Certificado x509 + chave privada | `openssl req -x509 -sha256 -nodes -days 730 -newkey rsa:2048 -keyout server.key -out server.crt` |
| Connected App | Setup → App Manager → New Connected App → Enable OAuth + **Use digital signatures** (sobe o `.crt`) |
| Consumer Key | Da Connected App criada |
| Usuário de integração | Usuário dedicado, licença própria, **nunca** usuário nominal de pessoa |
| Pré-autorização | Manage → Permitted Users: *Admin approved users*, com Permission Set atribuído |

### GitHub Environments (um por cliente **por ambiente**)
Cada par cliente+ambiente é um **GitHub Environment** chamado `<cliente>-<ambiente>`
(Settings → Environments → New environment → `acxya-dev`, `acxya-qa`). Dentro de cada um,
os mesmos 3 secrets **sem sufixo** — o Environment já isola, não precisa repetir o nome
na chave:
```
SF_CLIENT_ID
SF_USERNAME
SF_JWT_KEY
```
Cada ambiente tem a **sua própria** Connected App e o seu próprio usuário de integração:
dev e qa não compartilham credencial. Compartilhar anularia o motivo de existirem dois.

> **Se você já tinha um Environment `<cliente>` sem sufixo** (o formato anterior), ele
> não é mais lido por workflow nenhum. Crie `<cliente>-dev`, recadastre os 3 secrets nele
> (secrets são write-only — não dá pra copiar de um Environment pro outro, tem que colar
> de novo da fonte) e só então apague o antigo. Enquanto `<cliente>-dev` não existir, os
> workflows falham com uma mensagem dizendo exatamente isso.

Qual Environment cada etapa abre não está escrito em YAML: `run-demand.yml` tem um job
`decidir` que pergunta pra `src/salesforce_agents/ambientes.py` (via
`sfagents demanda ambiente`) em qual org a etapa atual roda, e o job seguinte abre esse
Environment. Um job do Actions declara um `environment:` só — por isso são dois jobs, e
por isso o `decidir` não abre nenhum: ele não precisa ver secret pra ler um arquivo.

`test-connection.yml` e `baseline-retrieve.yml` recebem `client` **e** `ambiente` como
input. `ci-salesforce-validate.yml` dispara sozinho em todo PR que mexe em
`clients/<cliente>/force-app/**` (detecta o cliente pelo path alterado, sem input manual),
sempre contra `<cliente>-dev`, e nunca faz deploy de verdade — só validação check-only.
Hoje só `acxya` tem secrets cadastrados; nos outros 5 clientes o job roda, avisa que o
Environment ainda não tem credencial, e passa sem validar nada.

**Produção não tem Environment neste repositório, e isso é deliberado** (guardrail #1).
Não é "ainda não configuramos": `ambientes.py` só conhece `dev` e `qa` e recusa qualquer
outro valor antes de montar qualquer comando `sf`. Se um dia existir entrega em produção,
ela nasce fora desta esteira, com required reviewer nomeado — não estendendo este mapa.

### Secrets de repositório (não de Environment)

Além de `ANTHROPIC_API_KEY`, o ciclo automático precisa dos secrets abaixo — são eles que
deixam o pipeline devolver o estado pro Squad OS. Sem eles nada quebra no git, mas o
quadro do app para de refletir a realidade, que é o mesmo que não ter automação:

| Secret | Pra quê |
|---|---|
| `SQUAD_OS_SYNC_TOKEN` | Autentica todos os endpoints de sync. Mesma string cadastrada como env var na Vercel. Fallback: usado quando o cliente não tem token próprio (ver abaixo) |
| `SQUAD_OS_SYNC_URL` | `https://<domínio>/api/sync/demanda` — estágio da demanda voltando |
| `SQUAD_OS_SYNC_ASSESSMENT_URL` | `https://<domínio>/api/sync/assessment` — saúde da org voltando |
| `SQUAD_OS_SYNC_CONEXAO_URL` | `https://<domínio>/api/sync/conexao` — resultado do teste de JWT voltando, e o gatilho do assessment de onboarding |
| `SQUAD_OS_SYNC_RAG_URL` | `https://<domínio>/api/sync/rag` — reingestão do RAG interno de um cliente (`run-demand.yml`, depois do commit) |
| `SQUAD_OS_RAG_QUERY_URL` | `https://<domínio>/api/sync/rag-query` — consulta ao RAG interno **durante** a sessão do agente (ferramenta `rag_consultar`, `src/salesforce_agents/rag.py`). Diferente dos demais: este lido pelo processo Python, não só pelo `curl` do workflow — nunca o copiloto do cliente em Squad OS, ver CLAUDE.md guardrail #2 |
| `SQUAD_OS_SYNC_EXECUCAO_URL` | `https://<domínio>/api/sync/execucao` — espelho histórico de observabilidade (admin: `/operacao/execucoes`; consultor: `/falhas`). Opcional: sem ele, só essas duas telas ficam vazias — nada do fluxo em si depende disto |

`ANTHROPIC_API_KEY` fica em **Settings → Secrets → Actions** do repositório (não dentro de
um Environment) — é a mesma conta Anthropic do squad para todos os clientes, não algo que
se isola por conta.

#### Migrando um cliente pro token de sync próprio

Achado do council de 2026-10-01: `SQUAD_OS_SYNC_TOKEN` é um único secret usado pelos 6
clientes — vazar uma vez compromete a capacidade de aprovar qualquer gate de qualquer
cliente remotamente, nos 6 ao mesmo tempo. `lib/sync-auth.ts` agora aceita um token **por
cliente** do lado do Squad OS, sem quebrar quem ainda não migrou. O lado do GitHub Actions
é mais restrito do que parece — **`secrets.*` não aceita nome dinâmico** (não dá pra fazer
`secrets["SQUAD_OS_SYNC_TOKEN_" + client]` num workflow; é limite de segurança do próprio
Actions). Quem resolve isso são os **secrets de Environment**, que têm uma regra exata pra
este caso: um secret de Environment com o **mesmo nome** de um secret de repositório
sobrepõe o de repositório pra jobs que abrem aquele Environment — sem mudar nada no YAML.

1. Gere um token novo (ex.: `openssl rand -hex 32`) só pra este cliente.
2. Cadastre a mesma string como env var `SQUAD_OS_SYNC_TOKEN_<CLIENTE>` na Vercel (cliente
   em caixa alta, hífen virando `_` — ex.: `somos-agility` → `..._SOMOS_AGILITY`). Esse é o
   lado que `sync-auth.ts` lê.
3. Cadastre a **mesma string**, com o **mesmo nome do secret global** (`SQUAD_OS_SYNC_TOKEN`,
   sem sufixo), dentro de cada GitHub Environment deste cliente que hoje dispara sync —
   `Settings → Environments → <cliente>-dev` e `<cliente>-qa` → secret `SQUAD_OS_SYNC_TOKEN`.
   Cobre `run-demand.yml` (job `rodar`), `run-assessment.yml` e `test-connection.yml` — os
   três já abrem Environment por cliente/ambiente.
4. **`run-planejamento.yml` fica de fora desta migração.** Ele não abre Environment
   nenhum — de propósito (não toca em org, não tem credencial Salesforce pra isolar) — e
   sem Environment não existe like-nomeado pra sobrepor. Enquanto isso não for revisitado,
   `/api/sync/plano` continua autenticando só pelo token global pra todo cliente, mesmo os
   já migrados nos outros quatro endpoints. Dar Environment a esse workflow só pra ganhar
   escopo de secret é possível, mas muda comportamento (Environment pode ter regra de
   aprovação configurada) — decisão deliberada, não consequência automática desta migração.
5. A partir do passo 3, **o token global para de autenticar os quatro endpoints migrados
   deste cliente** — não é mais uma chave a mais que também abre a porta, é segmentação de
   verdade. Os outros clientes continuam no token global até migrarem também.

### Ambiente local / CI onde `sfagents` roda
```
ANTHROPIC_API_KEY=...
```
Sem isso o orquestrador (`orchestrator.py`) não consegue abrir sessão do Claude Agent SDK.

### Squad OS
- É um artifact publicado (`db` capability) — todo leitor/escritor precisa estar
  logado na mesma organização de quem publicou. Não expõe credencial nenhuma por si só.
- Guarde a URL publicada em local que a equipe toda acesse (não é secreta, mas
  também não deve ser pública).

## 3. Mapa de execução — ordem obrigatória

| Passo | Ação | Depende de | Tempo | Feito quando |
|---|---|---|---|---|
| 1 | Criar as sandboxes `sbx-<cliente>-dev` e `sbx-<cliente>-qa` (Developer Pro) | — | 1–4h (refresh) | `sf org list` mostra as duas |
| 2 | Criar/usar `clients/<cliente>/` e trazer o metadata atual (`sf project retrieve start`) | 1 | 1h | `force-app/` reflete a org |
| 3 | Preencher `clients/<cliente>/CLAUDE.md` a partir do template | 2 | 15min | Briefing preenchido |
| 4 | Criar branches `develop` e proteger `main` | 2 | 15min | PR obrigatório em `main` |
| 5 | Gerar certificado + Connected App/External Client App **em cada sandbox** (dev e qa têm as suas) | 1 | 45min | `sf org login jwt` funciona nas duas |
| 6 | Criar os Environments `<cliente>-dev` e `<cliente>-qa` e cadastrar `SF_CLIENT_ID`/`SF_USERNAME`/`SF_JWT_KEY` em cada um | 4, 5 | 30min | `test-connection.yml` roda verde nos dois ambientes |
| 6b | Testar a conexão de dev pelo Squad OS — o assessment da org dispara sozinho | 6 | 10min | Bloco "Saúde da org" preenchido no perfil do cliente |
| 7 | Registrar uma demanda real no Squad OS e materializá-la (o botão faz os dois) | 5 | 5min | `sfagents demanda listar` mostra a demanda |
| 8 | Rodar `sfagents demanda avancar` com essa demanda até `release` | 3, 6, 7 | 1 dia | Ciclo completo com gates registrados em `gates.md` |
| 9 | Repetir com mais 4 demandas, anotando cada correção humana | 8 | 2 semanas | Retrabalho < 30% |
| 10 | Converter as correções em linhas de skill (`.claude/skills/`) | 9 | 2h | Doutrina atualizada |
| 11 | Só então: Connected App de PROD + environment protegido | 10 | 1h | Deploy prod manual funciona |

**Passos 1 a 8 são o caminho crítico.** Nada mais importa até o ciclo completo rodar uma vez.

> Nota sobre os passos 7 e 8: já não são manuais. Materializar no Squad OS commita
> `demanda.md` + `status.yaml` e dispara os agentes; cada etapa avança sozinha até o
> gate seguinte e volta pro quadro pelo sync. O que resta de humano é aprovar os gates
> — que é o ponto. Ver `ativacao.md`.

## 4. Ambientes

A esteira tem exatamente dois ambientes. Ela vai de dev até a sandbox de QA e **o agente
para ali**.

| Org | Alias | Tipo | Quem toca | Etapas |
|---|---|---|---|---|
| Dev | `sbx-<cliente>-dev` | Developer Pro | Agentes + você | análise → design → build (e os gates entre elas) |
| QA | `sbx-<cliente>-qa` | Partial/Full | Agente entrega; cliente homologa | qa → homologação → release |
| Produção | — | Produção | **Só humano, fora desta esteira** | nenhuma |

O corte fica em `qa` e não em `release` de propósito: assim a homologação humana acontece
na org em que a coisa vai ser aceita. Homologar em dev e mover pra QA depois é homologar
uma coisa e entregar outra. Esse ponto é uma constante só (`PRIMEIRO_ESTAGIO_QA` em
`ambientes.py`) — mudar de ideia é mudar uma linha, não caçar condições espalhadas em YAML.

Se o orçamento de sandbox for restrito, dev e qa podem ser a mesma org no piloto — mas aí
cadastre os mesmos secrets nos dois Environments, em vez de apontar workflow pro
Environment errado; senão a próxima pessoa lê o YAML e conclui a coisa errada. Nunca
misture orgs de clientes diferentes.
