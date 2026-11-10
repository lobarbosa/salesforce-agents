# SOMOSAGILITY-26 — Design (arquiteto)

**Cliente:** somos-agility · **Tipo:** sustentação (design enxuto)
**Org consultada:** `sbx-somos-agility-dev` (sandbox, confirmada por `sf org list` em 2026-11-10). Leitura apenas: metadata, Tooling API e contagens. Nenhum dado de registro.
**Entradas:** `01-analise.md` (aprovada no gate em 2026-11-10, com perguntas bloqueantes ainda sem resposta do negócio), `02-recon.md`, `assessment.md`, conferência adicional na org feita nesta etapa (seção 2).

---

## 1. Resumo da decisão

1. **Configuração nativa, sem Flow e sem Apex.** Converter o tipo de 4 campos de `Propostas_de_Solucao__c` de `TextArea` (teto fixo de 255) para `LongTextArea`.
2. **`PFP_1__c` sai desta demanda e vai para decisão de arquitetura sênior.** Achado novo desta etapa: um **campo fórmula em outro objeto lê `PFP_1__c`**. Fórmula não pode referenciar Long Text Area, então converter `PFP_1__c` exige mudar o modelo de dados. Pela regra do papel, não decido isso sozinho. Detalhes na seção 4.
3. **Escopo recomendado: só o bloco "Cenário 1"**, como a demanda pede. A extensão aos Cenários 2 e 3 custa pouco e tem o mesmo perfil técnico, mas fica para o gate decidir (pergunta G2).
4. **Tamanho de trabalho: 32.768 caracteres**, o padrão da plataforma para Long Text Area. É uma **hipótese** para destravar o design, não um número vindo do negócio (pergunta G3).

## 2. O que esta etapa confirmou na org, além do recon

Rodei `MetadataComponentDependency` (Tooling API) para os campos da demanda e para os campos ligados a eles. Isso **corrige e completa** o `02-recon.md`:

| # | Achado | Evidência | Efeito no design |
|---|---|---|---|
| D1 | `FluxoVendaProdutos__c.PFP1UNCPath__c` (rótulo "*PFP 1 (UNC Path)") é um **campo fórmula** do tipo Text com expressão `PropostaSolucao__r.PFP_1__c`. O mesmo vale para `PFP2UNCPath__c` → `PFP_2__c` e para `PFP3UNCPath__c` → `PFP_3__c`. O recon tratou esse campo como "String 1300 sem relação com a PSL", e não é isso: 1300 é o comprimento de exibição de uma fórmula de texto, e ela lê a PSL diretamente. | `CustomField.Metadata.formula` via Tooling; dependência `PFP_1 <- CustomField PFP1UNCPath` | **Bloqueia a conversão de `PFP_1__c`**. Fórmula não referencia Long Text Area. |
| D2 | Esses 3 campos fórmula aparecem em 5 layouts de `FluxoVendaProdutos__c`: "Layout de Fluxo de Venda de Produto", "Produtos na PFP", "Solicitação de Preços", "Validar Cotação" e "Validação Fiscal". Nenhum Flow, classe ou outra fórmula depende deles. | `MetadataComponentDependency` | Alguém do negócio usa esse valor em telas de outro processo. Quem decide como substituir é o negócio, não o agente. |
| D3 | A própria PSL tem `PFP_1_UNC_Path__c` (com `_2` e `_3`): fórmula de texto `Oportunidade__r.BluePrint__r.PFP_1_UNC_Path__c`. O recon não citou. | Tooling `CustomField` | Se `BluePrint__c.PFP_1_UNC_Path__c` mudasse para Long Text Area, esta fórmula também quebraria. Mais um motivo para tratar a cadeia PFP inteira junto. |
| D4 | O Flow `Concatenacao_download1` ("Concatenação &download=1") referencia `PFP_1__c`, `PFP_2__c` e `PFP_3__c`. A única versão dele está `Obsolete`, sem versão ativa. | `FlowDefinition.ActiveVersionId = null`, `Flow.Status = Obsolete` | Não roda hoje. Fica registrado para a decisão PFP (seção 4). |
| D5 | `Cotacao__c`, `Proposta_Acabada__c`, `Informa_es_T_cnicas_Complementares__c` e `Aceite_do_cliente__c` **só têm layouts como dependentes**: nenhuma fórmula, Flow, Apex, FlexiPage, list view, compact layout ou web link. O mesmo vale para os 8 equivalentes dos Cenários 2 e 3. | `MetadataComponentDependency` + XML em `tmp_recon/` | Conversão limpa, só configuração. |
| D6 | Os 5 campos têm `trackHistory=false` e nenhum tem `required`. | XML dos campos | Converter não afeta Field History. |
| D7 | O objeto já usa cerca de 70.536 caracteres de Long Text Area: `Coment_rios__c` com 5.000, `HistoricoStatusPSL__c` com 32.768 e `HistoricoStatusPSLJSON__c` com 32.768. | `sf sobject describe` | Somar 4 × 32.768 dá cerca de 201.608. Somar 12 × 32.768 (os 3 cenários) dá cerca de 463.752. Os dois ficam bem abaixo do teto por objeto que a documentação da Salesforce indica (1.638.400). No build, conferir esse número na documentação atual antes do deploy. |

