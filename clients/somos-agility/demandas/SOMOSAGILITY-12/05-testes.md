# 05 — Testes: SOMOSAGILITY-12

**Agente:** `qa` · **Data:** 2026-10-25
**Base dos casos:** critérios de aceite de `01-analise.md` (seção 4, CA-01 a CA-07), não o
que foi construído — testar o código contra ele mesmo não prova nada. Design (`03-design.md`)
e plano de build (`04-plano-build.md`) foram usados só para saber nomes reais de API,
mensagem de erro e data de corte, e para localizar riscos técnicos (R-01, R-02, R-05) que o
design já tinha sinalizado como precisando de teste explícito.

## Ambiente desta sessão

Só `sbx-somos-agility-dev` está autenticada. `sbx-somos-agility-qa` **não está conectada
nesta sessão** — confirmado tentando abrir `qa_browser_open` contra ela, que falhou
(`NamedOrgNotFoundError: No authorization information found for sbx-somos-agility-qa`).
Conforme a doutrina (guardrail #1: a etapa `qa` roda na sandbox de QA, nunca na de dev como
substituta), **não insisti e não caí para a dev**. Nenhum deploy real foi feito em nenhuma
sandbox até agora (`04-plano-build.md` só rodou `deploy validate`, check-only) — isto é,
os três componentes desta demanda **ainda não existem deployados em nenhuma sandbox**, nem
em dev nem em QA. Por isso, nenhum teste de UI pôde ser executado de fato nesta sessão; todos
os casos que dependem de tela estão com **"Obtido": não executado nesta sessão** e viram
roteiro para humano rodar depois que o deploy real acontecer em `sbx-somos-agility-qa`.

**O que foi automatizável sem precisar de sandbox QA, e foi executado:**
- Não há classe Apex nesta demanda (confirmado em `04-plano-build.md`, seção 2: só
  `ValidationRule`, `PermissionSet` e `Layout`) — não há `sf apex run test` a rodar.
- Verificação estática dos três arquivos de metadata em
  `clients/somos-agility/force-app/main/default/` contra o que `03-design.md` e
  `04-plano-build.md` descrevem, e contra os critérios de aceite originais (não contra a
  própria descrição do build). Essa verificação **não depende de nenhuma sandbox** — é
  leitura de arquivo — e é o que encontrou a falha principal reportada abaixo.
- Nenhuma query rodada; nenhum dado de cliente (CPF, e-mail, telefone, valor) foi acessado em
  nenhum momento.

---

## Resumo executivo — falhas primeiro

A regra entregue (bloqueio em qualquer save de registro novo, com recorte por `CreatedDate`)
é a opção que `03-design.md` escolheu conscientemente por limitação técnica (seção 1 do
design: "só na submissão" com mensagem específica não é possível de forma declarativa sem
Apex/Flow com novo valor de status). O próprio `04-plano-build.md` (seção 7, linha D-03) já
reportou essa divergência para o humano decidir, sem reabri-la. **Esta sessão de QA confirma,
por análise estática da fórmula contra os critérios de aceite literais de `01-analise.md`,
que a divergência tem efeito prático: CA-01, CA-02, CA-03 e CA-05, como estão escritos hoje,
não passam.** Isso não é uma regressão introduzida por erro de implementação — é a
consequência direta e já documentada da escolha de design — mas continua sendo uma falha de
critério de aceite enquanto `01-analise.md` não for reescrito para refletir H-D03 (o próprio
design já previu isso: "CA-05 precisa ser reescrito", seção 2 da tabela de D-03).

