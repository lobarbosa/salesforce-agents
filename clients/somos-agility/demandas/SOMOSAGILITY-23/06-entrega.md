# SOMOSAGILITY-23 — Entrega (doc)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (enxuto), 4, 5, 7.
**Etapa 6 (release/deploy):** não executada, de propósito. Nenhuma metadata foi criada, alterada ou implantada nesta demanda. Não existe pacote de deploy nem deploy ID.
**Data deste documento:** 2026-10-28

---

## 1. O que foi entregue

Um **diagnóstico** da causa provável do erro ao ajustar o campo "Renovação Realizado" em um lançamento financeiro. Não é uma correção.

- **O valor do lançamento não foi corrigido.** O registro está em produção. Alterar dado de produção é fora do alcance do agente (guardrail #1). A correção do valor cabe a pessoa autorizada da conta.
- **A causa não está confirmada.** O diagnóstico identifica o mecanismo mais provável e as evidências que sustentam essa hipótese. Confirmar a causa exige duas ações humanas, listadas na seção 7.
- **Nada foi validado na sandbox de QA.** A `sbx-somos-agility-qa` nunca foi conectada à esteira. Nenhum cenário de aceite foi executado nela.
- **Nenhuma mudança de configuração foi feita.** Não há regra, Flow, Apex, permissão nem layout alterados.

### O que o diagnóstico estabeleceu

1. O campo do erro é `Realizacao_Financeira_de_Venda__c.Renova_o__c`. Não é fórmula. Está editável no layout.
2. Nada no próprio objeto explica o erro: não há validation rule, nem Apex, nem processo de aprovação, nem Flow que dispare só por esse campo.
3. Salvar esse lançamento também salva dois registros pais, em cascata de roll-up. Isso foi reproduzido em sandbox de dev com dados sintéticos.
4. Uma validation rule de estado na Opportunity pai (`M38_Valida_Numero_DSA`) bloqueia qualquer save da Opportunity quando ela já viola a regra. Pelo mecanismo da cascata, isso afeta até o save causado por um filho. A hipótese é que o lançamento afetado pertence a uma Opportunity nesse estado. Não foi confirmado.
5. Não foi possível reproduzir o estado de violação por uso normal da tela em sandbox. Se a causa for essa, o dado violador entrou no sistema por outro caminho (importação, carga em lote, regra criada depois do registro). Isso não foi verificado.

---

## 2. Mecanismo técnico identificado

Todos os API names abaixo foram confirmados via `sf` na sandbox de dev (`sbx-somos-agility-dev`), exceto onde indicado. A metadata de produção não foi consultada e pode divergir (ver seção 6).

### 2.1 Cadeia de save

| Nível | Objeto | Relação | Roll-up / automação |
|---|---|---|---|
| Filho | `Realizacao_Financeira_de_Venda__c` | — | Campo editado: `Renova_o__c` (currency, não fórmula) |
| Pai 1 | `Resultado__c` | Master-Detail pelo filho (`Resultado__c`) | `RenovacaoRealizado__c` = SUM de `Renova_o__c`. Process Builder `Preencher_DSA` (ativo, `onAllChanges`) chama o subflow `Preencher_DSA_Flow` |
| Pai 2 | `Opportunity` | Master-Detail por `Resultado__c.Oportunidade__c` | `RenovacaoRealizado__c` = SUM de `Resultado__c.RenovacaoRealizado__c`. 110 validation rules no baseline, 26 ativas, e dezenas de Flows record-triggered |

### 2.2 Pontos de falha prováveis

- **Validation rules de estado na Opportunity.** Algumas regras ativas não usam `ISCHANGED`/`PRIORVALUE`. Elas dependem só do estado atual do registro e falham em qualquer save da Opportunity, inclusive o causado por roll-up:
  - `M38_Valida_Numero_DSA`: `N_mero_de_DSA__c >= 2`, sem exceção de perfil (mensagem `Msg38`). **Única hipótese testada em sandbox.** Confirmada no comportamento: o segundo `DSA__c` na mesma Opportunity é barrado na criação.
  - `M35_Somente_pode_existir_um_SOW_atual`: `Qtde_Propostas_SOW__c >= 2`, com exceção de alguns perfis (`Msg35`). **Não testada.** O campo não aparece no describe ao vivo da sandbox.
  - `M17`, `M18`, `M19`, `M20`, `M39`: campo "Sim" com descrição em branco ("Favor descrever"). **Não testadas.** Os campos referenciados não aparecem no describe ao vivo da sandbox.
- **Subflow `Preencher_DSA_Flow` sem fault path.** Qualquer falha dentro dele volta como erro ao save do filho. **Hipótese secundária, não testada.**

### 2.3 Por que o erro aparece "só neste lançamento"

Regras de estado na Opportunity bloqueiam só os filhos de Opportunities cujos dados já violam a regra. Lançamentos ligados a Opportunities que respeitam a regra salvam normalmente. Isso é consistente com o relato. **Continua sendo hipótese**: a mensagem exata do erro é o que decide qual regra disparou.

### 2.4 Verificações de metadata

- Não há validation rule, Apex, nem processo de aprovação no próprio objeto `Realizacao_Financeira_de_Venda__c`.
- O Flow `Preenche_recorrente_ajustado_realizado` referencia o objeto, mas o filtro de entrada não inclui `Renova_o__c`. Editar só esse campo não deveria acioná-lo.
- Permission sets que dão escrita em `Renova_o__c`: `Acesso_completo_Esteira_de_vendas_e_renovacoes` e `DiretorComercial`. Não foi confirmado qual permission set o usuário que reportou o erro tem.

---

## 3. Como funciona o fluxo de cascata (para quem vai dar manutenção)

Passos, do ponto de vista de quem edita um lançamento:

1. O usuário edita `Renova_o__c` no lançamento (`Realizacao_Financeira_de_Venda__c`) e clica em salvar.
2. O Salesforce recalcula o roll-up `RenovacaoRealizado__c` no `Resultado__c` pai. Como o pai é Master-Detail do filho, ele é salvo de novo.
3. O save do `Resultado__c` dispara o Process Builder `Preencher_DSA` e o subflow `Preencher_DSA_Flow`, que alteram `DSA__c`, `Comissao__c` e o próprio `Resultado__c`. Sem fault path: se algo falhar aqui, o erro sobe para o usuário que editou o filho.
4. O `Resultado__c` alterado recalcula o roll-up `RenovacaoRealizado__c` na `Opportunity`, que é salva de novo.
5. O save da `Opportunity` executa todas as validation rules ativas e os Flows dela. Se uma regra de estado estiver violada pelos dados atuais da Opportunity, ela bloqueia o save inteiro, inclusive o que partiu do filho.
6. O erro volta ao usuário na tela do lançamento, mesmo que a alteração feita no lançamento seja válida. A mensagem mostra a regra que falhou, por isso a mensagem exata é a informação decisiva.

**Consequência prática:** um ajuste de valor em um lançamento pode falhar por causa de um dado da Opportunity pai, não do lançamento. Corrigir só o valor do lançamento não resolve se o dado do pai continuar violando a regra. O próximo ajuste em qualquer filho da mesma Opportunity falha de novo.

---

## 4. Critérios de aceite — status

Referência: `01-analise.md` §4.

| Cenário | Status | Motivo |
|---|---|---|
| Ajustar o campo no lançamento afetado sem erro | Não verificado | Depende de produção e da correção de dado do pai, ambas fora do alcance do agente |
| Demais campos do lançamento afetado continuam editáveis | Não executado | Sandbox de QA não conectada |
| Lançamentos não afetados continuam funcionando | Não executado | Sandbox de QA não conectada |
| Causa registrada antes da correção (tipo e objeto responsável) | Parcialmente atendido | Tipo restrito a validation rule de estado na Opportunity pai. Causa específica não confirmada |
| Validação em sandbox de QA antes de produção | Bloqueado | Ambiente de QA não conectado à esteira |

A homologação foi aprovada pelo cliente com esses cenários em aberto (ver seção 8).

---

## 5. Histórico do diagnóstico

- **Análise (etapa 1):** critérios de aceite e sete lacunas. Estimativa inicial de 2–6 h. Aprovada no gate em 2026-10-21.
- **Recon (etapa 2):** metadata do objeto, automação e permissões, feito na sandbox de dev. Confirmou que o objeto não explica o erro sozinho.
- **Design (etapa 3):** decisão de não construir nada até a causa ser confirmada. Identificou a cascata de roll-up como complemento do recon. Estimativa revisada para 2–5 h. Aprovado no gate em 2026-10-27.
- **Diagnóstico em dev (etapa 4):** reprodução da cascata com dados sintéticos, sem dado de cliente. Confirmou o mecanismo. Testou M38 por DML direto. Encontrou divergência de metadata entre o baseline e a sandbox (ver seção 6). Todos os registros sintéticos foram apagados. Aprovado no gate em 2026-10-28.
- **Testes (etapa 5):** roteiro preparado, execução bloqueada porque a QA não estava conectada. Registrado como bloqueado, não como homologado.
- **Homologação:** aprovada pelo cliente em 2026-10-28, com a QA não validada e com os dois pontos humanos da seção 7 pendentes.

---

## 6. Limitações conhecidas e dívida técnica

### 6.1 Limitações do diagnóstico

- **Causa raiz não confirmada.** Faltam dois passos humanos (seção 7, itens 1 e 2). Sem eles, a hipótese de M38 é a mais provável, mas não está comprovada para este lançamento.
- **Mensagem de erro exata não obtida.** Nenhum artefato contém o texto do erro. O anexo do card é uma captura de tela da URL, sem texto do erro extraído.
- **Reprodução apenas em dev.** A sandbox de dev não tem nenhum registro do objeto (0 registros). O registro do incidente está em produção. A reprodução usou dados sintéticos e não prova o caso de produção.
- **Estado de violação não alcançável por uso normal.** Em dev, a criação de um segundo `DSA__c` na mesma Opportunity é barrada pela M38. Se a causa for M38, o dado violador chegou a produção por outro caminho. Esse caminho não foi identificado.
- **Recorrência não investigada.** Não se sabe se outros lançamentos são afetados. Se o diagnóstico mostrar que se repete, a análise deve ser refeita.
- **Situação do chamado na Agility não conhecida.** O chamado interno é de julho de 2026. Não se sabe se houve diagnóstico ou correção parcial do lado da Agility.
- **Quem reportou e qual perfil usou não confirmados.** Não se sabe se o erro ocorre para todos os perfis com acesso de escrita.

### 6.2 Divergência de metadata entre baseline e sandbox (achado)

O baseline retrievado de `force-app/` (commit `6ffa5a54`, 2026-10-17) traz campos referenciados por validation rules ativas. Esses campos não aparecem no describe ao vivo de `Opportunity` em `sbx-somos-agility-dev`:

- `Qtde_Propostas_SOW__c` (usado por `M35`)
- `Mapeamento_esta_valido_com_fabricante__c`, `Descreva_mapeada_opp_fabricante__c`, `Condicoes_especiais_de_fornecimento__c`, `Descreva_condicoes_especiais_forneciment__c` (usados por `M17`/`M39`, e provavelmente `M18`/`M19`/`M20`)

Não está claro se a divergência é só da sandbox de dev ou também existe em produção. **Investigar antes de descartar M35, M17–M20 e M39.** Essas regras não puderam ser testadas em dev.

### 6.3 Dívida técnica identificada (fora deste escopo)

- **`Preencher_DSA` é Process Builder**, tecnologia em fim de vida, e roda em toda alteração de `Resultado__c`, inclusive as causadas por roll-up. Não é só deste caso. Afeta qualquer alteração de `Resultado__c`. Migrar para Flow record-triggered merece demanda própria.
- **`Preencher_DSA_Flow` sem fault path.** Falhas dentro do subflow sobem para o usuário sem tratamento. Hipótese secundária deste caso, ainda não testada.
- **Cascata de automação em três objetos.** Um save de filho dispara Process Builder e subflow em `Resultado__c`, e 26 validation rules ativas com dezenas de Flows em `Opportunity`. Risco de ordem de execução e de regra que bloqueia o save de um objeto por causa de dado de outro. Vale revisar quais regras de estado devem existir.
- **Validation rules sem `ISCHANGED`.** As regras M38, M35, M17–M20 e M39 falham em qualquer save da Opportunity, não só nos saves que mudam o campo de negócio. Não são necessariamente erradas, mas devem ser revisadas caso a causa seja confirmada.

---

## 7. Próximos passos (ação humana, fora do alcance do agente)

1. **Obter a mensagem de erro exata do cliente.** Texto integral, idealmente com código `MsgNN`. Se aparecer `Msg38`, `Msg35` ou `Favor descrever (MsgNN)`, a causa fica quase identificada sem nenhuma reprodução.
2. **Conferência humana em produção.** Pessoa autorizada da conta abre a Opportunity pai do lançamento (via `Resultado__c` do lançamento) e verifica, na tela e sem extrair dados:
   - se há 2 ou mais `DSA__c` vinculados;
   - se há 2 ou mais propostas SOW marcadas como atuais;
   - se há campo "Sim" sem a descrição obrigatória.
3. **Se a causa for dado do pai:** corrigir o dado do pai primeiro e só depois ajustar "Renovação Realizado". Corrigir só o valor do lançamento volta a falhar no próximo ajuste de qualquer filho da mesma Opportunity. Não usar perfil de administrador para contornar a regra.
4. **Se a causa for M38 ou equivalente:** descobrir como a Opportunity chegou ao estado de violação (importação, carga, regra criada depois). Sem isso, o problema volta a aparecer.
5. **Se M35, M17–M20 ou M39 forem suspeitas:** confirmar em produção se os campos referenciados existem. Se não existirem, a divergência de metadata é o problema a resolver primeiro.
6. **Conectar `sbx-somos-agility-qa` à esteira** (skill `conectar-ambiente`) e preencher a seção "qa" do `CLAUDE.md` do cliente. Sem isso, nenhuma demanda futura consegue homologação real.
7. **Se a causa confirmada exigir mudança de regra, Flow ou Process Builder:** abrir nova demanda. Este diagnóstico não autoriza build. Uma mudança de regra volta ao gate do arquiteto, com novo design.

---

## 8. Rastreabilidade

- **ID da demanda:** `SOMOSAGILITY-23`
- **Cliente:** somos-agility
- **Registro afetado (produção):** `a6UU40000000Ue1MAE` (`Realizacao_Financeira_de_Venda__c`)
- **Chamado interno de origem:** `20260724-013` (código, sem dado pessoal)
- **Branch:** `feature/SOMOSAGILITY-23`
- **PR:** aberto automaticamente pela esteira na primeira etapa, conforme o CLAUDE.md raiz. Número não confirmado nesta documentação.
- **Deploy ID:** não existe. Nenhum deploy foi executado.
- **Estimativa aprovada pelo cliente:** 4 h (card, 2026-10-21).

### Commits da esteira

| Commit | Etapa | Descrição |
|---|---|---|
| `a3019195` | análise | Gate de análise aprovado |
| `aca6ec8c` | design | Design via CI (dev). Gate de design aprovado |
| `2ed6f636` | diagnóstico | Registro de diagnóstico de reprodução em sandbox, sem build |
| `64fc842c` | status | Avanço para `aguardando_gate_build` |
| `2397610e` | build | Diagnóstico via CI (dev). Gate de build aprovado |
| `d2a86772` | qa | QA via CI (dev). Bloqueada por ambiente |

Nenhum commit altera `force-app/`.

### Gates aprovados (`gates.md`)

| Gate | Aprovado por | Quando (UTC) | Artefatos |
|---|---|---|---|
| `aguardando_gate_analise` | Leonardo Barbosa | 2026-10-21 12:09 | `01-analise.md` |
| `aguardando_gate_design` | Leonardo Barbosa | 2026-10-27 22:59 | `02-recon.md`, `03-design.md` |
| `aguardando_gate_build` | Leonardo Barbosa | 2026-10-28 01:38 | `04-plano-build.md` |
| `aguardando_homologacao` | Juliana Mendes | 2026-10-28 23:25 | `05-testes.md` |

**Nota sobre o intervalo entre comentário e gate:** o comentário do card registra a aprovação às 22:53 (papel "Cliente", sem nome — guardrail #2) e `gates.md` registra o gate efetivado às 23:25 por Juliana Mendes. Isso é consistente com a fila de disparo por cliente (`DisparoEsteira`, CLAUDE.md raiz): a aprovação entra na fila no clique e só dispara quando o cliente fica livre no Actions — não é uma divergência de autoria, é o efeito esperado da fila. Os hashes dos artefatos revisados no gate estão no `gates.md`.

---

## 9. Verificação de conteúdo

Nenhum dado pessoal, valor financeiro do lançamento, nome de demandante ou contato foi copiado para este documento. As consultas feitas na sandbox retornaram só metadata, contagens e nomes de componentes (guardrail #2).
