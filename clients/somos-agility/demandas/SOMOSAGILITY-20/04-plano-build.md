# 04 — Build: BLOQUEADO (não é um plano de build concluído)

**Demanda:** SOMOSAGILITY-20 · **Cliente:** somos-agility · **Agente:** `builder-declarativo`
**Data:** 2026-10-28

> **Nenhum metadata foi escrito. Nenhuma branch foi criada. Nenhum deploy foi feito.
> Este arquivo documenta um bloqueio, não um build.**

## Por que o build não arrancou

O próprio `03-design.md` (linha 8) declara: *"Situação do design: aprovável na abordagem,
bloqueado para build em 2 pontos."* As duas perguntas estão marcadas textualmente como
**BLOQUEIO para o build** na seção 3 do design — e o texto atribui a decisão ao cliente,
não ao arquiteto:

- **6.1 — Gatilho/objeto de origem.** "Há três candidatos reais na org, cada um muda o
  objeto do Flow: (a) `Hist_rico_de_Venda_e_Renova_o__c.Pr_ximo_Vencimento__c`; (b)
  `Asset.Vencimento_Subscri_o__c`; (c) data de fim de `Contract`. O design é escrito na
  premissa (a) porque é o único com campo de vínculo pronto para duplicidade.
  **O cliente precisa escolher.**"
- **6.3 — Elegibilidade.** "**Nada na org define quem entra.** Candidatos para o cliente
  escolher (não assumidos): `Classe_de_renovacao__c`, `Tipo_do_Evento__c`,
  `E_o_mais_recente__c = true`."

`01-analise.md` (seção 6, linha 114) já previa isso: *"a resposta às perguntas 6.1 a 6.6
deve ser registrada no próprio card (comentário do cliente ou do consultor), para que entre
na sessão de análise pelo `comentarios-do-card.md`."*

## O que foi conferido antes de concluir pelo bloqueio

- `comentarios-do-card.md` — lido na íntegra. Tem 4 entradas: abertura do chamado (Vanessa
  Ranieri, Departamento Renovações, 2026-10-19, sem detalhe técnico), aprovação da estimativa
  de 19h, aprovação do gate `aguardando_gate_analise` e aprovação do gate
  `aguardando_gate_design`. **Nenhuma resposde 6.1 ou 6.3.**
- `gates.md` — o gate `aguardando_gate_design`, aprovado por Leonardo Barbosa em
  2026-10-28T23:33:40Z, lista como artefatos revisados apenas `02-recon.md` e
  `03-design.md`. É a aprovação da **abordagem técnica** (Flow agendado, declarativo) tal
  como o próprio design a apresenta — incluindo a frase que declara o bloqueio — e não uma
  resposta às duas perguntas de negócio que o design atribui ao cliente.
- `status.yaml` — histórico de transições não contém nenhuma entrada que resolva 6.1/6.3;
  a passagem `aguardando_gate_design → build` reflete a aprovação do gate acima, não uma
  decisão de cliente adicional.
- Histórico de commits da demanda (`git log`) — só commits de análise e de design; nada
  que adicione resposta a 6.1/6.3.

## O que precisa acontecer para o build rodar

Alguém do lado do cliente (Vanessa Ranieri / Departamento de Renovações) ou o consultor
responsável precisa registrar no card, em `comentarios-do-card.md` (via sync), respostas
objetivas a:

1. **6.1** — qual objeto de origem: HVR, Asset ou Contract (e, se Asset, está ciente de que
   isso é mudança de modelo de dados — ver `03-design.md` linhas 77–81 — e escala para
   decisão de arquitetura sênior antes de qualquer build)?
2. **6.3** — critério exato de elegibilidade: quais valores de `Classe_de_renovacao__c`
   e/ou `Tipo_do_Evento__c` entram ou saem, além do já assumido `E_o_mais_recente__c = true`.

Depois de registradas, se as respostas não mudarem o objeto de origem para Asset nem o
desenho para agrupamento por conta (6.6), o design já aprovado (abordagem Flow agendado,
seção 1–2 de `03-design.md`) continua válido e o build pode prosseguir sem nova rodada de
design. Se mudarem (Asset ou agrupamento por conta), o próprio `03-design.md` (riscos R3/R4,
seção 7) já prevê que o design "volta a este gate" — ou seja, nova sessão de `arquiteto`
antes de qualquer build.

## Status

Build não iniciado. `status.yaml` permanece em `build`, mas nenhum artefato de metadata foi
produzido. Nenhuma branch `feature/SOMOSAGILITY-20-*` foi criada. Nenhum comando `sf` foi
executado contra `sbx-somos-agility-dev` ou qualquer outra sandbox.
