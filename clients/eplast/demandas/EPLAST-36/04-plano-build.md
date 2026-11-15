**Resultado do build:** bloqueado

# EPLAST-36 — Plano de build

**Data:** 2026-11-15 · **Branch:** `feature/EPLAST-36` · **Org consultada:** alias `sbx-eplast-dev` (somente `sf org display`, nenhum deploy)

## Motivo do bloqueio: condição C1 do design (ambiente), não é pergunta de negócio

O `03-design.md` (seção 11, C1) manda não começar o build se o alias de dev apontar para a sandbox de QA. Conferido nesta sessão:

- `sf org list` mostra só um alias: `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`).
- `sf org display -o sbx-eplast-dev`: instância `https://eplast--qa.sandbox.my.salesforce.com`. O subdomínio é `--qa`, e o usuário conectado termina em `.qa`.
- O alias `sbx-eplast-qa` **não existe** neste runner (`No authorization information found`). Não consigo provar que são orgs distintas, e tudo indica que o alias de dev é a QA.

Fazer deploy agora levaria o build direto à sandbox de QA, que o builder não toca (CLAUDE.md da raiz, etapa 5 e guardrail 1). Não contornei nem troquei o alias.

## O que falta e quem resolve

| Pendência | Quem responde |
|---|---|
| Reconectar o alias `sbx-eplast-dev` na sandbox de dev de verdade (subdomínio sem `--qa`) e registrar o alias `sbx-eplast-qa` | Humano de delivery / esteira (`sfagents`) |

Nenhuma outra dúvida de design impede o build. As premissas PA-01 a PA-11 do design valem e não são motivo de bloqueio.

## Componentes criados

Nenhum. Nada foi escrito em `force-app/` e nada foi implantado.

## Próximo passo quando o ambiente estiver certo

Executar os itens da seção 3 do design: C3 (ler filtros dos 7 `RECORRENTES (ATIVOS)` e dos dois `SAZONAIS - MG`), C4 (tipos de relatório), C5 (acesso à pasta `MARKETING CLOUD`), e então ajustar/criar relatórios e o permission set `PS_Marketing_Publicos`.
