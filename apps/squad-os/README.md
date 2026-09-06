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
- **Supabase Auth** (magic link) — só o time interno loga; allowlist por
  `ALLOWED_EMAIL_DOMAIN`/`ALLOWED_EMAILS` (`lib/auth.ts`), aplicada em todo
  request por `proxy.ts` (Next.js 16 renomeou `middleware.ts` → `proxy.ts`,
  mesma função — ver `node_modules/next/dist/docs/.../proxy.md` se for mexer
  nisso, a API mudou de nome mas o resto é igual ao que você já conhece).
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
- **Realtime entre abas**: sem WebSocket/Supabase Realtime ainda — mutação
  local dá `router.refresh()`, outra aba só vê a mudança ao navegar de novo.
  O Artifact tinha `onSnapshot` "de graça"; aqui é uma escolha consciente de
  não adicionar antes de validar se faz falta de verdade num time pequeno.

## Setup

1. Crie um projeto no [Supabase](https://supabase.com) (Postgres + Auth já
   vêm juntos). Em **Authentication → Providers**, confirme que Email (magic
   link) está habilitado; em **Authentication → URL Configuration**, adicione
   a URL do deploy (`https://.../auth/callback`) em Redirect URLs.
2. Copie `.env.example` pra `.env.local` e preencha — `DATABASE_URL` vem de
   **Project Settings → Database → Connection string** (use a pooler
   "Transaction", porta 6543); `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` vêm de
   **Project Settings → API**.
3. `npm install`
4. `npx prisma migrate dev --name init` — cria as tabelas no Supabase a
   partir de `prisma/schema.prisma`.
5. `npm run dev` — http://localhost:3000, deve redirecionar pra `/login`.
6. Gere um GitHub PAT fine-grained (Contents:write + Actions:write, escopo só
   neste repositório) pra `GITHUB_TOKEN`, se for testar a materialização.

### Deploy (Vercel)

Aponte o projeto Vercel pra `apps/squad-os/` (root directory), configure as
mesmas env vars de `.env.example` como Environment Variables do projeto, e
rode `npx prisma migrate deploy` (ou deixe num passo de build) antes do
primeiro deploy pra garantir que o schema existe no Postgres de produção.

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
