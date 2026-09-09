# Publicar o Squad OS num domínio próprio

Plano de corte para tirar o Squad OS das URLs `*.vercel.app` e colocá-lo num
domínio da Acxya/Konecta. Escrito em 2026-09-09, contra o estado real do projeto
Supabase `phvxhahignvsgnhozxrr` (`us-east-2`, Postgres 17.6).

Não é uma lista de boas práticas genéricas: cada item aqui existe porque ou já
quebrou nesta operação, ou está aberto agora.

---

## 0. Antes de escolher o domínio: uma decisão que é sua

**Hoje qualquer pessoa na internet pode criar conta.** A tela de login tem a aba
"Criar conta", que chama `supabase.auth.signUp` sem restrição de e-mail. Quem se
cadastra não vê dado nenhum — o `proxy.ts` consulta a tabela `usuarios` e, sem
linha lá, a pessoa recebe "Esse e-mail ainda não tem acesso ao Squad OS". O
isolamento por papel e por cliente está de pé.

O que ela consegue, mesmo assim: criar uma linha em `auth.users`, consumir a
cota de e-mail do seu projeto Supabase e deixar a caixa de entrada de alguém
recebendo e-mail de confirmação com a sua marca. Numa URL `vercel.app` que
ninguém conhece isso é teórico. Num domínio da Acxya, indexável, deixa de ser.

| | Manter o auto-cadastro | Fechar o auto-cadastro |
|---|---|---|
| Como a pessoa entra | Cria conta sozinha, espera o admin liberar | Admin cria em `/admin/usuarios`, pessoa define a senha por "Esqueci minha senha" |
| Atrito pra quem é do time | Nenhum | Um passo do admin, uma vez por pessoa |
| Superfície aberta | Cadastro público + envio de e-mail | Nenhuma — só login de quem já existe |
| Trabalho pra implementar | Zero | Tirar a aba "Criar conta" de `app/login/page.tsx` (o resto do fluxo já existe) |

**Recomendo fechar.** O auto-cadastro foi construído quando a plataforma ainda
não tinha `/admin/usuarios` funcionando; agora tem, e o caminho "admin concede,
pessoa recupera a senha" cobre o mesmo caso com uma porta a menos. Isso é uma
decisão sua, não técnica — me diga qual e eu executo. **Todo o resto deste plano
vale nos dois casos**; só o passo 5 muda.

---

## 1. Pré-requisitos que já estão fechados

- Login por magic link, senha, cadastro e recuperação — funcionando.
- Papéis (`admin` / `consultor` / `cliente`) resolvidos no `proxy.ts` e
  aplicados nas rotas.
- RLS ligado em todas as tabelas do schema `public` (corrigido em 2026-09-09 —
  ver a migration `20260910000000_rls_nas_tabelas_novas`, que documenta a
  exposição encontrada).
- CI: `ci-python.yml`, `ci-squad-os.yml`, `ci-salesforce-validate.yml`.

## 2. Pré-requisitos que **faltam** — bloqueiam o corte

### 2.1 Banco próprio pro Preview  ⛔ bloqueante

Hoje Preview e Production apontam pro mesmo `DATABASE_URL`. Consequência: o
build de preview de um PR roda `prisma migrate deploy` **na produção**, antes do
merge. Já derrubou a produção uma vez (2026-09-09).