Observação: `MetadataComponentDependency` não cobre relatórios nem consumidores externos via API. Isso fica como risco residual (R3 e R4).

## 3. Decisão de nível: configuração nativa

**Nível 1 da doutrina, que é configuração.** O problema é o tipo do campo: `TextArea` tem teto fixo de 255 e não existe "aumentar o tamanho" dentro dele. A solução é trocar a definição do campo. Nenhuma regra de negócio, cálculo, gatilho ou integração precisa ser criada, então Flow e Apex não têm o que fazer aqui. Não há descida de nível para justificar.

**Tipo alvo: `LongTextArea`, e não `Url` nem `Html`:**
- `Url` também tem teto de 255, então não resolve o tamanho. Também não aceita caminho UNC (`\\servidor\...`) como link válido.
- `Html` (Rich Text) muda a forma de digitar, guarda marcação HTML junto com o texto e complica integração e template. Ninguém pediu formatação.
- `LongTextArea` aceita URL HTTP(S), caminho UNC e várias linhas sem validar formato. A conversão a partir de `TextArea` preserva os dados. O contra é que o link não fica clicável na tela, e isso depende da pergunta G4. Se o negócio exigir link clicável, o caminho vira outro desenho (por exemplo, `Url` em paralelo), e isso é mudança de modelo que volta para este gate.

## 4. `PFP_1__c`: decisão escalada para arquitetura sênior

**Mudança de modelo de dados. Não decido sozinho.**

A cadeia hoje:

```
BluePrint__c.PFP_1_UNC_Path__c (Url, 255)
   ├─> fórmula PSL.PFP_1_UNC_Path__c (texto)                      [D3]
   └─> Flow Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada
         (after-save; copia só quando PFP_1__c está vazio)
         └─> PSL.PFP_1__c (TextArea, 255)   <-- campo da demanda
               └─> fórmula FluxoVendaProdutos__c.PFP1UNCPath__c   [D1] — bloqueia
```

Para `PFP_1__c` aceitar mais de 255 caracteres, todos os caminhos abaixo mexem em modelo de dados:

| Opção | O que é | Custo / risco |
|---|---|---|
| P-a | Transformar `FluxoVendaProdutos__c.PFP1UNCPath__c` de fórmula em campo gravado (Long Text Area), alimentado por automação nova quando a PSL muda | Tipo de fórmula não converte em campo gravado: seria criar campo novo e aposentar o antigo nos 5 layouts. Exige Flow novo pai→filhos, carga retroativa e risco de CPU quando uma PSL tem muitos `FluxoVendaProdutos__c`. Esse risco precisa ser dimensionado (achado SOMOSAGILITY-10). |
| P-b | Remover a fórmula dos layouts de `FluxoVendaProdutos__c` e mostrar a PFP por outro meio (campo relacionado no layout, sem fórmula) | Mais barato, mas muda o que o usuário daquele processo vê. Precisa de aceite do negócio. |
| P-c | Criar campo novo Long Text Area na PSL só para links longos e manter `PFP_1__c` como está | Duplica informação, gera ambiguidade sobre qual campo vale e dobra o FLS num org com perfil por pessoa. |
| P-d | Não mexer em `PFP_1__c` | O sintoma continua para o PFP 1. Mas vale lembrar: quando o valor vem do BluePrint pelo Flow, a origem (`Url`, 255) já limita o tamanho de qualquer jeito. |

