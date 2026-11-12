# 04 — Build (NÃO EXECUTADO)

**Este arquivo não é um plano de build.** É o registro de que a etapa de build foi
interrompida antes de começar, porque o design aprovado (`03-design.md`, seção 10)
exige quatro decisões humanas (G1–G4) como pré-requisito explícito do build, e
nenhuma delas está registrada em artefato nenhum no disco. Nenhuma branch foi criada,
nenhuma metadata foi escrita, nenhum deploy foi feito contra `sbx-eplast-dev`.

## O que foi conferido antes de parar

- `status.yaml`: estágio `build`, transição de `aguardando_gate_design` → `build`
  aprovada por Carlos Sordi em 2026-11-12T03:34:43.
- `gates.md`: hash do gate bate com `02-recon.md`/`03-design.md` em disco hoje — o
  gate em si é válido e corresponde ao conteúdo atual. **Isso autoriza a transição de
  etapa, não substitui as decisões G1–G4 que o próprio design diz serem pré-requisito
  do build** (`03-design.md` §10: "O build **não começa** sem G1 a G4").
- `comentarios-do-card.md`: só duas entradas, ambas notificações genéricas de
  aprovação de gate ("Aprovou o gate X. Entrou na fila da esteira"). Nenhuma resposta
  a G1–G9 ou Q1–Q19.
- `demanda.md`: confirma que a Onda 3 (Comercial, onde esta demanda vive) está
  "ainda não contratada no projeto atual (Ondas 1–2)" — o próprio ponto de G1, não
  uma resolução dele.
- `contrato.md`: escopo contratado é Ondas 1–2 (120h); Onda 3 (Comercial) listada
  como não contratada. Consistente com G1 em aberto.
- `CLAUDE.md` do cliente: template vazio, sem convenção ou decisão registrada que
  resolva G1–G4.
- `assessment.md`: saúde geral vermelha; achado nº1 (automação concorrente em
  Account/Opportunity/Order) e nº3 (Validation Rules de Order com máquina de
  estados abandonada) reforçam que G4 (definição de "compra"/Order.Status) não é
  trivial nem segura de assumir sem confirmação explícita — a org já tem três
  definições divergentes de "sem compra" (`Inactive__c`, dois cenários distintos de
  `SFAgent2_v4`), e o design é explícito: "Esta demanda não pode criar uma quarta."
- Grep por `G1|G2|G3|G4|SFAgent2|eplast-ent-11|regra de compra` em todo
  `demandas/EPLAST-33/` e na raiz do cliente: únicas ocorrências são dentro de
  `01-analise.md`, `02-recon.md`, `03-design.md` (onde as perguntas são levantadas)
  e `contrato.md` (confirmação do escopo da Onda 3). Nenhuma resposta.

## Decisões pendentes (bloqueiam 100% do build)

| Gate | Pergunta | Quem decide | O que desbloqueia |
|---|---|---|---|
| **G1** | A Onda 3 está autorizada a entrar em esteira? (Onda 3/Comercial não está no escopo contratado atual — Ondas 1–2, conforme `contrato.md`) | Comercial/contrato do cliente | Todo o build |
| **G2** | EPLAST-33 é demanda própria, extensão de `eplast-ent-11`, ou parte do `SFAgent2` (`eplast-ent-09/10`)? | Arquiteto/Comercial | Todo o build; muda as horas (recuperação pode sair desta demanda) |
| **G3** | Canal: relatório/lista (Fase 1 como descrita) ou assistente de IA (Fase 1 vira conferência, regras migram para opção B)? | Comercial | Todo o build — define se Fase 1 é relatório ou conferência |
| **G4** | Definição única de "compra"/"sem compra": Order ou Opportunity ganha; quais `Order.Status` contam; qual data (`EffectiveDate` x `IssuanceDate__c`); janela N; o que fazer com `Account.Inactive__c` | Comercial, por escrito (D2 do design) | RN-1 e RN-2 — a única parte liberável em configuração pura |

Sem G4 em particular, não há forma de escrever metadata nenhuma para RN-1/RN-2 sem
inventar a regra de negócio — o que a instrução do agente proíbe explicitamente
("não invente metadata", "não improvise uma solução diferente da aprovada").

## Próximo passo

Este card deve voltar para decisão humana (Comercial do cliente responde G1–G4 por
escrito, idealmente registrado em `comentarios-do-card.md` ou em aditivo a
`03-design.md`) antes de qualquer nova tentativa de build. Depois disso, o agente de
build pode retomar: nenhum outro artefato precisa ser refeito, só estas quatro
respostas precisam existir em disco.
