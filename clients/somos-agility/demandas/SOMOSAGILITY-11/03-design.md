# SOMOSAGILITY-11 — Desenho da solução (sustentação, design enxuto)

**Etapa:** 3 (arquitetura) · **Autor:** agente `arquiteto` · **Data:** 2026-10-16
**Org usada para confirmação:** `sbx-somos-agility-dev`, sandbox (`Organization.IsSandbox =
true`, reconfirmado nesta etapa via `sf org list` + SOQL em `Organization`) · Org Id
`00DHa0000070wxfMAA` · API v68
**Produção:** não conectada nesta máquina. Nenhum comando desta etapa tocou prod.
**Base:** `01-analise.md` (aprovado no gate de 2026-10-16, Leonardo Barbosa) e `02-recon.md`
(coletado em 2026-10-16, **vence em 2026-10-23**).

**Esta etapa só fez leitura.** Describe, SOQL de metadata e `retrieve` para um projeto DX
temporário em `/tmp` (já removido). Nenhum `deploy`, nem `validate`, nenhuma DML e nada em
`force-app/` deste repositório. Não rodei `deploy validate` porque a decisão abaixo não
cria metadata para validar.

---

## 0. Resumo executivo

1. **Nível 0: operação de dados, sem metadata novo.** O campo já existe
   (`DSA__c.Status_Backoffice__c`, rótulo "Status Logística", picklist com 5 valores, no
   layout e editável por 15 perfis). Pela leitura do recon e desta etapa, a demanda é
   **popular esse campo em massa a partir da planilha**, não construir nada. Só sobe para o
   nível 1 (adicionar valor ao picklist) se a planilha trouxer um status que não está entre
   os 5 atuais.
2. **O objeto alvo não está confirmado.** `DSA__c` é a leitura mais forte, mas só a planilha
   ou alguém do negócio resolve isso. **Bloqueia o build.**
3. **Esta etapa encontrou uma correção ao recon que muda o risco.** O recon concluiu que
   "nenhuma automação ativa toca o campo" e que o risco de efeito colateral era **baixo**. A
   primeira parte está certa: nada referencia `Status_Backoffice__c`. A conclusão, porém, não
   se sustenta. **3 dos 5 Flows after-save de `DSA__c` rodam em qualquer edição do registro,
   qualquer que seja o campo alterado.** Então uma carga que mexe só no status logístico:
   - **pode disparar e-mails em massa** (`Notifica_se_DSA_Aprovada_por_Operacoes`, R1, Alta);
   - **reescreve 4 campos de valor CIF/FOB** a partir da PFV mais recente da Oportunidade
     (`Atualiza_DSA_com_informacoes_da_PFV`, R2, Alta). Isso pode quebrar o critério de
     aceite 3 do BA ("nenhum outro campo é alterado").
4. **5 perguntas bloqueiam o build (§7).** Nenhuma delas o agente consegue resolver.

---

## 1. Decisão: declarativo vs. código

### 1.1 Decisão

**Nível 0: carga de dados num campo existente, sem nenhum componente de metadata.**
Mecanismo: update em massa por Id, via Bulk API (§4). Sem Flow, sem Apex e sem mudança de
layout ou de FLS.

### 1.2 Por que não outro nível

