# Ativação — o que só você pode fazer

A arquitetura está pronta e o código está no ar. O que falta é o que exige uma
pessoa: credencial, decisão de conta e clique em painel de terceiro. Depois
destes passos a esteira roda de ponta a ponta sozinha, parando só nos gates
humanos da doutrina.

Ordem importa: cada bloco depende do anterior.

---

## 1. Supabase — 4 cliques e uma chave

| # | O quê | Onde | Por quê |
|---|---|---|---|
| 1.1 | Criar bucket `anexos-demanda`, **Public desmarcado**, sem policy | Storage → New bucket | Anexos de demanda. Sem policy é proposital — quem autoriza é a API do Squad OS, que sabe o cliente de cada demanda |
| 1.2 | Copiar a **service role key** | Project Settings → API Keys | Necessária agora pra **duas** coisas: anexos e o convite de usuário novo |
| 1.3 | Ligar **Leaked password protection** | Authentication → Policies → Password strength | Login por senha num domínio público sem isso é aceitar senha vazada conhecida |
| 1.4 | Conferir a retenção de backup | Database → Backups | O banco virou fonte de verdade de demanda de 6 clientes |

## 2. Vercel — variáveis de ambiente

Em Settings → Environment Variables, **Production e Preview**.

⚠️ **O escopo por ambiente é a pegadinha.** Cada variável na Vercel é marcada
para Production, Preview e/ou Development, e uma marcada só em Production deixa
o Preview num estado traiçoeiro: **build verde, toda rota em erro** — inclusive
`/login`, porque o `proxy.ts` roda antes de qualquer página. Aconteceu em
2026-09-11 com `NEXT_PUBLIC_SUPABASE_URL`. Hoje o app responde dizendo qual
variável falta (503, `lib/env.ts`) em vez de "Internal Server Error" em branco —
mas quem conserta é quem marca o escopo certo aqui.

Confira que **estas três** estão marcadas nos dois ambientes:

| Variável | Onde pegar |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase → Project Settings → API |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | idem (é pública por definição — vai no browser) |
| `DATABASE_URL` | botão Connect (ver abaixo qual pooler) |

E acrescente as que ainda não existem:

| Variável | Valor | Sem ela |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | a chave do passo 1.2 | Anexos recusam upload **e** conceder acesso não envia convite — ninguém novo consegue entrar |
| `SQUAD_OS_SYNC_TOKEN` | uma string aleatória longa que você inventa (ex.: `openssl rand -hex 32`) | O pipeline não consegue devolver o status — o quadro congela na etapa da materialização |
| `DIRECT_URL` | botão Connect → **Session pooler**, porta **5432** | Nada quebra hoje (cai no `DATABASE_URL`), mas o passo abaixo fica pela metade |

🔴 **Troque o `DATABASE_URL`** pela aba **Transaction pooler**, porta **6543**
(hoje ele aponta pro session pooler, 5432). Isto deixou de ser precaução em
2026-09-11: **o app caiu por isso em produção.**

Vercel Functions são clientes efêmeros. Em session mode cada invocação segura
uma sessão até esgotar o pool, e o pool do Supabase em session mode tem teto de
**15 clientes** — não os 60 de `max_connections` do Postgres, que é outro
número e o que enganou o diagnóstico na primeira tentativa. Passou disso, o
pooler recusa:

```
(EMAXCONNSESSION) max clients reached in session mode
  — max clients are limited to pool_size: 15
(ECHECKOUTFAILED) checkout failed
```

O Prisma não conecta, a rota lança, e a tela mostra um erro genérico. Foram
**90 recusas em três minutos** de navegação normal de uma pessoa só —
09:04 (24), 09:09 (55), 09:38-09:39 (11). Uma pessoa. Com dois consultores
mexendo ao mesmo tempo não há navegação possível.

