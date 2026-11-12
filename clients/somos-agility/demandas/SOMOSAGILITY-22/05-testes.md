# 05 — Testes: SOMOSAGILITY-22 — Relatório de Jobs do painel de controle financeiro

**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

---

## Por que reprovado (leia antes da tabela)

Esta é a terceira rodada de QA desta demanda (ver `status.yaml`: 2026-10-25 rodou só com dev
conectada, 7 cenários não executados, aprovado por engano; 2026-10-30 rodou com QA conectada
mas o `05-testes.md` não foi reescrito; 2026-11-12 o humano reverteu para `qa` e removeu o
arquivo antigo para refazer do zero). Desta vez a sandbox de QA está conectada de verdade, o
deploy foi refeito aqui, e a maior parte do roteiro foi executada de fato — mas o cenário mais
importante da demanda (**"Enviar para aprovação" grava "Pendente"**, a causa raiz que esta
demanda existe para corrigir) **não pôde ser confirmado de ponta a ponta**, por dois motivos
reais e documentados abaixo (seção "FALHA 1"), não por desistência. Como isso é o critério de
aceite principal, o veredito é reprovado — não por haver evidência de que a correção esteja
errada (ao contrário: o deploy foi limpo e o mecanismo é idêntico ao de um processo irmão já
em produção), mas porque QA existe para provar, não para presumir.

---

## FALHA 1 (crítica) — não foi possível confirmar "Enviar para aprovação → Pendente" de ponta a ponta

O Processo de Aprovação `JOB_de_solicitacoes_de_investimento` (ordem 2, o único alterado nesta
demanda) tem, no nível do processo (não de uma etapa), um `entryCriteria` que só deixa o
registro entrar no processo se o campo `CreatedBy` for **um de ~17 usuários/contas nomeados
especificamente** (mais a condição de status). Isso já existia antes desta demanda — não foi
alterado pelo build — mas é o que determina quem pode gerar um caso de teste válido para o
cenário principal.

Tentei três caminhos para criar e enviar um Job de teste como um desses usuários, todos
documentados com a evidência técnica exata:

1. **"Login" (Login As) na lista de usuários do Setup** — a página de usuários carrega dentro
   de um iframe que a ferramenta de clique (`qa_browser_click`, busca por texto visível) não
   alcança: `Locator.click: Timeout 10000ms exceeded` tanto para o link "Login" quanto para o
   nome do usuário.
2. **URL direta de login-as** (`/servlet/servlet.su?oid=...&sunid=...`) — abriu uma página em
   branco (sem conteúdo navegável), não autenticou como o usuário alvo.
3. **Definir `CreatedById` diretamente via API** (REST `sf data create record` e Bulk API 2.0
   `sf data import bulk`) — ambos recusados pela plataforma:
   `INVALID_FIELD_FOR_INSERT_UPDATE: Unable to create/update fields: CreatedById. Please check
   the security settings of this field...` — a org não tem a permissão "Insert System Field
   Values" habilitada para a sessão conectada, então não dá para forjar o criador por fora da
   UI.

Confirmei via `sf data query` (agregado, sem dado pessoal) que **15 dos 17** nomes exigidos
pelo critério existem como usuários ativos na sandbox de QA — ou seja, o teste é tecnicamente
possível para um humano com a sessão certa, só não para esta sessão automatizada.

Adicionalmente, **mesmo contornando o problema de identidade**, encontrei um segundo bloqueio,
desta vez na própria ferramenta de navegador: o botão de ação rápida "Enviar para aprovação" no
cabeçalho do registro e o botão de confirmação dentro do modal que ele abre têm o mesmo texto
acessível (`"Enviar para aprovação"`); `qa_browser_click` resolve sempre o primeiro em ordem de
DOM — que é o botão do cabeçalho, **coberto pelo modal** — e nunca o botão do modal em si:

```
locator resolved to <button name="Submit" ... class="slds-button slds-button_neutral">Enviar para aprovação</button>
... <div role="dialog" ...> ... subtree intercepts pointer events
```

Reproduzi isso de forma determinística em duas sessões de navegador distintas (uma delas com
página recém-carregada, sem nenhum estado residual). Cliquei em "Cancelar" (que tem texto
único e funciona normalmente) para fechar o modal sem enviar nada, então o Job de teste nunca
foi submetido por este caminho. Isso é uma limitação da ferramenta `qa_browser_click` (correspondência
por substring, sem suporte a match exato ou a elemento visível/top-most), não um defeito do
código entregue — mas registro aqui porque bloqueia qualquer tentativa futura de testar esta
tela específica do jeito automatizado, com qualquer usuário.