**Recomendação para o arquiteto humano:** tirar a cadeia PFP desta demanda e abrir uma demanda própria, de modelo de dados, cobrindo `PFP_1/2/3__c`, `BluePrint__c.PFP_X_UNC_Path__c`, as fórmulas D1 e D3 e o Flow. Antes, perguntar ao negócio se o problema do PFP 1 aparece quando o usuário **digita direto** na PSL ou quando o valor **vem do BluePrint** (pergunta G5). Se vier do BluePrint, mudar só a PSL não resolve nada. Por isso também **`BluePrint__c.PFP_1_UNC_Path__c` fica fora desta demanda**, como limitação conhecida.

## 5. Componentes a alterar (escopo recomendado)

Objeto `Propostas_de_Solucao__c`, bloco "Cenário 1" do layout `Propostas_de_Solucao__c-Retorno do Cliente`:

| Campo (API) | Rótulo | Tipo atual → novo | Tamanho atual → novo | `visibleLines` | Descrição |
|---|---|---|---|---|---|
| `Cotacao__c` | Cotação | `TextArea` → `LongTextArea` | 255 (fixo) → 32.768 *(hipótese, G3)* | 3 | manter a atual e acrescentar nota da SOMOSAGILITY-26 |
| `Proposta_Acabada__c` | Proposta Acabada | `TextArea` → `LongTextArea` | 255 → 32.768 | 3 | idem |
| `Informa_es_T_cnicas_Complementares__c` | Informações Técnicas Complementares | `TextArea` → `LongTextArea` | 255 → 32.768 | 3 | **hoje não tem descrição**: criar uma, porque o DoD (`padrao-entrega`) exige |
| `Aceite_do_cliente__c` | Aceite do cliente | `TextArea` → `LongTextArea` | 255 → 32.768 | 3 | idem à primeira linha |

Forma de entrega: os 4 `CustomField` em `force-app/` na branch `feature/SOMOSAGILITY-26`, com `sf project deploy validate` (check-only) antes. Não há Flow, Apex, permission set, layout ou FlexiPage a criar ou alterar. Os campos continuam nos layouts onde já estão, e Long Text Area aparece normalmente no layout.

**Se o gate aprovar G2 (estender):** os mesmos ajustes valem para `Cotacao_2__c`, `Cotacao_3__c`, `Proposta_Acabada_2__c`, `Proposta_Acabada_3__c`, `Informa_es_T_cnicas_Complementares_2__c`, `Informa_es_T_cnicas_Complementares_3__c`, `Aceite_do_cliente_2__c` e `Aceite_do_cliente_3__c`. Todos foram confirmados como `TextArea` e só têm layouts como dependentes (D5). `PFP_2__c` e `PFP_3__c` seguem a seção 4, não esta.

**Nada é depreciado.**

## 6. Permissões

- **FLS não muda.** A Salesforce preserva as permissões de campo quando o tipo muda. Nenhum perfil ou permission set é tocado.
- `Aceite_do_cliente__c` está liberado em 24 grants, contra 65 a 69 dos outros campos (recon, achado 4). **Não corrijo nesta demanda**: ninguém pediu e não sei se é intencional. Fica como pergunta G6. Isso afeta o QA: o usuário de integração desta esteira **não lê** esse campo. O teste precisa rodar na UI, com um usuário que já tenha acesso, ou com um permission set temporário só na sandbox, removido no fim e registrado em `05-testes.md`. Sem isso, o teste "passa" sem ter testado o campo.

## 7. Conflito de automação e escala

- **Automações no objeto:** `Propostas_de_Solucao__c` tem 6 Flows after-save ativos e o trigger `TrgPropostasSolucao`. **Nenhum lê ou grava os 4 campos do escopo** (recon, achados 3 e 6, e D5). A mudança não cria automação nova nem muda a ordem de execução. O único Flow que toca um campo da demanda (o de `PFP_1__c`) ficou fora do escopo (seção 4).
- **Governador e CPU:** não há lógica nova, então não há SOQL, DML ou CPU a mais. Um valor de até 32.768 caracteres por campo não pesa no heap das automações existentes, porque nenhuma delas lê esses campos. Os dois cenários de escala (carga em massa e um pai com muitos filhos) não se aplicam a esta mudança.
- **Volume:** dev tem 0 registros de PSL. O QA vai usar massa sintética.

