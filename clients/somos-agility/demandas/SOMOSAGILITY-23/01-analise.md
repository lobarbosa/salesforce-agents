# SOMOSAGILITY-23 — Análise (ba-discovery)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (enxuto), 4, 5, 7.
**Fontes:** `demanda.md`, `comentarios-do-card.md` (chamado interno Agility 20260724-013), anexo do card (PDF com captura de tela do erro; a mensagem de erro não foi transcrita, ver premissas).

---

## 1. Contexto de negócio

A área de Operações da Agility usa o objeto `Realizacao_Financeira_de_Venda__c` para registrar o resultado financeiro realizado de vendas. Ao ajustar o campo "Renovação Realizado" de um lançamento específico, o Salesforce exibe um erro e o valor não é gravado. O problema foi registrado no chamado interno Agility 20260724-013, aberto pela área de Operações, e chegou ao card em 2026-10-20.

O erro aparece **somente neste lançamento**. Isso indica que a causa está nos dados desse registro ou numa regra que só dispara para ele, e não numa falha geral do objeto ou do campo.

## 2. Objetivo

Permitir que o campo "Renovação Realizado" do lançamento afetado (`a6UU40000000Ue1MAE`) seja ajustado para o valor esperado informado em `demanda.md`, sem erro, mantendo o comportamento atual dos demais lançamentos.

O objetivo é destravar o ajuste. Se a causa for só um dado incorreto no registro, a correção pode ser pontual. Se a causa for uma regra ou automação, a correção precisa ser feita na regra, e isso muda o escopo (ver seção 5).

## 3. Regra de negócio

Regra de negócio **explícita na demanda:** o valor de "Renovação Realizado" do lançamento afetado deve ser o valor esperado informado em `demanda.md`.

Regras **implícitas**, a confirmar (não são fatos):
- Não há indicação de que a regra de negócio para o campo mudou. A demanda pede ajuste de um registro, não mudança de cálculo.
- Não está claro se existe validação, fórmula, Flow ou permissão que deva impedir essa edição. Por isso a causa é desconhecida (ver seção 5).

## 4. Critérios de aceite (Gherkin)

```gherkin
Funcionalidade: Ajuste de "Renovação Realizado" no lançamento afetado

  Cenário: Ajustar o campo no lançamento afetado sem erro
    Dado que estou logado com permissão de edição em Realizacao_Financeira_de_Venda__c
    E o registro "a6UU40000000Ue1MAE" está com "Renovação Realizado" diferente do valor esperado informado em demanda.md
    Quando altero "Renovação Realizado" para o valor esperado informado em demanda.md e salvo
    Então o registro é salvo sem mensagem de erro
    E ao reabrir o registro, "Renovação Realizado" exibe o valor esperado informado em demanda.md

  Cenário: Os demais campos do lançamento afetado continuam editáveis
    Dado que estou logado com permissão de edição em Realizacao_Financeira_de_Venda__c
    Quando altero outro campo editável do registro "a6UU40000000Ue1MAE" e salvo
    Então o registro é salvo sem mensagem de erro

  Cenário: Lançamentos não afetados continuam funcionando
    Dado um registro de Realizacao_Financeira_de_Venda__c diferente de "a6UU40000000Ue1MAE"
    Quando altero "Renovação Realizado" para um valor válido e salvo
    Então o registro é salvo sem mensagem de erro

  Cenário: Causa registrada antes da correção
    Dado que a análise técnica foi concluída
    Quando o artefato 02-recon.md é revisado
    Então ele identifica o tipo da causa (validação, fórmula, Flow, Apex, permissão, dado ou outro) e o objeto ou regra responsável

  Cenário: Validação em sandbox antes de produção
    Dado que a correção foi aplicada na sandbox de QA (sbx-somos-agility-qa)
    Quando o roteiro de teste de 05-testes.md é executado
    Então os cenários acima passam nessa sandbox
```

Observação: o cenário do valor usa "valor esperado informado em demanda.md" de propósito, para não repetir o valor financeiro fora da entrada original.

## 5. O que a demanda NÃO diz

Estas lacunas precisam ser respondidas antes do design (etapa 3):

