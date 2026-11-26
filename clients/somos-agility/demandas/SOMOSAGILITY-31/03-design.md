# SOMOSAGILITY-31 — Design (arquiteto)

- **Cliente:** somos-agility · **Tipo:** sustentação, alteração de metadata de campo (design enxuto)
- **Org consultada:** `sbx-somos-agility-dev` (Sandbox, Connected, confirmada com `sf org list` em 2026-11-26). Produção não tocada. A QA não estava conectada nesta sessão: nenhuma comparação dev × QA é afirmada aqui.
- **Entradas:** `01-analise.md` (gate de análise aprovado em `gates.md`), `02-recon.md`, `comentarios-do-card.md`, `00-preflight.md` (sem bloqueio, sem outra demanda nos mesmos componentes), histórico RAG (SOMOSAGILITY-26), skills `design-testavel`, `salesforce-doutrina`, `modelo-de-dados-e-acesso`, `carga-e-migracao`, `estimar-esforco`.
- **Documento técnico:** `03-documento-tecnico.md`.

---

## Em destaque para o arquiteto humano

### 1. Mudança de tipo de campo (decisão de modelo de dados, escalada)

A demanda diz "criar", mas os 9 campos **já existem** na dev como Área de texto (255) (confirmado nesta sessão: `FieldDefinition` de `Propostas_de_Solucao__c`, `DataType` = Área de texto(255), `Length` 255, `IsNillable` true nos 9). Mudança de tipo de campo é item de escalada (skill `modelo-de-dados-e-acesso`). Alternativas:

| Opção | O que é | Prós | Contras |
|---|---|---|---|
| **(a) Recomendada.** Alterar o tipo dos 9 campos para Área de texto longo (32768) | mesmo API name, mesmo rótulo, mesmos layouts, FLS e report types | nenhum consumidor que use o API name quebra por nome; sem migração; valores de até 255 são preservados pela plataforma | o tipo longo não pode ser usado em filtro de SOQL, filtro de relatório e de list view nem em fórmula; voltar para 255 trunca o que passar de 255 (rollback com perda) |
| (b) Criar 9 campos novos e migrar | padrão usado na SOMOSAGILITY-26 para `PFP_N_Texto__c` | o antigo fica intacto | 9 campos duplicados, layouts, FLS e report types refeitos, carga de dados em produção, consumidores precisam trocar de campo; esforço 3 a 4 vezes maior |

Na SOMOSAGILITY-26 a opção foi criar campos novos porque havia colisão de API name e o antigo era alimentado por Flow e lido por fórmula [demandas/SOMOSAGILITY-26/02-recon.md]. Aqui nenhum desses motivos existe: o recon não achou Flow, trigger, validation rule nem Apex do repo que leia os 9 campos (`02-recon.md`, seção 6.1, e Grep desta sessão no `force-app/`, que só achou 5 layouts, 2 permission sets e 4 report types). **Aceitar este design = responder P1 com (a).**

### 2. Perguntas em aberto para o gate

A análise pedia P1 a P5 respondidas antes do design. O gate da análise foi aprovado e o card só trouxe a resposta do objeto (`Propostas_de_Solucao__c`, comentário de 2026-11-26 12:15). As demais seguem abertas; o design anda com a premissa marcada e diz o que cada uma bloqueia.

| # | Pergunta | Premissa do design | Bloqueia |
|---|---|---|---|
| P1 | Alterar o tipo (a) ou criar campos novos (b)? | (a) | **o build** (aceite do gate) |
| P2 | Os 9 campos existem em QA e produção como Área de texto (255)? | sim, iguais à dev | não o build; o verificador do passo de QA confere antes do teste. Se a QA divergir, volta ao design |
| P3 | Quem lê os 9 campos fora do Salesforce ou em relatório: Conga, SDocs, SnapERP, relatórios com filtro, list views, painéis? | ninguém além do que o recon achou | não o build; **bloqueia a subida para produção** se algum relatório ou list view filtrar por um dos campos (o tipo longo não é filtrável) |
| P4 | A 31 é a demanda nova registrada pela 26? | sim. O recon da 26 tratou só `PFP_1/2/3__c` e afins em `Propostas_de_Solucao__c`, não estes 9 [demandas/SOMOSAGILITY-26/02-recon.md] | não |
| P5 | Quais perfis veem e editam? | os mesmos de hoje. A mudança de tipo não altera FLS, e o pacote não leva perfil nem permission set | não o build; CA-06 é provado como "FLS igual antes e depois" (ver plano de prova). Se o cliente quiser outro acesso, é escopo novo |
| P6 | 32.768 é o tamanho certo? Quantas linhas a caixa mostra na tela? | 32.768 (pedido) e 5 linhas visíveis | não |
| P7 | Os campos são obrigatórios? | **respondida pela org:** não (`IsNillable` true; `<required>false</required>` no XML do repo) | — |
| P8 | Há carga ou correção de registros? | não há | não |
| P9 (nova) | Quem sobe para produção e em que janela? A alteração de tipo em produção roda sobre todos os registros do objeto (a QA tinha 1.475 PSL na SOMOSAGILITY-26 [demandas/SOMOSAGILITY-26/05-testes-rodada-1.md]) | consultor dono da demanda, em janela combinada | não o build; a subida |

