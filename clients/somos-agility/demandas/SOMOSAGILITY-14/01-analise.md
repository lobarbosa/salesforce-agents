# SOMOSAGILITY-14 — Análise (BA discovery)

- Cliente: somos-agility
- Tipo: sustentação (bug) — etapas 1, 2, 3 (design enxuto), 4, 5, 7
- Fonte: `demandas/SOMOSAGILITY-14/demanda.md` (relato do consultor, sem alteração)
- Status: **rascunho para validação humana — bloqueado por informações pendentes (ver seção 6)**

---

## 1. Contexto de negócio

Existe um fluxo de **reembolso** na org do cliente em que um usuário consegue **abrir a solicitação de reembolso**, mas não consegue **enviá-la para aprovação**. O relato indica que o erro aparece na transição de "abrir" para "enviar para aprovação". O consultor (Simone, usuária reportante) anexou um print do erro e a SR (solicitação de reembolso) aberta.

Impacto declarado: o usuário fica impedido de concluir o reembolso. O relato não informa quantos usuários são afetados, se há prazo ou se há impacto financeiro.

## 2. Objetivo

Permitir que o usuário envie a solicitação de reembolso para aprovação, sem erro, seguindo o fluxo de aprovação já previsto para o processo.

Fora de escopo deste objetivo (a confirmar): mudar regras de aprovação, alterar valores/limites de reembolso, alterar permissões além do necessário para corrigir o erro.

## 3. Regra de negócio

Regra explícita do relato: **não há**. O relato descreve apenas o sintoma.

Regra implícita (a validar): a solicitação aberta pelo usuário deve poder ser submetida ao processo de aprovação de reembolso, e o fluxo deve refletir o estado correto da SR após o envio (ex.: em aprovação, não mais editável pelo solicitante). Nenhum desses pontos foi confirmado.

## 4. Critérios de aceite (Gherkin)

