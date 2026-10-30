# SOMOSAGILITY-9 — Design da solução (etapa 3, sustentação, design enxuto)

- **Cliente:** somos-agility. **Org de build:** `sbx-somos-agility-dev` (sandbox confirmada nesta sessão).
- **Base:** `01-analise.md` (gate aprovado em `gates.md`), `02-recon.md` (coleta de 2026-10-30) e o anexo do card liberado (e-mail com prints de produção, usado aqui só pelo conteúdo funcional).
- Toda metadata citada abaixo foi confirmada na org em `02-recon.md`. O que é **novo** está marcado como "criar".
- **Nomes de pessoa:** os API names `..._se_Walmor` e `..._se_Soto` já existem na org e são citados só porque o build precisa deles. No texto, as pessoas aparecem pelo papel.

---

## 1. O problema, agora que o anexo foi lido

O anexo e o recon respondem às perguntas bloqueantes da análise. A demanda tem **um** problema de negócio com três sintomas (responde a Q6):

| Item da demanda | O que é de fato (confirmado no recon) |
|---|---|
| "Realizado atualização do fluxo de aprovação" | **Já feito.** O approval process ativo `Excecao_Comercial_p_Atendimento_Tecnico__c.Qualificacao_v2_3` tem as etapas Diretor Financeiro → Diretor(a) Comercial e já não inclui o antigo diretor comercial. **Não há build aqui.** |
| "Ajustar campo obrigatório de preenchimento" | As **4 validation rules** do objeto identificam pessoas pelo nome do perfil (`$Profile.Name = 'Admin'` / `'Administração'`), ainda refletem o fluxo antigo, citam o antigo diretor na mensagem e **impedem o diretor financeiro de preencher "Responsável pelo custo"**, o contrário da regra atual. Além disso, **nada impede aprovar a etapa financeira com os campos vazios**, porque validation rule não roda em field update de approval process. |
| "Ajustar um lançamento" | Correção de **dados** em um registro de **produção** (`ECT-000080`), que chegou à etapa do diretor comercial sem os dois campos. Não é metadata. O agente não toca produção, então isso vira passo manual (seção 6). |

**Regra de negócio-alvo (RN-B, conforme o anexo):** `Responsavel_pelo_Custo__c` e `Ressalvas_do_Diretor_Financeiro__c` são preenchidos **pelo diretor financeiro** e **obrigatoriamente antes de ele aprovar** a etapa `Qualifica_o_Diretor_Financeiro`.

## 2. Decisão

**Nível: declarativo.** É configuração (validation rules, custom permission, permission set) mais **um record-triggered Flow** de validação. Sem Apex, sem alteração de modelo de dados e sem mexer no approval process.

| Necessidade | Nível escolhido | Por que não o nível acima |
|---|---|---|
| Quem pode preencher os dois campos | **Configuração:** validation rule com `$Permission` e custom permission concedida por permission set | Já é o nível mais alto. A troca de `$Profile.Name` por `$Permission` resolve a causa raiz: a regra deixa de apontar para uma pessoa por meio do perfil dela. O recon mostrou que a dev e a produção têm perfil e FLS diferentes para o mesmo usuário, e uma regra por perfil se comporta diferente em cada org. |
| Mensagens que citam o antigo diretor | **Configuração:** desativar as 4 regras atuais | Já é o nível mais alto. |
| Campo obrigatório **no momento da aprovação** | **Declarativo:** record-triggered Flow after-save com Custom Error | Validation rule **não é avaliada** em field update de approval process, por isso hoje dá para aprovar com os campos vazios. A alternativa só de configuração seria entry criteria na etapa 2 com `ifCriteriaNotMet = RejectRecord`. Ela foi descartada: em vez de impedir a aprovação com uma mensagem, ela **rejeita a solicitação inteira**, dispara o alerta de rejeição ao owner e obriga a ressubmeter. Isso é pior para o usuário e gera ruído no processo. Também exigiria alterar um approval process ativo. |

