# 03 — Design: SOMOSAGILITY-12

**Tipo:** sustentação, design enxuto
**Base:** `01-analise.md` (aprovado em `gates.md`, Carlos Sordi, 2026-10-20) e `02-recon.md` (coleta de 2026-10-20 em `sbx-somos-agility-dev`)
**Status:** proposta com partes condicionais, declaradas na seção 2. Aguarda o gate do arquiteto humano.

---

## 1. Decisão

**Nível escolhido: configuração + declarativo simples (validation rule). Sem Flow e sem Apex. Sem mudança de modelo de dados.**

1. **Configuração:** colocar `Classificacao_Gerencial__c` e `Denomina_o_do_Treinamento__c` no layout padrão do objeto.
   Hoje eles não estão nesse layout, e é ele que todos os perfis usam.
2. **Configuração:** dar FLS de edição nos dois campos aos usuários que criam JOB e hoje não têm acesso a eles.
3. **Declarativo:** criar uma validation rule em `JOB_de_Solicitacao_de_Treinamentos__c` que bloqueia o save quando um
   dos dois campos está vazio. A regra vale só para registros novos, criados a partir do go-live.

O efeito é que nenhum JOB criado depois do go-live consegue ser salvo sem os dois campos, e portanto nenhum desses JOBs
chega ao botão Submit for Approval sem eles. A mensagem de erro é específica e aparece na tela (atende CA-01 a CA-04).

### Por que não ficar só em configuração (layout com campo Required)
- "Required" no layout só vale para edição pela UI. Não vale para API, data loader ou integração.
- O layout é usado por todos os perfis. Marcar como Required obrigaria também a edição de registros legados, e a
  CA-06 / D-05 dizem que legado não deve ser bloqueado retroativamente.
- Mesmo assim o passo 1 é obrigatório: **sem os campos no layout, a validation rule bloquearia todo mundo sem dar
  como preencher.**

### Por que não alterar o critério de entrada do processo de aprovação (alternativa H-2, não recomendada)
É o único mecanismo declarativo que age **exatamente** na submissão. Mas:
- A mensagem para o usuário vira o erro genérico da plataforma ("nenhum processo de aprovação aplicável"). Ela não diz
  qual campo falta, então CA-01, CA-02 e CA-03 não são atendidos como escritos.
- Teria que mudar os **dois** processos ativos (`JobSTGeral_v2` e `Aprovacao_do_JOB_de_Treinamentos_v7`). Se só o
  primeiro barrar, o registro cai no segundo pelo `processOrder`.
- `JobSTGeral_v2` usa critério por filtro com 15 condições `CreatedBy` em OR. Incluir "e os campos preenchidos" exige
  reescrever o filtro ou passar para critério por fórmula.
- `Denomina_o_do_Treinamento__c` é LongTextArea. **Não confirmei** que LongTextArea pode ser usado em critério de
  entrada de processo de aprovação, e minha expectativa é que não possa (R-05). Se não puder, H-2 é inviável sem
  criar campo auxiliar, e isso é mudança de modelo de dados.

### Por que não Flow nem Apex
- **Um record-triggered Flow com Custom Error não ganha nada em relação à validation rule.** Ele tem o mesmo problema
  de não saber se o save é uma submissão, porque o status default já é `Pendente` (ver 02-recon, seção 2).
