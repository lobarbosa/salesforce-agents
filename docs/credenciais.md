# Mapa de credenciais e gargalo humano

Recomendação #6 do council de auditoria pré-produção (2026-10-01): ninguém juntou, num
lugar só, toda credencial que esta esteira depende, nem quem é dono de rotacionar cada
uma se vazar. Separado em dois achados do mesmo council — sprawl de credenciais e gargalo
humano no gate do arquiteto — porque os dois são risco organizacional, não de código, e
nenhum dos dois eu consigo responder sozinho: as colunas marcadas **TBD** abaixo são pra
você preencher, não porque esqueci de pesquisar.

## Credenciais

| Credencial | Onde vive | Escopo | Quem usa | Dono da rotação | Como rotacionar | Última rotação |
|---|---|---|---|---|---|---|
| `SQUAD_OS_SYNC_TOKEN` | Secret de repositório (GitHub) + env var (Vercel) | Global (6 clientes), ou por cliente se migrado — ver `docs/conexoes-e-setup.md` | Toda rota `/api/sync/*`, chamada pelos workflows | **TBD** | Gerar novo (`openssl rand -hex 32`), atualizar nos dois lados, nunca ficar com os dois valores diferentes simultaneamente por mais que o tempo de propagação do deploy | **TBD** |
| `SQUAD_OS_SYNC_TOKEN_<CLIENTE>` | Secret de **Environment** (GitHub, por cliente/ambiente) + env var (Vercel) | Só do cliente migrado | Mesmas rotas, só pra esse cliente | **TBD** | Mesma mecânica do global, isolada por cliente — vazamento de um não exige rotacionar os outros | **TBD** |
| `SF_CLIENT_ID` / `SF_USERNAME` / `SF_JWT_KEY` | Secret de **Environment** (GitHub), um trio por `<cliente>-<ambiente>` — 6 clientes × 2 ambientes = 12 trios | Só daquele cliente, só daquela sandbox (dev nunca vale pra qa) | `run-demand.yml`, `run-assessment.yml`, `test-connection.yml` — autenticação JWT contra a org | **TBD** | Gerar certificado novo no Connected App da sandbox, trocar os 3 valores do Environment — a chave privada (`SF_JWT_KEY`) é a que mais importa rotacionar se vazar, dá execução direto na org | **TBD** |
| `ANTHROPIC_API_KEY` | Secret de **repositório** (GitHub, não de Environment) | Global — mesma conta Anthropic do squad pra todos os clientes | Toda sessão de agente (`orchestrator.py`) | **TBD** | Revogar e gerar nova na console Anthropic, atualizar o secret | **TBD** |
| `AI_GATEWAY_API_KEY` | Env var (Vercel); dispensável em deploy Vercel real (autentica por OIDC do projeto) | Global | Copiloto (`/api/copilot/chat`) e RAG interno (embeddings, `lib/rag.ts`) | **TBD** | Gerar nova em `vercel.com/[team]/~/ai-gateway/api-keys` | **TBD** |
| `SUPABASE_SERVICE_ROLE_KEY` | Env var (Vercel) | Global | Rotas server-side do Squad OS que precisam bypassar RLS | **TBD** | Regenerar no painel do Supabase — invalida a anterior imediatamente, checar se algo além do Squad OS usa a mesma chave antes de girar | **TBD** |
| Anon key do Supabase | Env var pública (client-side) | Global | Browser do Squad OS (auth, upload) | **TBD** | Normalmente não precisa rotacionar sozinha (é pública por design, RLS é quem protege) — só se o projeto Supabase inteiro for comprometido | **TBD** |
| `DATABASE_URL` | Env var (Vercel) | Global | Prisma, todo o Squad OS | **TBD** | Trocar senha do usuário Postgres no Supabase, atualizar a connection string | **TBD** |
| `GITHUB_TOKEN` (automático) | Gerado pelo Actions por run, expira sozinho | Por execução | Abrir PR, comentar no PR (`gh pr ...`) dentro dos workflows | — (gerenciado pelo GitHub, não rotacionável manualmente) | — | — |

## O que fazer com isto

1. Preencha **dono da rotação** pra cada linha — uma pessoa, não "o time". Sem isso, "quem
   troca se vazar" é a mesma pergunta em aberto que o council achou.
2. Para as que têm `SQUAD_OS_SYNC_TOKEN*` e `SF_*`: confirme se algum já foi exposto em
   log de workflow, commit antigo, ou variável de ambiente que apareceu em algum
   screenshot/print — são as duas que mais importam, por tocarem produção real (a org do
   cliente e a capacidade de aprovar gate remotamente).
3. Depois de preenchido, isto pode virar rotina — não precisa de agente nenhum pra isso, é
   planilha. O valor de ter isto em `docs/` em vez de só na cabeça de alguém é sobreviver
   a alguém saindo do time.

## Gargalo humano no gate do arquiteto

Segundo achado do council marcado como organizacional, não técnico: o gate do `arquiteto`
é **bloqueante** pra toda demanda (CLAUDE.md, Regra de ouro) e o agente roda em `opus`
justamente porque "é o único gate humano bloqueante da doutrina, erro ali compõe nos 6
clientes" (CLAUDE.md § Seleção de modelo por agente). Isso presume que existe, do lado
humano, capacidade real de revisar design de ponta a ponta pros 6 clientes em paralelo
sem o gate virar fila.

**TBD, e só você responde:**
- Quantas pessoas reais, hoje, têm o conhecimento pra aprovar esse gate com critério (ver
  skill `conferir-gate`) — não só "têm acesso ao Squad OS", têm julgamento de arquitetura
  Salesforce pra dizer não quando `arquiteto` errar?
- Se os 6 clientes tivessem demanda em `aguardando_gate_design` ao mesmo tempo, esse gate
  vira fila de quantos dias?
- Existe hoje algum plano pra esse número crescer junto com os clientes, ou o plano é
  "contratar quando apertar"?

Sem essas três respostas, escalar a esteira pros outros 5 clientes aposta que a capacidade
humana de aprovar design acompanha — e é exatamente o tipo de aposta que esta doutrina
inteira foi desenhada pra não deixar passar sem alguém decidir de propósito.
