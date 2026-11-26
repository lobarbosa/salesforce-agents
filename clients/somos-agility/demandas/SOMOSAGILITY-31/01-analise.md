# SOMOSAGILITY-31 — Análise (ba-discovery)

- **Cliente:** somos-agility
- **Tipo:** Sustentação/melhoria de metadata (alteração de tipo de 9 campos existentes)
- **Org consultada:** `sbx-somos-agility-dev` (conectada, `sf org list`: Sandbox, Connected, alias `sbx-somos-agility-dev`). Produção não tocada.
- **Fontes:** `demanda.md`, `comentarios-do-card.md` (resposta de objeto em 2026-11-26 12:15), `00-preflight.md`, `assessment.md` (trechos), histórico RAG (SOMOSAGILITY-26).
- **Status:** rascunho para validação humana. Nada aqui vira design sem as perguntas do topo respondidas.

> **Divergência de etapa:** o `00-preflight.md` registra a etapa como `backlog`. A etapa pedida para esta sessão é `analise`. Esta análise segue `analise`; o preflight não traz bloqueio nem componente em conflito, então a divergência não muda o conteúdo.

---

## Perguntas de negócio em aberto (fechar antes do design)

A demanda não pode ir ao design sem as respostas marcadas como **bloqueia**.

**P1 (bloqueia). A demanda diz "criar", mas os 9 campos já existem na dev.** Consulta de metadata na `sbx-somos-agility-dev` (`FieldDefinition` do objeto `Propostas_de_Solucao__c`): os 9 campos existem como **Área de texto (255)**, com os rótulos Cotação, Proposta Acabada e Informações Técnicas Complementares (1, 2 e 3). O pedido é alterar o tipo para Área de texto longo (32768) ou criar campos novos com outro nome?
- (a) Alterar o tipo dos 9 campos existentes (255 → longo 32768), mantendo API name e dados.
- (b) Criar 9 campos novos e migrar valores, deixando os atuais.
- (c) Outra coisa: descrever.

**P2 (bloqueia). Os 9 campos existem em QA e em produção?** A consulta foi feita só na dev. Se em QA ou produção o tipo é outro, ou o campo não existe, a faixa e a estratégia mudam. Resposta esperada: confirmação do recon nas sandboxes de QA (sem produção, guardrail 1) e um relato do cliente sobre produção.

**P3 (bloqueia). Quem lê esses 9 campos hoje?** Templates de proposta ou cotação (Conga Composer, SDocs), relatórios, integrações (SnapERP), Flows, fórmulas e validation rules. Se algo lê o campo como texto curto, ou se o cliente depende de truncamento, a mudança de tipo precisa ser planejada com esses consumidores. Opções: lista de consumidores conhecidos; "não sabemos" (vira item do recon).

**P4 (bloqueia). Relação com SOMOSAGILITY-26.** A 26 entregou `PFP_1/2/3_Texto__c` em 32768 nos objetos BluePrint, PSL e FVP, e registrou um pedido novo (26/11, 11:56) com estes mesmos nomes de campo, marcado como "entra nesta demanda ou vira demanda nova". Esta demanda (31) é a demanda nova? Propostas_de_Solucao__c é um dos objetos já tratados na 26 ou é outro? Confirmar que nenhum dos 9 campos está em escopo da 26.

**P5 (bloqueia). Quais perfis veem e editam os 9 campos?** Hoje a FLS não foi consultada. Opções: "os mesmos perfis de hoje" (premissa), lista explícita de perfis que leem e editam, lista dos que não devem ver.

**P6. Tamanho.** O pedido fixa 32768. Confirmar que é o máximo que o negócio precisa e que nenhum texto atual é maior que 255 de forma que exija tratamento especial. Opções: aceitar 32768 (pedido); outro valor, com a justificativa.

**P7. Campos vazios.** Os 9 campos são obrigatórios hoje? Se não são, vazio continua vazio. Confirmar com opção sim/não.

**P8. Registros já gravados.** A alteração de tipo preserva os valores existentes (até 255 caracteres). Confirmar que não há carga, correção ou backfill nesta demanda. Opções: "não há carga"; "há carga de X registros" (vira esforço).

---

## 1. Contexto de negócio

O objeto `Propostas_de_Solucao__c` tem nove campos de texto, em três grupos (sufixo vazio, `_2` e `_3`), para cotação, proposta acabada e informações técnicas complementares. Hoje esses campos são Área de texto de 255 caracteres. O comentário do card (2026-11-26, 12:15) informa que o objeto é `Propostas_de_Solucao__c`. A demanda pede que o conteúdo caiba em texto longo de 32.768 caracteres, o que é o mesmo tamanho já adotado na SOMOSAGILITY-26 para `PFP_*_Texto__c`.

