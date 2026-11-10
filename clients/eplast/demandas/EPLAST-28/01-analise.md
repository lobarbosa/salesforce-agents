# EPLAST-28 — Alertas de oportunidade parada ou sem acompanhamento

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), **não contratada** no projeto atual (Ondas 1–2)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Status:** análise para validação humana. **Não pronta para design** — há uma questão contratual bloqueante (seção 6).

Fontes usadas: `demandas/EPLAST-28/demanda.md` (história do consultor), `assessment.md` (2026-09-30),
`contrato.md` (materializado pelo Squad OS, Status Report semana 05), histórico RAG
(`[demandas/EPLAST-26/01-analise.md]`, demanda irmã sobre Opportunity). O documento de origem
(Solicitação de Proposta) não está no workspace: a análise só tem a frase de uma linha da demanda.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para implantar IA no Salesforce em Sales e Marketing, em seis ondas.
Pelo `contrato.md`, as Ondas 1 (diagnóstico e desenho) e 2 (projeto-piloto) estão contratadas,
120 h, com fim previsto em **2026-11-30**. A Onda 3 (Comercial) está listada como "ainda não
contratada". Este item é um dos entregáveis desse bloco: alertar automaticamente o responsável
por uma oportunidade quando ela fica parada ou sem acompanhamento além do prazo combinado.

A dor de negócio implícita é o follow-up comercial que se perde: oportunidade aberta que ninguém
mexe. A demanda não traz números (quantas oportunidades param, quanto valor fica parado, hoje
quem percebe e como). Sem isso não há baseline para medir se o alerta resolve algo.

## 2. Objetivo

Reduzir oportunidades abertas sem acompanhamento além do prazo combinado, avisando o dono (e, se
definido, quem escala) no momento em que a parada passa do limite — e não depois, em relatório.

**Objetivo mensurável ainda não definido.** Proposta de métrica a validar: % de oportunidades
abertas com parada acima do prazo, medido antes e depois do piloto (ver baseline em
`eplast-ent-06` e medição do piloto em `eplast-ent-12`, ambos da Onda 1/2).

## 3. Regra de negócio

Regra mínima que a demanda permite inferir (tudo entre colchetes depende de validação, seção 5):

- RN-1. Uma oportunidade **aberta** é considerada *parada* quando passa [N] dias sem [EVENTO DE
  ACOMPANHAMENTO — pendente]. N e o evento variam conforme [PARÂMETRO — pendente].
- RN-2. Ao atingir o limite, o **dono da oportunidade** é alertado pelo canal [PENDENTE].
- RN-3. O alerta não se repete enquanto a parada durar, e é zerado quando há novo acompanhamento.
- RN-4. [Escalonamento ao gestor após X dias — PENDENTE, pode não existir].
- RN-5. O alerta não altera a oportunidade nem outros registros (premissa de arquitetura, seção 5).

## 4. Critérios de aceite (Gherkin)

