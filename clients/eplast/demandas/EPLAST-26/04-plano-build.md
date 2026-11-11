# EPLAST-26 — Plano de build: Scoring de leads e oportunidades

**Status deste artefato: BLOQUEADO antes de iniciar.** Nenhuma branch, commit, metadata ou PR
foi criado nesta sessão. Este documento registra por que o estágio `build` não produziu um
plano de construção executável, e o que precisa acontecer antes que produza. Detalhe completo
da evidência em `BLOQUEIO-build.md`, ao lado.

## O que o design aprovado (03-design.md) manda construir, quando destravado
Fase 1 — score por **campo fórmula** (configuração, sem Apex, sem DML, sem gatilho de
automação), condicionado às perguntas abertas P1/P3/P13 (regra de pontuação) com o cliente:

- `Lead.ScoreConversao__c` (fórmula, Number) e `Lead.PrioridadeConversao__c` (fórmula, Text)
- `Opportunity.ScoreConversao__c` (fórmula, Number) e `Opportunity.PrioridadeConversao__c`
  (fórmula, Text)
- Permission set `PS_Comercial_ScoreConversao` (FLS de leitura nos 4 campos)
- Inclusão dos campos nos layouts `Lead-Lead Layout`, `Opportunity-Opportunity Layout` e
  `Opportunity-CPQ Opportunity Layout`
- Até 2 list views (`Lead.Leads_PorPrioridade`, `Opportunity.Oportunidades_PorPrioridade`)

Nada disso foi criado. A lista acima é a referência do design, não um plano de execução desta
sessão — não há passo a passo de ordem de criação, nem commits, porque o build não começou.

## Por que não iniciei a construção
Dois dos bloqueios que o próprio design (seção 1, item 4, e "Bloqueios em aberto") colocou
como condição para iniciar o build seguem abertos, reconferidos nesta sessão:

1. **P12 — Onda 3 (Comercial) ainda não contratada.** `contrato.md` confirma que só as Ondas
   1–2 estão no escopo pago; esta demanda pertence à Onda 3. Construir agora entregaria
   trabalho fora do contratado.
2. **P14 — sandbox de qa não existe/não é distinta da de dev.** `sf org list` nesta sessão
   mostrou uma única org autenticada (`sbx-eplast-dev`), sem `sbx-eplast-qa` — mesmo achado do
   recon. Construir sem isso resolvido arrisca build e homologação caírem na mesma sandbox.

O terceiro bloqueio citado no design (aprovação de estimativa pelo cliente) não se aplica:
Eplast é contrato de **projeto**, e nesse tipo de contrato o gate de design libera o build
direto, sem essa aprovação.

## O que falta medir, e por quê não meço aqui
Como o build não começou, os itens abaixo — que normalmente entrariam num plano de build real
— não têm dado novo desta sessão além do que já estava em `02-recon.md`/`03-design.md`:
- Tamanho compilado final das fórmulas (R11 do design): só se mede escrevendo a fórmula.
- Confirmação de qual página Lightning usa layout vs. seção própria (P4 do design): fica para
  o build real, quando o campo já existir para testar a atribuição.
- Cobertura de teste Apex atual da org: não reconferi nesta sessão porque a Fase 1 não cria
  Apex (R12 do design já registra que a cobertura de 10–11% não se aplica a este build); não
  é um número necessário para decidir se construo ou não.

## Passo a passo de execução — somente após o build ser destravado
Quando P12 e P14 estiverem resolvidos (ver `BLOQUEIO-build.md`), a sequência prevista, sem
reabrir o gate de design (salvo mudança de P1/P7):
1. Confirmar com o cliente/consultor a regra de pontuação (pesos, faixas, corte) e a definição
   de conversão (P1, P3, P13) — está pendente desde o design, não é novo.
2. Abrir/reusar `feature/EPLAST-26`.
3. Criar os 4 campos fórmula com `Description` documentando a regra, validando `ISBLANK` nos
   campos mínimos antes de pontuar.
4. Criar `PS_Comercial_ScoreConversao` com FLS de leitura.
5. Incluir os campos nos layouts listados acima (confirmando antes se a página ativa usa
   layout ou seção própria).
6. Criar as list views condicionadas a P4/P5.
7. Medir o tamanho compilado da fórmula e dividir em fórmulas parciais se necessário (R11).
8. Rodar o cenário de regressão exigido pelo design: salvar Lead e Opportunity depois do
   deploy e confirmar no debug log que as mesmas automações de antes (CPQ, `OpportunityTrigger`,
   `OpportunityFlow`, `Oportunidade_Industria`) disparam, e que a leitura do score não aciona
   nada novo.
9. Abrir PR para `feature/EPLAST-26` → gate humano (`aguardando_gate_build`).

Nenhum destes passos foi executado nesta sessão.