## 8. Riscos do assessment que tocam esta demanda

| Risco do assessment | Situação nesta demanda |
|---|---|
| #1 e #2: 31 automações concorrentes em Oportunidade e 59 Process Builders | **Não se aplica, e isso é boa notícia.** A demanda não altera Oportunidade, nenhum campo dela nem nenhuma dessas automações. Os 4 campos ficam na PSL e nada depende deles além de layouts (D5). A relação PSL→Oportunidade só aparece na cadeia PFP, que saiu do escopo. |
| #3 e #4: cobertura Apex em 40% e classes sem teste | **Não se aplica.** Não entra Apex novo nem alterado. Mudar o tipo de um campo que nenhuma classe referencia não muda a cobertura nem exige teste novo. Volta a valer se a decisão PFP (seção 4) levar a código. |
| #6: perfil por pessoa | **Aparece, mas não é tratado aqui.** A diferença de FLS em `Aceite_do_cliente__c` é um exemplo concreto do problema. Nesta demanda: nenhuma permissão nova (não piora) e um cuidado registrado para o QA (seção 6). A correção é a recomendação #6 do assessment, fora daqui. |
| #8: 387 Validation Rules | **Descartado no objeto.** Nenhuma das 16 regras da PSL referencia os 4 campos (recon, achado 5). |
| Inventário: Conga, SDocs e SnapERP | **Risco residual, não verificável aqui** (R3 e R4). |

## 9. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Reversão com perda de dados.** Long Text Area volta para Text Area, mas os valores acima de 255 caracteres são **truncados sem volta**. Antes de qualquer valor longo ser gravado, o rollback é limpo. Depois disso, não é. | **Alta** (se precisar reverter em QA ou produção com dado gravado) | Ver plano de rollback (seção 10). |
| R2 | **O que Long Text Area não permite:** filtro em SOQL `WHERE`, ordenação e agrupamento, uso em fórmula, filtro de list view e critério de visibilidade em Dynamic Forms. Em filtro de relatório, só `contém`. | Média | Na org, nada usa esses campos assim (D5), mas relatórios não aparecem na API de dependências. O validate pega fórmula, list view e FlexiPage. Para relatórios, ver R3. |
| R3 | **Relatórios ou integração (SnapERP)** que filtram ou ordenam por esses campos, ou que leem com tamanho fixo de 255. Não dá para ver pela API de dependências, e produção está fora do alcance. | Média | Perguntar ao consultor (G7). No QA, abrir os relatórios da PSL que tenham esses campos, se existirem na sandbox de QA. |
| R4 | **Templates Conga/SDocs** de Cotação ou Proposta: 0 templates em dev. Um campo longo pode quebrar o layout do documento gerado. | Baixa | Perguntar ao consultor (G7). O merge de Long Text Area funciona nos dois produtos, o risco é só visual. |
| R5 | **Paridade com a sandbox de QA:** só dev foi consultada. Se QA tiver outra fórmula ou dependência, o deploy lá falha. | Média | Antes do release, rodar `deploy validate` contra `sbx-somos-agility-qa` (o `ci-salesforce-validate.yml` já faz isso no PR). |
| R6 | **Entrega parcial do pedido:** a demanda cita 5 campos e esta entrega cobre 4. Se ninguém comunicar, o usuário vai achar que o PFP 1 também foi resolvido. | Média | Registrar no gate e em `06-entrega.md`. Abrir a demanda do PFP (seção 4). |
| R7 | **Identificação do "Cenário SF"** como bloco Cenário 1 de "Retorno do Cliente" é de alta confiança (os 5 nomes batem lado a lado), mas nenhuma pessoa confirmou. | Baixa | Pergunta G1. |

## 10. Plano de rollback