Os valores entre `<>` são parâmetros ainda não definidos. Os cenários são testáveis assim que
os parâmetros forem preenchidos; antes disso, são a forma do critério, não o número.
Dados de teste: sintéticos, criados na sandbox de dev (guardrail #2). Nenhum registro real.

```gherkin
Funcionalidade: Alerta de oportunidade parada

  Cenário: oportunidade parada além do prazo gera alerta ao dono
    Dado uma Opportunity aberta de dono U1 cujo último acompanhamento foi em <DATA_A>
    E o prazo configurado para o seu <PARÂMETRO> é de <N> dias
    Quando a verificação roda em <DATA_A> + <N> + 1 dia
    Então U1 recebe um alerta pelo canal <CANAL>
    E o alerta identifica a oportunidade pelo nome e pelo link do registro

  Cenário: oportunidade dentro do prazo não gera alerta
    Dado uma Opportunity aberta de dono U1 cujo último acompanhamento foi em <DATA_A>
    Quando a verificação roda em <DATA_A> + <N> - 1 dia
    Então nenhum alerta é enviado para U1

  Cenário: a mesma parada não gera alerta repetido
    Dado que o alerta da parada atual já foi enviado para a oportunidade X
    Quando a verificação roda novamente sem novo acompanhamento
    Então nenhum segundo alerta é enviado para X
    # frequência de reenvio, se existir: <FREQ> — PENDENTE

  Cenário: novo acompanhamento zera a parada
    Dado que o alerta da oportunidade X já foi enviado
    Quando é registrado um novo acompanhamento em X
    E a verificação roda
    Então nenhum alerta é enviado para X
    E a próxima parada conta a partir do novo acompanhamento

  Cenário: oportunidade fechada não gera alerta  [proposto, PENDENTE de validação]
    Dado uma Opportunity com estágio fechado (ganha ou perdida)
    E que está além do prazo sem acompanhamento
    Quando a verificação roda
    Então nenhum alerta é enviado para ela

  Cenário: escalonamento ao gestor  [PENDENTE — só existe se confirmado]
    Dado que a parada de X já tem <N2> dias além do alerta ao dono
    Quando a verificação roda
    Então o gestor de U1 recebe alerta de escalonamento, uma única vez

  Cenário: a verificação não altera a oportunidade  [proposto, validar]
    Dado um conjunto de oportunidades elegíveis a alerta
    Quando a verificação roda
    Então nenhum registro de Opportunity tem LastModifiedDate alterado
    E nenhuma trigger ou Flow de Opportunity é disparado pela verificação
    # critério de guarda contra o achado 1 do assessment (automação concorrente)

  Cenário: código Apex novo tem teste dedicado  [convenção do squad]
    Dado uma classe Apex nova ou alterada para este alerta
    Então existe classe <Classe>Test com cobertura >= 85% na classe
    E a validação de deploy na sandbox de dev passa
```

## 5. O que a demanda NÃO diz (precisa de resposta antes do design)

Ordenado por impacto na arquitetura. Os itens 1 a 4 mudam o desenho de forma relevante; sem
eles o arquiteto não escolhe entre Flow agendado, Apex agendado ou relatório com notificação.

**Bloqueantes de design:**

1. **Definição de "parada" e de "acompanhamento".** Sem atividade (Task/Event) há [N] dias? Sem
   mudança de estágio? Sem alteração de qualquer campo? Quais atividades contam (e-mail logado,
   Task concluída, reunião, orçamento/Quote do CPQ)? A escolha muda o campo de referência e se
   a verificação precisa de lógica própria.
2. **"Prazo combinado".** Valor único para a empresa, ou por estágio, por tipo de negócio ou por
   Record Type (a org tem 14 Record Types, nenhum inativo)? Quem combinou esse prazo, com quem,
   e onde está registrado? "Combinado" sem documento é só suposição. Se for por estágio, a
   configuração vira metadata de parâmetro, não constante no código.
3. **Canal do alerta.** Notificação interna do Salesforce, e-mail, Chatter, Teams/Slack, ou
   Marketing Cloud Connect? Atenção: Marketing Cloud entrega a Onda 4 (Marketing), **não
   contratada** — escolher esse canal puxa escopo fora do contrato atual. Frequência: evento
   único, digest diário ou ambos?
4. **Destinatários e escalonamento.** Só o dono? Gestor (hierarquia de Role/Manager, quantos
   níveis)? Em qual dia de parada o gestor entra? Há quem deva ficar fora (ex.: integração,
   usuário inativo)?

**Não bloqueantes, mas precisam de resposta antes do build:**

5. **Ação além da notificação.** Só avisa, ou cria Task de follow-up para o dono? Criar Task
   escreve em atividade, o que muda o próprio critério de "parada" (ciclo de feedback).
6. **Oportunidades elegíveis.** Excluir fechadas (ganha/perdida)? Excluir as que têm Quote ativa
   no CPQ? Excluir tipos específicos?
7. **Conteúdo do alerta e LGPD.** Quais campos aparecem na mensagem (nome da conta, valor,
   estágio, próximo passo)? Valor de oportunidade é dado de negócio, não pessoal, mas o cliente
   precisa dizer o que pode sair de dentro da org em notificação externa (e-mail).
8. **Volume.** Quantas oportunidades abertas existem em produção e quantos usuários recebem alerta
   por dia? O assessment não mediu isso: a sandbox de dev tem 0 Opportunity e não se deve consultar
   produção. Sem esse número não há como dimensionar o job nem escolher frequência.
9. **Sobreposição com entregável contratado (`eplast-ent-09`).** A Onda 2 tem o agente "Quais
   clientes precisam de acompanhamento hoje?", em construção **fora da esteira**, em homologação
   nas semanas 6–7. Ele pode já responder parte desta necessidade. Precisa saber: o alerta é
   complemento, substituto ou duplicata? Se o agente já existe na org, o assessment (feito antes)
   não o registra; confirmar via `sf` antes de qualquer design (guardrail #3).
10. **Sobreposição com `EPLAST-26` (scoring de leads e oportunidades).** Também em Onda 3 e também
    gravaria ou leria Opportunity. Se o score vier a ser critério de prioridade do alerta, as duas
    demandas precisam ser desenhadas juntas, senão a ordem de automação em Opportunity fica
    indefinida duas vezes.
11. **Objeto e campos de referência.** Usar campos padrão de atividade do Opportunity (candidatos
    a confirmar via `sf`: `LastActivityDate`, `LastStageChangeDate`; não verificados) ou criar
    campo próprio? O assessment mostra 68,6% dos campos custom sem descrição, inclusive 9 dos 28
    de Opportunity; qualquer campo novo sai com `Description` preenchida.
12. **Ambiente de build.** O alias `sbx-eplast-dev` aponta para uma sandbox cujo usuário e URL se
    identificam como "qa" (achado 6 do assessment). Antes do build, confirmar em qual sandbox o
    código vai ser construído e testado; senão dev e QA podem compartilhar o mesmo ambiente.

## 6. Questão bloqueante de escopo contratual

**A Onda 3 (Comercial) não está contratada.** Confirmado em `contrato.md`: o escopo contratado é
Ondas 1 e 2, 120 h, fim previsto 2026-11-30. A Onda 3 aparece como "ainda não contratada", com
fonte no Status Report semana 05 (29/10/2026). A própria demanda diz o mesmo na última linha.

Isso não é lacuna técnica. Desenhar, construir e homologar uma solução para escopo sem contrato
tem implicação comercial: horas que não são cobradas, expectativa criada no cliente, e risco de
o trabalho ficar fora de qualquer aceite. Também pesa a data: faltam 20 dias para o fim previsto
do contrato atual.

**Decisão necessária antes do design, de consultor ou arquiteto (não do agente):**

- (a) A Onda 3 será contratada, por aditivo ou novo ciclo? Em que data e com quantas horas?
- (b) Ou este item sai do quadro até a contratação, e a demanda fica em `backlog` sem avançar?
- (c) Ou há autorização explícita para análise e design antecipados, sem build, com registro em
  ata?

Até essa resposta, o agente não avança para o arquiteto. O design e o build pressupõem escopo
aprovado.

Histórico: `[demandas/EPLAST-26/01-analise.md]` registra a mesma situação para a demanda de
scoring (Onda 3, "não contratada no projeto atual"), com a mesma conclusão de não-prontidão para
design. Vale tratar as duas juntas nessa decisão.

## 7. Riscos do assessment que tocam este pedido

Assessment de 2026-09-30, saúde **vermelha**. Riscos que se aplicam diretamente:

- **Achado 1 (alta) — automação concorrente em Opportunity.** Em Opportunity já coexistem
  `OpportunityTrigger` custom (after insert/update), `OpportunityAfter`/`OpportunityBefore` do
  SBQQ e dois Flows `RecordAfterSave` (`Oportunidade_Industria`, `OpportunityFlow`). Um alerta que
  grave qualquer coisa em Opportunity, ou que seja acionado por evento de Opportunity, entra nessa
  ordem de execução não garantida. Recomendação do assessment, que este item herda: mapear a
  ordem real antes do design e preferir um único ponto de entrada. Para este pedido, a forma
  natural é uma verificação agendada que só lê (sem trigger de Opportunity), o que está como
  critério de guarda na seção 4. Nenhuma escolha é feita aqui.
- **Achado 2 (alta) — cobertura Apex de 10%.** Qualquer Apex novo precisa de `<Classe>Test` com
  cobertura >= 85%. O assessment também registra que classes centrais do ERP Protheus não têm
  teste identificável. Se o alerta compartilhar lógica de Opportunity com algo do Protheus, a
  cobertura desse caminho não existe hoje.
- **Achado 6 (média) — alias de dev apontando para sandbox "qa".** Ver item 12 da seção 5.
- **Achado 4 (média) — campos sem descrição.** Ver item 11 da seção 5.
- **Achado 5 (média) — convenção `Test<Classe>`.** Qualquer classe de teste nova segue
  `<Classe>Test`, não o prefixo que a maioria das classes de teste atuais usa.

O assessment foi feito antes de qualquer demanda da Onda 3. A foto pode estar desatualizada; a
ordem de execução de Opportunity deve ser remapeada na hora do design, não usada como está.

## 8. Complexidade

**G.** Motivo: o pedido toca Opportunity, objeto com automação concorrente de alta severidade no
assessment, exige mapeamento de ordem de execução antes do design, e tem quatro decisões de
arquitetura em aberto (definição de parada, prazo, canal, escalonamento). Se o escopo ficar só em
verificação agendada somente-leitura, com canal interno e sem escalonamento, a complexidade cai
para M.

## 9. Estimativa de esforço humano

**Estimativa de esforço:** 24–56 h

Premissas que mais pesam na faixa:
- Escopo base: verificação agendada somente-leitura, notificação interna ou e-mail, sem escalonamento
  e sem Marketing Cloud. Escalonamento e canal externo somam faixa acima do máximo.
- O mapeamento da ordem de execução de Opportunity (achado 1) entra nesta faixa. Se for tratado como
  demanda separada, o mínimo cai para algo perto de 16 h.
- Testes em sandbox de dev com dados sintéticos; cobertura de Apex de 85% por classe nova inclui
  `<Classe>Test`.
- Não inclui a decisão contratual (seção 6) nem a curadoria de descrição de campos.
- Faixa larga porque a definição de parada e o prazo não existem ainda. O arquiteto refina no design.

## 10. Premissas a validar (todas pendentes, nenhuma assumida)

- P1. Existe um prazo combinado documentado. **Pendente.**
- P2. A verificação é agendada, não disparada por evento de Opportunity. **Pendente (depende de
  mapeamento do achado 1).**
- P3. Os destinatários são o dono e, opcionalmente, o gestor por hierarquia. **Pendente.**
- P4. Não há Marketing Cloud nem integração externa neste item. **Pendente (depende da Onda 4).**
- P5. Dados de teste são sintéticos, criados em dev. Nenhum dado real entra no contexto.
  **Premissa de guardrail, sem pendência de resposta.**
- P6. O documento de origem (Solicitação de Proposta Konecta) descreve este item com mais detalhe do
  que a linha da demanda. **Pendente: precisa ser anexado ou transcrito.**

## 11. Próximos passos

1. Consultor/arquiteto decide a questão contratual (seção 6).
2. Consultor responde os itens bloqueantes 1 a 4 e os 9 e 10 (sobreposição) da seção 5.
3. Sob demanda do arquiteto, `org-recon` confirma via `sf` o que já existe: agente de
   `eplast-ent-09`, campos padrão de atividade em Opportunity, Flows e triggers na ordem de
   execução. Nada disso foi confirmado nesta análise.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
