# Publicar o Squad OS num domínio próprio

Plano de corte para tirar o Squad OS das URLs `*.vercel.app` e colocá-lo num
domínio da Acxya/Konecta. Escrito em 2026-09-09, contra o estado real do projeto
Supabase `phvxhahignvsgnhozxrr` (`us-east-2`, Postgres 17.6).

Não é uma lista de boas práticas genéricas: cada item aqui existe porque ou já
quebrou nesta operação, ou está aberto agora.

**Atualizado em 2026-09-20:** dos bloqueantes do §2, só o banco de Preview
dedicado (§2.1) segue aberto — por decisão de custo, não por trabalho
pendente. Os demais (§2.2, §2.3, §2.4) foram fechados e reconferidos direto
contra o projeto real nesta data; os detalhes de cada um estão atualizados
abaixo em vez de arquivados numa seção à parte. O corte em si (§3) também
avançou: domínio `os.acxya.com.br` já está no ar, DNS resolvido, cadastrado
na Vercel — falta confirmar o passo 3 (Supabase Auth) e fechar o teste de
login nos 3 papéis.

---

## 0. Auto-cadastro  ✅ fechado

**Decisão tomada: fechar.** Confirmado em 2026-09-20 ("vou seguir a sua
recomendação"), mas o código já refletia essa decisão desde antes deste corte
— `app/login/page.tsx` não tem aba "Criar conta" (só "Link por e-mail" e
"Senha"), `signInWithOtp` vai com `shouldCreateUser: false`, e o comentário no
próprio arquivo documenta o porquê. O caminho de entrada é: admin concede
acesso em `/admin/usuarios`, a pessoa usa "Esqueci minha senha" pra definir a
dela — nenhum passo a mais pra quem é do time, uma porta a menos aberta pra
quem não é.

Fica registrado abaixo o raciocínio original, pra quem chegar depois querer
saber por quê:

| | Manter o auto-cadastro | Fechar o auto-cadastro (o que está em produção) |
|---|---|---|
| Como a pessoa entra | Cria conta sozinha, espera o admin liberar | Admin cria em `/admin/usuarios`, pessoa define a senha por "Esqueci minha senha" |
| Atrito pra quem é do time | Nenhum | Um passo do admin, uma vez por pessoa |
| Superfície aberta | Cadastro público + envio de e-mail | Nenhuma — só login de quem já existe |

O motivo de ter existido essa decisão: sem restrição, qualquer pessoa na
internet cria uma linha em `auth.users` e consome cota de e-mail do projeto —
teórico numa URL `vercel.app` que ninguém conhece, real num domínio indexável
da Acxya. O isolamento por papel e por cliente nunca dependeu disso (`proxy.ts`
decide pela tabela `usuarios`, não por existir em `auth.users`), mas a
superfície aberta não precisava existir.

---

## 1. Pré-requisitos que já estão fechados

- Login por magic link, senha e recuperação — funcionando. (Cadastro público
  fechado — ver §0.)
- Papéis (`admin` / `consultor` / `cliente`) resolvidos no `proxy.ts` e
  aplicados nas rotas.
- RLS ligado em todas as tabelas do schema `public` (corrigido em 2026-09-09 —
  ver a migration `20260910000000_rls_nas_tabelas_novas`, que documenta a
  exposição encontrada).
- CI: `ci-python.yml`, `ci-squad-os.yml`, `ci-salesforce-validate.yml`.

## 2. Pré-requisitos

### 2.1 Banco próprio pro Preview  ⛔ bloqueante — o único que falta

Hoje Preview e Production apontam pro mesmo `DATABASE_URL`. Consequência: o
build de preview de um PR roda `prisma migrate deploy` **na produção**, antes do
merge. Já derrubou a produção uma vez (2026-09-09).

Enquanto for um banco só, toda mudança destrutiva de schema tem que ir em dois
merges (ver `apps/squad-os/README.md`, "Preview e Production compartilham o
mesmo banco"). Isso é contornável agora, mas com o app num domínio real e mais
gente usando, a probabilidade de alguém esquecer o passo vira alta.

**Fazer:** criar um segundo projeto Supabase (ou um branch de banco) e apontar
só a env var `DATABASE_URL` de **Preview** pra ele. Custo: confirmado em
2026-09-20, **US$10/mês** (a org já está no plano Pro, que tira o projeto novo
da faixa gratuita de 2 projetos). Decisão explícita de adiar — não é esquecimento:
perguntado, a resposta foi "não quero ter custo com isso agora". Enquanto for um
banco só, toda mudança destrutiva de schema segue tendo que ir em dois merges
(ver `apps/squad-os/README.md`, "Preview e Production compartilham o mesmo
banco"). Retomar quando o custo for aceitável — o resto do corte não depende
disso.

### 2.2 Proteção de senha vazada  ✅ feito em 2026-09-20

Estava desligado (`auth_leaked_password_protection` no linter de segurança).
O caminho não é o que a primeira versão deste doc dizia — **Authentication →
Policies** não existe mais nesse formato. O caminho real, confirmado contra o
dashboard: **Authentication → Sign In / Providers → Email** (expandir a linha
do provider Email) → "Prevent use of leaked passwords". Ligado e confirmado
via linter (`get_advisors`): o achado sumiu.

### 2.3 Bucket de anexos  ✅ feito

`anexos-demanda` existe (`storage.buckets`, `public = false`, criado em
2026-09-13) — sem policy, como previsto. `SUPABASE_SERVICE_ROLE_KEY` está nas
env vars da Vercel, Production e Preview (confirmado em 2026-09-20).

### 2.4 Backup  ✅ conferido — retenção diária no piso certo, PITR em aberto

**Database → Backups** confirmado em 2026-09-20: backup físico diário, 7 dias
de retenção — é exatamente o que o plano Pro entrega (Free não teria nenhum;
Team seria 14 dias, Enterprise 30). O piso do §2.4 original está garantido.

**PITR não está ligado** — é um add-on pago à parte do Pro, não vem incluso.
Mesma natureza de decisão do §2.1 (custo, não trabalho pendente): decidir
quando fonte de verdade de 6 clientes justificar o gasto extra além do backup
diário.

---

## 3. O corte, na ordem

A ordem importa: o passo 3 é o que já quebrou antes.

**1. Escolher e adicionar o domínio.** ✅ feito. `os.acxya.com.br`,
subdomínio dedicado (não a raiz — mantém o site institucional livre e o
certificado independente), adicionado na Vercel.

**2. Apontar o DNS.** ✅ feito. DNS resolvido, domínio respondendo.

**3. Reapontar o Supabase Auth.** ⚠️ **confirmar — é aqui que quebra, e
silenciosamente.** O link de login é gerado com o `emailRedirectTo` que o app
manda, mas o Supabase só honra o destino se ele casar com a allow list — senão
cai silenciosamente na Site URL e descarta o caminho, sem erro visível. Foi
assim que o link caiu em `localhost:3000` por horas em 2026-09-09. Login por
senha não passa por aqui (por isso pode já estar funcionando mesmo sem este
passo feito) — quem depende disto é magic link e "esqueci minha senha", e são
exatamente os dois caminhos que o auto-cadastro fechado (§0) tornou a única
porta de entrada pra gente nova.

Confira em **Authentication → URL Configuration** (confirmado contra a
documentação viva do Supabase em 2026-09-20 — o caminho não mudou):
- **Site URL:** `https://os.acxya.com.br` (o domínio novo, sem barra final)
- **Redirect URLs:** as três linhas
  ```
  https://os.acxya.com.br/**
  https://<projeto>-*-<time>.vercel.app/**
  http://localhost:3000/**
  ```
  A segunda linha é o que faz preview deploy continuar logando: cada deploy
  ganha uma URL imutável própria, e sem o curinga cada uma delas precisaria ser
  cadastrada à mão. `*` casa um segmento, `**` casa qualquer coisa — os
  separadores são `.` e `/`.

Não tenho como ler nem escrever essa config remotamente (não está no conjunto
de ferramentas do MCP do Supabase desta sessão) — só quem confirma é você, no
dashboard.

**4. Testar o login no domínio novo** com os três papéis antes de anunciar:
admin, consultor e um usuário `cliente` (esse último tem que cair direto em
`/clients/<id>` e não conseguir sair de lá). Em 2026-09-20: admin e cliente
testados; **consultor ainda não** — e como o passo 3 muda o comportamento de
magic link/recuperação, vale re-testar esses dois fluxos especificamente
depois de confirmar o passo 3, não só o login por senha.

**5. Auto-cadastro.** ✅ já resolvido — ver §0.

**6. Esvaziar `ADMIN_BOOTSTRAP_EMAILS`.** ✅ feito em 2026-09-20. Essa variável
fazia qualquer e-mail da lista virar admin no primeiro login. Ela existia pra
destravar o primeiro admin — esse já existe como linha normal em `usuarios`.
Deixá-la preenchida num domínio público seria uma porta de admin que ninguém
está olhando. Variável apagada — **precisa de um redeploy** pra valer no
deployment já publicado (env var não retroage sozinha).

**7. Conferir a proteção dos previews.** ✅ já vinha assim. Vercel → Settings
→ Deployment Protection → o projeto está em **"Standard Protection"**, que é
o nível padrão da Vercel: Preview exige login Vercel (só quem é do time
acessa), Production fica pública no domínio. Confirmado em 2026-09-20 —
não precisou mudar nada. Continua valendo a razão original: preview deploy lê
o mesmo banco de produção até o §2.1 ser feito, e essa proteção é a barreira
que evita preview público virar produção pública por outra porta.

**8. Anunciar.** Só depois de 1–7. O time já sabe que a plataforma existe
(segundo você, em 2026-09-20), mas "sabe que existe" não é o mesmo que "passo
8 feito" — este passo é especificamente depois do login testado nos 3 papéis
(passo 4), pra não anunciar um acesso que ainda vai quebrar pra alguém.

---

## 4. Checklist de corte

Estado em 2026-09-20:

- [ ] Banco próprio pro Preview, `DATABASE_URL` de Preview reapontada (§2.1) — **adiado por custo, decisão sua**
- [x] Leaked password protection ligada (§2.2)
- [x] Bucket `anexos-demanda` criado + `SUPABASE_SERVICE_ROLE_KEY` nas env vars (§2.3)
- [x] Retenção de backup confirmada (§2.4) — diária, 7 dias (PITR não ligado, também custo)
- [x] Domínio adicionado na Vercel e "Valid Configuration" — `os.acxya.com.br`
- [ ] Site URL e Redirect URLs do Supabase atualizadas — **confirmar, só você acessa essa tela**
- [ ] Login testado nos 3 papéis, no domínio novo — admin e cliente ok, **falta consultor**
- [x] Decisão do auto-cadastro executada — já estava fechado em código
- [x] `ADMIN_BOOTSTRAP_EMAILS` vazia — **falta o redeploy pra valer**
- [x] Vercel Authentication ligada nos previews — já era o padrão do projeto
- [ ] Anunciado para o time — time já sabe que existe, mas só formalizar depois do passo 4 fechado

## 5. Rollback

O domínio antigo (`*.vercel.app`) continua respondendo depois de adicionar o
novo — não é uma troca, é um alias a mais. Então o rollback é: reverter a Site
URL do Supabase pro domínio antigo, avisar o time, investigar sem pressa. O
único passo com efeito real e imediato é o 3; todos os outros são aditivos.

Migração de schema não faz parte deste corte de propósito. Se algo de banco
precisar mudar junto, faça antes ou depois, nunca no mesmo dia — misturar
"trocar o endereço" com "mudar o schema" é como se perde a capacidade de dizer
o que quebrou.

---

## Nota sobre o que não consegui verificar

O token da Vercel disponível nas sessões de agente segue sem enxergar o
projeto do Squad OS (`list_projects` no time `acxya's Team` volta vazio) — os
passos de domínio e DNS do §3 foram relatados como feitos por você, não
verificados por mim direto no projeto. O que falta (Site URL/Redirect URLs do
Supabase, teste de login do consultor) também não está nas ferramentas MCP
desta sessão — configuração de Auth URL não tem tool de leitura nem escrita
disponível aqui, e teste de login é ação humana por natureza.

O que passou a estar verificado direto contra o sistema real, e não mais de
memória: o estado do RLS de todas as tabelas, a exposição do PostgREST, o
linter de segurança do Supabase, a região e a versão do Postgres (isso já
valia desde 2026-09-09) — e agora também, em 2026-09-20: o caminho real do
toggle de leaked password protection (achado via busca na documentação viva
do Supabase, porque o caminho antigo deste doc estava errado), o bucket
`anexos-demanda` (via SQL em `storage.buckets`), a retenção de backup (via
screenshot que você mandou de **Database → Backups**), e o nível de
Deployment Protection do projeto (via screenshot de **Settings → Deployment
Protection**). Os dois últimos foram confirmados por você mandar a tela, não
por eu acessar — vale registrar a diferença.