1. **Mensagem de erro exata.** O PDF anexado é uma captura de tela. A mensagem não está em texto no anexo nem na demanda. Sem ela não dá para saber se o erro vem de regra de validação, Flow, Apex, permissão de campo ou outra automação. Essa é a principal lacuna: ela decide o caminho (declarativo x código) e a faixa de esforço.
2. **Se o registro está em produção.** A URL aponta para o domínio de produção do cliente, mas a demanda não diz isso de forma explícita. Não é possível reproduzir em sandbox sem saber se o registro existe lá, e copiar dados de cliente para sandbox exige avaliação de LGPD.
3. **Se a correção é de dado ou de regra.** Ajustar o valor de um registro é uma correção de dado. Mudar a regra que bloqueia é uma correção de metadata. São trabalhos diferentes e com responsáveis diferentes.
4. **Quem executa a correção de dado em produção.** O agente não toca produção (guardrail #1). Presume-se que é o humano (consultor ou admin da conta), mas isso precisa ser confirmado.
5. **Perfil e permissão do usuário afetado.** Não está dito quem tentou a edição nem se outros perfis conseguem editar esse campo nesse registro.
6. **Recorrência.** Não está dito se o erro acontece em outros lançamentos com características parecidas (mesmo período, mesmo produto, mesmo parceiro). A demanda fala de um caso só.
7. **Situação do chamado 20260724-013 na Agility.** O chamado foi aberto em julho de 2026 e o card entrou em outubro de 2026. Não se sabe se houve diagnóstico ou correção parcial do lado da Agility, nem se o erro ainda ocorre hoje.
8. **Campo em metadata.** O nome de API de "Renovação Realizado" não foi confirmado contra a org. Isso é trabalho do recon (etapa 2), não desta análise.

## 6. Premissas a validar

Nenhuma destas premissas é fato confirmado. Todas estão **pendentes**:

- [ ] **P1 (pendente, bloqueante):** A mensagem de erro exata exibida ao tentar salvar "Renovação Realizado" é: `<a confirmar>`. Pergunta: qual é o texto integral da mensagem (e, se houver, o nome da regra, do Flow ou o código de erro)? Pode ser enviado em texto no card, o que dispensa a leitura da imagem.
- [ ] **P2 (pendente):** O registro `a6UU40000000Ue1MAE` existe em produção. Assume-se que sim, pela URL.
- [ ] **P3 (pendente):** A correção pedida é de dado (ajuste pontual do valor) e não de regra. Assume-se que é de dado, mas se a causa for regra, o escopo muda para metadata e passa a ter build, PR e deploy.
- [ ] **P4 (pendente):** A correção de dado em produção é feita por pessoa autorizada da conta, não pelo agente.
- [ ] **P5 (pendente):** O erro não é recorrente em outros lançamentos. Se for, o escopo cresce e a análise precisa ser refeita.
- [ ] **P6 (pendente):** O campo é editável para o perfil de quem reportou. Se não for, o caso é de permissão, e a correção pode ser de configuração de acesso.
- [ ] **P7 (pendente):** Não há processo de aprovação ou bloqueio de edição ativo nesse registro, que impeça a edição por motivo de fechamento financeiro.

## 7. Complexidade

**P (provisória).** Um campo, um registro afetado, e a correção pode ser só de dado. Sobe para **M** se a causa estiver numa automação compartilhada (Flow ou Apex que atinge outros lançamentos) ou se exigir mudança de regra com build e deploy.

## 8. Estimativa de esforço

**Estimativa de esforço:** 2–6 h

Premissas que mais pesam na faixa:
- Se a causa for dado no registro ou regra simples de validação, a faixa fica perto de 2 h (diagnóstico, correção, teste e homologação).
- Se a causa for Flow, Apex ou permissão, com validação em sandbox e revisão de PR, a faixa sobe para perto de 6 h.
- A faixa é larga porque a mensagem de erro exata ainda não está confirmada (P1). O arquiteto refina no design.
- Não inclui o tempo de conversa com a Agility sobre o chamado 20260724-013.

---

## Perguntas bloqueantes antes do design

1. Qual é a mensagem de erro exata (texto integral, regra ou código, se houver)? Pode ser em texto no card.
2. O registro `a6UU40000000Ue1MAE` está em produção? Ele pode ser reproduzido em sandbox, e de que forma, dado o LGPD?
3. A correção pedida é só do valor deste registro, ou também precisa mudar uma regra?
4. Quem da conta executa a correção de dado em produção?
5. Em qual perfil o erro foi reproduzido, e outros perfis conseguem editar o campo nesse registro?
6. O erro se repete em outros lançamentos?
7. O chamado 20260724-013 tem diagnóstico ou correção parcial do lado da Agility?

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