**Spike obrigatório no início do build (S1):** provar na dev que um Flow after-save dispara na field update `Status_e_Etapa_Diretor_comercial` (aprovação da etapa 1) **e** que o Custom Error desfaz a aprovação com a mensagem visível para o aprovador. É comportamento de plataforma que eu não provei nesta org e não vou afirmar sem teste.
- **Se S1 passar:** segue este design.
- **Se S1 falhar:** a alternativa é um trigger Apex `before update` com `addError`, porque triggers voltam a disparar em field update de workflow/approval. Isso **desce para código**, então o build **para e volta ao arquiteto humano** para aceite explícito antes de seguir. A alternativa de configuração (entry criteria com rejeição automática) fica como opção caso o negócio prefira evitar código.

**Modelo de dados:** **não muda.** Nenhum objeto ou campo é criado, alterado ou removido. Não há escalonamento de arquitetura sênior por esse motivo.

## 3. Componentes

### Criar

| Tipo | API name | Conteúdo |
|---|---|---|
| CustomPermission | `ECT_Diretor_Financeiro` | Label "ECT - Diretor Financeiro". Descrição: autoriza preencher "Responsável pelo custo" e "Ressalvas do diretor financeiro" na Exceção Comercial p/ Atendimento Técnico. |
| PermissionSet | `PS_ECT_DiretorFinanceiro` | Objeto `Excecao_Comercial_p_Atendimento_Tecnico__c`: Read + Edit (sem View All/Modify All). FLS Read + Edit em `Responsavel_pelo_Custo__c` e `Ressalvas_do_Diretor_Financeiro__c`. Custom permission `ECT_Diretor_Financeiro`. Descrição preenchida. |
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.ECT_Campos_Diretor_Financeiro_Exclusivos` | Ver fórmula abaixo. Mensagem: *Os campos "Responsável pelo custo" e "Ressalvas do diretor financeiro" são de preenchimento exclusivo do Diretor Financeiro.* |
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.ECT_Campos_Diretor_Financeiro_Obrigatorios` | Ver fórmula abaixo. Mensagem: *Preencha "Responsável pelo custo" e "Ressalvas do diretor financeiro" — obrigatórios após a aprovação do Diretor Financeiro.* Mantém a proteção que existe hoje em `Checa_Responsavel_pelo_Custo_se_Soto` (parte por status) e a estende às Ressalvas. |
| Flow (record-triggered, after-save, Update) | `ECT_AfterSave_ValidaAprovacaoDiretorFinanceiro` | Objeto `Excecao_Comercial_p_Atendimento_Tecnico__c`. Entrada por fórmula (abaixo), que roda só quando o registro passa a atender a condição. Um único elemento Custom Error com a mensagem *Antes de aprovar, preencha "Responsável pelo custo" e "Ressalvas do diretor financeiro".* `triggerOrder = 10`. Descrição preenchida. |

Fórmula `ECT_Campos_Diretor_Financeiro_Exclusivos`:
```
AND(
  NOT($Permission.ECT_Diretor_Financeiro),
  OR(
    AND(ISNEW(),
        OR(NOT(ISPICKVAL(Responsavel_pelo_Custo__c, "")),
           NOT(ISBLANK(Ressalvas_do_Diretor_Financeiro__c)))),
    AND(NOT(ISNEW()),
        OR(ISCHANGED(Responsavel_pelo_Custo__c),
           ISCHANGED(Ressalvas_do_Diretor_Financeiro__c)))
  )
)
```

Fórmula `ECT_Campos_Diretor_Financeiro_Obrigatorios`:
```
AND(
  OR(ISPICKVAL(Status_de_Aprovacao__c, "Pendente - Diretor comercial"),
     ISPICKVAL(Status_de_Aprovacao__c, "Aprovado")),
  OR(ISPICKVAL(Responsavel_pelo_Custo__c, ""),
     ISBLANK(Ressalvas_do_Diretor_Financeiro__c))
)
```

