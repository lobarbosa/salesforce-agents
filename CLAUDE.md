# Delivery Salesforce com Agentes

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas por
consultores no Squad OS. Modelo: **humano + agente em co-construção**. Agente nunca entrega
sozinho.

Este arquivo é carregado em toda sessão de agente e relido a cada turno — por isso traz só
as regras. O porquê de cada uma, os achados que as motivaram e o funcionamento do Squad OS
estão em `docs/doutrina-detalhada.md`: **leia a seção correspondente antes de alterar a
esteira (`src/salesforce_agents/`, `.github/workflows/`) ou o portal (`apps/squad-os/`)**.

## Regra de ouro
Toda demanda passa por **gates humanos bloqueantes**. O agente para e espera aprovação
explícita. Não existe "vou seguindo e depois você revisa". Nenhum agente aprova gate.

## Fluxo canônico

| # | Etapa | Agente | Artefato | Gate |
|---|-------|--------|----------|------|
| 1 | Análise e critérios de aceite | `ba-discovery` | `01-analise.md` | Humano aprova |
| 2–3 | Recon da org e desenho | `arquiteto` (skill `org-recon`) | `02-recon.md`, `03-design.md` | **Arquiteto humano aprova** |
| 4 | Build em branch + sandbox dev | `builder-declarativo` / `dev-apex` | `04-plano-build.md` | Revisão do PR |
| 5 | Testes na sandbox de QA | `qa` | `05-testes.md` | Cliente homologa |
| 6–7 | Deploy em QA e documentação | `release`, `doc` | `06-entrega.md` | — |

- O orquestrador roda **uma etapa por sessão**, aciona o subagente da etapa e para no gate.
- Sustentação (bug/melhoria) usa design enxuto, mas passa pelos mesmos gates.
- Sessão é um tiro só: roda em job de CI e acaba quando você para de responder. Só encerre
  depois de conferir no disco que o artefato da etapa foi gravado. "Não consegui medir X" é
  resposta válida; inventar não é.

## O que o fluxo exige de cada artefato (lido por máquina)
- `04-plano-build.md` abre com `**Resultado do build:** concluído` ou `bloqueado`. Bloqueado
  (pergunta de negócio sem resposta) volta ao gate de design; nunca invente a resposta.
- `05-testes.md` abre com `**Veredito:** aprovado|reprovado` e `**Org de teste:**` com a
  sandbox de QA. Só aprovado, com evidência por caso, chega ao cliente; o resto volta para
  o build, e o roteiro reprovado fica como `05-testes-rodada-<n>.md`.
- **Nada é marcado como entregue sem evidência**: `entregue` exige `05-testes.md` aprovado
  na sandbox de QA e `06-entrega.md`, no fluxo ou em correção manual.
- `gates.md` e `status.yaml` são escritos pela esteira (`sfagents`), nunca pelo agente.
- Demais linhas que o portal lê: skill `padrao-entrega`.

## Guardrails inegociáveis
1. **Produção é proibida.** Só existem `sbx-<cliente>-dev` (build e antes) e
   `sbx-<cliente>-qa` (QA em diante). Nenhum deploy, DML ou anonymous Apex fora delas. Três
   camadas conferem isso (allowlist de alias, hook `guard-prod.sh`, `IsSandbox` na org);
   não substitua nem contorne nenhuma.
2. **Dados reais não entram no contexto (LGPD).** Nunca SOQL que retorne CPF, e-mail,
   telefone ou valores de cliente — só metadata e contagens agregadas. Nunca screenshot de
   registro real. Anexo do card só chega à sessão se alguém de delivery o liberou.
3. **Não invente metadata.** Confirme objeto, campo, Flow ou classe via `sf` contra a org
   antes de citar. Sem confirmação, declare a incerteza.
4. **Git é obrigatório.** Build em `feature/<DEMAND-ID>`; nada direto na `main`; todo merge
   por PR com revisor humano e CI verde. Nunca force-push em branch de demanda.
5. **Estado em disco.** Cada demanda vive em `clients/<cliente>/demandas/<DEMAND-ID>/`.
   O fluxo recusa avançar sem o artefato da etapa. Corrigir status para trás é permitido.
6. **Uma demanda por vez, por cliente**, na mesma sandbox.
7. **Nunca misture clientes.** Cada cliente é isolado em `clients/<cliente>/`, com org,
   `CLAUDE.md` de briefing e histórico próprios.

## Economia de contexto
Tudo o que entra na sessão é relido a cada turno; é o maior custo da esteira.
- Leia só o que a etapa precisa. Para achar um trecho (assessment, designs anteriores,
  demandas passadas do cliente), use `rag_consultar` ou Grep em vez de abrir o arquivo.
- Não releia arquivo já lido na sessão.
- Em `sf`, peça campos e metadata específicos, com LIMIT; não despeje describe ou retrieve
  inteiro na conversa.
- Subagente devolve um resumo curto ao orquestrador, não o conteúdo do artefato.

## Convenções
- Branch `feature/<DEMAND-ID>`; commit `<DEMAND-ID>: verbo no imperativo`.
- Apex: cobertura mínima de 85% por classe; classe de teste dedicada `<Classe>Test`.
- Nomenclatura: skill `padrao-entrega`; a convenção do `CLAUDE.md` do cliente tem prioridade.
- Decisão declarativo vs. código: skill `salesforce-doutrina`.

## Antes de qualquer coisa
1. Confirme com `sf org list` qual org está conectada e diga qual é antes de tocar em algo.
2. Leia o `CLAUDE.md` do cliente (raiz do workspace): é o briefing da conta e pode trazer
   regras que valem acima das convenções do squad.
