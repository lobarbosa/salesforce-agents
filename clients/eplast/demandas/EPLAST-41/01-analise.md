# EPLAST-41 · Apoio à criação de textos comerciais e de relacionamento

**Org desta etapa:** `sbx-eplast-dev` (sandbox `eplast--qa`, conferido com `sf org list` em 2026-11-15).
**Origem:** Solicitação de Proposta Konecta, item "apoio na criação de textos comerciais e conteúdos de relacionamento".
**Onda:** 4 · Marketing, não contratada em `contrato.md`. Pela regra 1 da conta, o escopo não bloqueia; a demanda segue análise, design e build. Não é pendência.

---

## 1. Contexto de negócio

A Eplast quer que o vendedor e o time de relacionamento peçam a uma IA um rascunho de texto a partir de um registro do CRM (conta ou oportunidade), revise e use. O texto é apoio: quem decide o conteúdo e quem envia é o humano, e o envio de qualquer mensagem sai pelo Marketing Cloud (regra 2 da conta).

O pedido tem duas partes:

- **Textos comerciais.** Já coberto em grande parte pela EPLAST-30 (Onda 3, Comercial): proposta, follow-up e argumentos. Ver seção 3.
- **Conteúdos de relacionamento.** Mensagens de relacionamento com o cliente, sem tipo definido na demanda. Este é o trecho novo.

## 2. Objetivo

Reduzir o tempo de escrita de textos comerciais e de relacionamento, mantendo o CRM como origem dos dados e o humano como revisor. Sucesso = o vendedor gera um rascunho a partir de uma conta ou oportunidade, revisa e o salva no registro, sem que o CRM envie nada.

## 3. Escopo

**Dentro:**
- Rascunho de texto de relacionamento gerado a partir de uma Account ou Opportunity, sob demanda do usuário.
- Reaproveitamento dos três rascunhos comerciais já previstos na EPLAST-30 (proposta, follow-up, argumentos), sem recriá-los.
- Gravação opcional do texto aprovado pelo usuário como Task no registro de origem.

**Fora:**
- Envio de e-mail ou mensagem por qualquer ferramenta do CRM (Flow com e-mail alert, Apex, `EmailMessage`, `emailSimple`). Quem envia é o Marketing Cloud.
- Qualquer configuração, público, jornada ou envio no Marketing Cloud, e qualquer alteração no conector `et4ae5`.
- Agente novo, e alteração do `SFAgent2` nesta versão.
- Geração de PDF de proposta.
- Segmentação, campanha, reativação e automação de envio (demanda EPLAST-42).
- Pedido (Order) como origem do texto.

## 4. Confirmações na org (dev, 2026-11-15)

Só metadata e contagens; nenhum registro foi lido.

| Componente | Confirmado | Decisão | Por quê |
|---|---|---|---|
| Agente `SFAgent2` (Bot) | Sim, um Bot com esse nome | **Não cria agente novo. Não altera nesta versão.** | Regra 3. Rascunho a partir de registro não é conversa; a EPLAST-30 (PA-02) já decidiu isso |
| GenAiPromptTemplate `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade` | Sim, os três existem na dev | **Reaproveita**, não recria | Regra 3. Ver conflito abaixo |
| Flow `Opportunity_Screen_RascunhoComercial` | Sim | **Reaproveita como base** para a tela de rascunho; relacionamento estende o mesmo padrão | Regra 3 |
| Custom Permission `IA_Rascunho_Comercial` | Sim | **Reaproveita** para controlar quem vê as telas de rascunho | Regra 3; mesma permissão já prevista na EPLAST-30 |
| Task (`Subject`, `Description` textarea 32.000, `WhatId`, `WhoId`, `TaskSubtype`) | Sim | **Reaproveita** para guardar o texto aprovado | Padrão da EPLAST-29 (P3): texto em `Description` com `TaskSubtype = Task`, sem criar `EmailMessage` |
| Contact `HasOptedOutOfEmail` (padrão) e `et4ae5__HasOptedOutOfMobile__c` | Sim | **Reaproveita** como referência de consentimento, lido pelo Marketing Cloud | Campos padrão e do conector |
| Pacote `et4ae5` (Marketing Cloud Connect 264.1) | Instalado | **Não alterado** | Regra 2 |
| Triggers custom `AccountTrigger`, `OpportunityTrigger`, `OrderTrigger` | Sim, os três | **Não alterados.** A demanda não grava em Account nem Opportunity | Achado 1 do assessment (seção 6) |
| Flow `Task_Agente_CriarTarefa`, `Account_Agente_ProximaAcao` | Sim | **Não alterados.** Verificar se algum Flow de Task dispara na gravação | EPLAST-29 usa esses componentes |