Histórico: o pedido apareceu no card da SOMOSAGILITY-26 (26/11, 11:56) como "fora do escopo entregue", com a nota de que os três nomes coincidem com campos da conversão "Cenário 1" que o design da 26 (seção 9) excluiu. A 26 registrou a decisão como pendente: entra na 26 ou vira demanda nova. [demandas/SOMOSAGILITY-26/06-entrega-complemento.md]. Esta demanda (31) foi aberta em 26/11, o que sugere a segunda opção; isso é premissa, ver P4.

## 2. Objetivo

Permitir que o time registre nesses nove campos um texto de até 32.768 caracteres, sem perder o que já está gravado e sem alterar outro campo, objeto ou automação.

## 3. Regra de negócio

- RN-01. Os nove campos passam a aceitar até 32.768 caracteres. (Regra de tipo; a regra de negócio por trás do texto não foi informada.)
- RN-02. Nenhum outro campo, objeto, layout de outro objeto ou automação muda por causa desta demanda.
- RN-03. Valores já gravados nos campos continuam os mesmos após a alteração (premissa a confirmar em P8).

## 4. Critérios de aceite (Gherkin)

Cada critério traz quem, estado de partida, ação e resultado observável. Os valores pendentes de P1 a P8 estão entre `<...>`.

```gherkin
Funcionalidade: Campos de texto longo em Propostas_de_Solucao__c

  Cenário: CA-01 tipo dos nove campos na dev
    Dado que, na sandbox de dev, os campos Cotacao__c, Proposta_Acabada__c, Informa_es_T_cnicas_Complementares__c e os sufixos _2 e _3 são Área de texto (255)
    Quando o build é aplicado na sandbox de dev
    Então a consulta FieldDefinition dos nove campos mostra Área de texto longo (32768)

  Cenário: CA-02 valor já gravado preservado
    Dado um registro de teste de Propostas_de_Solucao__c com Cotacao__c preenchido com texto de 255 caracteres, criado antes da alteração
    Quando o campo é alterado para texto longo
    Então o valor lido do campo é idêntico ao gravado antes (mesmo texto, mesmo tamanho)

  Cenário: CA-03 aceita o tamanho alvo
    Dado um usuário com o perfil <perfil que edita, P5>
    Quando grava 32.768 caracteres em Proposta_Acabada_2__c de um registro de teste
    Então o registro é salvo e a leitura devolve 32.768 caracteres

  Cenário: CA-04 recusa acima do tamanho alvo (caso negativo)
    Dado o mesmo usuário e o mesmo registro de teste
    Quando tenta gravar 32.769 caracteres em Informa_es_T_cnicas_Complementares_3__c
    Então o sistema recusa com erro de valor grande demais (STRING_TOO_LONG) e nada é gravado no campo

  Cenário: CA-05 campo vazio (caso de borda)
    Dado um registro de teste com Cotacao__c em branco
    Quando o registro é salvo
    Então o salvamento segue o comportamento de hoje, <vazio aceito | obrigatório, conforme P7>

  Cenário: CA-06 perfil sem permissão (caso negativo)
    Dado um usuário do perfil <perfil sem acesso ao campo, P5>
    Quando abre um registro de teste de Propostas_de_Solucao__c
    Então o campo <não aparece | aparece só leitura>, conforme P5

  Cenário: CA-07 nenhuma outra mudança (caso negativo de escopo)
    Dado o pacote de metadata da demanda
    Quando é comparado com a sandbox de dev antes da alteração
    Então nenhum campo, objeto, layout, Flow ou validation rule fora dos nove campos aparece como alterado

  Cenário: CA-08 layouts mantidos
    Dado os layouts de Propostas_de_Solucao__c que hoje exibem cada um dos nove campos
    Quando a alteração é aplicada
    Então cada campo continua no mesmo layout, na mesma posição, com a mesma visibilidade

  Cenário: CA-09 dependências sem erro
    Dado as validation rules ativas e os Flows que referenciam os nove campos (lista do recon, P3)
    Quando a alteração é implantada na sandbox de dev
    Então o deploy não reporta erro de dependência e cada regra ou Flow continua ativo

  Cenário: CA-10 consumidor externo (só quando P3 listar consumidor)
    Dado o template ou relatório <nome, P3> que lê um dos nove campos
    Quando é gerado com um registro de teste com texto de mais de 255 caracteres
    Então o documento ou relatório mostra o texto completo, <sem truncamento | conforme a regra de P3>
```

