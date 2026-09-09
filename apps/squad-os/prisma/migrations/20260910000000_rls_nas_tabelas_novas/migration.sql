-- Fecha uma exposição real, não uma boa prática abstrata.
--
-- O Supabase publica o schema `public` inteiro via PostgREST em
-- https://<ref>.supabase.co/rest/v1/. A anon key que autoriza esse endpoint
-- é pública por design — ela vai no bundle do browser, qualquer visitante da
-- tela de login tem ela. O que separa "publicado" de "legível" é só o RLS:
-- tabela com RLS ligado e nenhuma policy nega tudo por PostgREST; tabela com
-- RLS desligado responde a qualquer um.
--
-- `clients`, `demandas` e `usuarios` já estavam com RLS ligado. As tabelas
-- criadas pelas migrations seguintes (ambientes_org, comentarios, e as quatro
-- do card) nasceram sem — Prisma não liga RLS sozinho, e ninguém percebeu.
-- Verificado em 2026-09-09 contra o projeto real: GET /rest/v1/ambientes_org
-- com a anon key devolveu 206 e `content-range: */1`. Naquele momento
-- `username` e `consumer_key` estavam vazios, então nenhuma credencial
-- vazou — mas a aba Conexões grava exatamente esses dois campos, e o
-- próximo cliente configurado publicaria o usuário de integração e o
-- Consumer Key da org pra internet.
--
-- Ligar RLS sem criar policy nenhuma é o estado correto aqui: o app não passa
-- por PostgREST, ele fala Postgres direto via Prisma com o papel `postgres`,
-- que é dono das tabelas e por isso ignora RLS (relforcerowsecurity = false).
-- Ou seja: nada muda pro app, e o PostgREST passa a negar tudo. Quem autoriza
-- continua sendo proxy.ts + as rotas, que sabem papel e cliente.
--
-- NÃO adicione FORCE ROW LEVEL SECURITY: isso passaria a valer também pro
-- dono, e derrubaria o app inteiro.

ALTER TABLE "ambientes_org"   ENABLE ROW LEVEL SECURITY;
ALTER TABLE "comentarios"     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "subtarefas"      ENABLE ROW LEVEL SECURITY;
ALTER TABLE "checklist_itens" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "registros_tempo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "anexos"          ENABLE ROW LEVEL SECURITY;