**Conflito a resolver no design:** a `03-design.md` da EPLAST-30 registra que os três templates "só existem no `force-app/`" e precisam ser criados. Na dev eles **já existem** (`GenAiPromptTemplate` com esses nomes, conferido agora). A EPLAST-30 está em `backlog`, então esses templates foram criados fora da esteira ou em rodada anterior. O arquiteto deve confirmar a origem e o estado do conteúdo antes de reaproveitar. Não li o corpo dos templates.

## 5. Regra de negócio

- RN-1. O rascunho é gerado sob demanda, a partir de um registro de Account ou Opportunity escolhido pelo usuário.
- RN-2. O rascunho aparece na tela, copiável. Nada é gravado no CRM até o usuário clicar em salvar.
- RN-3. Ao salvar, o texto vai para uma Task vinculada ao registro de origem (`WhatId`). Nenhum `EmailMessage` é criado.
- RN-4. O CRM não envia e não agenda envio. Envio é responsabilidade do Marketing Cloud, feito por quem opera o MC.
- RN-5. O prompt usa só dados comerciais do registro (nome da conta, segmento, produtos, histórico comercial agregado). Não envia e-mail, telefone, CPF nem nome de contato ao modelo.
- RN-6. Textos comerciais seguem as regras de conteúdo da EPLAST-30 (PA-03 e PA-04 daquela análise): fonte de cada argumento, sem recomendação de produto.

## 6. Riscos do assessment que tocam a demanda

- **Achado 1 (automação concorrente em Account, Opportunity e Order).** Tocado de forma indireta. A demanda grava Task vinculada a Account ou Opportunity, sem atualizar o registro pai. O assessment pede mapear a ordem de execução antes de qualquer demanda nesses objetos. Não há trigger custom em Task (confirmado). O arquiteto deve checar se o Flow de Task ou algum Flow `RecordAfterSave` em Task alcança o pai. Se alcançar, o desenho muda.
- **Achado 2 (cobertura Apex de ~10%).** Solução prevista é declarativa (Prompt Template, Screen Flow, Task). Se surgir Apex, a classe precisa de `<Classe>Test` com cobertura mínima de 85%.
- **Achado 3 (validation rules de Order).** Não afeta, porque Order está fora do escopo.
- **Achado 4 (campos custom sem descrição).** Se algum campo novo for criado, precisa de descrição.
- **Achado 6 (alias de dev com nome "qa").** Resolvido pela regra 5 da conta. Não é risco.

## 7. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca comunicação e relacionamento. Ela **não cria público, segmento, campanha nem dado para o Marketing Cloud**.

- **Dados que o MC lê:** nenhum dado novo é criado para o MC. O MC continua lendo o que já lê pelo conector. O texto salvo em `Task.Description` não é fonte de envio do MC nesta demanda; quem opera o MC copia o texto aprovado para o envio.
- **Público ou segmento no CRM:** não é criado. O registro de origem é escolhido pelo vendedor. Se a EPLAST-42 precisar de um segmento, a preparação é tratada lá.
- **O que o MC devolve e onde é gravado:** nada. Esta demanda não recebe dados de entrega, abertura ou clique.
- **Consentimento e opt-out:** o rascunho não verifica opt-out. Quem respeita `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` é o MC, no envio. O CRM não bloqueia a geração por opt-out.
- **Para quem opera o Marketing Cloud:** montar o envio com o texto aprovado, respeitar opt-out e registrar o envio no MC. Nada disso é feito pelo build.

## 8. Critérios de aceite

