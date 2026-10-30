# SOMOSAGILITY-14 — Plano de build

- Cliente: somos-agility
- Org: `sbx-somos-agility-dev` (única org conectada, confirmado via `sf org list`)
- Base: `03-design.md` (aprovado em 2026-10-21 por Leonardo Barbosa)
- Status: **BUILD BLOQUEADO — P5 não confirmado**

---

## 1. Resultado

**Nada foi alterado na sandbox. Nenhum commit de metadata foi feito. Nenhum PR foi aberto.**

O design (`03-design.md`, seções 2 e 7) condiciona o início do build à confirmação de **P5**:
qual dos 4 Approval Process ativos em `Solicitacao_de_Reembolso__c`
(`SolicitacaoReembolsoBackofficeRHGov4`, `ReembolsoMarketing4`, `ReembolsoPosVenda5`,
`Reembolso_Comercial_pre_vendas_e_CS`) é o correto para incluir a usuária. O design já registrava
que essa escolha "não é algo que se infere da metadata" — é decisão de negócio de quem é dono do
processo de reembolso.

Tentei confirmar P5 via `sf` CLI contra `sbx-somos-agility-dev` antes de aceitar esse bloqueio
como definitivo. O resultado reforça a suspeita do design, mas não a supera.

## 2. O que foi tentado para resolver P5

1. **Busca por campo de área/departamento no `User`.** `FieldDefinition` do objeto `User` tem um
   campo padrão `Department`. Na dev, só 12 dos 38 usuários ativos têm esse campo preenchido, e a
   usuária "Simone*" **não é uma delas** (`COUNT()` = 0). Não há nada para usar aqui.
2. **Papel (`UserRole`) da usuária.** Confirmado (role name não é dado pessoal, é estrutura
   organizacional): `Gerente de Contas Large Accounts`. Isso é consistente com a área comercial,
   mas é só um indício — nenhum dos 4 Approval Process usa `Role` como critério de entrada (o
   recon já havia confirmado isso: critério de entrada é só `CreatedBy equals <nome>`).
3. **Busca por objeto/campo custom que amarre perfil, papel ou área a um Approval Process.**
   Consultei `EntityDefinition` por nomes que sugerissem isso (`%provacao%`, `%rea%Reembolso%`).
   **Nenhum objeto custom, custom metadata type ou custom setting desse tipo existe na org.**
4. **Retrieve dos 4 Approval Process ativos** (para um diretório temporário fora do repo, igual ao
   recon — nada commitado) e leitura do `entryCriteria` de nível de processo (não o de etapa, que é
   outra coisa). Confirma de novo o que o recon já disse: o critério é **só** uma lista nominal de
   `CreatedBy equals <nome>`, sem perfil, papel, área ou campo do registro em nenhum dos 4.
5. **Correlação estatística entre o perfil dos usuários já incluídos em cada AP e o perfil da
   usuária (`Gerente de Contas`).** Cruzei, via `sf data query`, o `Profile.Name` de cada um dos 32
   nomes que já aparecem nos critérios de entrada dos 4 AP (sem copiar nome de usuário nenhum para
   este artefato — só contagem agregada por AP, mesmo padrão do recon):

   | Approval Process | Total de critérios nominais | Quantos têm perfil exatamente "Gerente de Contas" |
   |---|---|---|
   | `SolicitacaoReembolsoBackofficeRHGov4` | 5 | 0 |
   | `ReembolsoMarketing4` | 2 | 0 |
   | `ReembolsoPosVenda5` | 12 | 0 (tem 1 "Gerente de Contas e Soluções", perfil diferente) |
   | `Reembolso_Comercial_pre_vendas_e_CS` | 13 | **7** (mais 2 variantes do mesmo nome de perfil: "Gerente de contas - Marcia", "Gerente de Contas - AI") |

   Achado: **100% dos usuários com o perfil exato "Gerente de Contas" que já estão em algum dos 4
   AP estão em `Reembolso_Comercial_pre_vendas_e_CS`**, e é a maioria dos critérios desse processo.
   Nenhum outro AP tem um usuário com esse perfil.

## 3. Por que isso não basta para liberar o build

O achado do item 5 é o **mesmo sinal que o design já identificou e já descartou explicitamente**:
a seção 2 do design diz "O candidato mais provável pelo perfil é `Reembolso_Comercial_pre_vendas_e_CS`,
mas isso é palpite e não vale como base de build." O que fiz foi quantificar esse palpite (7 de 13,
0 nos outros três) — uma correlação mais forte do que "candidato mais provável", mas ainda é
**inferência sobre dado existente**, não uma **regra de metadata configurada**. Continua sendo
verdade que:

- Nenhum dos 4 AP usa perfil, papel ou área como critério de entrada — a correlação observada é um
  efeito de quem foi incluído manualmente ao longo do tempo, não uma regra que a org aplica.
- Uma amostra de 7 pessoas não garante que todo "Gerente de Contas" pertence a esse processo — pode
  haver segmentação por carteira/conta (Large Accounts vs. outra) que a org não registra em lugar
  nenhum consultável.
- O comentário do cliente de 2026-10-15 diz que a aprovação "sempre deve olhar o campo aprovador do
  reembolso, que fica no cadastro/contato" (`Contact.AprovadorReembolso__c`) — isto é, para este
  cliente a rota de aprovação correta pode depender do aprovador cadastrado da pessoa (H2 do
  design), não (só) de qual dos 4 AP nominais ela está. Isso é motivo adicional para não tratar a
  correlação por perfil como suficiente: mesmo acertando o AP de entrada, a etapa seguinte depende
  de `aprovadorCordGerente__c`/`Contact.AprovadorReembolso__c`, que o design já registrou (P7) como
  não verificável sem ler dado de registro, e que é ação de cadastro do admin do cliente, não do
  agente.