Transaction mode devolve a conexão a cada statement e não tem esse teto. Com
`DIRECT_URL` cadastrada, a migração continua indo pelo session pooler, que é
onde DDL precisa rodar.

Se algo der errado, voltar o `DATABASE_URL` pra 5432 desfaz — é uma variável de
ambiente, não um deploy.

⚠️ `SUPABASE_SERVICE_ROLE_KEY` **nunca** com prefixo `NEXT_PUBLIC_`: ela ignora
RLS, e com o prefixo iria pro bundle do browser.

## 3. GitHub — secrets do repositório

Settings → Secrets and variables → Actions → **Repository secrets**:

| Secret | Valor |
|---|---|
| `SQUAD_OS_SYNC_TOKEN` | **a mesma string** do passo 2 |
| `SQUAD_OS_SYNC_URL` | `https://<seu-domínio>/api/sync/demanda` |
| `SQUAD_OS_SYNC_ASSESSMENT_URL` | `https://<seu-domínio>/api/sync/assessment` |
| `SQUAD_OS_SYNC_CONEXAO_URL` | `https://<seu-domínio>/api/sync/conexao` |
| `SQUAD_OS_SYNC_PLANO_URL` | `https://<seu-domínio>/api/sync/plano` |
| `ANTHROPIC_API_KEY` | já existe |

Enquanto o domínio próprio não existir, use a URL de produção da Vercel — mas
a **estável**, não a de um deploy específico (as com hash mudam a cada deploy).

## 4. GitHub — Environments por cliente e ambiente

Os Environments sem sufixo (`acxya`) **não são mais lidos por workflow nenhum**.
Para cada cliente, crie dois: `<cliente>-dev` e `<cliente>-qa`, cada um com os
três secrets:

```
SF_CLIENT_ID
SF_USERNAME
SF_JWT_KEY
```

Secrets são write-only — não dá pra copiar de um Environment pro outro, tem que
colar de novo da fonte. Cada ambiente tem **sua própria** Connected App e seu
próprio usuário de integração; compartilhar anula o motivo de existirem dois.

Hoje só `acxya` tem credencial cadastrada, e no formato antigo. Comece por
`acxya-dev`.

## 5. Salesforce — a sandbox de QA

`sbx-acxya-qa` não existe. Enquanto não existir, nenhuma demanda da Acxya passa
da etapa `qa`: o job vai falhar dizendo que o Environment `acxya-qa` não tem
credencial. **Esse é o comportamento correto** — não aponte o alias de dev ali
pra "destravar", porque aí a homologação aconteceria na org errada.

Para cada cliente novo: criar as duas sandboxes, gerar certificado + Connected
App em cada uma, cadastrar os secrets nos dois Environments. O runbook completo
está em `conexoes-e-setup.md` §2.

## 6. Domínio de produção

Ver `publicacao-producao.md`. Os dois bloqueantes que estavam lá:

- **Auto-cadastro** — ✅ resolvido, fechado no código. O caminho agora é: admin
  concede acesso em `/admin/usuarios`, o app manda o convite, a pessoa define a
  senha. Depende do passo 2 (service role key).
- **Banco próprio pro Preview** — ⛔ **ainda aberto, e é a sua decisão.**
  Preview e Production compartilham o `DATABASE_URL`, então o build de preview
  de um PR migra a produção antes do merge. Já derrubou a produção uma vez.

  Recomendação, com os custos conferidos na sua org: **um segundo projeto
  Supabase, no free — custa $0** (`get_cost` devolveu 0/mês) — apontado só na
  env var de Preview. **Não use o branching do Supabase**: $0,0134/hora
  (≈ $9,70/mês por branch) e ainda exige o plano Pro.

  E o item que eu colocaria antes desse: a org está no **plano free**, e este
  banco virou fonte de verdade de demanda de 6 clientes, com credencial de
  integração e briefing de conta. Sem PITR, com retenção mínima de backup e com
  auto-pause por inatividade. **Produção no Pro ($25/mês)** compra backup e
  disponibilidade; o preview compartilhado é um risco que se contorna com
  disciplina, perder o banco não.