```gherkin
Funcionalidade: Rascunho de texto de relacionamento e comercial

  Cenário: Gerar rascunho a partir de uma conta
    Dado um usuário com a permissão IA_Rascunho_Comercial
    E uma Account com dados comerciais preenchidos
    Quando ele escolhe o tipo de relacionamento e pede o rascunho
    Então o texto aparece na tela em até 30 segundos
    E o texto pode ser copiado
    E nenhum registro é criado ou alterado enquanto ele não clicar em salvar

  Cenário: Salvar o texto aprovado como Task
    Dado um rascunho gerado para uma Account
    Quando o usuário clica em salvar
    Então existe uma Task com WhatId igual à Account
    E TaskSubtype igual a "Task"
    E Description igual ao texto salvo
    E nenhum EmailMessage é criado

  Cenário: Nenhum envio pelo CRM
    Dado um rascunho salvo ou não salvo
    Quando o fluxo de geração e salvamento termina
    Então nenhum EmailMessage, e-mail alert ou envio agendado é criado no CRM
    E nenhum registro de Marketing Cloud é criado ou alterado

  Cenário: Prompt sem dado pessoal de contato
    Dado a configuração dos templates de relacionamento
    Quando os parâmetros de entrada são listados
    Então não há entrada de e-mail, telefone, CPF ou nome de contato
    E há entrada de nome da conta e dados comerciais agregados

  Cenário: Textos comerciais reaproveitados
    Dado que os templates Rascunho_Proposta_Comercial, Rascunho_Followup_Comercial e Argumentos_Comerciais_Oportunidade existem na dev
    Quando a entrega é feita
    Então nenhum template com nome igual é criado novamente
    E a tela de rascunho comercial usa os templates existentes ou a versão nova deles, sem duplicata

  Cenário: Falha do modelo
    Dado que a geração do rascunho falha
    Quando o usuário solicita o texto
    Então a tela mostra mensagem de erro sem texto parcial
    E nenhuma Task é criada

  Cenário: Conta sem oportunidade
    Dado uma Account sem Opportunity aberta
    Quando o usuário pede um rascunho comercial que depende de oportunidade
    Então a tela avisa que não há oportunidade e não gera texto inventado

  Cenário: Agente e assistente intactos
    Dado o agente SFAgent2 na dev
    Quando a entrega é concluída
    Então existe apenas um Bot SFAgent2
    E as ações ConsultarPedidos, AgregacaoPedidos e IdentificarConta não foram alteradas

  Cenário: Marketing Cloud intacto
    Dado o pacote et4ae5 instalado
    Quando a entrega é concluída
    Então nenhum componente de et4ae5 foi alterado pela entrega
```

## 9. Premissas assumidas (validar na homologação)

Todas resolvidas por evidência da org ou por padrão do squad (regra 4 da conta). Nenhuma está pendente.

- [x] **PA-41-1 · O que é "textos comerciais".**
  **Pergunta:** o pedido inclui textos além dos três da EPLAST-30?
  **Decisão:** "textos comerciais" são os três rascunhos da EPLAST-30 (proposta, follow-up, argumentos). Esta demanda não cria um quarto tipo.
  **Evidência:** os três templates com esses nomes existem na dev (conferido em 2026-11-15); a EPLAST-30 (PA-03) define os mesmos três tipos.
  **Como mudar:** se o cliente quiser outro tipo comercial, abre-se demanda nova.

- [x] **PA-41-2 · O que é "conteúdo de relacionamento".**
  **Pergunta:** qual tipo de mensagem de relacionamento?
  **Decisão:** o usuário escolhe o tipo e o objetivo em texto livre (ex.: agradecimento, retorno de contato, acompanhamento pós-venda). O template recebe esse texto como entrada. Não há lista fixa de tipos nesta versão.
  **Evidência:** padrão de entrada livre já usado no rascunho comercial da EPLAST-30; picklist fixa exigiria decisão de conteúdo que a demanda não traz.
  **Como mudar:** se o cliente quiser tipos fixos, vira picklist no registro de tipo e a instrução do template se ajusta. Não exige mudança estrutural.

- [x] **PA-41-3 · Objetos de origem.**
  **Pergunta:** o rascunho sai de Account, Contact, Opportunity ou Order?
  **Decisão:** Account e Opportunity. Order fica fora. Contact fica fora como origem; o nome do contato não entra no prompt (RN-5).
  **Evidência:** mesma decisão da EPLAST-29 (PD-1): Account e Opportunity são onde o vendedor trabalha; Order tem as validation rules e a concorrência de automação do assessment (achados 1 e 3).
  **Como mudar:** incluir Contact ou Order é demanda com análise de risco própria.

- [x] **PA-41-4 · Onde o texto fica.**
  **Pergunta:** o texto aprovado é gravado no CRM? Como?
  **Decisão:** sim, como Task vinculada ao registro de origem, com `TaskSubtype = Task` e texto em `Description`. Sem `EmailMessage`. Gravação só depois de clique em salvar.
  **Evidência:** EPLAST-29 (P3) decidiu o mesmo caminho para rascunho de e-mail e mensagem; `EmailMessage` aproximaria a demanda do envio, o que a regra 2 proíbe.
  **Como mudar:** se o cliente quiser o texto em outro objeto ou em campo, troca-se o destino sem mudar o restante.

- [x] **PA-41-5 · Dado pessoal no prompt.**
  **Pergunta:** o modelo pode receber dado de contato?
  **Decisão:** não. O prompt recebe só dados comerciais do registro (RN-5).
  **Evidência:** LGPD (guardrail 2 do squad) e minimização de dado como padrão. Nenhum e-mail, telefone ou CPF é necessário para escrever uma mensagem de relacionamento genérica.
  **Como mudar:** se o cliente aceitar e autorizar o uso de nome de contato, vira entrada adicional, com aprovação registrada.