| Critério | Por que falha como está escrito | Status |
|---|---|---|
| CA-01, CA-02, CA-03 | Pressupõem "o registro existe com só um campo vazio e **é bloqueado só na hora de enviar para aprovação**". Para um JOB novo (pós go-live), esse estado nem é alcançável: qualquer save com um dos dois campos vazio já é bloqueado desde a criação, antes de chegar à etapa de submissão — o Gherkin não consegue nem montar o "Dado". Para um JOB legado, o estado é alcançável, mas aí a regra **não bloqueia** (exemption por `CreatedDate`), contrariando o "Então o envio é bloqueado". | **Falha (confirmada por análise estática da fórmula)** |
| CA-05 | "Salvar alterações em outros campos sem enviar para aprovação" deveria ser aceito. Para um JOB novo, **qualquer save** passa pela validation rule, inclusive edição de campos não relacionados — então, se Classificação/Denominação estiverem vazias, o save é bloqueado mesmo sem o usuário estar tentando submeter. Só passa para JOB legado. | **Falha para JOB novo / Passa para JOB legado** |
| CA-04, CA-06 | Não dependem de distinguir "salvar" de "submeter" — continuam válidos como escritos. | Esperado passar (a confirmar em QA) |
| CA-07 | Placeholder na análise ("comportamento definido em D-06"). D-06 foi resolvido no design via FLS (C-2/H-D06), não há regra de negócio adicional a testar além de R-01. | Coberto por R-01 |

**Recomendação para o humano:** decidir se aceita a divergência (e então reescrever CA-01,
CA-02, CA-03 e CA-05 em `01-analise.md` para refletir "bloqueado desde a criação", como o
design já antecipou) ou se escala para o arquiteto a alternativa que distingue save de
submissão (H-2 ou mudança de modelo de dados, ambas descartadas no design por outros custos —
seção 6 de `03-design.md`). Isso não bloqueia necessariamente o release se o cliente aceitar
a divergência como está — mas é uma decisão de negócio, não deste agente.