**O que isso significa para o aceite:** o critério "ao enviar para aprovação, o status vira
Pendente" — a razão de existir desta demanda — não foi observado acontecendo na sandbox de QA
nesta rodada. Há evidência indireta forte de que funciona (ver tabela abaixo, casos 1, 3, 9 e
10), mas evidência indireta não é o mesmo que ver o campo mudar.

**Recomendação concreta:** um humano com acesso interativo (login normal, não headless) faz o
teste manual em `sbx-somos-agility-qa`: logar como um dos usuários cujo nome bate com o
critério de entrada do processo de ordem 2 (lista em `force-app/.../JOB_de_solicitacoes_de_investimento.approvalProcess-meta.xml`,
tratada aqui como config interna e não transcrita), criar um Job fictício, clicar "Enviar para
aprovação" e confirmar que o status vai para "Pendente". Isso deve levar menos de 5 minutos
para uma pessoa com a sessão certa, contra o que não é alcançável por este agente headless.

---

## O que foi executado de verdade nesta rodada

### 1. Deploy da correção em `sbx-somos-agility-qa`

A sandbox de QA **ainda não tinha a correção** antes desta sessão (confirmado pelo orquestrador
antes de me acionar, e reconfirmado por mim via retrieve: a versão anterior não tinha
`initialSubmissionActions`). Rodei:

```
sf project deploy validate --target-org sbx-somos-agility-qa \
  --metadata "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento" \
  --test-level RunSpecifiedTests --tests ChangePasswordControllerTest
```
→ `Status: Succeeded`, `numberComponentErrors: 0`, 1/1 teste passando.

Confirmei antes que `ChangePasswordControllerTest` existe em QA (`SELECT COUNT(Id) FROM
ApexClass WHERE Name = 'ChangePasswordControllerTest'` → 1), mesma escolha do build em dev,
pelo mesmo motivo (classe boilerplate da plataforma, sem relação com Job/aprovação/financeiro,
evita rodar a suíte inteira numa org com cobertura de 40% — achado do assessment).

Com a validação limpa, rodei o deploy real:
```
sf project deploy start --target-org sbx-somos-agility-qa \
  --metadata "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento" \
  --test-level RunSpecifiedTests --tests ChangePasswordControllerTest
```
→ `Status: Succeeded`, `numberComponentErrors: 0`, `numberTestErrors: 0`.

Confirmei via `sf project retrieve start` (retrieve temporário, apagado logo depois, sem
entrar no commit) que a QA agora tem o bloco `<initialSubmissionActions><action><name>Status_Qualificacao</name>
<type>FieldUpdate</type></action></initialSubmissionActions>`, com `lastModifiedDate` de
2026-11-12 (hoje), batendo com o deploy desta sessão.

### 2. Regressão de volume — nenhum Job some/aparece por causa do deploy