- **Apex (trigger before update) também não detecta a primeira submissão.** O field update da submissão grava
  `Pendente` sobre `Pendente`, então nada muda. Para detectar a submissão seria preciso criar um valor de status novo
  ("Não Enviado") e trocar o default, e isso é mudança de modelo de dados (ver seção 6). Além disso, código para uma
  regra de dois campos seria trazer trigger, handler e teste de 85% para uma org que já tem 40% de cobertura
  (assessment, achado #3).

## 2. Dúvidas bloqueantes: o que o recon respondeu e o que continua aberto

| ID | Situação após o recon | Hipótese adotada no design |
|---|---|---|
| **D-01** objeto | **Respondida com evidência, falta confirmar com o consultor.** `JOB_de_Solicitacao_de_Treinamentos__c`. A sigla "JST" aparece literalmente na descrição do processo v7 e nos lookups filhos `JST__c` e `Relacionado_ao_JST__c` (02-recon, seção 1) | **H-D01:** o objeto é o JOB de Treinamentos. Se for o JOB de Investimento, o design é refeito (outros campos, outros processos) |
| **D-02** processo e gatilho | **Parcial.** O gatilho é o botão padrão Submit for Approval. Existem 2 processos ativos e só `JobSTGeral_v2` termina no Walmor | **H-D02:** a regra vale para qualquer JOB, independente de qual processo ele entra. A validation rule não depende do processo, então essa hipótese é a mais barata de manter |
| **D-03** só na submissão ou sempre | **Continua aberta, e não tem resposta técnica neutra.** "Só na submissão" com mensagem específica não é possível de forma declarativa (seção 1) | **H-D03 (recomendada):** obrigatório desde o primeiro save de registros novos. **CA-05 precisa ser reescrito** para "registros criados antes do go-live podem ser salvos com os campos vazios". Se o humano exigir "só na submissão", o caminho é H-2, com as perdas da seção 1 |
| **D-05** legado | Aberta. Volume em produção desconhecido, sandbox com 0 registros | **H-D05:** legado não é bloqueado nem saneado (atende CA-06). **Lacuna aceita:** um JOB legado ainda não submetido pode ser submetido vazio. Fechar essa lacuna exige saneamento (outra demanda) ou H-2 |
| **D-06** usuário sem permissão | Aberta, mas o recon mostra que **o caso existe**: 13 perfis criam JOB sem FLS de edição nos campos, com até 3 usuários ativos afetados na sandbox | **H-D06:** quem pode criar JOB passa a poder editar os dois campos (componente C-3). A alternativa (bloquear quem não tem acesso) impediria esses usuários de criar JOB |
| **D-08** texto da mensagem | Aberta | Texto provisório na seção 3. O consultor pode trocar antes do build sem impacto no design |
| **D-09** anexo de detalhamento | **Continua ausente.** Não existe no repositório e a org não substitui o anexo | **Nenhuma hipótese sobre o conteúdo.** Se o anexo trouxer regra diferente (por exemplo, obrigatoriedade só para um dos processos, ou por valor de `Objetivo__c`), a fórmula da validation rule muda. O desenho em camadas (layout, FLS, regra) continua valendo |

**O que fica bloqueado até as respostas:**
- O **build não começa** sem a confirmação de D-01 (objeto) e uma decisão explícita em D-03 (H-D03 ou H-2).
- O **QA não começa** sem D-05, D-06 e D-08 fechadas, como a análise já previa.
- D-09: se o anexo aparecer depois do gate e mudar a regra, `03-design.md` volta para revisão. O `conferir-gates` vai
  mostrar que o hash mudou.

## 3. Componentes

### Criar
| # | Tipo | API name (proposto) | Detalhe |
|---|---|---|---|
| C-1 | ValidationRule | `JOB_de_Solicitacao_de_Treinamentos__c.JST_Classif_Denominacao_Obrigatorias` | Ver fórmula abaixo. `errorDisplayField` em branco (erro no topo, porque são dois campos). Descrição preenchida citando SOMOSAGILITY-12 |

Fórmula proposta (hipótese H-D03 + H-D05). A data é o go-live real, preenchida no build:
```
AND(
  OR( ISNEW(), CreatedDate >= DATETIMEVALUE("<AAAA-MM-DD> 00:00:00") ),
  OR( ISBLANK( TEXT( Classificacao_Gerencial__c ) ),
      ISBLANK( Denomina_o_do_Treinamento__c ) )
)
```
Mensagem provisória (D-08): *"Preencha Classificação Gerencial e Denominação do Treinamento. Os dois campos são
obrigatórios para enviar o JOB para aprovação da diretoria."*

Por que o recorte por `CreatedDate`:
1. Atende CA-06 (legado não é bloqueado).
2. Evita o risco R-02: salvar um filho `Previsao_de_Gastos_do_Treinamento__c` recalcula os roll-ups e faz o JOB pai legado
   passar pela validation rule. Sem o recorte, um pai legado vazio faria o save do filho falhar.

A data é um literal na fórmula, não um ID. Não fere a regra de "sem hardcode de ID" da `padrao-entrega`.


Também a criar, se a opção (b) da seção 4 for escolhida:

| # | Tipo | API name (proposto) | Detalhe |
|---|---|---|---|
| C-2 | (opcional, depende de decisão humana) PermissionSet | `PS_JST_ClassificacaoDenominacao` | Só FLS de edição em `Classificacao_Gerencial__c` e `Denomina_o_do_Treinamento__c`. Só é necessário se a opção (b) da seção 4 for escolhida |

### Alterar
| # | Tipo | Componente | Mudança |
|---|---|---|---|
| C-3 | Layout | `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos` | Incluir os dois campos com `behavior=Edit`, não `Required`, pelos motivos da seção 1. A posição na tela é decidida no build com o consultor |
| C-4 | FLS | Ver seção 4 | Edição nos dois campos para quem cria JOB |

O layout `...Treinamentos CEO` já tem os dois campos como `Edit` e não está atribuído a nenhum perfil confirmado.
**Não será alterado.**

### Depreciar
Nada.

## 4. Impacto em permissões

13 perfis criam/editam JOB sem FLS de edição nos dois campos (lista em 02-recon, seção 6). Com C-1 ativa, os usuários
desses perfis **não conseguem criar JOB**. Opções, e a escolha é do humano:

- **(a) Editar a FLS dos 13 perfis.** É o mais direto, mas reforça o padrão "perfil por pessoa" que o assessment aponta
  como dívida (achado #6). Deploy de Profile exige cuidado para levar só `fieldPermissions`.
- **(b) Criar `PS_JST_ClassificacaoDenominacao` (C-2)** e atribuir aos usuários afetados. Segue a recomendação do
  assessment. A atribuição a usuário é tarefa do admin do cliente, não do agente, e precisa ser feita também em produção.
- **(c) Atribuir o `jobsAprovacao` existente** aos usuários afetados. **Não recomendado:** o nome sugere poderes de
  aprovação e o conteúdo completo dele não foi inspecionado.

Recomendação: **(b)**.

Os processos de aprovação, os aprovadores e quem pode submeter (`owner`) não mudam.

## 5. Riscos técnicos

| ID | Risco | Severidade | Mitigação |
|---|---|---|---|
| R-01 | **Usuário que cria JOB mas não tem FLS dos campos fica impedido de salvar** (13 perfis, até 3 usuários ativos na sandbox, número de produção desconhecido) | **Alta** | C-4 é pré-requisito de deploy da C-1. As duas vão no mesmo pacote. QA testa com um usuário de perfil afetado |
| R-02 | **Ordem de execução por roll-up: salvar `Previsao_de_Gastos_do_Treinamento__c` recalcula 7 campos Summary no JOB pai, e o pai passa pelas validation rules.** Um pai sem os campos faria o save do filho falhar | **Alta, se não mitigado** | Recorte por `CreatedDate` na C-1. Todo pai criado depois do go-live já nasce com os campos. QA testa explicitamente a inclusão de filho em JOB legado e em JOB novo |
| R-03 | A sandbox pode estar diferente de produção (layouts, FLS, processos). A data de refresh não foi confirmada | Média | `ci-salesforce-validate` (check-only) contra o QA e conferência do humano antes do release. Retrieve do layout em QA antes do build |
| R-04 | Legado ainda não submetido pode ser submetido vazio (lacuna aceita em H-D05) | Média | Declarado. Fechar exige saneamento (outra demanda) ou H-2 |
| R-05 | `ISBLANK` sobre LongTextArea em validation rule: espero que seja suportado, mas não validei com deploy. Em critério de processo de aprovação (H-2), espero que **não** seja suportado | Média | Primeiro passo do build: `sf project deploy validate` da C-1 na sandbox de dev. Se falhar, usar `LEN(Denomina_o_do_Treinamento__c) = 0` |
| R-06 | Validation rules **não** rodam em field updates de processo de aprovação, então a C-1 nunca interfere em aprovar, rejeitar ou fazer recall. Por outro lado, ela também não "vê" a submissão | Baixa (informativo) | Já considerado na decisão |
| R-07 | `Classificacao_Gerencial__c` só tem valores até `Investimento 2026`. Em 2027, um campo obrigatório sem o valor do ano força escolha errada ou trava o usuário | Baixa agora, média a partir de jan/2027 | **Fora do escopo.** Sinalizado para o consultor abrir demanda |
| R-08 | Governor limits e escala | Baixa | Validation rule não consome SOQL nem DML. Não há bulkificação a fazer. Carga em massa (data loader) de JOB novo vai falhar linha a linha se faltar campo, e esse é o comportamento desejado |

**Conflito de automação:** não há Flow, trigger, Process Builder nem outra validation rule no objeto (02-recon, seção 4).
**O único ponto de ordem de execução é o recálculo de roll-up (R-02).**

## 6. Mudança de modelo de dados: não é necessária, mas foi a alternativa considerada

O caminho recomendado **não cria campo e não altera picklist**. As duas alternativas que cumpririam "só na submissão"
com precisão exigiriam mudança de modelo de dados:
- criar um valor `Não Enviado` em `Status_da_Qualifica_o__c` e torná-lo default, para que a submissão vire uma mudança
  de status detectável (afeta relatórios e list views que dependem de `Pendente`); ou
- criar um campo auxiliar (por exemplo, fórmula ou checkbox) para usar no critério de entrada da aprovação, se
  LongTextArea não puder ser usado ali.

**Se o humano decidir por H-2 ou exigir detecção da submissão, a decisão sai da minha alçada e é escalada ao arquiteto
sênior.** Eu não a tomo aqui.

## 7. O que NÃO será feito nesta demanda

- Alterar os processos de aprovação (`JobSTGeral_v2`, `Aprovacao_do_JOB_de_Treinamentos_v7`): critérios, etapas,
  aprovadores, ações.
- Corrigir a etapa 1 do v7, cujo critério `1 AND 2 AND 3` nunca é verdadeiro (só registrado em 02-recon).
- Saneamento ou preenchimento em lote de JOBs legados (D-05).
- Mudar a obrigatoriedade no objeto `JOB_de_Solicita_o_de_Investimento__c`.
- Incluir `Investimento 2027` e posteriores na picklist (R-07).
- Atribuir permission set a usuários (tarefa do admin do cliente) e qualquer ação em produção.
- Mexer no layout `...Treinamentos CEO` ou em outros campos do layout padrão.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Estimativa de esforço

**Estimativa de esforço:** 6–10 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). Validation rule + layout + FLS (e permission set opcional), com teste dos 13 perfis que criam JOB.

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