| Nível | Cabe? | Justificativa |
|---|---|---|
| 0 — Só dados | **Sim** (se os 5 valores cobrem a planilha) | O campo, o layout e a FLS já existem (recon §1, §5, §6). A demanda fala em "inclusão das informações ... em massa", e não em criar campo. |
| 1 — Configuração (novo valor de picklist) | **Só condicionalmente** | Só se a planilha trouxer valor fora dos 5. Isso é uma mudança pequena de `CustomField` (`valueSet`) e passa por PR e `deploy validate`. Não é mudança de modelo de dados. |
| 2 — Flow | **Não** | Não há regra de negócio que peça automação (pendência #4 do BA, ainda aberta). Se a recorrência (pendência #5) indicar carga periódica, o design é **reaberto**, não estendido aqui. |
| 3 — Apex | **Não** | Não há callout, transação complexa nem volume que exija Apex. Um batch Apex para fazer um update de picklist seria custo de manutenção sem ganho. |

### 1.3 Escalada: mudança de modelo de dados

**Não há mudança de modelo de dados neste design.** Se a planilha mostrar que o pedido
precisa de um **campo novo** (por exemplo, data de despacho, transportadora ou código de
rastreio) em vez de só o status, isso é mudança de modelo de dados. **Volta ao arquiteto
humano sênior**, não é decidido aqui.

---

## 2. Objeto alvo: leitura e o que falta

| Candidato | Campo | Valores | Automação ativa | Leitura |
|---|---|---|---|---|
| `DSA__c` | `Status_Backoffice__c` ("Status Logística") | Aguardando comercial · Aguardando definição do GP · Aguardando liberação de faturamento · Em andamento · Finalizado | Pesada (§5) | **Candidato mais provável.** O rótulo diz "Logística" e os valores descrevem um fluxo operacional. |
| `Novo_DSA__c` | `Status_backoffice__c` ("Status backoffice") | Valores de aprovação (Aprovado, Rejeitado, Pendente, Recall…) | Nenhuma (recon §3) | Improvável. Os valores não descrevem logística. |

Fonte: `02-recon.md` §1–§3. **Como arquiteto, recomendo `DSA__c`, mas essa recomendação é
uma leitura e não uma confirmação.** Não existe metadata que resolva a dúvida, porque a
resposta está na planilha (que não chegou) ou com o negócio. **O build não começa sem essa
confirmação (B-1).**

Se a resposta for `Novo_DSA__c`, o design fica **mais simples**: não há Flow nem VR ativos,
e R1–R4 abaixo deixam de valer. O que muda é que os valores atuais não servem para
logística, o que provavelmente leva ao nível 1 (novos valores). Nesse caso, reabrir este
documento.

---

## 3. Inventário de componentes

| Ação | Componente | Observação |
|---|---|---|
| Criar | **nenhum** | — |
| Alterar | **nenhum** (no nível 0) | Só se B-3 = "há valor novo": `CustomField DSA__c.Status_Backoffice__c`, com novo `<value>` no `valueSetDefinition`. O picklist é local, não usa Global Value Set (confirmado no retrieve). |
| Depreciar | nenhum | — |
| Dados | `DSA__c.Status_Backoffice__c` em N registros | N é desconhecido, depende da planilha. |

**Permissões:** nenhuma mudança em perfil ou permission set. Há uma condição operacional (R4,
§5): o usuário que executa a carga precisa ter edição no campo (15 perfis têm, recon §6) **e**
conseguir editar registros bloqueados por aprovação.

---

## 4. Mecanismo da carga e o guardrail de produção

| Ambiente | Quem roda | Como | Dados |
|---|---|---|---|
| `sbx-somos-agility-dev` (etapa 4) | agente | `sf data update bulk --sobject DSA__c --file <csv> --target-org sbx-somos-agility-dev` (Bulk API 2.0, confirmado na CLI 2.154.4) | **Fictícios.** A sandbox tem 0 DSAs (recon §7), então a massa precisa ser criada respeitando as 6 VRs ativas. |
| `sbx-somos-agility-qa` (etapas 5/6) | agente executa, humano homologa | mesmo comando, alias `-qa` | Fictícios, ou a planilha **se** ela tiver só Id + status (ver §8). |
| **Produção** | **humano, nunca o agente** | Data Loader (ou o mesmo CSV via `sf`), na janela que o cliente definir | Planilha real |

- **A chave da carga é o `Id` do `DSA__c`.** Se a planilha só trouxer outra chave (nº da
  Oportunidade, nº do pedido), alguém precisa fazer o cruzamento para Id **em produção**, e
  isso é trabalho do humano. O agente não consulta prod e não vê dado real (B-2).
- **CSV mínimo: `Id,Status_Backoffice__c`.** Nenhuma outra coluna. Isso evita sobrescrever
  campos que não estão no escopo.
- **Backup antes da carga em prod (feito pelo humano):** exportar `Id,Status_Backoffice__c`
  dos registros afetados. O campo tem `trackHistory = false` (confirmado no retrieve), então
  sem esse export não há como saber o valor anterior nem fazer rollback.
- **Para prod, recomendo o Data Loader com batch size reduzido (50–100).** O motivo está em
  R6: Bulk API 2.0 não deixa escolher o tamanho do lote.

---

## 5. Automação existente em `DSA__c`: ordem de execução e riscos

**Há automação no mesmo objeto e no mesmo evento (update): 5 Flows after-save, 2 Workflow
Rules ativas, 1 Process Builder ativo, 6 Validation Rules ativas e 2 processos de aprovação
ativos. Isso é risco de ordem de execução, mesmo sem nenhum deles referenciar o campo alvo.**

Confirmado nesta etapa, além do recon:
- **0 Apex triggers** em `DSA__c`/`Novo_DSA__c` (o recon não tinha consultado).
- **6 VRs ativas, e não 7** como o recon dizia. As fórmulas foram lidas e **nenhuma
  referencia `Status_Backoffice__c`**.
- **4 Workflow Rules** (o recon não cobriu): 2 ativas, `DSA Premium Plus` (só na criação) e
  `Notificar Premium Plus DSA Subs`. Nenhuma referencia o campo.
- **Process Builder:** dos 59 ativos na org, só `Pedido_Urgente` é de `DSA__c`. Ele só entra
  quando `Pedido_Urgente__c` muda, então não é afetado.
- **Flows after-save:** os 5 foram relidos olhando a **condição de entrada**, que o recon não
  tinha avaliado:

| Flow | Condição de entrada | Exige mudança? | Roda numa carga só de status? |
|---|---|---|---|
| `Atualiza_DSA_com_informacoes_da_PFV` | **nenhuma** | não | **Sim, em todo registro** |
| `Atualiza_DSAs_com_Status_de_Aprovacao_e_Etapas` | `Status_DSA__c` não nulo | não | **Sim**, mas regrava `Status_de_Aprovacao_e_Etapas__c` a partir de `Status_DSA__c`, que não muda (idempotente) |
| `Notifica_se_DSA_Aprovada_por_Operacoes` | `Status_DSA__c = Aprovado` e `Notificacao_Enviada__c = false` | não | **Sim, se o registro atender** |
| `DSA_Cancelado` | `ISCHANGED(Status_DSA__c)` | sim | Não |
| `DSA_Recall` | `Status_DSA__c = Recall`, só quando passa a atender | sim | Não |

### R1 — Disparo de e-mails em massa · Severidade **Alta** (probabilidade desconhecida)

`Notifica_se_DSA_Aprovada_por_Operacoes` dispara até 11 `emailAlert`s, para destinatários
fixos e para `Email_Contratos__c`/`Email_Governanca__c`, e depois marca
`Notificacao_Enviada__c`. Ele roda em **qualquer** update de um DSA aprovado que ainda esteja
com `Notificacao_Enviada__c = false`. Pode haver DSAs aprovados que nunca foram marcados, por
exemplo registros de antes do Flow existir ou com `Picklist_Notificacao__c` vazio. Nesse caso
a carga gera uma rajada de e-mails reais em produção para contratos e governança.

- **O que precisa ser medido (só em prod, só pelo humano, contagem agregada, guardrail #2
  ok):** `SELECT COUNT() FROM DSA__c WHERE Status_DSA__c = 'Aprovado' AND
  Notificacao_Enviada__c = false`, restrito aos Ids da planilha.
- **Opções:** (a) a contagem dá 0 e não há o que fazer; (b) tirar esses registros da carga;
  (c) desativar o Flow durante a janela da carga em prod. É mudança em prod, feita pelo
  humano, com o risco de esquecer de reativar; (d) aceitar os e-mails.
- **Recomendação:** medir antes. Se der > 0, (b) ou (c) é decisão do negócio (B-4). Não
  recomendo (d) sem o negócio saber o que vai disparar.
- Incerteza: não confirmei o caminho exato do Flow quando `Picklist_Notificacao__c` está
  vazio (nenhuma regra casa). O QA cobre isso com massa fictícia.

### R2 — Valores CIF/FOB recalculados como efeito colateral · Severidade **Alta** para o critério de aceite 3

`Atualiza_DSA_com_informacoes_da_PFV` busca o `Produto_da_Proposta_de_Solucao__c` **mais
recente** da Oportunidade do DSA e regrava `Valor_CIF__c`, `Valor_CIF_Moeda__c`,
`Valor_FOB__c` e `Valor_FOB_Moeda__c` no próprio DSA, **em toda edição**. Duas consequências:
- se a PFV mudou desde o último save do DSA, a carga **muda valores monetários** sem
  ninguém pedir;
- se não houver PFV, a busca está com `assignNullValuesIfNoRecordsFound = false` e o update
  referencia campos de um registro nulo. **Pode zerar os 4 campos.** Não confirmado, o QA
  precisa provar.

Ponto importante para o humano: **isso já acontece hoje em qualquer edição manual de um DSA
pela tela.** A carga não cria o comportamento, ela o aplica de uma vez a N registros. Mesmo
assim, o critério de aceite 3 do BA, como está escrito, **não é garantível** sem mexer no
Flow, e mexer no Flow está fora do escopo.

- **Opções:** (a) aceitar e reescrever o critério 3 como "nenhum campo muda **além do que a
  automação existente já recalcula em qualquer edição**"; (b) desativar o Flow na janela da
  carga (mesmo problema de R1(c)); (c) abrir uma demanda separada para o Flow só rodar quando
  a Oportunidade ou a PFV mudar.
- **Recomendação:** (a) nesta demanda e (c) como achado à parte. O Flow sem condição de
  entrada é um problema do objeto, não desta carga (B-5).

### R3 — Registros legados que já violam VR · Severidade **Média**

VR é avaliada contra o registro inteiro em todo update. `Valida_Opp_Ganha_Parceiro`,
`Oportunidade_e_psl_obrigatorios`, `Checa_Multiano_e_Prazo`, `Checa_FCP_F5_e_Prazo` e
`Motivo_Processamento_Urgente` vão **recusar** DSAs antigos que estiverem fora dessas regras,
mesmo que a carga só altere o status logístico. A Bulk API tem sucesso parcial por registro:
as linhas com erro voltam num arquivo, e o resto entra.
- **Recomendação:** não desligar VR. O humano revisa o arquivo de erros e decide caso a caso.
  Isso entra no plano de build como passo explícito.

### R4 — Registros bloqueados por aprovação · Severidade **Média**

`DSA_versao_simplificada_Reno` e `DSA_versao_simplificada_v2` estão ativos com
`recordEditability = AdminOrCurrentApprover`. DSAs em aprovação pendente só podem ser
editados por quem tem "Modify All Data" ou "Modify All" no objeto, ou pelo aprovador atual.
- **Recomendação:** quem roda a carga em prod precisa ter essa permissão. Caso contrário,
  esses registros falham e aparecem no arquivo de erros.

### R5 — Picklist não restrito · Severidade **Média**

O XML do campo não tem `<restricted>true</restricted>`. Pela API, **qualquer texto é aceito**:
um erro de digitação ou de acento na planilha ("Aguardando definicao do GP") entra como valor
inativo, e ninguém percebe.
- **Recomendação:** validar a coluna da planilha contra os 5 valores exatos antes de
  qualquer carga. Isso entra no plano de build. Tornar o picklist restrito é uma melhoria
  válida, mas **fica fora** desta demanda (mudaria o comportamento de outras entradas e
  integrações que esta etapa não mapeou).

### R6 — Recursão e CPU em volume · Severidade **Baixa a Média** (depende do volume, desconhecido)

3 Flows after-save fazem update no `$Record`, o que provoca novos ciclos de save no mesmo
registro (VRs, workflow e flows reavaliados). `Atualiza_DSA_com_informacoes_da_PFV` faz uma
busca por registro. O motor de Flow agrupa em lote, então não há SOQL-em-loop clássico, mas o
custo de CPU por lote de 200 é alto num objeto tão carregado. Sem volume conhecido, não dá
para medir.
- **Recomendação:** batch size reduzido em prod (§4) e uma rodada em QA com volume parecido
  com o da planilha (ver §8).

### R7 — Workflow cross-object · Severidade **Baixa**

`Notificar Premium Plus DSA Subs` (`onCreateOrTriggeringUpdate`) usa critérios em
`Opportunity`. Se a Oportunidade mudou desde o último save do DSA, o update da carga pode
fazer o registro "passar a atender" e disparar o alerta. É um caso de borda e é mitigado pela
mesma revisão de R1.

---

## 6. LGPD (guardrail #2)

- **O dado da carga não é pessoal.** `Status_Backoffice__c` é um status operacional de um
  documento comercial (DSA), com valores fixos e sem nenhum dado de pessoa física. Um CSV
  `Id,Status_Backoffice__c` não carrega CPF, e-mail, telefone nem valor monetário.
- **O que pode ter dado pessoal ou de negócio é a planilha original.** Se ela vier com
  colunas de cliente, contato ou valor (o que é comum em planilha de logística), essas colunas
  **não entram no repositório nem no contexto do agente**. Só o CSV reduzido a
  `Id,Status_Backoffice__c` pode ser anexado à demanda.
- **Os e-mails de R1** iriam para destinatários reais em prod. Isso não é vazamento, mas é
  comunicação não pedida, e entra na decisão B-4.
- As queries desta etapa foram só de metadata. Não houve nenhuma leitura de registro: a
  contagem é 0 na dev.

---

## 7. Perguntas abertas

### 7.1 BLOQUEIAM o build

| # | Pergunta | Quem responde |
|---|---|---|
| **B-1** | O objeto alvo é `DSA__c`, `Novo_DSA__c` ou os dois? | consultor/negócio, ou a própria planilha |
| **B-2** | A planilha vai ser entregue? Qual a chave de cruzamento (Id do DSA ou outra) e qual o volume aproximado? | consultor (Juliana Mendes) |
| **B-3** | Todos os valores da planilha estão entre os 5 atuais? Se não, quais valores novos (isso leva ao nível 1)? | consultor/negócio |
| **B-4** | R1: o humano roda o COUNT em prod e escolhe a opção (a/b/c/d) | arquiteto humano + negócio |
| **B-5** | R2: aceita reescrever o critério de aceite 3 (opção a)? | arquiteto humano (e BA, já que o critério foi aprovado no gate da análise) |

### 7.2 NÃO bloqueiam o build

- Recorrência (pendência #5 do BA). Se for recorrente, reabrir o design numa demanda nova.
- Prefixo e convenção do cliente: não se aplica, porque nada é criado no nível 0.
- R3/R4/R6 se resolvem na operação (arquivo de erros, usuário com permissão, batch size).
- Quem roda a carga em prod e quando: é janela do cliente, fora da esteira.

---

## 8. Validação em QA (o que a etapa 5 precisa provar)

1. Massa fictícia em `DSA__c` cobrindo: aprovado com `Notificacao_Enviada__c = false` (R1),
   DSA com e sem PFV na Oportunidade (R2), registro em aprovação pendente (R4) e registro que
   viola uma VR (R3).
2. Carga só com `Id,Status_Backoffice__c`, depois comparar campo a campo antes e depois.
   Os efeitos de R2 precisam ficar documentados.
3. Confirmar se houve e-mail disparado. Na sandbox, ver o deliverability e o log de e-mail.
4. Linha com valor fora da lista (R5), para provar que a API aceita e justificar a validação
   prévia da planilha.

---

## 9. O que NÃO será feito nesta demanda

- Nenhuma mudança em Flow, VR, Workflow, PB ou processo de aprovação de `DSA__c` (achados
  R2/R5 vão para demanda separada, se o humano quiser).
- Nenhum campo novo e nenhuma mudança de layout, FLS ou permission set.
- Nenhuma automação recorrente de carga.
- **Nenhuma carga em produção pelo agente.** A esteira para em QA (guardrail #1).
- Limpeza das 32 VRs inativas e dos 15 Record Types inativos de `DSA__c`. Isso é contexto do
  achado #8 do assessment, não desta demanda.

---

## 10. Plano de deploy e rollback

- **Deploy de metadata:** nenhum no nível 0. Se B-3 levar ao nível 1: PR com o `CustomField`,
  `ci-salesforce-validate.yml` (check-only), deploy em dev e depois em qa. O rollback é
  desativar o valor novo, nunca apagar, para não perder dado já carregado.
- **Carga:** dev (massa fictícia), depois qa (homologação humana), depois prod (humano).
- **Rollback da carga:** recarregar o export de backup `Id,Status_Backoffice__c` (§4). Esse
  rollback **não desfaz** os efeitos colaterais de R1 (e-mail enviado) nem de R2 (valores
  CIF/FOB regravados). Esse é o motivo de B-4 e B-5 bloquearem.

---

## 11. Incertezas declaradas

- O objeto alvo é inferido (§2), não confirmado.
- O comportamento de `Atualiza_DSA_com_informacoes_da_PFV` sem PFV (zerar ou não os
  campos) foi lido no XML e não foi executado.
- O caminho de `Notifica_se_DSA_Aprovada_por_Operacoes` com `Picklist_Notificacao__c` vazio
  não foi confirmado.
- O volume e a distribuição dos registros em prod são desconhecidos (a dev tem 0 registros).
  R1/R6 dependem disso.
- O recon vence em 2026-10-23. Se o build começar depois disso, refazer a checagem de
  automação de `DSA__c`.
- Não mapeei integrações externas que gravam em `DSA__c` (o briefing do cliente está vazio
  nessa seção).

---

## Encerramento

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o
build. Para liberar, é preciso:

1. **Aprovar a decisão de nível 0** (carga de dados, sem metadata), ou nível 1 se B-3 indicar
   valor novo.
2. **Responder B-1 a B-5** (§7.1). Em especial, confirmar o objeto alvo e garantir que a
   planilha (reduzida a `Id,Status_Backoffice__c`) chegue à demanda.
3. **Decidir R1 e R2**, os dois riscos Alta que esta etapa encontrou além do recon.

## Estimativa de esforço

**Estimativa de esforço:** 6–12 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). Carga de dados no nível 0 (sem metadata nova), com massa fictícia respeitando 6 validation rules e homologação; sobe se a planilha trouxer valor novo de picklist ou carga recorrente.

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
