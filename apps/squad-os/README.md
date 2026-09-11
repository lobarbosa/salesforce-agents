# Squad OS

Segunda geração do Squad OS — antes um [Artifact publicado](https://claude.ai/code/artifact/d17fac68-5684-42da-9817-77757600e828)
(claude.ai, banco `db` próprio), agora um app Next.js real com Postgres e
auth de verdade, pra ficar num domínio nosso em vez de depender do runtime de
Artifacts. Mesma função: onde a demanda nasce, o briefing do cliente vive, e
o consultor responde perguntas/aprova gates sem precisar de ninguém no meio.

## Arquitetura

- **Next.js 16** (App Router) na Vercel.
- **Postgres via Supabase** — schema em `prisma/schema.prisma`. Prisma 7 usa
  driver adapters em vez de `url` no datasource (ver `lib/prisma.ts`).
- **Supabase Auth** (magic link) + **acesso por papel** (`Usuario` em
  `prisma/schema.prisma`): `admin` (gerencia acesso, tela `/admin/usuarios`),
  `consultor` (time interno, vê todos os clientes) e `cliente` (só o próprio
  cliente, só a aba Demandas — sem editar briefing/conexão, sem disparar
  agentes). Quem pode logar não é mais allowlist por domínio de e-mail; é
  essa tabela. `proxy.ts` resolve sessão + papel numa passada só e injeta o
  resultado como headers `x-squad-os-*` pro resto do app ler (`lib/current-user.ts`)
  sem repetir a consulta — Next.js 16 renomeou `middleware.ts` → `proxy.ts` e
  passou a rodar em runtime Node.js por padrão (por isso dá pra usar Prisma
  ali direto; ver `node_modules/next/dist/docs/.../proxy.md` se for mexer
  nisso). `ADMIN_BOOTSTRAP_EMAILS` só existe pra destravar o primeiro admin.
- **Ponte de materialização** (`lib/github.ts`) — o pedaço que antes era
  manual (ver `docs/conexoes-e-setup.md` §3 passo 7 na raiz do repo): ao
  clicar "Materializar e disparar agentes" numa demanda, o app commita
  `clients/<slug>/demandas/<code>/{demanda.md,status.yaml}` neste repositório
  via API do GitHub e dispara `run-demand.yml` (`workflow_dispatch`).

### Por que `slug` e `code` existem

O Artifact antigo guardava clientes com um ID aleatório do Firestore — nunca
existiu um jeito automático de saber que o cliente "X" no OS correspondia ao
diretório `clients/x/` deste repo (por isso a materialização era manual).
Aqui, `Client.slug` é gerado do nome na criação e É o nome do diretório
(`clients/<slug>/`); `Demanda.code` segue o mesmo formato que
`src/salesforce_agents/demands.py:_next_id()` já usa (`<CODE>-<n>`, ex.:
`ACXYA-1`) — é o `id` que vai dentro de `status.yaml`.

### O que ainda não existe (de propósito, não é esquecimento)

- **Sync de volta**: depois que uma demanda é materializada, os agentes
  avançam `status.yaml` via git — o `status` desta demanda no Postgres fica
  parado no que foi na hora da materialização. Igual ao Artifact antigo
  ("estágios de execução aparecem como leitura, não são movidos por aqui"),
  só que agora dá pra fechar o ciclo: um passo a mais em `run-demand.yml`
  que faz `POST` do novo `status.yaml` pra uma rota de sync (autenticada por
  token, não por sessão de usuário) é o próximo passo natural — não entrou
  nesta primeira versão pra não misturar "trocar a plataforma" com "mudar o
  modelo de sincronização" no mesmo lote de mudança.
- **Reordenar subtarefa/checklist por arrastar**: a coluna `ordem` existe e a
  API respeita, mas a UI ainda só adiciona no fim. Reordenar é conveniência;
  o que faltava de verdade era ter a lista.

- **Realtime entre abas**: sem WebSocket/Supabase Realtime ainda — mutação
  local dá `router.refresh()`, outra aba só vê a mudança ao navegar de novo.
  O Artifact tinha `onSnapshot` "de graça"; aqui é uma escolha consciente de
  não adicionar antes de validar se faz falta de verdade num time pequeno.

## Setup

1. Crie um projeto no [Supabase](https://supabase.com) (Postgres + Auth já
   vêm juntos). Em **Authentication → Providers**, confirme que Email (magic
   link) está habilitado; em **Authentication → URL Configuration**, preencha
   **Site URL** com o alias estável de produção da Vercel (`https://<projeto>.vercel.app`)
   e cadastre os Redirect URLs **com wildcard**:

   - `https://<projeto>.vercel.app/**`
   - `https://*-<team-slug>.vercel.app/**`
   - `http://localhost:3000/**`

   O wildcard não é conveniência, é requisito: `app/login/page.tsx` manda
   `emailRedirectTo` a partir de `window.location.origin`, e a Vercel emite uma
   URL de deployment nova (`<projeto>-<hash>-<team>.vercel.app`) a cada deploy.
   Cadastrar a URL de um deployment específico quebra no deploy seguinte —
   quando o `emailRedirectTo` não bate com a allow list, o Supabase descarta o
   valor silenciosamente e cai no Site URL, perdendo o path `/auth/callback`.
   Sintoma: o e-mail chega com link pra raiz do Site URL (`.../?code=...`) em
   vez de `/auth/callback`. Achado real (2026-09-09).

   A tela de login oferece dois caminhos, ambos passando pelo mesmo
   `/auth/callback` (que troca o `code` por sessão) e pela mesma allowlist da
   tabela `usuarios` — autenticar nunca é o mesmo que ter acesso:

   - **Link por e-mail** (magic link), com `shouldCreateUser: false` — o link só
     sai pra quem já existe em `auth.users`.
   - **E-mail e senha**. A redefinição cai em `/auth/nova-senha`, que exige
     sessão válida (por isso não está em `PUBLIC_PATHS` do `proxy.ts`).

   **Não há auto-cadastro.** Quem cria usuário é o admin, ao conceder acesso em
   `/admin/usuarios`: a rota grava a linha em `usuarios` e chama
   `auth.admin.inviteUserByEmail`, e a pessoa define a senha pelo link do
   convite. Por isso `SUPABASE_SERVICE_ROLE_KEY` não é opcional — sem ela não
   sai convite, e sem convite ninguém novo entra.
2. Copie `.env.example` pra `.env.local` e preencha. **São duas variáveis de
   banco, dois modos de pooler**, ambas do botão **Connect** do projeto:

   | Variável | Aba / porta | Quem usa | Por quê |
   |---|---|---|---|
   | `DATABASE_URL` | Transaction pooler, **6543** | runtime (`lib/prisma.ts`) | Vercel Functions são clientes efêmeros; a conexão volta pro pool a cada statement |
   | `DIRECT_URL` | Session pooler, **5432** | migração (`prisma7.config.ts`) | `prisma migrate deploy` roda DDL numa sessão longa, que transaction mode não sustenta |

   `prisma7.config.ts` cai no `DATABASE_URL` se `DIRECT_URL` não existir, então
   uma instalação antiga com só a primeira continua funcionando.

   Nenhuma das duas é a conexão direta (`db.<ref>.supabase.co`): ela é IPv6-only
   sem o add-on de IPv4, e não serve nem pro runtime nem pro build runner da
   Vercel.

   **Não acrescente `?pgbouncer=true&connection_limit=1`** no `DATABASE_URL`.
   Esses parâmetros são do Prisma clássico; aqui o acesso é por driver adapter
   (`@prisma/adapter-pg`), e quem fala com o banco é o `pg`. O adapter só emite
   prepared statement quando recebe `statementNameGenerator` nas opções — o
   `lib/prisma.ts` não passa, então as queries saem sem nome e transaction mode
   não tem o que quebrar (ver `performIO` em
   `node_modules/@prisma/adapter-pg/dist/index.js`).

   Percent-encode a senha nas duas (`@` vira `%40`, `#` vira `%23`).
   `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` vêm de
   **Project Settings → API**; `ADMIN_BOOTSTRAP_EMAILS` com o(s) seu(s)
   e-mail(s), pra conseguir logar a primeira vez.
3. `npm install`
4. `npx prisma migrate dev --name init` — cria as tabelas no Supabase a
   partir de `prisma/schema.prisma` (inclui `usuarios`).
5. `npm run dev` — http://localhost:3000, deve redirecionar pra `/login`.
   Peça o link com um e-mail de `ADMIN_BOOTSTRAP_EMAILS`; a partir daí, use
   `/admin/usuarios` pra conceder acesso a consultores e a cada cliente
   (papel `cliente` + qual cliente).
6. Gere um GitHub PAT fine-grained (Contents:write + Actions:write, escopo só
   neste repositório) pra `GITHUB_TOKEN`, se for testar a materialização.
7. **Anexos** (opcional — sem isso o app sobe igual, só a aba Anexos recusa
   upload com mensagem explícita): no painel do Supabase, **Storage → New
   bucket**, nome `anexos-demanda`, **Public desmarcado**. Não crie policy
   nenhuma no bucket: a API do Squad OS acessa com a service role key
   (`SUPABASE_SERVICE_ROLE_KEY`, em **Project Settings → API Keys**) e é ela
   que autoriza, sabendo o cliente de cada demanda. Uma policy de
   `authenticated` no bucket deixaria o papel `cliente` do cliente A baixar
   anexo do cliente B — o download sai por URL assinada de 60s gerada pela
   rota, nunca por link público.

### Deploy (Vercel)

Aponte o projeto Vercel pra `apps/squad-os/` (root directory) e configure as
mesmas env vars de `.env.example` como Environment Variables do projeto
(Production **e** Preview, se for usar preview deploys). `package.json` já
tem um script `vercel-build` (`prisma migrate deploy && next build`) —
Vercel roda esse script no lugar de `build` automaticamente quando ele existe,
então toda migração pendente é aplicada antes de cada build, sem passo manual.
`prisma migrate deploy` é idempotente (só aplica o que ainda não rodou), então
não há problema em rodar em todo deploy, incluindo previews.

#### Preview e Production compartilham o mesmo banco

Hoje as duas Environments da Vercel apontam pro mesmo `DATABASE_URL`. A
consequência não é óbvia e custou caro em 2026-09-09: **o build de preview de
um PR aplica a migração em produção**, antes do merge. Enquanto a migração for
aditiva (criar tabela, criar coluna) isso é inofensivo — o código antigo
simplesmente ignora o que não conhece. Deixa de ser inofensivo no instante em
que a migração remove ou renomeia algo que o código de `main` ainda lê.

Enquanto for um banco só, toda mudança destrutiva vai em **dois merges**:

1. o merge que tira o campo do `schema.prisma` e do código (sem migration
   nenhuma) — a coluna continua no banco, só deixa de ser lida;
2. o merge seguinte, com o `DROP` sozinho.

A alternativa de verdade é dar um banco próprio ao Preview (um projeto Supabase
separado, ou um branch de banco do Supabase) e apontar só a env var de Preview
pra ele. Aí um PR volta a poder carregar schema e código no mesmo merge, que é
como deveria ser. Enquanto isso não acontecer, os dois merges não são
burocracia — são a única coisa separando um PR aberto de uma produção fora do ar.

##### Por que o DROP não vem junto

`clients.marcas` e `clients.concorrentes` saíram do briefing a pedido e já
saíram do `schema.prisma` — este é o merge (1). As colunas seguem no banco,
vazias (verificado: 5 clientes, nenhuma linha com conteúdo em nenhuma das
duas). O merge (2) é uma migration com exatamente isto:

```sql
ALTER TABLE "clients" DROP COLUMN "marcas";
ALTER TABLE "clients" DROP COLUMN "concorrentes";
```

### Migrando os dados do Artifact antigo

```bash
DATABASE_URL=... npm run migrate:from-artifact -- <pasta-com-export>
```

Ver o cabeçalho de `scripts/migrate-from-artifact.ts` pra como gerar essa
pasta (ação `read_db` do Artifact, com `out_dir`).

## Status

Scaffold funcional — build e typecheck passam, fluxo de auth e as três abas
(Conhecimento/Conexão/Demandas) estão implementados, materialização testável
assim que houver `GITHUB_TOKEN`. Não testado ainda contra um Postgres real
(nenhum projeto Supabase foi criado nesta sessão). Próximos passos:

- Criar o projeto Supabase de verdade e rodar `prisma migrate dev` contra ele.
- Rodar `migrate:from-artifact` com um export real do Artifact antigo.
- Deploy piloto na Vercel, com os 6 clientes reais.
- Sync de volta (`status.yaml` → Postgres) via `run-demand.yml`, quando o
  piloto mostrar que o `status` desatualizado no board incomoda na prática.
- Decidir quando descontinuar o Artifact antigo (deixar em modo leitura com
  um aviso apontando pro novo domínio por um tempo antes).