---

## 1. Decisão e justificativa

**Configuração nativa (nível 1): alteração de metadata de 9 campos, sem Flow e sem Apex.** Tipo e tamanho de campo são configuração pura; não há regra a automatizar, então Flow e código não se aplicam. Nada desce de nível.

O pacote leva **só os 9 arquivos `CustomField`**. Layouts, permission sets, perfis e report types continuam referenciando os mesmos API names e não entram no pacote (RN-02 e CA-07). O builder parte do XML atual da dev (retrieve dos 9 campos) e muda só `type`, `length` e `visibleLines`, preservando `label`, `description` (existe em `Cotacao__c` e `Proposta_Acabada__c`), `required` e as flags de tracking.

## 2. Componentes

| Componente | API name | Ação |
|---|---|---|
| Campo | `Propostas_de_Solucao__c.Cotacao__c` | alterar tipo: TextArea → LongTextArea (32768, 5 linhas) |
| Campo | `Propostas_de_Solucao__c.Cotacao_2__c` | idem |
| Campo | `Propostas_de_Solucao__c.Cotacao_3__c` | idem |
| Campo | `Propostas_de_Solucao__c.Proposta_Acabada__c` | idem |
| Campo | `Propostas_de_Solucao__c.Proposta_Acabada_2__c` | idem |
| Campo | `Propostas_de_Solucao__c.Proposta_Acabada_3__c` | idem |
| Campo | `Propostas_de_Solucao__c.Informa_es_T_cnicas_Complementares__c` | idem |
| Campo | `Propostas_de_Solucao__c.Informa_es_T_cnicas_Complementares_2__c` | idem |
| Campo | `Propostas_de_Solucao__c.Informa_es_T_cnicas_Complementares_3__c` | idem |

Nada a criar, nada a depreciar. Nenhum Flow, agente ou classe é alterado; portanto não há versão nova nem passo de ativação.

## 3. Conflito de automação e ordem de execução

Automações no objeto (do `02-recon.md`): trigger `TrgPropostasSolucao` (handler `PropostasSolucaoTriggerHandler`), 6 Flows after-save ativos, 13 validation rules ativas. **Nenhuma lê ou grava os 9 campos** (recon: retrieve e Grep; esta sessão: Grep do repo sem outra ocorrência). A demanda não adiciona automação, então não há risco novo de ordem de execução. O que muda é o tipo do dado que essas automações carregam no contexto (ver limites).

## 4. Limites e pior caso, com número

- **Volume na dev:** 0 registros de `Propostas_de_Solucao__c`, 0 Opportunity, 0 Account (contagens desta sessão). **QA:** 1.475 PSL segundo a QA da SOMOSAGILITY-26 (histórico, não medido agora). Produção: não medida.
- **CPU e SOQL:** a demanda não acrescenta consulta nem DML. Sem mudança.
- **Heap (o limite que o tipo longo toca):** um registro com os 9 campos cheios carrega 9 × 32.768 = 294.912 caracteres. O trigger do objeto recebe `Trigger.new` e `Trigger.old` com todos os campos. Em lote de 200 registros com os 9 campos cheios, o volume teórico passa de 50 milhões de caracteres, muito acima do heap síncrono de 6 MB. **Premissa de negócio:** o uso real fica longe disso (texto de proposta, não arquivo), e a carga em massa desses campos não acontece. Prova: o verificador roda uma atualização em lote de 200 PSL de teste com `Cotacao__c` em 32.768 caracteres (6,5 milhões de caracteres no lote) e registra sucesso ou o erro. Se falhar, o design volta para declarar teto de lote para Data Loader (ex.: lote de 20) com aceite do responsável.
- **Alteração de tipo em produção:** a plataforma converte o campo sobre todos os registros do objeto. Com volume na casa de milhares, é rápido; o número de produção é desconhecido (P9).

## 5. Riscos do assessment e do histórico