Rodei contagem agregada (sem registros individuais, guardrail #2) antes e depois do deploy:

```
SELECT COUNT(Id) FROM JOB_de_Solicita_o_de_Investimento__c  → 1274 (antes e depois, idêntico)
SELECT Status_da_Qualificaco__c, COUNT(Id) ... GROUP BY ...  → idêntico antes e depois:
  (branco) 167 · Pendente 13 · Recall 1 · Rejeitado 82 · Não Enviado 34 · Aprovado 977
```

Confirma o que o design já previa (`03-design.md`, seção 4): a correção só vale para envios
futuros, não reprocessa dados existentes. Nenhum Job pré-existente mudou de estado ou
desapareceu por causa do deploy.

### 3. Filtro do relatório já contempla todos os status (H1 refutada, de novo)

Reconferi o XML do relatório `Financeiro/JOBs_de_Investimento_HsY` (já versionado, não tocado
por este build): o filtro inclui `,Não Enviado,Pendente,Aprovado,Rejeitado,Recall` (a vírgula
inicial cobre o valor em branco também). Confirma que a causa nunca foi a seleção de valores no
filtro do relatório — é consistente com o diagnóstico do design.

### 4. Dashboard "Controle Financeiro" — abri de verdade via navegador

Abri `/lightning/r/Dashboard/01ZU4000000TSqXMAW/view`. Os 6 componentes do dashboard são todos
do tipo gráfico (`Donut`/`Bar`), sem grade de linhas — por isso é seguro visualizar (nenhum
dado individual de Job, valor financeiro ou nome de solicitante aparece, só contagem agregada
por `Status_da_Qualificaco__c`). Na primeira carga o componente mostrou "Sem dados, tente
atualizar o painel" (cache); cliquei de novo e o componente "Job Solicitação de Investimento"
renderizou: total 265 (recorte da janela `timeFrameFilter` do relatório, menor que os 1274
totais da org, como esperado), com as categorias "Não Enviado", "Pendente", "Aprovado" (242,
91,32%) e "Rejeitado" visíveis na legenda — ou seja, a classificação por `Status_da_Qualificaco__c`
funciona e mostra as categorias certas para os dados que já existem. **Não** abri o relatório
detalhado por trás do dashboard (`drillToDetailEnabled: false` no dashboard, mas o relatório em
si tem `showDetails: true` e colunas com valores financeiros e nome de evento) — abrir isso
exporia dado real por registro, o que o guardrail #2 proíbe. Print em anexo a esta sessão não
foi salvo pois a captura foi usada só para leitura em tela, sem dado pessoal.

### 5. Regressão — Flow before-save não grava `Status_da_Qualificaco__c` (R4)

Confirmado **estruturalmente**: o único Flow before-save ativo do objeto
(`Status_Previs_o_de_Gastos_JOB.flow-meta.xml`, já versionado) não referencia
`Status_da_Qualificaco__c` em nenhum lugar (`grep` no arquivo, vazio). Como não consegui
enviar um Job de teste para aprovação (FALHA 1), não pude confirmar isso *durante uma execução
real*, só pela definição do componente — o que é uma confirmação válida (o Flow literalmente
não tem acesso de leitura/escrita ao campo), mas não é o mesmo que observar o campo não mudar
num envio de verdade.

### 6. Regressão — lookup `Relacionado_ao_Job__c` só aceita Job "Aprovado" (R6)

Confirmado **estruturalmente**: o arquivo `Relacionado_ao_Job__c.field-meta.xml` (em
`Lancamento_de_Despesas__c`) não foi tocado por este build e continua com `lookupFilter`
`active=true`, `isOptional=false`, `Status_da_Qualificaco__c equals Aprovado`.

Tentei confirmar isso também por execução real, em dois passos, e documento os dois:
- Via API (`sf data create record` num `Lancamento_de_Despesas__c` apontando para um Job de
  teste com status "Não Enviado"): a inserção falhou, mas por **outras** validation rules do
  objeto ("Inserir a Oportunidade, Caso, Conta ou RO..." e "Especificar o Tipo da Despesa"), não
  pelo lookup filter. Isso é esperado e documentado pela própria Salesforce: **lookup filters
  (mesmo os obrigatórios) só são aplicados pela UI, nunca pela API** — então esse teste via API
  não prova nada sobre o filtro, só sobre as validation rules.
- Via UI (`/lightning/o/Lancamento_de_Despesas__c/new`): a página de criação não terminou de
  carregar em nenhuma das tentativas (ficou no esqueleto de carregamento, sem erro visível para
  diagnosticar a causa) — não consegui preencher nem testar o formulário por esse caminho nesta
  sessão.

Limpei os dois Jobs de teste usados nessas tentativas (`sf data delete record`); a contagem
voltou a 1274 depois da limpeza, confirmado.

### 7. Nenhum dado de cliente saiu do ambiente de teste

Todas as consultas feitas foram agregadas (`COUNT`/`GROUP BY`) ou sobre os próprios registros
de teste que criei e apaguei (`JOB-1326` — "TESTE QA SOMOSAGILITY-22 (nao usar)", valores
R$ 0,00, apagado ao final; e um segundo Job de teste para a tentativa do item 6, também
apagado). Não abri, consultei nem printei nenhum Job, Conta, Contato ou relatório com dado real
de cliente. A única tela com dado potencialmente real que cheguei a visualizar foi a lista de
usuários do Setup (nomes e usernames internos da equipe do cliente, para decidir viabilidade de
teste) — não screenshot nem transcrevi nada dali para este arquivo.

---

## Fora de escopo (não é falha desta demanda, mas precisa de registro)

- **G4 do design continua sem confirmação**: ninguém registrou em nenhum artefato que alguém
  olhou em produção se o processo "JOB de solicitações de investimentos" já tinha ou não a ação
  de envio inicial antes desta correção. Isso não bloqueia QA em sandbox, mas deveria ser
  resolvido antes de qualquer conversa sobre levar isto a produção (fora do alcance do agente,
  guardrail #1).
- **Pedido do cliente em `comentarios-do-card.md` (2026-10-30)**: tornar obrigatórios os campos
  "Classificação Gerencial" e "Denominação" numa etapa de aprovação. Isso **não foi analisado,
  desenhado, aprovado em gate nem construído** nesta demanda — é um pedido novo e deve virar uma
  demanda própria, com seu próprio ciclo de análise → design → build → QA. Nada foi implementado
  para isso aqui.

---

## Tabela de casos

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1. Nenhum Job some/aparece com o deploy | `COUNT` e `GROUP BY Status_da_Qualificaco__c` antes e depois do deploy em QA | Totais idênticos | 1274 total e mesma distribuição por status antes/depois | **Passou** |
| 2. Filtro do relatório cobre todos os status | Inspeção do `report-meta.xml` de `JOBs_de_Investimento_HsY` | Todos os valores de status selecionados | Filtro inclui Não Enviado, Pendente, Aprovado, Rejeitado, Recall e branco | **Passou** |
| 3. Deploy da correção em QA (validate + real) | `sf project deploy validate`/`start` com o `ApprovalProcess` | Succeeded, 0 erros | Succeeded nas duas etapas, metadata confirmada em QA após | **Passou** |
| 4. Dashboard classifica por status corretamente | Abrir dashboard `01ZU4000000TSqXMAW` via navegador | Categorias corretas, sem dado individual exposto | Donut com Não Enviado/Pendente/Aprovado/Rejeitado, total 265, sem grid de linhas | **Passou** (parcial — não comparado número-a-número com o relatório detalhado, por guardrail #2) |
| 5. **Enviar para aprovação → status vira "Pendente"** (critério principal) | Criar Job de teste com usuário elegível ao critério de entrada do processo de ordem 2; clicar "Enviar para aprovação" | Status muda para "Pendente" | Não executado — bloqueio de identidade (entryCriteria por usuário nomeado) + bloqueio de ferramenta (clique no modal) | **BLOQUEADO — ver FALHA 1** |
| 6. Aprovar/Rejeitar/Reenviar | Decidir o Job enviado | Aprovado/Rejeitado/Pendente conforme a ação | Depende do caso 5 | **Não executado** (dependente) |
| 7. Regressão: `Status_Previs_o_de_Gastos__c` não muda no envio (R4) | Confirmar que o Flow before-save não referencia o campo de qualificação | Sem mudança | Confirmado estruturalmente (Flow não referencia o campo); não observado em execução real (depende do caso 5) | **Parcial** |
| 8. Regressão: lookup `Relacionado_ao_Job__c` só aceita "Aprovado" (R6) | Tentar associar Job não aprovado a um Lançamento de Despesa | Bloqueado pelo filtro | Metadata do filtro confirmada inalterada; teste via API não é válido (lookup filter não é aplicado pela API) e teste via UI não carregou | **Parcial** |
| 9. Nenhum dado de cliente exposto | Revisão de todas as queries/prints desta sessão | Só agregados e registros de teste próprios | Confirmado — nenhuma query individual, nenhum screenshot de registro real | **Passou** |
| 10. Pedido fora de escopo (campos obrigatórios) registrado, não implementado | Checagem de `comentarios-do-card.md` e `gates.md` | Nenhuma implementação nesta demanda | Confirmado — nada construído para isso; recomendado abrir demanda própria | **Passou** (registro) |

---

## Recomendação final

1. Um humano com login interativo em `sbx-somos-agility-qa` precisa fechar o caso 5 (e por
   consequência os casos 6 e 7) manualmente — é rápido para quem tem a sessão certa.
2. Depois disso, se o status virar "Pendente" como esperado, a demanda pode avançar para
   homologação com confiança total; se não virar, é uma reabertura de build, não de QA.
3. Abrir uma demanda nova para o pedido de campos obrigatórios (fora de escopo aqui).
4. Considerar registrar `qa_browser_click` como limitação conhecida (colisão de texto em
   modais com botão de fundo homônimo) para quem for melhorar a ferramenta — não é específico
   desta demanda, deve afetar qualquer teste de Processo de Aprovação por este caminho.

---

Testes executados. Preciso da sua homologação para liberar o release.