Condição de entrada do Flow:
```
AND(
  ISCHANGED({!$Record.Status_de_Aprovacao__c}),
  TEXT({!$Record__Prior.Status_de_Aprovacao__c}) = "Pendente - Diretor financeiro",
  TEXT({!$Record.Status_de_Aprovacao__c}) = "Pendente - Diretor comercial",
  OR(ISBLANK(TEXT({!$Record.Responsavel_pelo_Custo__c})),
     ISBLANK({!$Record.Ressalvas_do_Diretor_Financeiro__c}))
)
```
A rejeição da etapa 1 (`Rejeitado`) e o recall não são bloqueados. Só a aprovação com os campos vazios é bloqueada.

### Alterar (desativar, sem excluir, para permitir rollback trivial)

| Tipo | API name | Ação |
|---|---|---|
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.Checa_Responsavel_pelo_Custo_se_Walmor` | `active = false` |
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.Checa_Ressalvas_se_Walmor` | `active = false` |
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.Checa_Ressalvas_se_Soto` | `active = false` |
| ValidationRule | `Excecao_Comercial_p_Atendimento_Tecnico__c.Checa_Responsavel_pelo_Custo_se_Soto` | `active = false` |

### Depreciar
As 4 regras acima ficam inativas. **Excluí-las** fica para uma limpeza posterior, depois da homologação em QA (seção 7).

### Não tocar
`Qualificacao_v2_3` (ativo) e as 4 versões inativas, o Flow `SLA_2`, as field updates e alerts do workflow do objeto, o layout, os email templates, os perfis e o FLS que os perfis já têm.

## 4. Conflito de automação e ordem de execução

**Risco de ordem de execução: o Flow ativo `SLA_2` também é after-save, Update, neste objeto, e entra exatamente na mesma transição (`Status_de_Aprovacao__c` → `Pendente - Diretor comercial`) que o novo Flow vai validar.** `SLA_2` não tem `triggerOrder` e só agenda email alerts (13 scheduled paths). Ele não altera o registro.
- Mitigação: o novo Flow recebe `triggerOrder = 10` para rodar antes. Mesmo que a ordem não se confirme, o Custom Error **desfaz a transação inteira**, inclusive os scheduled paths que `SLA_2` teria enfileirado, e por isso não sobra alerta de SLA para uma aprovação que não aconteceu. O roteiro de QA confere isso.
- Não há trigger Apex, classe dependente nem Process Builder neste objeto (`02-recon.md` §7). O acoplamento alto que o assessment aponta é em Oportunidade, não aqui.

**Limites e escala:** só validação, sem SOQL nem DML. O Flow é record-triggered e a plataforma bulkifica. As validation rules não consomem limite relevante. O volume do objeto na dev é 0 e o de produção é desconhecido, mas uma ECT é aprovada uma a uma pela UI, então não há cenário de carga.

## 5. Impacto em permissões

- **Novo:** `PS_ECT_DiretorFinanceiro`. **A atribuição é dado de usuário, não metadata.** Ela não vai no pacote de deploy e é passo manual em cada org:
  - dev e QA: atribuir ao usuário que representa o diretor financeiro, para os testes (feito no build e no QA);
  - produção: um humano do cliente atribui ao diretor financeiro atual, **depois** do deploy e na mesma janela. Sem isso, nem ele consegue preencher os campos.
- **Efeito das novas regras sobre quem já editava:**
  - perfil `Admin`, perfil `Administração` e permission set `DiretorComercial` deixam de conseguir **alterar** os dois campos se o usuário não tiver o novo PS. Hoje o perfil `Administração` já é impedido de preencher "Responsável pelo custo", e o `Admin`, de mudar as Ressalvas. A mudança é coerente com a regra de negócio, mas **retira poder de edição** de quem tem `DiretorComercial` (1 atribuição ativa na dev) sobre "Responsável pelo custo" (decisão D2).
  - O FLS dos perfis **não** é alterado. O controle de "quem preenche" passa a ser só a custom permission.
- **Admins** (`Administrador do sistema`) também ficam sujeitos à regra de exclusividade. Para corrigir dados (como `ECT-000080`), o admin recebe o PS temporariamente. Na dev, `Administrador do sistema` nem tem FLS de edição em Ressalvas.

## 6. Correção do "lançamento" `ECT-000080`: fora do build

O registro está em **produção**, e o agente não tem acesso a ela (guardrail #1). É correção de dado, a ser feita por um admin humano do cliente na produção, com os valores que estão no e-mail do card (Responsável pelo custo = `Cliente` e o texto de ressalvas indicado ali):
- **Depois** do deploy desta demanda: o admin recebe `PS_ECT_DiretorFinanceiro` temporariamente, preenche os dois campos e remove o PS. O registro está travado na etapa do diretor comercial, e só admin com Modify All consegue editá-lo.
- Antes, confirmar se o registro já não foi corrigido desde setembro.
- Esse passo entra em `06-entrega.md` como passo manual pós-deploy, com dono humano.

## 7. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **A dev não reproduz a produção** em perfil, atribuição e FLS do diretor financeiro (`02-recon.md` §6). Teste aprovado na dev pode não refletir a produção. | **Alta** | O design não depende de perfil, só de PS e custom permission, que vão iguais nas duas orgs. O QA deve rodar com um usuário de perfil equivalente ao de produção, a ser confirmado pelo humano. Passo manual de atribuição documentado. |
| R2 | O Flow after-save pode não disparar na field update da aprovação, ou o Custom Error pode não desfazer a aprovação. | **Média** | Spike S1 no início do build. Se falhar, o build para e volta ao arquiteto com a alternativa em Apex ou a de configuração. |
| R3 | **Ordem de execução com `SLA_2`** (mesmo objeto, after-save Update, mesma transição). | **Média** | `triggerOrder = 10` e rollback total pelo Custom Error. Caso de teste específico: aprovar com campos vazios não pode deixar alerta de SLA agendado. |
| R4 | Registros **já** em `Pendente - Diretor comercial` ou `Aprovado` com os campos vazios (como `ECT-000080`) passam a falhar em qualquer edição por causa de `ECT_Campos_Diretor_Financeiro_Obrigatorios`. Quantidade em produção desconhecida. | **Média** | Hoje a regra já existe para "Responsável pelo custo" e só se estende às Ressalvas. Admin corrige com PS temporário. Pedir ao humano a contagem de produção antes do deploy (D5). |
| R5 | Solicitação em produção parada em `Pendente - Diretor financeiro` com os campos vazios: depois do deploy, o diretor financeiro precisa preenchê-los antes de aprovar. | **Baixa** | É o comportamento desejado. Comunicar ao usuário no release. |
| R6 | Integração externa que escreva nesses campos passaria a ser bloqueada pela regra de exclusividade. | **Baixa** | Nenhuma dependência Apex foi encontrada. A seção de integrações do briefing do cliente está vazia (Q12 continua aberta). |
| R7 | 4 validation rules inativas a mais (o assessment já registra 261 inativas). | **Baixa** | Excluir em limpeza posterior à homologação. |

## 8. O que NÃO será feito nesta demanda

- Alterar `Qualificacao_v2_3` ou excluir as 4 versões inativas do approval process. A atualização do fluxo já está feita. Incluir `Ressalvas_do_Diretor_Financeiro__c` nos `approvalPageFields` seria útil, mas significa mexer em approval process ativo e fica como sugestão separada.
- Corrigir `ECT-000080` ou qualquer outro registro (dado de produção, passo humano).
- Alterar perfis, FLS de perfil ou o permission set `DiretorComercial`.
- Excluir as validation rules antigas (só desativar).
- Corrigir a diferença de maiúsculas e minúsculas na fórmula `Data_Hora_do_SLA_Solicitado__c` (observação lateral do recon, sem evidência de efeito).
- Trocar os aprovadores de usuário fixo por fila ou papel no approval process.
- Mexer nos Flows de SLA.

## 9. Critérios de aceite refinados (substituem os cenários BLOQUEADOS da análise)

```gherkin
Funcionalidade: ECT — campos do Diretor Financeiro

  Cenário: diretor financeiro preenche os campos durante a sua etapa
    Dado uma ECT em "Pendente - Diretor financeiro"
    E o usuário aprovador da etapa tem PS_ECT_DiretorFinanceiro
    Quando ele preenche "Responsável pelo custo" e "Ressalvas do diretor financeiro" e salva
    Então o registro é salvo sem erro
    E nenhuma mensagem cita pessoa pelo nome

  Cenário: aprovação da etapa financeira com campo vazio é bloqueada
    Dado uma ECT em "Pendente - Diretor financeiro" com ao menos um dos dois campos vazio
    Quando o diretor financeiro aprova
    Então a aprovação não acontece e aparece "Antes de aprovar, preencha ..."
    E o status continua "Pendente - Diretor financeiro"
    E nenhum alerta de SLA da etapa do diretor comercial fica agendado

  Cenário: aprovação da etapa financeira com campos preenchidos segue o fluxo
    Dado os dois campos preenchidos
    Quando o diretor financeiro aprova
    Então o status passa para "Pendente - Diretor comercial"

  Cenário: rejeição da etapa financeira não exige os campos
    Dado uma ECT em "Pendente - Diretor financeiro" com os campos vazios
    Quando o diretor financeiro rejeita
    Então o status passa para "Rejeitado"

  Cenário: usuário sem a permissão não altera os campos
    Dado um usuário com edição no objeto e sem PS_ECT_DiretorFinanceiro
    Quando altera um dos dois campos
    Então aparece "... de preenchimento exclusivo do Diretor Financeiro."

  Cenário: outros processos de aprovação não mudam
    Dado os approval processes de Excecao_Financeira__c
    Então nenhum deles é alterado pelo pacote desta demanda
