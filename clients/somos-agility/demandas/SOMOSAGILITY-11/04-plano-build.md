# SOMOSAGILITY-11 — Plano de build

**Etapa:** 4 (build) · **Autor:** agente `builder-declarativo` · **Data:** 2026-10-21
**Resultado desta etapa: BUILD BLOQUEADO. Nenhum componente foi criado, nenhuma branch foi
aberta, nenhum PR foi aberto, nenhuma org foi tocada.**

---

## 0. Por que este artefato não é um plano de build

O gate `aguardando_gate_design` foi aprovado por Leonardo Barbosa em
2026-10-21T17:14:46 (`gates.md`), com o hash de `02-recon.md` e `03-design.md` batendo com
o que está em disco hoje. Esse gate aprovou a **decisão de nível 0** (carga de dados em
`Status_Backoffice__c`, sem metadata novo).

A própria seção "Encerramento" de `03-design.md` é explícita de que a aprovação do gate é
**uma das três** condições para liberar o build, não a única:

1. Aprovar a decisão de nível 0 — **feito** (gate de 2026-10-21).
2. Responder as perguntas B-1 a B-5 da seção 7.1 — **não feito**, ver §1 abaixo.
3. Decidir R1 e R2 (os dois riscos Alta) — **não feito**, ver §1 abaixo.

Conferi `gates.md`, `comentarios-do-card.md`, `status.yaml` e o anexo liberado na pasta
`anexos/` — não há, em nenhum desses lugares, resposta às cinco perguntas nem decisão sobre
os dois riscos. Prosseguir com o build escolhendo um objeto, um valor de picklist ou uma
decisão de risco por conta própria seria inventar uma solução diferente da que foi
aprovada — o que a instrução deste agente proíbe explicitamente. Portanto, esta etapa para
aqui e reporta o bloqueio.

---

## 1. O que falta, item a item (seção 7.1 de `03-design.md`)

| # | Pergunta | Quem responde | Status |
|---|---|---|---|
| **B-1** | O objeto alvo é `DSA__c`, `Novo_DSA__c` ou os dois? | consultor/negócio, ou a própria planilha | **Sem resposta.** O design recomenda `DSA__c` por inferência de nome e valores de picklist, mas marca isso como leitura, não confirmação. |
| **B-2** | A planilha vai ser entregue? Qual a chave de cruzamento (Id do DSA ou outra) e qual o volume aproximado? | consultor (Juliana Mendes) | **Sem resposta.** Ver §2 — o anexo chegou, mas não pôde ser lido por nenhuma ferramenta desta sessão. |
| **B-3** | Todos os valores da planilha estão entre os 5 atuais do picklist? Se não, quais valores novos (level 1)? | consultor/negócio | **Sem resposta.** Depende do conteúdo da planilha, que não pôde ser lido. |
| **B-4** | R1 (disparo de e-mail em massa via `Notifica_se_DSA_Aprovada_por_Operacoes`): o humano roda o `COUNT()` em prod e escolhe a opção (a/b/c/d) | arquiteto humano + negócio | **Sem resposta.** Nenhum registro de decisão em `gates.md` ou `comentarios-do-card.md`. |
| **B-5** | R2 (recálculo de Valor CIF/FOB via `Atualiza_DSA_com_informacoes_da_PFV`): aceita reescrever o critério de aceite 3? | arquiteto humano (e BA) | **Sem resposta.** O critério de aceite 3 de `01-analise.md` segue como estava, sem reescrita aceita. |

Nenhuma das cinco está marcada em `comentarios-do-card.md`, que só contém registros
mecânicos de aprovação de gate e de estimativa — nenhuma resposta textual de negócio às
perguntas abertas do design.

## 2. O anexo da planilha — tentativa de leitura e resultado

`demandas/SOMOSAGILITY-11/anexos/x39f1n-CONTROLE-LOGISITCA---DSA.xlsx` está presente na
pasta (liberado por delivery como sem dado pessoal). Tentei ler com a ferramenta de leitura
de arquivo disponível nesta sessão e ela recusou com o erro: "This tool cannot read binary
files. The file appears to be a binary .xlsx file." A ferramenta de leitura de documentos
disponível neste ambiente suporta `.md`, `.pdf` e `.docx` — **não suporta `.xlsx`**.