- R5 do design (`03-design.md` seção 5) classifica como risco médio "inclusão no AP errado faz a SR
  seguir para os aprovadores errados (risco financeiro e de controle)" — exatamente o tipo de erro
  que uma inferência estatística, por mais forte que seja, pode causar silenciosamente.

Decisão: **não escolher `Reembolso_Comercial_pre_vendas_e_CS` com base nesta correlação.** Seria
construir em cima de um palpite quantificado, não de uma confirmação, e o próprio design pede
exatamente o oposto disso.

## 4. Pergunta exata que falta responder, e quem deveria responder

> Para a usuária reportante (perfil `Gerente de Contas`, papel `Gerente de Contas Large Accounts`),
> qual dos 4 Approval Process ativos de `Solicitacao_de_Reembolso__c` deve avaliar a aprovação do
> reembolso dela — `Reembolso_Comercial_pre_vendas_e_CS` (maior correlação observada) ou outro — e
> quem deve ser o aprovador dela no campo `AprovadorReembolso__c` do Contact associado?

Quem deveria responder: **dono do processo de reembolso / admin do cliente** (mesma indicação do
design, seção 7, P5). Não é uma pergunta que o consultor relator (Simone) necessariamente sabe
responder sozinha, porque envolve quem aprova o dinheiro dela, não como ela usa o sistema.

## 5. Possível ampliação de escopo (para o humano decidir, não decidido aqui)

Os comentários do card trazem dois pontos que o design já havia colocado fora do escopo desta
demanda pontual, e que merecem decisão humana explícita antes de a esteira continuar:

1. **Comentário do cliente, 2026-10-15:** pede revisão de "todo o fluxo do reembolso dos usuários
   que estão como gerente de contas" (plural, não só a usuária relatora). Se isso proceder, o
   diagnóstico muda de "uma usuária não está numa lista nominal" para "um grupo de perfil inteiro
   pode estar incompleto em um ou mais dos 4 AP" — o que é maior que um bug pontual de sustentação.
2. **Comentário do cliente, 2026-10-20, com fluxograma anexo
   (`anexos/qz10kg-Fluxo-de-solicitacao-e-aprovacao-de-reembolso.jpg`):** pede uma correção
   estrutural do processo "para não ter mais impacto na criação de novos usuários". Abri e li o
   fluxograma: ele descreve o processo em termos de papéis (Solicitante, Gerente de Projeto/Grupo
   GP, Gestor/Aprovador de Reembolso, Financeiro/Grupo Operações) e regras gerais (PIN obrigatório,
   exigência de ao menos 1 Lançamento de Despesa, campos obrigatórios por etapa) — **não cita
   nenhum dos 4 Approval Process pelo nome**, então ele não resolve P5 nem substitui a decisão de
   negócio pendente. Ele confirma a leitura já registrada na análise/design: a correção estrutural
   que trocaria o critério nominal por um critério de papel/grupo (ex.: usar o
   `Contact.AprovadorReembolso__c` de forma consistente, como o cliente já pede desde 15/10) é
   exatamente o que `03-design.md`, seção 6, já havia escopado para **fora** desta demanda,
   recomendando uma demanda própria de melhoria.

Registro isso para o humano decidir se SOMOSAGILITY-14 continua sendo a correção pontual (incluir 1
nome em 1 AP, assim que P5 for respondida) ou se o pedido do cliente já extrapolou esse escopo e
precisa voltar para análise/design como uma demanda estrutural maior — decisão de negócio, não do
agente (guardrail: "se durante o build você descobrir que o design não fecha, pare e reporte — não
improvise uma solução diferente da aprovada").

## 6. Estado da branch e do repositório

- Branch `feature/SOMOSAGILITY-14` já existe e é a branch corrente — **não recebeu nenhum commit
  desta sessão**, porque não há metadata para alterar sem resposta a P5.
- Nenhum arquivo em `force-app/` foi criado ou alterado (não existe ainda `force-app/` para
  somos-agility).
- O retrieve dos 4 Approval Process, feito só para a análise do item 2.5 acima, foi para um
  diretório temporário fora do repositório (`/tmp`) e já foi removido. Nenhum nome de usuário de
  outras pessoas foi copiado para este artefato (guardrail #2) — só contagens agregadas por perfil.
- Nenhum PR foi aberto.
- A demanda **não deve avançar** para o próximo gate (QA) enquanto P5 não for respondida — não há
  artefato de build completo para homologar.

## 7. Riscos do design (R1–R6) que continuam valendo para quando o build for liberado

Registrados aqui para não se perderem quando a resposta de P5 chegar e o build puder prosseguir:

- **R1** (conflito de automação no envio — Alta): QA precisa enviar a SR da usuária incluída e
  conferir se `Status__c` e `Status_de_Aprovacao_e_Etapas__c` ficam preenchidos sem erro.
- **R2** (metadata da dev pode não bater com a org do erro — Alta, ligado a P3 ainda não
  respondida): confirmar que os 4 AP ativos da org onde o erro realmente ocorreu têm o mesmo nome e
  versão que os da dev antes de generalizar a correção.
- **R3** (deploy de AP ativo pode ser recusado — Média): usar `ci-salesforce-validate`
  (check-only) antes do deploy real; plano B é clonar nova versão do AP.
- **R4** (critério por nome quebra em silêncio com homônimo/mudança de nome — Média, estrutural):
  fora do escopo desta demanda, registrado como dívida.
- **R5** (inclusão no AP errado desvia a aprovação financeira — Média): é precisamente o risco que
  este bloqueio evita materializar ao não adivinhar P5.
- **R6** (limites de governador — Baixa): sem mudança de lógica, não se aplica a este build.