- O assessment não cita `Propostas_de_Solucao__c` (0 ocorrências, `01-analise.md` seção 7). Nenhum risco específico do objeto.
- Cobertura Apex da org em 40%: não se aplica, a demanda não tem Apex. Diferença org × repo: a dev tem 96 classes sem namespace e o repo 95; a que falta no repo é `SolicitacaoReembolsoTriggerHandlerTest` (pelo nome, outro assunto). O Grep do repo vale, então, para as classes de negócio, mas não pega SOQL dinâmico por string.
- Automações de Opportunity (assessment: 31; 26 validation rules ativas na dev, contagem desta sessão): não são tocadas pela demanda, mas o registro de teste depende de uma Opportunity, e criar a Opportunity passa por elas.
- SOMOSAGILITY-26: rollback de metadata não desfaz dado gravado [demandas/SOMOSAGILITY-26/06-entrega-complemento.md]. Aqui o efeito é mais forte: voltar de 32.768 para 255 trunca o que tiver passado de 255. Ver riscos.

## 6. Pré-requisitos de ambiente (com dono)

| # | Pré-requisito | Dono | Quando |
|---|---|---|---|
| PR-1 | Massa sintética na dev **antes** do deploy: 1 Account, 1 Contact, 1 Opportunity com `Or_amentista__c` = o Contact de teste e `Conversao_de_Lead__c` = "Não", e 1 PSL com `Cotacao__c` = 255 caracteres sintéticos. Receita da SOMOSAGILITY-26 [demandas/SOMOSAGILITY-26/05-testes-rodada-1.md]. Prefixo `TESTE SOMOSAGILITY-31` | builder (dado de teste na dev é permitido) | antes de implantar os 9 campos na dev |
| PR-2 | Na QA, a mesma massa sintética, criada pelo QA depois do deploy da esteira (a QA não permite criar antes, porque o deploy é passo fixo) | agente `qa` | sessão de QA |
| PR-3 | Retrieve dos 9 campos e dos 5 layouts na QA antes do teste, para confirmar P2 (tipo 255 na QA) e ter a base do CA-08 | agente `qa`, a partir do `05-deploy-qa.md` | sessão de QA |
| PR-4 | Resposta a P3: lista de relatórios, list views, painéis e templates (Conga, SDocs) e da integração SnapERP que usam os 9 campos. Na falta da lista, a verificação "Onde é usado" do Setup em cada campo, na QA | consultor dono da demanda | antes da homologação |
| PR-5 | Usuário de teste: não é preciso usuário de outro perfil (CA-06 vira comparação de FLS). Sem pedido de licença | — | — |
| PR-6 | Nada a desligar: nenhuma automação é substituída | — | — |

Diferença dev × QA: as validation rules e os Flows da QA não foram comparados (QA não conectada). A massa sintética preenche o que as 13 regras do objeto exigem para um registro novo (detalhe no documento técnico, seção 7); se a QA tiver regra a mais, a falha é de ambiente, com `**Origem:** ambiente`.

## 7. Plano de prova por critério

| Critério | Como se prova na dev | Como se prova na QA | O que precisa existir |
|---|---|---|---|
| CA-01 tipo dos 9 campos | `FieldDefinition` dos 9 campos: `DataType` Área de texto longo, `Length` 32768 | mesma consulta | deploy feito |
| CA-02 valor preservado | PSL de teste criada antes do deploy com `Cotacao__c` de 255 caracteres sintéticos; depois do deploy, Apex anônimo lê o campo e compara tamanho e igualdade com o texto gerado pela mesma regra (resultado só `len` e `iguais=true/false`) | o deploy já aconteceu antes da sessão. Prova aceita: (1) contagem agregada, por Apex anônimo, de quantas PSL têm cada campo não vazio e quantas têm tamanho maior que 255, saída só em números (esperado: maior que 255 = 0); (2) a prova controlada fica a da dev. **Comparação antes/depois na QA não é possível** sem uma contagem prévia; se o gate quiser, PR extra: o consultor roda a contagem na QA antes do passo de deploy | PR-1; acesso de leitura na QA |
| CA-03 aceita 32.768 | Apex anônimo grava 32.768 caracteres em `Proposta_Acabada_2__c` da PSL de teste e lê `len=32768` | mesmo, na massa da QA | PR-1 / PR-2 |
| CA-04 recusa 32.769 | Apex anônimo tenta 32.769 em `Informa_es_T_cnicas_Complementares_3__c`; esperado `STRING_TOO_LONG` e o campo igual ao anterior | mesmo | PR-1 / PR-2 |
| CA-05 campo vazio | PSL de teste salva com `Cotacao__c` vazio (aceita, como hoje: P7 respondida pela org) | mesmo | PR-1 / PR-2 |
| CA-06 perfil sem permissão | contagem agregada de `FieldPermissions` por campo (`PermissionsRead`, `PermissionsEdit`) antes e depois do deploy, para os 9 campos: iguais | mesma contagem depois do deploy, comparada com a da dev (a da QA antes não existe); o cliente confere na homologação que quem não via continua sem ver | nada além de leitura |
| CA-07 nada além dos 9 campos | o PR contém só os 9 `.field-meta.xml`; `git diff --stat` | `05-deploy-qa.md` lista só os 9 componentes | — |
| CA-08 layouts mantidos | retrieve dos 5 layouts antes e depois; diff sem mudança | retrieve dos 5 layouts na QA, presença dos campos na mesma seção que o repo tem | PR-3 |
| CA-09 dependências sem erro | deploy sem erro; contagem de validation rules ativas do objeto (13) e Flows ativos do objeto (6) igual antes e depois | mesma contagem na QA, antes vs. depois não comparável; vale "deploy sem erro" e regras e Flows ativos | — |
| CA-10 consumidor externo | não se prova na dev | só se P3 listar consumidor: gerar o template ou relatório com a PSL de teste de mais de 255 caracteres. Sem lista, vai para `05-roteiro-cliente.md` como conferência do cliente | PR-4 |
| Regressão (heap, seção 4) | atualização em lote de 200 PSL de teste com `Cotacao__c` em 32.768 | não repetido na QA | PR-1 ampliado (200 PSL na mesma Opportunity de teste) |