Não há, nesta sessão, nenhuma ferramenta capaz de abrir o conteúdo deste anexo. Seguindo a
instrução recebida, não tentei contornar essa limitação com script, unzip ou parser manual
do formato — o anexo é tratado como **não lido**. Isso significa que B-1, B-2 e B-3 (todas
dependentes do conteúdo da planilha) continuam sem resposta mesmo com o anexo presente.

## 3. O que precisa acontecer para destravar

Pelo menos um destes caminhos, para cada pendência:

1. **Para B-1/B-2/B-3 (conteúdo da planilha):**
   - Alguém de delivery ou o consultor (Juliana Mendes) converte a planilha para um formato
     legível pelas ferramentas desta sessão (CSV ou texto simples) e reanexa ao card, **ou**
   - Alguém cola em texto no comentário do card: o objeto alvo confirmado (`DSA__c` ou
     `Novo_DSA__c`), a chave de cruzamento usada na planilha (Id do DSA ou outra), o volume
     aproximado de registros, e a lista de valores distintos de status presentes na planilha
     (para conferir contra os 5 valores atuais do picklist).
   - Importante: se a planilha tiver colunas com dado de cliente/contato/valor monetário,
     essas colunas não devem ser coladas no comentário nem reanexadas em texto — só o que
     for necessário para resolver B-1/B-2/B-3 (guardrail #2, já registrado em `03-design.md`
     §6).
2. **Para B-4 (risco R1 — e-mail em massa):** o arquiteto humano (ou negócio) roda, em
   produção, a contagem `SELECT COUNT() FROM DSA__c WHERE Status_DSA__c = 'Aprovado' AND
   Notificacao_Enviada__c = false` restrita aos Ids da planilha, e decide entre as opções
   (a) nenhuma ação se der 0, (b) excluir esses registros da carga, (c) desativar o Flow na
   janela da carga, (d) aceitar os e-mails. Essa consulta é contagem agregada em prod feita
   pelo humano — fora do escopo desta sessão de agente (guardrail #1).
3. **Para B-5 (risco R2 — recálculo de CIF/FOB):** o arquiteto humano (e o BA, já que o
   critério de aceite 3 foi aprovado no gate da análise) decide se aceita reescrever o
   critério 3 de `01-analise.md` para "nenhum campo muda além do que a automação existente já
   recalcula em qualquer edição", conforme a recomendação (a) do design.

Com B-1 a B-5 respondidas e R1/R2 decididos, a próxima sessão de build pode prosseguir:
montar o CSV `Id,Status_Backoffice__c` (ou o objeto que for confirmado), rodar a carga em
`sbx-somos-agility-dev` com massa fictícia cobrindo os cenários de R1 a R5 descritos em
`03-design.md` §8, e registrar os componentes/ações nesta mesma seção do plano de build.

---

## 4. O que esta etapa fez e não fez

- **Fez:** leu `demanda.md`, `01-analise.md`, `02-recon.md`, `03-design.md`, `gates.md` e
  `comentarios-do-card.md`; tentou ler o anexo da planilha e confirmou que nenhuma
  ferramenta desta sessão consegue abri-lo; conferiu `status.yaml` para confirmar o estágio
  atual.
- **Não fez (deliberadamente):** não criou branch, não escreveu nenhum componente de
  metadata, não rodou `sf project deploy`, não gerou CSV de carga, não tocou em nenhuma org
  (nem dev nem qa), não escolheu um objeto entre `DSA__c`/`Novo_DSA__c`, não assumiu valores
  de picklist nem volume, e não decidiu R1/R2 em nome do arquiteto humano ou do negócio.

**Build bloqueado. Esta demanda precisa retornar para quem pode responder B-1 a B-5 e
decidir R1/R2 antes de qualquer sessão de build prosseguir.**