## 5. O que a demanda não diz (e precisa ser respondido)

- Se "criar" significa alterar o tipo dos existentes ou criar campos novos (P1).
- Se os campos existem em QA e produção com o mesmo tipo (P2).
- Quem lê os campos e o que depende do tipo atual (P3).
- Perfis que veem e editam (P5), valor obrigatório (P7), carga e registros já gravados (P8).
- Se o pedido tem relação com a SOMOSAGILITY-26 (P4).
- A regra de negócio do texto: o que vai nesses campos, quem preenche, em que etapa. A demanda só fala de tipo e tamanho; não há regra de preenchimento a testar.

## 6. O que o cliente confere na homologação

Não se prova em sandbox; vai para `05-roteiro-cliente.md` como conferência do cliente:
- Como o texto longo aparece na tela do cliente (altura da caixa, quebra de linha) e se atende ao uso real.
- Se o conteúdo gerado em documentos e relatórios usados pelo cliente (P3) está como ele espera.
- Se o texto de 32.768 caracteres de fato é o que o negócio precisa (P6).

## 7. Riscos do assessment que tocam o pedido

- O assessment (foto do onboarding) não cita `Propostas_de_Solucao__c` (0 ocorrências em `assessment.md`). Nenhum risco específico do objeto foi registrado lá; por isso não há mais risco a citar além dos gerais abaixo.
- **Validation rules do objeto (confirmado na dev):** 16 no total, 13 ativas (entre elas `PslSemOrcamentista`, `M01_Proibido_PFP_sem_PSL`, `M02_Proibido_PSL_sem_PFP`, `M04_PSL_unica`, `M05_Valida_Uma_PFP`, `CNPJ_obrigatorio_se_PFP_fechada` e variantes). Não li as fórmulas, então não sei se alguma referencia os nove campos. Vai para o recon (P3, CA-09).
- **Cobertura Apex da org em 40%, cobertura mínima de 85% do squad:** se o recon achar Apex que lê ou grava esses campos, a alteração passa a exigir teste de classe, e a faixa sobe. Nesta análise não se assume Apex no escopo.
- **Automações concorrentes:** o assessment fala de 31 automações em Oportunidade, não de Propostas. Não confirmado para este objeto; o recon deve listar Flows e triggers que tocam `Propostas_de_Solucao__c`.
- **Histórico da SOMOSAGILITY-26:** a alteração de campos de texto em produção já deu problema de rollback (rollback de metadata não desfaz dado gravado nos campos novos). Esta demanda deve ter o mesmo cuidado no `06-entrega.md`. [demandas/SOMOSAGILITY-26/06-entrega-complemento.md]

## 8. Complexidade

**P** se P1 for (a) e P3 não listar consumidor. Trabalho de metadata simples em nove campos de um objeto. **M** se P3 listar consumidores ou se houver Apex que lê os campos.

## 9. Premissas a validar (pendentes)

- **Premissa pendente (P1):** a ação é alterar o tipo dos nove campos existentes, não criar campos novos.
- **Premissa pendente (P2):** os nove campos existem e têm o mesmo tipo em QA. Não confirmado em QA nem em produção.
- **Premissa pendente (P8):** não há carga nem correção de registros existentes.
- **Premissa pendente (P5):** a FLS dos nove campos segue os perfis de hoje, sem mudança de acesso.
- **Premissa pendente (P7):** os campos não são obrigatórios hoje.
- **Premissa pendente (P4):** os nove campos não são escopo da SOMOSAGILITY-26; a 31 é a demanda nova que a 26 registrou.

---

**Estimativa de esforço:** 3–6 h
Esforço humano: revisar o tipo de cada campo na dev, conferir layouts e FLS, rodar a verificação de dependências, deploy na QA pelo passo da esteira, roteiro de teste e homologação com uma pessoa do cliente.
- Vale se P1 for (a), se P3 não listar consumidor fora do Salesforce e se não houver Apex nem carga de dados.
- Sobe para o máximo se o recon achar validation rule ou Flow que referencia os campos e precisa de ajuste.
- Sobe além de 6 h se P3 listar Conga, SDocs ou SnapERP lendo os campos, ou se P1 virar a opção (b): aí o design precisa de migração de valores.
- Sobe se P2 mostrar tipo diferente em QA (o build passa a alinhar as sandboxes).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto. Não passar ao design sem respostas a P1, P2, P3, P4 e P5.
