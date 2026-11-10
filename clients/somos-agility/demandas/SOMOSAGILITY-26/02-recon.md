# Recon da Org — SOMOSAGILITY-26

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v68.0, `IsSandbox: true`
confirmado via `SELECT IsSandbox FROM Organization`).
**Data da coleta:** 2026-11-10.
**Cobertura:** apenas metadata (describe, Tooling API, retrieve de componentes para `tmp_recon/`,
fora de `force-app/`) e contagens agregadas (`COUNT()`) — nenhuma consulta trouxe dado de
registro real (guardrail #2).

## 1. "Cenário SF" é a Propostas de Solução (PSL) — não existe objeto com esse nome

Não há objeto, aba ou app chamado "Cenário SF" na org (`sf sobject list`, busca por
`CustomObject.DeveloperName` via Tooling API — nenhum resultado). Os cinco campos citados na
demanda existem, porém, todos juntos, lado a lado, num único layout:

**Objeto:** `Propostas_de_Solucao__c` (label "Propostas de Solução", apelidado de "PSL" em
nomes de regra/classe internos).
**Layout:** `Propostas_de_Solucao__c-Retorno do Cliente` — é a única página da org em que os
cinco campos da demanda aparecem juntos, dentro de uma seção repetida três vezes (**Cenário
1**, **Cenário 2**, **Cenário 3** — campo `Cenario1__c`/`Cenario2__c`/`Cenario3__c` abre cada
bloco). "Cenário SF" é, com alta confiança, o nome que o negócio dá a essa seção/página — "SF"
= Salesforce, para diferenciar de "cenário" em outro sistema (SnapERP, Conga).

| Campo da demanda | API Name (bloco "Cenário 1") | Tipo | `length` (máx. caracteres) |
|---|---|---|---|
| PFP 1 (UNC Path) | `PFP_1__c` | `TextArea` | **255** |
| Cotação | `Cotacao__c` | `TextArea` | **255** |
| Proposta acabada | `Proposta_Acabada__c` | `TextArea` | **255** |
| Informações técnicas complementares | `Informa_es_T_cnicas_Complementares__c` | `TextArea` | **255** |
| Aceite do cliente | `Aceite_do_cliente__c` | `TextArea` | **255** |

Confirmado por dois caminhos: `sf sobject describe --sobject Propostas_de_Solucao__c` (4 dos 5
campos) e o XML de metadata retornado por `sf project retrieve start --metadata
CustomObject:Propostas_de_Solucao__c` (os 5, inclusive o que o describe não mostrou — ver
achado 4). Nenhum dos cinco tem `<length>` explícito no XML porque **o tipo `TextArea` da
Salesforce não tem campo de tamanho configurável: 255 é o teto fixo do tipo**, não uma opção
baixa escolhida por alguém.

**Isso muda a opção A da análise.** A hipótese "aumentar o comprimento do campo Text atual"
(opção A) não existe como caminho — não há "tamanho" para aumentar dentro do tipo `TextArea`
(nem dentro do tipo `Text`, que também tem teto de 255). A única forma de aceitar um valor
maior que 255 caracteres é **mudar o tipo do campo**: para `LongTextArea` (até 131.072
caracteres, configurável) ou `Url`/`Html`. Ou seja, a pergunta 5 da análise ("precisa ser
clicável?") deixa de decidir só entre manter texto (A) e virar link (C) — ela decide isso
**e também**, goste ou não, entre dois tipos diferentes de texto (B), porque A como descrita
não é possível.

Existem campos equivalentes para Cenário 2 (`PFP_2__c`, `Cotacao_2__c`, `Proposta_Acabada_2__c`,
`Informa_es_T_cnicas_Complementares_2__c`, `Aceite_do_cliente_2__c`) e Cenário 3 (sufixo `_3`),
todos também `TextArea`/255 — ver achado 6 (pergunta de escopo).

## 2. O mesmo "PFP 1 (UNC Path)" existe com três desenhos diferentes em três objetos — risco de
   confundir qual campo o design deve mudar

Uma busca por label "PFP" + "UNC" achou **três campos de três objetos diferentes**, todos com
rótulo parecido com "PFP 1 (UNC Path)". Só um deles é o da demanda:

| Objeto | Campo | Tipo | `length` | Usado por esta demanda? |
|---|---|---|---|---|
| `Propostas_de_Solucao__c` (PSL) | `PFP_1__c` | `TextArea` | 255 | **Sim** — é o campo do layout "Retorno do Cliente" |
| `BluePrint__c` | `PFP_1_UNC_Path__c` | `Url` | 255 | Não é o campo da demanda, mas **alimenta** `PFP_1__c` via Flow (achado 3) |
| `FluxoVendaProdutos__c` | `PFP_1_UNC_Path__c` | `String` | 1300 | Não — objeto e fluxo de negócio diferentes, sem relação encontrada com a PSL |

Achado de higiene (não é o escopo desta demanda, mas vale registrar para quem for mexer em
qualquer um desses campos no futuro): o nome quase idêntico em três objetos com três
implementações diferentes é o tipo de inconsistência que gera confusão de manutenção — a
demanda cita "PFP 1 (UNC Path)" sem Id de registro nem link de org confirmando qual é, e o
texto por si só bateria com qualquer um dos três.

## 3. Um Flow ativo copia o campo do BluePrint (255) para o campo da PSL (255) — mesmo teto,
   sem risco de truncamento na automação, mas acopla os dois campos

O objeto `Propostas_de_Solucao__c` tem **6 Flows ativos `RecordAfterSave`** (listados no
achado 5). Um deles, `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`
("Atualiza os Campos PFP X (UNC Path) se PSL Criada ou Atualizada"), lê
`{!$Record.Oportunidade__r.BluePrint__r.PFP_1_UNC_Path__c}` (o campo `Url`/255 do `BluePrint__c`
relacionado via `Propostas_de_Solucao__c.Oportunidade__c` → `Opportunity.BluePrint__c`) e grava
o valor em `PFP_1__c` desta PSL (mesmo padrão para PFP 2 e PFP 3).

Hoje os dois lados têm teto de 255 — não há truncamento nem erro de `STRING_TOO_LONG` nesta
automação específica. **Mas se o design aumentar só `PFP_1__c` (PSL) para `LongTextArea` sem
olhar para `BluePrint__c.PFP_1_UNC_Path__c` (que continua `Url`/255), o Flow seguirá entregando
no máximo 255 caracteres** — a origem do dado (BluePrint) seria o novo gargalo, e a demanda não
seria resolvida para quem preenche a PFP 1 a partir do fluxo do BluePrint, só para quem digita
direto na PSL. O arquiteto precisa decidir se o escopo inclui `BluePrint__c.PFP_1_UNC_Path__c`
(e os campos 2 e 3) ou se vai documentar essa limitação como fora de escopo.

Os outros 5 Flows ativos do objeto (`Atualiza_Quando_Proposta_de_Solucao_da_Oportunidade_Aprovada`,
`Cria_o_da_Proposta`, `Margens_e_Condi_es_Especiais`, `Nova_Proposta_de_Solu_o_SOW_CCS`,
`Propostas_de_Solu_o`) não referenciam nenhum dos cinco campos da demanda (busca por
`<field>` nos XMLs retornados para `tmp_recon/flows/`).

## 4. Achado de FLS: `Aceite_do_cliente__c` é invisível para o usuário integrado — perfil por
   pessoa na prática (risco já apontado pelo assessment)

`sf sobject describe` (rodado com a credencial da integração desta esteira) **não lista**
`Aceite_do_cliente__c` nem `Aceite_do_cliente_2__c` entre os 86 campos retornados — só
`Aceite_do_cliente_3__c` aparece. Os dois "sumidos" existem de verdade (confirmados via
Tooling API `CustomField`, e via metadata retrieve, que não é filtrado por FLS); eles só não
aparecem no describe porque **nenhum perfil/permission set do usuário da integração tem Read
nesses dois campos especificamente**.

Contagem de `FieldPermissions` (Read+Edit) nos cinco campos da demanda, agregada por campo,
sem nome de perfil nem usuário (guardrail #2):

| Campo | Grants com Read+Edit | Observação |
|---|---|---|
| `PFP_1__c` | 69 | |
| `Cotacao__c` | 65 | |
| `Proposta_Acabada__c` | 68 | |
| `Informa_es_T_cnicas_Complementares__c` | 65 | |
| `Aceite_do_cliente__c` | 24 (+ 1 grant só leitura) | **Muito abaixo dos outros quatro** |

`Aceite_do_cliente__c` tem FLS liberada a menos de um terço dos perfis/permission sets que
liberam os outros quatro campos do mesmo bloco "Cenário 1". É o mesmo risco que o assessment já
registrou (achado 6, "perfil por pessoa": 20 de 26 perfis em uso têm um único usuário) se
manifestando neste objeto específico: campos do mesmo formulário visível a conjuntos
diferentes de gente, sem relação óbvia com a regra de negócio. Mudar o **tipo** do campo
(`TextArea` → `LongTextArea`) não altera FLS — a Salesforce preserva as permissões de campo
existentes numa conversão de tipo. Ou seja, este achado não bloqueia a mudança de tipo, mas é
relevante para o QA: se o roteiro de teste rodar com um perfil que não enxerga
`Aceite_do_cliente__c` hoje, o teste vai "passar" sem nunca ter testado esse campo.

## 5. Validation Rules: 11 ativas no objeto, nenhuma toca os cinco campos

`Propostas_de_Solucao__c` tem 16 Validation Rules no total, **11 ativas**: `M01_Proibido_PFP_sem_PSL`,
`M02_Proibido_PSL_sem_PFP`, `M04_PSL_unica`, `M05_Valida_Uma_PFP`, `NaoAlteraFaseSemContato`,
`NaoAtualizaFaseEVP`, `PreencheContatoTipoProposta`, `Propost_Soluc_status_validad_pelo_client`,
`Proposta_Soluc_status_descar_pelo_client`, `PslSemOrcamentista`,
`CNPJ_obrigatorio_se_PFP_fechada` (+ `_2`/`_3`). As 5 inativas:
`Comissao_obrigatoria`, `M03_Obrigatorio_preenchimento_campos_PFP`,
`Permitir_apenas_1_PSL_Fech_Cliente` (e suas variações). Busca por `<field>`/nome de campo nas
fórmulas das 16 regras (ativas e inativas) — **nenhuma referencia `PFP_1__c`, `Cotacao__c`,
`Proposta_Acabada__c`, `Informa_es_T_cnicas_Complementares__c` ou `Aceite_do_cliente__c`**, exceto
a já citada `M03_Obrigatorio_preenchimento_campos_PFP`, que está **inativa** e só valida
`ISBLANK()` (funciona igual em `TextArea` ou `LongTextArea`, não é afetada por mudança de tipo).
**Conclusão: não há validation rule travando ou dependendo do tamanho/tipo desses campos hoje.**

## 6. Apex: há trigger no objeto, mas não toca nos cinco campos

`Propostas_de_Solucao__c` tem um trigger ativo, `TrgPropostasSolucao`, que delega para
`PropostasSolucaoTriggerHandler` → `PropostasSolucaoBO.preencherHistoricoStatus()` (preenche
`HistoricoStatusPSL__c`/`HistoricoStatusPSLJSON__c`, campos de auditoria de mudança de status,
255 e 32768 caracteres respectivamente). Nenhuma das duas classes referencia qualquer um dos
cinco campos da demanda. **Mudar o tipo dos cinco campos não tem impacto Apex conhecido** — o
que, somado ao achado 5, aponta para uma solução puramente declarativa (sem Apex), o que
também significa que o risco de cobertura de teste de 40% (achado 3/4 do assessment) **não se
aplica a esta demanda** se o design confirmar que não entra Apex novo.

## 7. Templates Conga/SDocs: não verificável nesta sandbox

A análise levantou a hipótese de Cotação/Proposta alimentarem documento gerado por Conga
Composer ou SDocs. `SELECT COUNT() FROM APXTConga4__Conga_Template__c` e `SELECT COUNT() FROM
SDOC__SDTemplate__c` retornaram **0** nesta sandbox — não há template configurado para
inspecionar aqui. Templates de produção (se existirem) não são alcançáveis pelo agente
(guardrail #1). Isto fica como pergunta em aberto para o cliente/consultor, não como premissa
resolvida.

## 8. Volume de dados: zero registros na sandbox de dev

`SELECT COUNT() FROM Propostas_de_Solucao__c` e `SELECT COUNT() FROM BluePrint__c` retornam
**0** nesta sandbox — mesmo padrão já visto em outras demandas deste cliente (dev sem massa de
dados). O roteiro de QA (critério "dados existentes permanecem íntegros") vai precisar de massa
sintética criada na própria sandbox, não existe dado para reaproveitar.

## Perguntas em aberto para o design (arquiteto)

1. **Confirmar com o cliente que "Cenário SF" = bloco "Cenário 1" do layout "Retorno do
   Cliente" em Propostas de Solução.** A identificação é por bater exatamente os 5 nomes de
   campo lado a lado nesse layout — alta confiança, mas não foi confirmada com o consultor.
2. **Escopo: só o bloco "Cenário 1" (os 5 campos citados), ou os três blocos (Cenário 1/2/3,
   15 campos no total)?** A pergunta 8 da análise segue aberta; a estrutura on repetida sugere
   que os três blocos têm o mesmo problema, mas a demanda só cita os nomes sem sufixo.
3. **`BluePrint__c.PFP_1_UNC_Path__c` (e `_2`/`_3`) entram no escopo?** Hoje são `Url`/255 e
   alimentam `PFP_1__c` via Flow (achado 3) — se ficarem de fora, o Flow seguirá entregando no
   máximo 255 caracteres nesse caminho específico de preenchimento, mesmo depois do campo da
   PSL aceitar mais.
4. **Tipo alvo: `LongTextArea` (texto) ou `Url`/`Html`?** Depende da resposta pendente da
   análise (pergunta 5: precisa ser clicável, e aceita caminho UNC além de URL HTTP(S)?). Não
   há meio-termo "aumentar o Text/TextArea atual" — essa opção não existe na plataforma
   (achado 1).
5. **Tamanho alvo em caracteres**, agora que se sabe que o teto técnico saltaria de 255 para
   até 131.072 — qual link real precisa caber (P3 da análise seguia como hipótese, 255; isso
   não faz mais sentido como "aumento", precisa virar um valor de `LongTextArea`).

## Não pôde ser medido

- Conteúdo de templates Conga/SDocs (achado 7) — zero templates configurados nesta sandbox.
- Paridade com `sbx-somos-agility-qa` — só a org de dev está autenticada nesta sessão; comparar
  antes do build se o design decidir mudar tipo de campo (mudança de tipo pode se comportar
  diferente se a sandbox de QA tiver dado real nesses campos, o que a de dev não tem).
- Produção: fora do alcance do agente (guardrail #1); qualquer link realmente em uso pelos
  usuários de negócio só existe lá.
