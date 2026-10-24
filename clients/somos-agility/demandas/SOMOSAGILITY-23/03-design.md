# SOMOSAGILITY-23 — Design enxuto (arquiteto)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Design enxuto, etapa 3 do fluxo reduzido.
**Entradas:** `demanda.md`, `comentarios-do-card.md`, `01-analise.md` (aprovada em `gates.md`,
2026-10-21), `02-recon.md`, anexo do card (só a URL do registro, sem texto do erro).
**Org de referência:** `sbx-somos-agility-dev` (sandbox). Nenhuma org de produção foi
consultada nem será.

---

## 1. Decisão

**Nesta demanda não há build de metadata nem de código. A decisão declarativo vs. código fica
suspensa até a mensagem de erro exata chegar.** O próximo passo é diagnóstico com apoio humano.
Não é construção.

- **Nível escolhido agora:** nenhum (sem configuração, sem Flow, sem Apex).
- **Hipótese principal (não confirmada):** o erro vem de uma **regra que roda num registro pai**
  quando o roll-up é recalculado, por causa do **estado dos dados** desse pai em produção. A
  regra em si não está quebrada. Se isso se confirmar, a correção é de dado e feita por humano
  autorizado em produção, fora do alcance do agente (guardrail #1).
- **Hipótese secundária (não confirmada):** falha sem tratamento no subflow
  `Preencher_DSA_Flow`, que o Process Builder `Preencher_DSA` chama no pai. Se for essa, a
  demanda vira build declarativo (fault path ou migração do Process Builder). Nesse caso este
  design é refeito e volta ao gate.

### Por que não desci para declarativo ou código

Não existe causa confirmada para corrigir. Escolher um componente para alterar agora seria
inventar a causa, e o guardrail #3 proíbe isso. O incidente aconteceu num registro de produção
que não existe nesta sandbox (0 registros do objeto, ver `02-recon.md` §4). Por isso não dá para
reproduzir o erro e provar a correção antes de construir.

## 2. Complemento do recon: cascata de roll-up (achado novo)

O recon (`02-recon.md`) olhou só o próprio objeto `Realizacao_Financeira_de_Venda__c` e concluiu
que nada na metadata explica o erro. Isso vale para o objeto, mas **a análise para antes da hora**.
Salvar esse registro também salva dois registros pais. A metadata abaixo foi confirmada no
baseline retrievado da sandbox (`force-app/`, commit `6ffa5a54`, 2026-10-17). Nesta sessão não
havia org autenticada para nova consulta ao vivo. **A metadata de produção pode ser diferente da
sandbox**, e isso não foi verificado.

1. `Realizacao_Financeira_de_Venda__c.Resultado__c` é **Master-Detail** para `Resultado__c`.
2. `Resultado__c.RenovacaoRealizado__c` é **roll-up SUM de `Renova_o__c`**. Alterar "Renovação
   Realizado" no filho recalcula o pai `Resultado__c`, e o pai passa pelo próprio save.
3. Em `Resultado__c` está ativo o Process Builder `Preencher_DSA` (`processType` Workflow,
   versão ativa 2, `onAllChanges`, critério sempre `true`). Ele chama o subflow
   `Preencher_DSA_Flow`, que busca `DSA__c` pela oportunidade, preenche `DSA__c`/`Comissao__c` e
   faz update do `Resultado__c`. **O subflow não tem fault path.** Qualquer falha nele volta como
   erro no save do filho.
4. `Resultado__c.Oportunidade__c` é **Master-Detail** para `Opportunity`.
   `Opportunity.RenovacaoRealizado__c` é **roll-up SUM de `Resultado__c.RenovacaoRealizado__c`**.
   A edição sobe mais um nível: a Opportunity também é salva.
5. Na Opportunity existem **110 validation rules no baseline, 26 ativas**, e cerca de 30 Flows
   record-triggered de update ativos, além de Process Builders. Entre as regras ativas, algumas
   **dependem só do estado do registro** (não usam `ISCHANGED`/`PRIORVALUE`). Por isso falham em
   qualquer save da oportunidade, inclusive no save causado por roll-up:
   - `M38_Valida_Numero_DSA`: `N_mero_de_DSA__c >= 2`, sem exceção de perfil (Msg38).
   - `M35_Somente_pode_existir_um_SOW_atual`: `Qtde_Propostas_SOW__c >= 2`, com exceção de
     alguns perfis (Msg35).
   - `M17`, `M18`, `M19`, `M20`, `M39`: campo "Sim" com descrição em branco ("Favor descrever").

**Por que isso combina com "só neste lançamento":** esse tipo de regra bloqueia apenas os
filhos de uma oportunidade cujos dados já violam a regra. Os outros lançamentos, ligados a
oportunidades que respeitam a regra, salvam normalmente. É um padrão conhecido da plataforma.
**Mesmo assim, é hipótese.** Qual regra (ou Flow) dispara neste registro só a mensagem de erro
vai mostrar.

**Conflito de automação (sinalizado conforme o método): um único save do filho dispara a
automação de três objetos em cascata (Resultado__c com Process Builder + subflow, e Opportunity
com 26 validation rules ativas e dezenas de Flows). Isso é risco real de ordem de execução, e é
o principal suspeito deste incidente.**

## 3. Plano de diagnóstico (o que destrava a decisão)

O agente não executa nada disso em produção. Os passos ficam em ordem de custo:

1. **Mensagem de erro exata (bloqueante, quase sem custo).** Pedir ao cliente, pelo card, o
   texto integral do erro. Várias regras desta org têm código (`MsgNN`). Se aparecer "Msg38",
   "Msg35" ou "Favor descrever (MsgNN)", a causa fica identificada quase com certeza, sem
   reproduzir nada.
2. **Conferência pelo humano autorizado em produção.** Abrir a oportunidade pai do
   `Resultado__c` desse lançamento e verificar se ela viola alguma das regras de estado do §2.5
   (ex.: dois DSAs ligados, duas propostas SOW atuais, campo "Sim" sem descrição). Isso é leitura
   na tela, feita por humano, sem extração de dado.
3. **Reprodução em sandbox (opcional, só se 1 e 2 não fecharem).** Em `sbx-somos-agility-dev`,
   criar dados sintéticos sem dado de cliente: uma Opportunity, um `Resultado__c` e um
   `Realizacao_Financeira_de_Venda__c`. Colocar a oportunidade num estado que viole a regra
   suspeita e editar `Renova_o__c` no filho. Assim se confirma o mecanismo da cascata. A
   reprodução não prova o caso de produção, porque a metadata pode divergir. Leva cerca de 1–2 h
   e só roda com aprovação deste gate.

### Saídas possíveis depois do diagnóstico

| Causa confirmada | O que acontece | Quem executa |
|---|---|---|
| Dado da oportunidade pai viola regra de estado | Corrigir o dado do pai (ex.: o DSA duplicado) e depois ajustar "Renovação Realizado" | Humano autorizado da conta, em produção. **Sem build.** |
| Falha no subflow `Preencher_DSA_Flow` | Novo design: fault path ou migração do Process Builder para Flow record-triggered | Build declarativo, volta ao gate |
| Regra mal desenhada (não deveria barrar roll-up) | Novo design: ajustar a regra (ex.: exigir `ISCHANGED` do campo de negócio) | Build declarativo, volta ao gate. **Decisão de negócio do cliente** |
| Outra causa (permissão, metadata só de produção) | Revisar a análise | — |

## 4. Componentes

- **Criar:** nenhum.
- **Alterar:** nenhum.
- **Depreciar:** nenhum. Registro para backlog, fora deste escopo: `Preencher_DSA` é Process
  Builder (tecnologia em fim de vida) e roda em toda alteração de `Resultado__c`, inclusive as
  causadas por roll-up. A migração dele merece uma demanda própria.

## 5. Impacto em permissões

Nenhum. O campo já é editável no layout e pelos permission sets
`Acesso_completo_Esteira_de_vendas_e_renovacoes` e `DiretorComercial` (`02-recon.md` §3).
Observação para o diagnóstico: várias regras da Opportunity isentam perfis como
"Administração". Se um usuário com esse perfil consegue salvar e o usuário de Operações não
consegue, isso reforça a hipótese de validation rule. **O caminho não é dar perfil de
administrador ao usuário.**

## 6. Modelo de dados

Sem mudança de modelo de dados, nada a escalar. Os relacionamentos Master-Detail e os roll-ups
ficam como estão.

## 7. Riscos técnicos

| Risco | Severidade | Mitigação |
|---|---|---|
| A metadata de produção diverge do baseline da sandbox (regra ou Flow que só existe em produção) | Alta | A mensagem de erro exata responde isso sem depender do baseline |
| Corrigir o valor sem tratar a causa: o próximo ajuste em qualquer filho da mesma oportunidade volta a falhar | Média | Corrigir primeiro o dado do pai que viola a regra, depois o valor |
| Contornar com perfil de administrador e deixar o dado da oportunidade inconsistente | Média | Não recomendado. Corrigir o dado do pai |
| Process Builder sem fault path em toda alteração de `Resultado__c` (fragilidade estrutural, além deste caso) | Média | Demanda separada de migração (§4) |
| Limites de governador | Baixa | Edição de um registro só, sem volume. Não há SOQL em loop a avaliar porque não há código novo |

## 8. O que NÃO será feito nesta demanda

- Nenhum deploy, DML ou Apex anônimo em produção pelo agente, nem a correção do valor do
  lançamento. Isso é do humano autorizado da conta (guardrail #1).
- Nenhuma cópia de dado de produção para a sandbox (guardrail #2 / LGPD).
- Nenhuma alteração de validation rule, Flow ou Process Builder antes de a causa ser confirmada.
- Nenhuma migração de `Preencher_DSA` (fica para backlog).
- Nenhuma investigação de recorrência em outros lançamentos. Se o diagnóstico mostrar que se
  repete, a análise é refeita.

## 9. Estimativa de esforço

**Estimativa de esforço:** 2–5 h

O que mudou em relação à análise (2–6 h) e por quê:
- **O teto baixou de 6 h para 5 h.** O recon eliminou Apex, validation rule e approval process
  no próprio objeto. Este complemento mostrou que o caminho mais provável termina em correção
  de dado, sem build, PR nem deploy.
- **O piso continua em 2 h.** Inclui conseguir e interpretar a mensagem de erro, orientar o
  humano que corrige em produção, conferir depois da correção e registrar a entrega.
- **O topo cobre a reprodução opcional em sandbox (§3, passo 3).** Se o diagnóstico apontar
  falha no subflow ou regra mal desenhada, esta estimativa deixa de valer: entra build
  declarativo e este design é refeito com nova faixa.
- O tempo do humano autorizado do cliente para corrigir o dado em produção não está incluído.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
Nesta demanda o build é zero e o próximo passo é o diagnóstico do §3.
