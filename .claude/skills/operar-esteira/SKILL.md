---
name: operar-esteira
description: Runbook de quem opera a esteira em nome do responsável — aprovar gate pelo banco e pelo workflow, registrar decisão no design, tratar QA reprovado e build bloqueado, e o que nunca fazer. Use antes de aprovar um gate "via Claude", de mexer em branch de demanda ou de escrever no banco do Squad OS. Não é para os agentes de etapa.
---

# Operar a esteira

Isto é para a sessão que opera a esteira com autorização do responsável. Os agentes de
etapa (`.claude/agents/`) nunca aprovam gate nem escrevem em `status.yaml` ou `gates.md`.

## O que você pode e não pode aprovar

- Só aprove o que o responsável autorizou, e marque o autor como
  `<Nome do responsável> (via Claude)`. Autorização dada numa conversa não vale para a
  próxima: confirme o que está valendo.
- **Nunca** o gate de análise nem a homologação. A homologação é do cliente; a entrega
  manual é homologada pelo cliente ou por um admin, nunca por quem a registrou.
- Gate de design de contrato AMS só libera o build com a estimativa aprovada pelo cliente
  (`estimativa_aprovada_horas` igual a `estimativa_consultor_horas`). Não contorne.
- Não reaprove o mesmo gate sem fato novo. Build bloqueado numa pergunta de negócio volta
  bloqueado; a esteira recusa a reaprovação sem mudança no design ou no card.
- Leia a skill `conferir-gate` (`.claude/skills/conferir-gate/SKILL.md`) antes de aprovar.

## Aprovar um gate

Três passos, nesta ordem. Todo `UPDATE` ou `INSERT` filtra por `code` **e** `client_id`:
os códigos são parecidos e um filtro só por código já alterou a demanda errada.

1. Comentário no card dizendo o que foi conferido e o que segue (`comentarios`:
   `id`, `demanda_id`, `autor`, `autor_email` vazio, `texto`, `criado_em`).
2. Linha em `disparos_esteira`: `tipo='aprovar'`, `gate=<status atual>`, `autor`,
   `criado_em` e `disparado_em` com `now()`, `ambiente` (`dev` para design, `qa` para o gate
   de build), `nota` curta.
3. Workflow `run-demand.yml` na `main`, com `client` (slug), `demand_id`,
   `aprovar_gate=<autor>` e `gate_esperado=<status atual>`.

Faça o comentário e o disparo num único comando, condicionados ao status esperado, para não
aprovar uma demanda que já saiu do gate.

Depois, agende uma conferência (10 a 15 minutos) e leia o resultado. Aprovar e não voltar
para ver é o erro mais comum.

## Abrir uma demanda pelo banco

Prefira o botão "+ nova demanda" do portal. Se precisar criar pelo banco, faça o mesmo que
`lib/demandas-server.ts`: código sequencial do cliente, `status='backlog'`, `autor` como
`<Nome do responsável> (via Claude)`, uma entrada no `historico`, e o **dono**: `dono_id`
com o `id` de quem vai responder por ela em `usuarios` (admin ou consultor),
`dono_definido_em=now()` e `dono_definido_por` igual ao autor. Sem saber quem é, deixe sem
dono e diga ao responsável; não escreva o dono no texto da demanda.

## Registrar uma decisão do responsável

O builder segue o `03-design.md`, não o comentário do card. Decisão de negócio vai para o
design, na branch da demanda:

1. `git fetch origin feature/<ID>` e um worktree destacado num diretório temporário.
2. Acrescente ao fim de `03-design.md` uma seção
   `## Decisão do responsável (<data>, <nome>): <título>` com o achado, a decisão e o que a
   verificação e o QA devem provar.
3. Se a demanda precisa voltar de etapa, use `demands.transition` (nunca edite
   `status.yaml` à mão) e espelhe o status e o histórico no banco.
4. Commit `<ID>: verbo no imperativo`, push para `feature/<ID>` sem force, remova o worktree.

## QA reprovado

Leia o `05-testes-rodada-<n>.md` mais recente na branch. Classifique:

- **Defeito de construção com causa clara** (o QA aponta o componente): registre a correção
  no design, aprove o gate de design e acompanhe. Peça que a versão fique ativa na dev para
  o verificador exercitar o caso antes do gate.
- **Só ambiente ou não exercitado** (licença, fila, usuário, acesso): a esteira já parou a
  demanda no gate de build, e o card abre com "O QA não conseguiu provar". Não reaprove
  antes de o que falta estar resolvido: aprovar só repete a rodada. Leve ao responsável a
  lista do que falta e quem providencia.
- **Pergunta de negócio**: não reaprove. Leve ao responsável com a pergunta escrita.
- **Reprovou de novo pela mesma causa**: pare e avise. Não entre em laço.

## Avisar o responsável

Avise quando a ação é dele: decisão de negócio, QA que o builder não corrige, gate de
análise, homologação, falta de crédito de API. Não narre cada execução que deu certo.

## Nunca

- Produção do Salesforce. O conector Salesforce da sessão é produção: não use.
- Dado real de cliente no contexto: só metadata e contagens agregadas.
- Force-push em branch de demanda; escrita direta na `main`.
- Merge de PR sem o responsável pedir. PRs de demanda (`feature/<ID>`) não se mesclam em
  lote: fecham na entrega.
- Aplicar migração do portal à mão. Confira em `_prisma_migrations` se o deploy aplicou.