- [x] **PA-41-6 · Permissão de acesso.**
  **Pergunta:** quem pode gerar o rascunho de relacionamento?
  **Decisão:** reaproveita a custom permission `IA_Rascunho_Comercial`, mesma da EPLAST-30.
  **Evidência:** a permissão existe na dev e já controla as telas de rascunho.
  **Como mudar:** criar permissão própria se o time de relacionamento for distinto do comercial; é uma linha no permission set.

- [x] **PA-41-7 · Consentimento.**
  **Pergunta:** o CRM bloqueia rascunho para contato com opt-out?
  **Decisão:** não bloqueia a geração. O opt-out é respeitado pelo Marketing Cloud no envio (seção 7).
  **Evidência:** rascunho não é envio, e o consentimento é gerido pelos campos do conector que o MC já usa (`et4ae5__HasOptedOutOfMobile__c`) e pelo padrão `HasOptedOutOfEmail`.
  **Como mudar:** se o cliente quiser um aviso na tela, é uma verificação agregada no Flow, sem dado pessoal na tela.

- [x] **PA-41-8 · Uso de IA e licença.**
  **Pergunta:** a geração generativa está habilitada na org?
  **Decisão:** assume-se que sim, porque os GenAiPromptTemplates existem na dev.
  **Evidência:** existência dos templates. Não foi confirmado o status da licença ou do Trust Layer. O recon confirma.
  **Como mudar:** se não estiver habilitado, o build fica bloqueado até a ativação, e isso é passo do cliente.

- [x] **PA-41-9 · Dependência da EPLAST-30.**
  **Pergunta:** a EPLAST-41 é construída antes ou junto com a EPLAST-30?
  **Decisão:** o arquiteto decide no design, com base no estado real dos templates (conflito da seção 4). Esta análise não bloqueia por isso.
  **Evidência:** EPLAST-30 em `backlog`; templates já existentes na dev.
  **Como mudar:** a ordem muda o esforço (seção 10), não o escopo.

## 10. Complexidade e esforço

**Complexidade:** M. Componentes declarativos (Prompt Template, Screen Flow, Task), com reaproveitamento de três templates e de um Screen Flow existentes, mas com regra de consentimento e fronteira com o Marketing Cloud a documentar e testar.

**Estimativa de esforço:** 16–28 h

Premissas que mais pesam na faixa:
- Se a EPLAST-30 for construída antes, a faixa cai para o baixo da faixa (reaproveita templates e tela). Se for construída junto, sobe para o alto.
- Escrever e testar o conteúdo dos templates de relacionamento (instruções, tipos livres, revisão de tom) é a maior parte do esforço humano.
- Homologação com o cliente e roteiro em linguagem de usuário estão incluídos.
- Não inclui configuração no Marketing Cloud, que é de quem opera o MC.
- Faixa larga porque a demanda é vaga e o arquiteto ainda não confirmou o estado dos templates existentes.

## 11. O que a demanda não diz

Cada item abaixo foi resolvido por premissa (seção 9), salvo onde indicado.

1. Quais tipos de mensagem de relacionamento. Resolvido em PA-41-2.
2. Se "textos comerciais" incluem além dos três da EPLAST-30. Resolvido em PA-41-1.
3. De qual objeto o texto sai. Resolvido em PA-41-3.
4. Onde o texto aprovado fica. Resolvido em PA-41-4.
5. Se o modelo recebe dado de contato. Resolvido em PA-41-5.
6. Quem tem acesso. Resolvido em PA-41-6.
7. Como o consentimento entra. Resolvido em PA-41-7.
8. Se a IA generativa está licenciada e ativa. Resolvido por evidência parcial em PA-41-8; confirmação pelo recon.
9. Relação com a EPLAST-29 (assistente que também rascunha e-mail e mensagem por linguagem natural). Esta demanda é a versão fora do chat, em tela de registro, com a mesma gravação em Task. O arquiteto deve confirmar que não há duplicidade de componente entre as duas.
10. Se algum texto é enviado automaticamente. Não é: a demanda descarta envio (RN-4).

**Perguntas abertas:** nenhuma. Não há pergunta de caso 3 (que bloqueie por errar ser caro e não haver evidência ou padrão).

## 12. Próximo passo

O arquiteto recebe esta análise após a aprovação humana. No design, ele precisa:
- confirmar a origem e o estado dos três GenAiPromptTemplates já existentes na dev (conflito da seção 4);
- decidir a ordem em relação à EPLAST-30 (PA-41-9);
- checar se algum Flow de Task alcança Account ou Opportunity (achado 1);
- confirmar o status da geração generativa na org (PA-41-8).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