Enquanto for um banco só, toda mudança destrutiva de schema tem que ir em dois
merges (ver `apps/squad-os/README.md`, "Preview e Production compartilham o
mesmo banco"). Isso é contornável agora, mas com o app num domínio real e mais
gente usando, a probabilidade de alguém esquecer o passo vira alta.

**Fazer:** criar um segundo projeto Supabase (ou um branch de banco) e apontar
só a env var `DATABASE_URL` de **Preview** pra ele. Custo: um projeto Supabase a
mais. Depois disso um PR volta a poder carregar schema e código no mesmo merge.

### 2.2 Proteção de senha vazada  ⛔ rápido

O linter de segurança do Supabase aponta `auth_leaked_password_protection`
desligado. Com login por senha aberto num domínio público, ligar isso é o
mínimo: **Authentication → Policies → Password strength → Leaked password
protection**. Um clique.

### 2.3 Bucket de anexos

`Storage → New bucket` → `anexos-demanda`, **Public desmarcado**, nenhuma
policy. E `SUPABASE_SERVICE_ROLE_KEY` nas env vars da Vercel (Production e
Preview). Sem isso a aba Anexos recusa upload com mensagem explícita — não
quebra nada, mas fica pela metade.

### 2.4 Backup

Confirmar em **Database → Backups** qual é a retenção do plano atual. Num banco
que passa a ser fonte de verdade de demanda de 6 clientes, backup diário é o
piso; PITR é o que você quer.

---

## 3. O corte, na ordem

A ordem importa: o passo 3 é o que já quebrou antes.

**1. Escolher e adicionar o domínio.** Vercel → o projeto → Settings → Domains →
Add. Sugestão: um subdomínio dedicado (`os.acxya.com.br`), não a raiz — mantém o
site institucional livre e o certificado independente.

**2. Apontar o DNS.** A Vercel mostra o registro exato (`CNAME` para
`cname.vercel-dns.com` no caso de subdomínio). Propagação: minutos a algumas
horas. Espere o domínio ficar "Valid Configuration" antes do passo 3.

**3. Reapontar o Supabase Auth.** ⚠️ **É aqui que quebra.** O link de login é
gerado com o `emailRedirectTo` que o app manda, mas o Supabase só honra o
destino se ele casar com a allow list — senão cai silenciosamente na Site URL e
descarta o caminho. Foi assim que o link caiu em `localhost:3000` por horas.

Em **Authentication → URL Configuration**:
- **Site URL:** `https://os.acxya.com.br` (o domínio novo, sem barra final)
- **Redirect URLs:** mantenha as três linhas
  ```
  https://os.acxya.com.br/**
  https://<projeto>-*-<time>.vercel.app/**
  http://localhost:3000/**
  ```
  A segunda linha é o que faz preview deploy continuar logando: cada deploy
  ganha uma URL imutável própria, e sem o curinga cada uma delas precisaria ser
  cadastrada à mão. `*` casa um segmento, `**` casa qualquer coisa — os
  separadores são `.` e `/`.

**4. Testar o login no domínio novo** com os três papéis antes de anunciar:
admin, consultor e um usuário `cliente` (esse último tem que cair direto em
`/clients/<id>` e não conseguir sair de lá).

**5. Resolver o auto-cadastro** conforme a decisão do §0.

**6. Esvaziar `ADMIN_BOOTSTRAP_EMAILS`.** Essa variável faz qualquer e-mail da
lista virar admin no primeiro login. Ela existia pra destravar o primeiro admin
— esse já existe como linha normal em `usuarios`. Deixá-la preenchida num
domínio público é uma porta de admin que ninguém está olhando.

**7. Conferir a proteção dos previews.** Vercel → Settings → Deployment
Protection → **Vercel Authentication ligada para Preview**. Preview deploy lê o
mesmo banco de produção (até o §2.1 ser feito); preview público seria a
produção pública por outra porta.

**8. Anunciar.** Só depois de 1–7.

---

## 4. Checklist de corte

Copie e marque:

- [ ] Banco próprio pro Preview, `DATABASE_URL` de Preview reapontada (§2.1)
- [ ] Leaked password protection ligada (§2.2)
- [ ] Bucket `anexos-demanda` criado + `SUPABASE_SERVICE_ROLE_KEY` nas env vars (§2.3)
- [ ] Retenção de backup confirmada (§2.4)
- [ ] Domínio adicionado na Vercel e "Valid Configuration"
- [ ] Site URL e Redirect URLs do Supabase atualizadas
- [ ] Login testado nos 3 papéis, no domínio novo
- [ ] Decisão do auto-cadastro executada
- [ ] `ADMIN_BOOTSTRAP_EMAILS` vazia
- [ ] Vercel Authentication ligada nos previews
- [ ] Anunciado para o time

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

O token da Vercel disponível nesta sessão não enxerga o projeto do Squad OS
(`list_projects` no time `acxya's Team` volta vazio). Os nomes de tela e os
caminhos de menu da Vercel acima estão escritos de memória da documentação, não
lidos do seu projeto — confira ao executar. O que foi verificado direto contra o
sistema real: o estado do RLS de todas as tabelas, a exposição do PostgREST, o
linter de segurança do Supabase, a região e a versão do Postgres.