```

## 10. Decisões pedidas ao arquiteto humano no gate

- **D1.** "Ressalvas do diretor financeiro" é sempre obrigatório antes da aprovação, mesmo sem ressalva a fazer? O design assume **sim**, como diz o anexo ("os campos precisam ser preenchidos").
- **D2.** "Responsável pelo custo" passa a ser **exclusivo** do diretor financeiro, o que retira a edição de quem tem o PS `DiretorComercial` e do perfil `Admin`? O design assume **sim**.
- **D3.** Além do diretor financeiro, alguém mais recebe `PS_ECT_DiretorFinanceiro` em produção (substituto em férias, admin de suporte)?
- **D4.** Confirmar que a produção está com `Qualificacao_v2_3` ativo, igual à dev. O agente não consegue ver a produção.
- **D5.** Contagem, em produção, de ECTs em `Pendente - Diretor comercial` ou `Aprovado` com algum dos dois campos vazio (para dimensionar R4). Só o número.

## 11. Estimativa

**Estimativa de esforço:** 6–12 h

O que mudou em relação à análise (10–20 h) e por quê:
- **Escopo menor.** A "atualização do fluxo de aprovação" já está feita na org (`Qualificacao_v2_3` ativo, sem o antigo aprovador) e não entra no build. O "lançamento" é correção de dado em produção, feita por um humano, e não exige metadata.
- **Nível mais baixo.** A solução é configuração mais um Flow de um único elemento. Não há Apex nem mudança de modelo de dados, e o objeto tem pouca automação (um Flow ativo, nenhum trigger).
- **O que segura o limite superior:** o spike S1 (aprovação mais Flow), testar os dois caminhos de aprovação com usuários de permissões diferentes em dev e QA, e a divergência de permissões entre dev e produção (R1). Se S1 falhar e o caminho virar Apex com classe de teste, a faixa volta para perto da original e o build retorna ao gate.

Distribuição aproximada: spike S1 de 1 a 2 h; custom permission, PS e validation rules de 1 a 2 h; Flow de 1 a 2 h; testes em dev e QA com dois perfis de 2 a 4 h; release, passos manuais e documentação de 1 a 2 h.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