Além disso, **um item fora do escopo foi pedido pelo cliente depois do gate de design**
(`comentarios-do-card.md`, 2026-10-23: "Revisar também o preenchimento destes mesmos campos
no objeto job de investimentos"). `03-design.md` seção 7 explicitly exclui
`JOB_de_Solicita_o_de_Investimento__c` do escopo desta demanda. Nenhum componente desta
demanda toca esse objeto. Não é uma falha de teste — é um pedido de escopo novo que precisa
virar outra demanda, sinalizado aqui para não ser perdido.

---

## Casos de teste

### Verificação estática (executada nesta sessão, sem depender de sandbox)

| Caso | Passos | Esperado (critério de aceite literal) | Obtido | Status |
|---|---|---|---|---|
| CA-01 | Ler a fórmula de `JST_Classif_Denominacao_Obrigatorias.validationRule-meta.xml` e simular: JOB com Denominação preenchida, Classificação vazia, tentativa de envio para aprovação | Envio bloqueado, mensagem específica sobre Classificação, registro permanece na etapa anterior | Para JOB novo: estado inalcançável (já bloqueado antes, na criação/edição que deixaria Classificação vazia). Para JOB legado: `OR(ISNEW(), CreatedDate>=2026-10-21)` é falso → regra não dispara → envio não é bloqueado. Mensagem, quando dispara, é genérica ("Favor preencher os campos antes de enviar para aprovação"), não nomeia o campo específico. | **Falha** |
| CA-02 | Mesma simulação, com Classificação preenchida e Denominação vazia | Envio bloqueado, mensagem específica sobre Denominação | Mesma lógica de CA-01, espelhada | **Falha** |
| CA-03 | Mesma simulação, os dois campos vazios | Envio bloqueado, mensagem indica os dois campos | Para JOB novo, o registro nunca chega a existir vazio (bloqueado na criação). Para JOB legado, não é bloqueado. Quando a regra dispara, a mensagem não nomeia os campos, é um texto genérico. | **Falha** |
| CA-04 | Simular JOB com os dois campos preenchidos, envio para aprovação | Envio aceito, segue para aprovação | `OR(ISBLANK(...), ISBLANK(...))` é falso com os dois preenchidos → `AND(...)` falso → regra não dispara, save/submit passa | **Passa (análise estática) — confirmar em QA** |
| CA-05 | Simular JOB com Classificação vazia, salvando alteração em outro campo, sem enviar para aprovação | Gravação aceita | Para JOB novo: `OR(ISNEW(), CreatedDate>=corte)` é verdadeiro em qualquer save pós go-live (não só na submissão) → se o campo está vazio, o save é bloqueado mesmo sem ser submissão. Para JOB legado: exemption por `CreatedDate` faz a gravação passar. | **Falha para JOB novo / Passa para JOB legado** |
| CA-06 | Simular edição de um JOB criado antes do go-live (`CreatedDate < 2026-10-21`), com campo vazio | Não é reprocessado nem bloqueado retroativamente | `OR(ISNEW(), CreatedDate>=corte)` falso (não é novo, `CreatedDate` anterior ao corte) → `AND(...)` falso → regra nunca dispara para esse registro, em nenhum save | **Passa (análise estática) — confirmar em QA** |
| R-05 | Confirmar que `ISBLANK(TEXT(Classificacao_Gerencial__c))` e `ISBLANK(Denomina_o_do_Treinamento__c)` (LongTextArea) são aceitos pela plataforma | A fórmula compila e é aceita em deploy | Já confirmado em `04-plano-build.md` seção 8.1: `sf project deploy validate` retornou `Succeeded`, 0 erros de componente, para os 3 componentes desta demanda. Não refeito nesta sessão (evidência já existe e não foi alterada desde então) | **Passa (evidência do build, não re-executado)** |

### Roteiro para execução humana em `sbx-somos-agility-qa` (depende de deploy real + sandbox conectada)

Pré-requisito comum a todos os casos abaixo: deploy real (não `validate`) dos três
componentes (`PS_JST_ClassificacaoDenominacao`, o layout alterado, e
`JST_Classif_Denominacao_Obrigatorias`) em `sbx-somos-agility-qa`, na ordem descrita em
`04-plano-build.md` seção 4 (PermissionSet → Layout → ValidationRule). Nenhum desses
componentes existe hoje em nenhuma sandbox (só validados, nunca deployados de fato).

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| CA-04 (UI) | 1. Login em QA com usuário com FLS nos dois campos. 2. Criar um `JOB de Solicitação de Treinamentos` novo preenchendo Classificação Gerencial e Denominação do Treinamento (e os campos hoje já obrigatórios do layout). 3. Salvar. 4. Clicar em "Submit for Approval" | Save aceito; submissão aceita; registro segue para a etapa de aprovação (`JobSTGeral_v2` ou `Aprovacao_do_JOB_de_Treinamentos_v7`, conforme critério de entrada) | Não executado nesta sessão — sandbox de QA não conectada | **Pendente (roteiro para humano)** |
| CA-05 / divergência D-03 (UI) | 1. Com o mesmo usuário, criar um JOB novo deixando Classificação Gerencial vazia. 2. Tentar salvar (sem clicar em Submit, só alterando outro campo, ex.: `Justificativa__c`) | Segundo CA-05 literal: gravação deveria ser aceita. Esperado real (pela fórmula): save **bloqueado** com a mensagem "Favor preencher os campos antes de enviar para aprovação", mesmo sem o usuário estar enviando para aprovação | Não executado nesta sessão — mas o resultado é previsível pela fórmula (ver verificação estática acima); humano deve confirmar na tela e decidir se aceita a divergência | **Pendente (roteiro para humano) — resultado esperado é FALHA do CA-05 literal** |
| CA-06 (UI) | 1. Identificar (ou pedir ao admin do cliente) um `JOB de Solicitação de Treinamentos` existente em QA com `CreatedDate` anterior a 2026-10-21 e algum dos dois campos vazio. **Se não existir nenhum registro assim na sandbox de QA** (a de dev tinha 0 registros — `02-recon.md` seção 7 —, QA pode estar igual), reportar isso como achado: não há como testar CA-06 por falta de massa de dados legados na sandbox, e registrar que o teste real só poderá ocorrer em produção ou com carga de dados de teste com `CreatedDate` manipulada (requer permissão "Set Audit Fields upon Record Creation" habilitada e inserção via API, nunca via UI). 2. Se existir, editar um campo não relacionado e salvar | Gravação aceita, sem bloqueio, mesmo com campo vazio | Não executado nesta sessão | **Pendente (roteiro para humano) — ver nota sobre massa de dados** |
| R-01 — permissão por perfil | 1. Criar usuário de teste (sem dado pessoal real) com um dos 13 perfis listados em `02-recon.md` seção 6 sem FLS de edição nos dois campos (ex.: `Marketing`, `PMO`, `Diretor Financeiro`). 2. **Sem** atribuir `PS_JST_ClassificacaoDenominacao` a esse usuário: tentar criar um JOB novo preenchendo os campos obrigatórios de sempre — confirmar que os dois campos novos não aparecem/não são editáveis na tela (comportamento atual, antes da correção) e que o save do JOB novo, sem conseguir preencher os dois campos, é bloqueado pela validation rule (efeito colateral do R-01 se a FLS não for corrigida). 3. Atribuir `PS_JST_ClassificacaoDenominacao` ao mesmo usuário de teste. 4. Repetir a criação do JOB, agora preenchendo os dois campos | Passo 2: sem o permission set, o usuário fica impedido de criar JOB novo (risco R-01 confirmado se não mitigado). Passo 4: com o permission set atribuído, o usuário consegue preencher os campos e salvar o JOB normalmente | Não executado nesta sessão | **Pendente (roteiro para humano) — crítico, é o risco de maior severidade do design (R-01, Alta)** |
| R-02 — roll-up em JOB legado | 1. Usando o mesmo registro legado de CA-06 (ou um criado via API com `CreatedDate` anterior ao corte, se nenhum existir), criar um registro filho `Previsao_de_Gastos_do_Treinamento__c` vinculado a esse JOB pai, com o pai ainda com campo(s) vazio(s). 2. Salvar o filho | O save do filho é aceito (não falha), mesmo recalculando os 7 roll-ups do pai — porque o pai é exempto da validation rule pelo `CreatedDate` | Não executado nesta sessão | **Pendente (roteiro para humano) — depende de existir/criar massa de dados legados, ver nota em CA-06** |
| R-02 (espelho) — roll-up em JOB novo | 1. Criar um JOB novo com os dois campos preenchidos (só assim ele consegue existir). 2. Criar um filho `Previsao_de_Gastos_do_Treinamento__c` vinculado a ele | O save do filho é aceito normalmente — o pai já tem os campos preenchidos (é impossível ele existir vazio), então o recálculo de roll-up não aciona a validation rule | Não executado nesta sessão | **Pendente (roteiro para humano)** |
| Volume / carga em massa | Confirmar com o admin do cliente se há processo de data loader/integração que insere `JOB_de_Solicitacao_de_Treinamentos__c` em massa. Se sim, planejar com o cliente que cargas de JOB novo sem os dois campos vão falhar linha a linha (comportamento esperado, R-08 do design, não é bug) | Carga falha linha a linha para registros sem os campos, sem erro de governor limit (validation rule não consome SOQL/DML) | Não executado — depende de confirmação do cliente sobre processos de integração, fora do alcance de metadata/sandbox | **Pendente (roteiro para humano/consultor)** |
| Mensagem de erro (D-08) | 1. Em qualquer dos cenários de bloqueio acima, capturar o texto exato exibido na tela | Mensagem: "Favor preencher os campos antes de enviar para aprovação" (resposta literal do consultor em `comentarios-do-card.md`) | Não executado nesta sessão | **Pendente (roteiro para humano)** |
| Layout — posicionamento | 1. Abrir um JOB qualquer em QA. 2. Confirmar visualmente que Classificação Gerencial e Denominação do Treinamento aparecem na seção "Dados Gerais", após Centro de Custo, como `Edit` (não `Required` pelo layout) | Campos visíveis e editáveis na posição descrita em `04-plano-build.md` seção 3.4 | Não executado nesta sessão. Nota: a posição foi decidida pelo builder sem consultor disponível (`04-plano-build.md` seção 9, item 2) — vale revisão de UI com o cliente, não só funcional | **Pendente (roteiro para humano)** |

---

## O que não é testável nesta sandbox/sessão

- Nenhum teste de UI foi executado de fato: `sbx-somos-agility-qa` não conectada nesta
  sessão, e os componentes também nunca foram deployados de verdade em nenhuma sandbox (só
  `deploy validate`, check-only, em dev).
- Volume real de JOBs legados com campos vazios em produção é desconhecido (`02-recon.md`
  seção 7) — a sandbox de dev tinha 0 registros no objeto. Não foi possível estimar o
  impacto de CA-06/R-04 em escala; isso só é visível com dado de produção, que o agente não
  acessa (guardrail #1).
- Não foi possível confirmar se a sandbox de QA tem FLS/layout/processos de aprovação iguais
  aos de produção (R-03 do design, "data do último refresh não confirmada").

## Encerramento

Testes executados. Preciso da sua homologação para liberar o release.
