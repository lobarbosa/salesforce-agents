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