---

## O que passa a acontecer sozinho depois disso

```
Cliente novo
  └─ você preenche a conexão de dev e clica "testar conexão"
       └─ test-connection.yml autentica
            └─ volta por /api/sync/conexao → org marcada como conectada
                 └─ dispara o assessment automaticamente  ← a primeira atividade
                      └─ agente audita a org (read-only)
                           └─ volta por /api/sync/assessment
                                └─ saúde e recomendações no perfil do cliente

Projeto (contrato de projeto)
  └─ você cadastra os entregáveis contratados na aba Contrato
       └─ clica "Gerar demandas dos entregáveis"
            └─ o contrato é materializado em clients/<slug>/contrato.md
                 └─ run-planejamento.yml aciona o agente `planejador`
                      └─ ele quebra cada entregável nas demandas que ele vira
                           └─ volta por /api/sync/plano → cartões em `backlog`
                                └─ você decide quais viram esteira

Demanda
  └─ consultor registra no Squad OS e clica "materializar"
       └─ run-demand.yml roda a etapa e avança até o gate
            └─ volta por /api/sync/demanda → o quadro mostra o gate esperando
                 └─ humano aprova no card
                      └─ dispara a próxima etapa sozinho
                           └─ ... até `entregue`, parando em cada gate
```

Ninguém abre o GitHub Actions em nenhum ponto.

### Onde ele **para e espera você**, de propósito

| Parada | Quem libera |
|---|---|
| `aguardando_gate_analise` | consultor/admin, no card |
| `aguardando_gate_design` | **arquiteto humano** — o gate bloqueante da doutrina |
| `aguardando_gate_build` | consultor/admin, depois de revisar o PR |
| `aguardando_homologacao` | **o cliente** — é o único gate que o papel `cliente` aprova |
| Produção | ninguém, por aqui. A esteira termina na sandbox de QA |
| Demandas propostas pelo planejador | ficam em `backlog`; nada é materializado nem executado sozinho |

### Onde ele **falha de propósito**, em vez de seguir

- O agente rodou e não produziu o artefato da etapa → job vermelho
  (`ArtifactAusenteError`). Um pipeline que engole isso deixa `status.yaml`
  declarando etapa que não aconteceu.
- A etapa cai numa org diferente da que o job autenticou → job vermelho. Entregar
  na org errada em silêncio é o erro que ninguém percebe até o cliente abrir a
  sandbox.
- O assessment não produziu `assessment.json` válido → job vermelho, em vez de
  gravar "saúde: undefined" no perfil do cliente.
- O planejador devolveu um `entregavelId` que não existe no contrato → job
  vermelho, e a rota de sync recusa o lote inteiro. Meia importação deixaria o
  quadro num estado que ninguém consegue auditar depois.

---

## Teste de fumaça, quando terminar

1. `acxya` → aba Conexão → dev → "testar conexão". Em ~1 min o status vira
   **conectado** e o assessment dispara sozinho.
2. Alguns minutos depois, a aba Conhecimento do Cliente mostra **Saúde da org**
   preenchida, e existe um PR `acxya: assessment da org`.
3. Crie uma demanda de teste, materialize. O card sai de `backlog`, roda
   `analise` e para em `aguardando_gate_analise` — com o bloco de gate visível.
4. Aprove no card. A etapa `design` dispara sozinha.
5. Em `/admin/usuarios`, conceda acesso a um e-mail seu alternativo. Deve chegar
   um convite; pelo link você define a senha e entra.

Se o passo 2 não acontecer mas o PR existir, o que faltou foi
`SQUAD_OS_SYNC_ASSESSMENT_URL`/`SQUAD_OS_SYNC_TOKEN` — o dado está no git, só
não voltou pro app.
