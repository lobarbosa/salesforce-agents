**Resultado do build:** concluído

# SOMOSAGILITY-16 — Plano de build (builder-declarativo)

**Org consultada:** `sbx-somos-agility-dev` (conectada, confirmada com `sf org list`). Nenhum deploy, DML ou Apex executado. Produção não foi tocada pela esteira.

## Componentes criados

Nenhum. O design (03-design.md, seções 1, 2 e 4) decide por configuração pura: a assinatura do relatório "Leads Semanais" não é metadata, não há Flow, Apex, perfil ou permission set. Nada entra em `force-app/`. Não há descrição de componente a preencher.

## Decisões pendentes do design (seção 8)

Registradas no card (`comentarios-do-card.md`, comentário de 2026-11-24 21:54, equipe):

| # | Decisão | Como foi resolvida |
|---|---|---|
| D1 | Escopo | Remover só o destinatário Fabio Soto (padrão do design, 5a). O card informa que os demais destinatários continuam recebendo. |
| D2 | Ambiente e executor | Execução direta em produção por um consultor da equipe (conforme comentário de 2026-11-23 23:59). O nome do papel exato do executor não foi registrado no card. |
| D3 | Lista nominal | Ficou no card, não no repositório. O repositório guarda só contagem e papel/perfil (RN4). |
| D4 | Prazo | Sem prazo declarado; a remoção já foi feita. |

Observação: o comentário "Card encerrado" não traz o estado "antes" nem o Id do relatório conferido em produção. O QA deve pedir esses dados ao executor.

## Runbook (design, seção 6) — status de execução

Executado por humano em produção, fora da esteira. Estado do registro:

1. Confirmar alvo (relatório, pasta Leads, org de produção): sem evidência no card.
2. Confirmar usuário único: sem evidência no card.
3. Enumerar assinaturas: sem evidência no card.
4. Mapear o "antes": contagem do antes não registrada.
5. Aplicar 5a (remover Fabio Soto): **informado como realizado** no card, em 2026-11-24 21:54.
6. Mapear o "depois": o card lista 3 destinatários restantes (1 papel/grupo e 2 usuários). Nomes ficam no card, não aqui.
7. Evidência em `05-testes.md`: pendente de quem executou (contagem antes/depois, perfil/papel, data/hora, confirmação de que Fabio Soto não consta mais, sem nomes, e-mails ou prints de dados).

**Rollback:** reinscrever Fabio Soto na mesma assinatura. Depende de a lista do "antes" estar guardada com a consultora.

## Versões e ativação

Não se aplica. Nenhum Flow, agente ou classe criado ou alterado.

## Limites desta etapa

- A esteira não leu nem alterou a assinatura em produção (guardrail #1). A remoção só é conhecida pelo relato no card, sem prova independente.
- Não há o que a verificação na sandbox de dev possa exercitar: a assinatura de produção não existe lá (design, seção 3). A verificação deve sair como inconclusiva ou não aplicável.

## Correções da rodada 1

Org consultada: `sbx-somos-agility-dev`. Nenhuma alteração de metadata, deploy ou DML. Nada em produção.

| Falha | Tratamento |
|---|---|
| FALHA 1 (crítica): critérios 1 a 4 sem prova do antes/depois | **Não corrigível nesta etapa.** A mudança foi feita por humano em produção e o guardrail #1 impede que a esteira leia ou altere a assinatura. O builder não pode gerar o "antes" (não foi guardado) nem o "depois" independente. Inventar essa evidência é proibido. |

O que falta e quem responde (para o gate, antes de nova rodada de QA):

1. **Executor da mudança (consultor da equipe que removeu o usuário):** registrar no card, sem nomes, e-mails ou prints de dados: data/hora da execução, contagem de destinatários antes e depois, perfil/papel de cada destinatário restante, e confirmação de que o usuário removido não consta mais. O card já traz o relato de 3 destinatários restantes (1 papel/grupo, 2 usuários) em 2026-11-24 21:54.
2. **Consultora (Juliana Mendes):** informar se a contagem do "antes" existe (a lista nominal guardada com ela, conforme D3). Se não existe, o critério 2 (demais destinatários inalterados) só pode ser aceito por declaração.
3. **Gate humano:** decidir entre (a) aguardar a evidência do item 1, ou (b) aceitar formalmente que a prova é a declaração do executor no card, registrando as limitações dos critérios 1 a 4 como "sem prova independente". Esta é decisão do humano, não do agente.

O caso 5 (nenhuma escrita em produção pelo agente) passou e permanece como está. O caso 3 foi apenas parcial na QA, porque a QA não reflete a produção; não há correção possível aqui.
