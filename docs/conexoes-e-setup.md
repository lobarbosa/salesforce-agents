# Conexões, credenciais e mapa de execução

Adaptado do runbook original do squad — aqui o Jira foi substituído pelo **Squad OS**
(o app onde a demanda nasce e o briefing do cliente vive) mais o modelo de demanda
em arquivo (`clients/<cliente>/demandas/<ID>/`).

## 1. Matriz de conexões

| # | Conexão | Para quê | Onde vive | Bloqueia o quê |
|---|---|---|---|---|
| 1 | **Sandbox Salesforce dedicada** (`sbx-<cliente>`) | Onde os agentes constroem e testam | `sf` CLI local | Tudo |
| 2 | **Connected App + JWT** (por ambiente) | Autenticação do CI sem senha/MFA | GitHub Secrets | Pipeline |
| 3 | **GitHub + Actions** | Versionamento, PR, deploy determinístico | Repo do cliente | Deploy |
| 4 | **`ANTHROPIC_API_KEY`** | Autentica o orquestrador (Claude Agent SDK) | variável de ambiente onde `sfagents` roda | Todo o pipeline de agentes |
| 5 | **Squad OS** (artifact publicado) | Intake de demanda + briefing de cliente — substitui o Jira | claude.ai (artifact), banco próprio | Início do ciclo |
| 6 | Sincronização OS → repositório | Materializa a demanda criada no OS como `demanda.md` + `status.yaml` | manual por ora (ver §3, passo 7) | Início do ciclo de execução |
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

### GitHub Environments (um por cliente)
Cada cliente é um **GitHub Environment** com o mesmo nome do diretório em `clients/`
(Settings → Environments → New environment → nome = `<cliente>`, ex.: `acxya`). Dentro
dele, 3 secrets **sem sufixo** (o Environment já isola por cliente, não precisa repetir
o nome na chave):
```
SF_CLIENT_ID
SF_USERNAME
SF_JWT_KEY
```
Os workflows (`test-connection.yml`, `baseline-retrieve.yml`, `run-demand.yml`) recebem
`client` como input e usam `environment: ${{ inputs.client }}` — então rodam pra qualquer
cliente sem duplicar arquivo de workflow, só apontando o Environment certo.

Quando precisar de INT/UAT/PROD além da sandbox por cliente, o padrão vira Environments
compostos: `<cliente>-int`, `<cliente>-uat`, `<cliente>-prod` — **`<cliente>-prod` sempre
com required reviewer nomeado** (Settings do Environment → Deployment protection rules).
Sem isso o guard humano é ficção. Nenhum cliente tem environment de prod configurado
ainda — isso é o passo 11 do mapa de execução, não algo a antecipar.

`ANTHROPIC_API_KEY` fica em **Settings → Secrets → Actions** do repositório (não dentro de
um Environment) — é a mesma conta Anthropic do squad para todos os clientes, não algo que
se isola por conta.

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
| 1 | Criar sandbox dedicada `sbx-<cliente>` (Developer Pro) | — | 1–4h (refresh) | `sf org list` mostra a org |
| 2 | Criar/usar `clients/<cliente>/` e trazer o metadata atual (`sf project retrieve start`) | 1 | 1h | `force-app/` reflete a org |
| 3 | Preencher `clients/<cliente>/CLAUDE.md` a partir do template | 2 | 15min | Briefing preenchido |
| 4 | Criar branches `develop` e proteger `main` | 2 | 15min | PR obrigatório em `main` |
| 5 | Gerar certificado + Connected App/External Client App **na sandbox do cliente** | 1 | 45min | `sf org login jwt` funciona |
| 6 | Criar o GitHub Environment `<cliente>` e cadastrar `SF_CLIENT_ID`/`SF_USERNAME`/`SF_JWT_KEY` nele | 4, 5 | 30min | `test-connection.yml` roda verde pra esse cliente |
| 7 | Registrar uma demanda real no Squad OS e materializá-la em `clients/<cliente>/demandas/<ID>/demanda.md` | 5 | 15min | `sfagents demanda listar` mostra a demanda |
| 8 | Rodar `sfagents demanda avancar` com essa demanda até `release` | 3, 6, 7 | 1 dia | Ciclo completo com gates registrados em `gates.md` |
| 9 | Repetir com mais 4 demandas, anotando cada correção humana | 8 | 2 semanas | Retrabalho < 30% |
| 10 | Converter as correções em linhas de skill (`.claude/skills/`) | 9 | 2h | Doutrina atualizada |
| 11 | Só então: Connected App de PROD + environment protegido | 10 | 1h | Deploy prod manual funciona |

**Passos 1 a 8 são o caminho crítico.** Nada mais importa até o ciclo completo rodar uma vez.

> Nota sobre o passo 7: hoje a materialização é manual — leia a demanda no Squad OS e
> rode `sfagents demanda nova` com o mesmo texto. Automatizar essa ponte (sync
> periódico OS → repo) é o próximo passo natural depois que o piloto validar o
> restante do fluxo.

## 4. Ambientes

| Org | Tipo | Quem toca | Refresh |
|---|---|---|---|
| `sbx-<cliente>` | Developer Pro | Agentes + você | Sob demanda |
| `sbx-int-<cliente>` | Developer Pro | Pipeline (`develop`) | Mensal |
| `sbx-uat-<cliente>` | Partial/Full | Cliente homologa | Por release |
| `prod-<cliente>` | Produção | **Só humano, janela acordada** | — |

Se orçamento de sandbox for restrito, `sbx-<cliente>` e `sbx-int-<cliente>` podem ser a
mesma org no piloto — mas nunca misture a org dos agentes com a de homologação do cliente,
e nunca misture orgs de clientes diferentes.