Limpeza: toda a massa com prefixo `TESTE SOMOSAGILITY-31` é apagada ao fim de cada sessão, conferida por contagem.

## 8. Impacto em permissões

Nenhum. O pacote não leva perfil nem permission set. FLS atual (recon: 63 a 66 linhas de `FieldPermissions` por campo, só os 3 sem sufixo contados) é mantida pela plataforma na troca de tipo; isso é provado no CA-06 por contagem antes e depois. Os permission sets `Acesso_completo_Esteira_de_vendas_e_renovacoes` e `DiretorComercial` (repo) continuam válidos sem alteração.

## 9. Riscos técnicos

| Risco | Severidade | Tratamento |
|---|---|---|
| **Rollback com perda:** voltar o tipo para Área de texto (255) trunca todo valor acima de 255 gravado depois da subida | **Alta** em produção | rollback só por decisão do cliente; antes, exportar os valores pelo consultor. Na sandbox, o rollback é reimplantar o XML antigo enquanto só houver texto de até 255 |
| **Consumidor não levantado** (relatório ou list view com filtro, Conga/SDocs, SnapERP, Apex por SOQL dinâmico) quebra com o tipo longo: filtro e `WHERE` deixam de aceitar o campo | **Média** | P3 + PR-4; o deploy na dev e na QA falha se houver dependência de metadata que impeça a troca, e isso vira achado. Relatório salvo com filtro não bloqueia o deploy, por isso o "Onde é usado" na QA |
| Heap em lote com campos cheios (seção 4) | Baixa no uso, alta no teórico | prova de lote de 200; teto de lote declarado se falhar |
| Repo defasado em relação à dev: layouts, permission sets e report types vieram do Grep do repo | Baixa | o pacote não leva esses itens; CA-08 compara o retrieve real |
| Massa de teste esbarra nas 26 validation rules ativas da Opportunity ou em regra só da QA | Média (já reprovou QA no histórico) | receita conhecida da SOMOSAGILITY-26; falha de criação de massa sai com `**Origem:** ambiente` |
| Tipo diferente na QA ou em produção (P2) | Média | PR-3; se a QA já for longo ou não tiver o campo, volta ao design |

## 10. O que NÃO será feito

- Criar campos novos ou migrar dados (opção b).
- Alterar layout, posição de campo, perfil, permission set, report type, relatório, list view ou template.
- Alterar outros campos textarea do objeto (`PFP_1__c`, `Cenario1__c` etc.).
- Ajustar consumidor externo (Conga, SDocs, SnapERP). Se P3 listar um que quebre, é demanda própria.
- Carga ou correção de registros existentes (P8).
- Subida para produção (consultor, fora da esteira).

---

**Estimativa de esforço:** 4–7 h
Mudou em relação à análise (3–6 h): subiu 1 h nos dois extremos porque a dev não tem nenhum registro de PSL, Opportunity nem Account, e a prova exige montar massa sintética (Account, Contact, Opportunity com Orçamentista e Conversão de Lead, PSL) passando por 26 validation rules ativas na Opportunity e 13 no objeto, antes do deploy na dev e de novo na QA; e porque os consumidores fora do repo (P3) precisam de conferência manual na QA. Não caiu, apesar de o recon não ter achado automação lendo os campos, porque esse ganho já estava no mínimo da análise. Referência: SOMOSAGILITY-26 (campos de texto longo no mesmo objeto), mais pesada por ter Flow; esta é só metadata.
- Vale se P1 for (a) e P3 não listar consumidor que filtre pelos campos.
- Vale sem carga de dados (P8) e com a QA igual à dev (P2).
- Sobe acima de 7 h se P3 listar relatório, template ou integração a ajustar, ou se P1 virar (b) (novo design com migração).
- Não inclui a exportação de valores antes de um eventual rollback em produção.

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