1. **Antes do deploy em QA:** guardar na branch o XML atual dos 4 campos (`type=TextArea`) como artefato de reversão.
2. **Reverter antes de existir valor com mais de 255 caracteres:** fazer deploy do XML anterior. Os dados ficam intactos.
3. **Reverter depois de existir valor longo:** isso trunca os dados. Antes, um humano levanta **só a contagem** de registros com valor acima de 255 em cada campo (guardrail #2: o agente não lê o conteúdo). Quem tiver acesso exporta esses registros por canal próprio do cliente. Só então se faz a reversão. Em produção, quem decide é o humano: o agente não age lá (guardrail #1).
4. Nenhuma automação, permissão ou layout precisa ser revertido, porque nada disso muda.

## 11. O que NÃO será feito nesta demanda

- Converter `PFP_1__c`, `PFP_2__c` e `PFP_3__c` (seção 4: decisão de modelo de dados, escalada).
- Mexer em `BluePrint__c.PFP_X_UNC_Path__c`, nas fórmulas `PSL.PFP_X_UNC_Path__c` e `FluxoVendaProdutos__c.PFPXUNCPath__c`, nos Flows `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` e `Concatenacao_download1`.
- Os 8 campos dos Cenários 2 e 3, a não ser que o gate aprove G2.
- Tornar o link clicável ou validar o formato de URL/UNC.
- Corrigir a diferença de FLS de `Aceite_do_cliente__c`.
- Qualquer mudança em Oportunidade.
- `FluxoVendaProdutos__c`: o recon tinha registrado errado o nome do campo de lá (o API name real é `PFP1UNCPath__c`). Isso fica corrigido aqui, sem nenhuma ação.

## 12. Perguntas para o gate (arquiteto humano e negócio)

| # | Pergunta | Quem responde | Bloqueia o build? |
|---|---|---|---|
| G1 | "Cenário SF" é o bloco Cenário 1 do layout "Retorno do Cliente" em Propostas de Solução? | consultor | Não. O build segue com a hipótese, e o QA confirma com quem abriu a demanda. |
| G2 | Estender aos 8 campos equivalentes dos Cenários 2 e 3? Recomendo **sim**, se o negócio confirmar que o problema é o mesmo. O custo extra é de +1 a 1,5 h. | arquiteto humano + consultor | Sim, porque define a lista de campos. |
| G3 | Qual o maior link real esperado? 32.768 é valor de trabalho. Qualquer número entre 256 e 131.072 funciona, e um teto menor (por exemplo 2.000) reduz texto livre sem controle. | consultor ou cliente | Não. Ajustar o número antes do deploy custa pouco. |
| G4 | O link precisa ser clicável? Se sim, Long Text Area não basta e o desenho volta para este gate. | consultor ou cliente | **Sim**, se a resposta for "precisa ser clicável". |
| G5 | O problema do PFP 1 aparece ao digitar direto na PSL ou quando o valor vem do BluePrint? E o gate aceita abrir uma demanda separada de modelo de dados para a cadeia PFP (opções P-a a P-d)? | consultor + arquiteto sênior | Não bloqueia os 4 campos. Bloqueia qualquer trabalho no PFP. |
| G6 | A FLS restrita de `Aceite_do_cliente__c` é intencional? | consultor | Não. |
| G7 | Algum relatório, integração (SnapERP) ou template (Conga/SDocs) filtra, ordena ou imprime esses campos? | consultor | Não, mas pode virar ajuste antes do release. |

## 13. Estimativa de esforço refinada

**Estimativa de esforço:** 3–6 h

Escopo: os 4 campos do Cenário 1. Composição:
- Build: 4 campos em `force-app/`, descrições e validate: 0,5–1 h.
- QA em sandbox com massa sintética, cobrindo os critérios da análise e o cuidado de FLS de `Aceite_do_cliente__c`: 1,5–2,5 h.
- PR, validate em QA, homologação e entrega: 1–2 h.
- Se G2 for aprovada: **+1 a 1,5 h** (8 campos a mais, mesmo procedimento).

**O que mudou em relação à análise (3–8 h) e por quê:** o teto alto caiu porque o recon e esta etapa descartaram, para os 4 campos, as dependências que justificavam a faixa larga (validation rules, Apex, Flows, fórmulas). Sobra só a mudança de tipo. O teto não chega mais perto do piso porque mudar tipo tem reversão restrita (R1), relatórios e integrações não são visíveis (R3) e a FLS desigual exige um teste mais cuidadoso. A cadeia PFP **não entra nesta estimativa**: ela vira demanda própria, com estimativa própria depois da decisão sênior.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
