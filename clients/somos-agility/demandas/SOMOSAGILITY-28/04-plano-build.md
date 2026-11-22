**Resultado do build:** bloqueado

# Plano de build SOMOSAGILITY-28

**Org conectada (`sf org list`):** `sbx-somos-agility-dev` (sandbox, Connected). Nada foi implantado, nenhum DML foi feito.
**Branch:** `feature/SOMOSAGILITY-28`

## Por que bloqueou

Nova tentativa de build, depois de um segundo aceite do gate de design (2026-11-22 21:06). O card nao traz resposta nova: so "Encerrar Card" e as aprovacoes de gate. Aprovar o gate nao responde G1, G2 e G7.

O `03-design.md` (seção 9) marca G1, G2 e G7 como bloqueantes do build e manda o builder sair com "bloqueado" enquanto não houver resposta. O `comentarios-do-card.md` só traz "Realizado o acesso para o perfil do usuário" (2026-11-11), a aprovação da estimativa de 2 h e a aprovação dos gates. Nenhuma das três perguntas foi respondida. Aprovar o gate de design não responde pergunta de negócio.

Construir agora exigiria inventar o objeto e o nível de acesso do permission set, e a regra é não inventar.

## Perguntas sem resposta

| # | Pergunta | Quem responde | Por que impede construir |
|---|---|---|---|
| G1 | O objeto é `JOB_de_Solicitacao_de_Treinamentos__c` (label "JOB de Solicitação de Treinamentos")? Se não, qual dos outros 4 objetos com "Treinamento" no label? | Solicitante / consultor da demanda | O objeto foi escolhido por semelhança de nome. Um objeto errado leva a um permission set errado e a nova checagem de automação e permissões (R1). |
| G2 | Nível de acesso: ler, criar, editar ou excluir; só os próprios registros ou os de todos. Sintoma exato, em texto e sem dado de registro. | Solicitante / consultor | Define ObjectPermissions, FLS e aba. Se pedir "ver os de todos", cai em R4 (ViewAll ou regra de compartilhamento), que é decisão humana e não foi tomada. ViewAll não foi concedido por padrão. |
| G7 | Opção A (só documentar o ajuste já feito no perfil) ou Opção B (permission set)? | Arquiteto humano / solicitante | Com a Opção A não há build. |

Não bloqueiam a criação do PS, mas ficam abertas para QA e encerramento: G3 (org do ajuste manual e reversão), G4 (perfil e licença do colaborador, necessário para reproduzir R2 e R6), G5, G6 (quem autoriza em produção) e G8.

## O que fica pronto para quando liberar

Com G1, G2 e G7 respondidos (Opção B), o build é pequeno:
- 1 PermissionSet `PS_Treinamento_SolicitacaoJob`, com descrição preenchida, em `force-app/main/default/permissionsets/`.
- Permissão de objeto conforme G2, sem ViewAll e sem ModifyAll por padrão.
- Aba, record type `Mestre` e FLS dos campos que o layout em uso exige. Os campos saem de `sf sobject describe` com a validação do solicitante.
- Confirmação do objeto alvo dos lookups `Nome_do_Aluno_1..4__c` (R7).
- Nenhum perfil, PS existente, regra de compartilhamento, Flow ou Apex alterado.

## Componentes criados

Nenhum.

## Versões e ativação

Não se aplica. Nenhum Flow, agente ou classe existente é alterado.