Os cenários abaixo são **provisórios**. Os nomes de objetos, campos, Flows, botões e mensagens estão marcados com `<...>` e serão preenchidos após confirmação via `sf` CLI na etapa de recon (guardrail #3). Nenhum nome de metadata foi inventado.

```gherkin
Funcionalidade: Envio de solicitação de reembolso para aprovação

  Contexto:
    Dado que existe um usuário com perfil <PERFIL_A_CONFIRMAR> na sandbox de dev
    E que existe uma solicitação de reembolso <SR_TIPO_A_CONFIRMAR> em rascunho criada por esse usuário

  Cenário: Envio bem-sucedido para aprovação
    Quando o usuário aciona "<ACAO_ENVIAR_PARA_APROVACAO_A_CONFIRMAR>" na solicitação
    Então a solicitação muda para o status "<STATUS_EM_APROVACAO_A_CONFIRMAR>"
    E um registro de aprovação é criado para a solicitação, com o aprovador previsto pela regra <REGRA_APROVADOR_A_CONFIRMAR>
    E nenhuma mensagem de erro é exibida ao usuário

  Cenário: Reprodução do defeito antes da correção (regressão)
    Dado que a solicitação está nas mesmas condições do relato
    Quando o usuário aciona "<ACAO_ENVIAR_PARA_APROVACAO_A_CONFIRMAR>"
    Então o defeito reportado NÃO ocorre mais
    E o erro exibido no print do relato não aparece

  Cenário: Solicitação com dado inválido continua bloqueada com mensagem clara
    Dado que a solicitação tem <CAMPO_OBRIGATORIO_A_CONFIRMAR> vazio ou inválido
    Quando o usuário aciona "<ACAO_ENVIAR_PARA_APROVACAO_A_CONFIRMAR>"
    Então o envio é recusado
    E a mensagem exibida indica o campo a corrigir
    E a solicitação continua em rascunho

  Cenário: Usuário sem permissão não consegue enviar para aprovação de outro solicitante
    Dado que a solicitação foi criada por outro usuário
    Quando o usuário tenta acionar "<ACAO_ENVIAR_PARA_APROVACAO_A_CONFIRMAR>"
    Então a ação não está disponível OU é recusada com mensagem de permissão
    E nenhum dado da solicitação é alterado
```

Observação de testabilidade: os cenários 1 e 2 dependem de saber **qual** ação e **qual** status o processo usa hoje. Sem isso, o critério "não ocorre mais" não é verificável — fica bloqueado até a resposta da seção 6.

## 5. O que a demanda NÃO diz

Pontos que precisam de resposta antes do design (`03-design.md`):

1. **Print do erro: não disponível.** O anexo não chegou em texto neste ambiente. Não há mensagem de erro, código, nem tela conhecidos. Não inferi o conteúdo.
2. **SR aberta: não disponível.** Não se sabe qual tipo de SR, qual status, quais campos preenchidos, nem o `Id`/número do registro afetado. (Não usar dado real de cliente no contexto — guardrail #2: pedir número/Id e pedir que a SR seja descrita sem valores sensíveis, ou apenas pelo ID para consulta de metadata/contagem.)
3. **Passo exato do erro:** o usuário clica em qual botão/ação? Em qual tela (layout/página)? O erro aparece ao clicar, ao salvar ou ao carregar a tela?
4. **Perfil e permissões** do usuário relator (perfil, permission sets, filas/grupos). O erro pode ser de acesso e não de lógica.
5. **Ambiente onde ocorreu:** produção ou outra sandbox? (A esteira só atua em `sbx-somos-agility-dev`. Se o erro é em produção, o caminho muda: reprodução em dev, correção via branch, promoção via release.)
6. **Reprodução:** o erro é sempre reproduzível, ou só para esta SR/este usuário? Desde quando? Algo mudou recentemente (deploy, nova regra, novo aprovador)?
7. **Regra de aprovação:** qual é o processo de aprovação em uso (Approval Process, Flow, fila, aprovador por hierarquia)? Quem é o aprovador esperado?
8. **Frequência e impacto:** quantos usuários/SRs afetados, e há prazo ou reembolsos parados?
9. **Solução esperada:** o consultor quer apenas a correção do erro, ou também a revisão da regra? (Só a correção está no escopo desta análise.)
10. **Integrações:** o envio para aprovação dispara algo em sistema externo (financeiro, ERP, e-mail)? O `CLAUDE.md` do cliente não lista integrações (seção vazia).

## 6. Pendências bloqueantes (precisam ser respondidas antes do design)

| # | Pergunta | Quem responde | Bloqueia |
|---|----------|---------------|----------|
| P1 | Enviar o print do erro (texto da mensagem e o passo exato) | Consultor | Reprodução, cenário 2 |
| P2 | Informar o ID/número da SR afetada e o tipo de SR (sem colar dados pessoais ou valores) | Consultor | Recon, cenário 1 |
| P3 | Confirmar o ambiente onde o erro ocorre (produção ou sandbox) | Consultor | Toda a esteira (guardrail #1) |
| P4 | Confirmar perfil/permission sets do usuário relator | Consultor / admin do cliente | Diagnóstico de acesso vs. lógica |
| P5 | Confirmar o processo de aprovação em uso e o aprovador esperado | Admin do cliente / consultor | Cenário 1 e design |
| P6 | Confirmar se o problema é reproduzível e desde quando | Consultor | Priorização e hipótese de causa |

Recomendação: não acionar o `org-recon` nem o arquiteto antes de P1 e P3 estarem respondidas. P3 é a mais crítica: se o erro for em produção, a demanda não pode seguir a esteira de build como está.

## 7. Premissas a validar (pendentes — nenhuma foi confirmada)

- **PM1** — O fluxo de reembolso é um processo de aprovação nativo do Salesforce (Approval Process) ou um Flow customizado. *Pendente.*
- **PM2** — O erro está na org de dev do cliente, reproduzível lá. *Pendente — depende de P3.*
- **PM3** — O erro é de lógica/configuração (validação, Flow, regra de aprovação), não de dado pontual corrompido. *Pendente — depende de P1 e P2.*
- **PM4** — A correção cabe no escopo de sustentação (sem mudança de arquitetura). *Pendente — se o diagnóstico mostrar necessidade de mudança de regra de negócio, a demanda sai de sustentação e volta para análise.*
- **PM5** — O `CLAUDE.md` do cliente ainda está sem preenchimento (org de dev, convenções, integrações). Isso significa que não há prefixo de campo, nem URL de org, nem convenção de branch confirmados para este cliente. *Confirmado pelo arquivo; a ser completado.*

## 8. Estimativa de complexidade

**P (pequena)** — *provisória, não confirmada*: se a causa for uma regra de validação, permissão ou um campo obrigatório faltando, o ajuste é pontual. A estimativa vira M ou G se o erro estiver em Flow/Apex compartilhado ou se a regra de aprovação precisar mudar. Hoje, sem o print e sem a SR, não há base para mais que isso.

## 9. Próximos passos

1. Consultor responde P1 a P6 (prioridade: P3 e P1).
2. Com as respostas, reescrever os cenários com nomes reais (após `org-recon` e confirmação via `sf` CLI).
3. Revalidar a análise com o humano e só então acionar o `org-recon` (etapa 2) e depois o arquiteto (etapa 3, gate bloqueante).
