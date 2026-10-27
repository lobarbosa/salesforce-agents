# SOMOSAGILITY-23 — Plano de build / diagnóstico (builder-declarativo)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (enxuto), 4, 5, 7.
**Org usada:** `sbx-somos-agility-dev` (sandbox, confirmada via `sf org list` — único alias
conectado nesta sessão, `Status: Connected`). Nenhuma org de produção foi tocada, autenticada
ou consultada.
**Gate que libera esta etapa:** `aguardando_gate_design`, aprovado por Leonardo Barbosa em
`gates.md` (2026-10-27T22:59:50Z, commit `aca6ec8c`).

---

## 1. Escopo desta etapa

Conforme `03-design.md`: **nenhuma metadata foi criada ou alterada nesta demanda.** Não há
Flow, campo, objeto, validation rule, permission set ou qualquer componente de
`force-app/` tocado. Esta etapa executa exclusivamente o **passo 3 do plano de diagnóstico**
do design (§3): reprodução em sandbox com dados sintéticos, para testar o mecanismo de
cascata de roll-up (`Realizacao_Financeira_de_Venda__c → Resultado__c → Opportunity`) e a
hipótese de que uma validation rule de estado (sem `ISCHANGED`) na Opportunity bloqueia o
save do filho.

Os passos 1 e 2 do plano de diagnóstico (pedir a mensagem de erro exata ao cliente; humano
autorizado conferir a oportunidade pai em produção) continuam **fora do alcance do agente**
— ação humana, não executada aqui.

## 2. Pré-checagens (guardrail #3 — nada referenciado sem confirmar via `sf`)

Antes de criar qualquer registro, os seguintes campos/objetos foram confirmados ao vivo em
`sbx-somos-agility-dev` (não apenas no baseline retrievado em 2026-10-17 citado no design):

| Componente | Confirmado via | Resultado |
|---|---|---|
| `Realizacao_Financeira_de_Venda__c.Renova_o__c` | `sf sobject describe` | `currency`, `createable`/`updateable` `true` — igual ao recon |
| `Resultado__c.Oportunidade__c` | `sf sobject describe` | lookup/master-detail para `Opportunity`, obrigatório |
| `Resultado__c.RenovacaoRealizado__c` | `sf data query` (antes/depois) | roll-up confirmado funcionando na prática (ver §4) |
| `Realizacao_Financeira_de_Venda__c.Resultado__c` | `sf sobject describe` | lookup obrigatório para `Resultado__c` |
| `Opportunity.N_mero_de_DSA__c` | `sf sobject describe` + metadata local (`force-app/.../Opportunity/fields/N_mero_de_DSA__c.field-meta.xml`) | **roll-up summary (`type Summary`, `summaryOperation count`)** sobre `DSA__c.Oportunidade__c`, não editável diretamente (`calculated: true`, `createable`/`updateable: false`) |
| `DSA__c.Oportunidade__c` | metadata local (`force-app/.../DSA__c/fields/Oportunidade__c.field-meta.xml`) | **Master-Detail** para `Opportunity` (confirma que o roll-up é tecnicamente válido) |
| `DSA__c` campos obrigatórios | `sf sobject describe` | `Oportunidade__c`, `Contato_para_Faturamento_Cobran_a__c`, `Contato_para_Entrega__c` (todos lookup, não-nillable) |
| `ValidationRule M38_Valida_Numero_DSA` (Opportunity) | `sf data query` (Tooling API, `Metadata.errorConditionFormula`) | `N_mero_de_DSA__c >= 2`, **sem exceção de perfil**, `Active: true` |
| `ValidationRule M35_Somente_pode_existir_um_SOW_atual` (Opportunity) | idem | referencia `Qtde_Propostas_SOW__c >= 2` (com exceção de perfil), `Active: true` |
| `ValidationRule M17/M18/M19/M20/M39` (Opportunity) | idem | referenciam campos "Sim"/"descreva" específicos, `Active: true` |

### Achado não previsto pelo design: divergência de metadata entre o baseline e a sandbox viva

O `03-design.md` já avisava que "a metadata de produção pode ser diferente da sandbox" — o
achado aqui é o inverso e mais direto: **campos referenciados por validation rules ativas na
própria `sbx-somos-agility-dev` não existem hoje no describe ao vivo do objeto Opportunity
nessa mesma sandbox**, embora existam no baseline em `force-app/` (retrievado em
2026-10-17, commit `6ffa5a54`):

- `Qtde_Propostas_SOW__c` (referenciado por `M35_Somente_pode_existir_um_SOW_atual`) — **não
  encontrado** no describe ao vivo de `Opportunity`.
- `Mapeamento_esta_valido_com_fabricante__c`, `Descreva_mapeada_opp_fabricante__c`,
  `Condicoes_especiais_de_fornecimento__c`, `Descreva_condicoes_especiais_forneciment__c`
  (referenciados por `M17`/`M39`, e por extensão prováveis equivalentes de `M18`/`M19`/`M20`)
  — **não encontrados** no describe ao vivo.

Ou seja: nesta sandbox, as validation rules M35/M17/M18/M19/M20/M39 estão marcadas como
`Active: true` mas referenciam campos que o describe ao vivo não lista. Isso não impede a
regra de existir no metadata (Salesforce não força recompilação retroativa de uma
`ErrorConditionFormula` existente quando um campo referenciado desaparece do describe-time
accessível por API em certas condições), mas **impede o agente de reproduzir essas
hipóteses nesta sandbox com dados sintéticos**, porque não há como setar um valor num campo
que o describe não expõe como `createable`. Isso não estava prevista no design e é relevante
para quem revisar esta demanda: a única hipótese realmente testável nesta sandbox, dentre as
listadas no §2.5 do design, foi **M38 (`N_mero_de_DSA__c >= 2`)**, porque o campo e o objeto
relacionado (`DSA__c`) existem e são operáveis ao vivo.

**Recomendação para quem seguir o diagnóstico:** confirmar se essa divergência também existe
em produção (via humano autorizado, passo 2 do design) antes de descartar M35/M17-M20/M39 —
pode ser que só a sandbox de dev esteja desatualizada em relação a produção, não o
contrário.

## 3. Setup sintético criado (sem dado de cliente — guardrail #2)

Todos os registros usaram nomes óbvios de teste (`TESTE DIAGNOSTICO SOMOSAGILITY-23`) e
valores fictícios (telefone `0000000000`, valores monetários arbitrários). Nenhum dado de
cliente foi copiado ou inventado. IDs abaixo já não existem mais (apagados ao final, ver §6).

| Ordem | Objeto | Id (apagado) | Observação |
|---|---|---|---|
| 1 | `Contact` | `003Ha00000pUbb3IAC` | `LastName='TESTE DIAGNOSTICO SOMOSAGILITY-23'`, `Phone='0000000000'` (validation rule nativa do objeto exige telefone) |
| 2 | `Opportunity` | `006Ha00000Q50q1IAB` | `Name='TESTE DIAGNOSTICO SOMOSAGILITY-23'`, `StageName='Qualificação'`, `CloseDate=2026-12-31`, `Conversao_de_Lead__c='Não'` |
| 3 | `Resultado__c` | `a6xHa0000002BSPIA2` | `Oportunidade__c` apontando para a Opportunity acima |
| 4 | `Realizacao_Financeira_de_Venda__c` | `a6UHa0000004Cx3MAE` | `Resultado__c` apontando para o Resultado acima, `Renova_o__c=100` (criado com a Opportunity ainda sem nenhum DSA — estado válido) |
| 5 | `DSA__c` (1º) | `a00Ha00000ONbNdIAL` | `Oportunidade__c` apontando para a Opportunity acima, contatos de faturamento/entrega = o Contact acima |

## 4. Tentativas e resultados

### Tentativa 1 — confirmar o mecanismo de cascata de roll-up (sem violação de regra)

Com a Opportunity em estado válido (0 depois 1 `DSA__c`, abaixo do limite de `M38`),
atualizei `Renova_o__c` do RFV sintético de `100` para `250` (`sf data update record`).

- **Resultado: salvou sem erro.**
- Conferido que o roll-up propagou de verdade pela cadeia inteira:
  - `Resultado__c.RenovacaoRealizado__c` → `250`
  - `Opportunity.RenovacaoRealizado__c` → `250`

**Conclusão desta tentativa:** o mecanismo de cascata descrito no design (§2) é real e
funciona tecnicamente como previsto — editar `Renova_o__c` no filho realmente recalcula e
resalva os dois pais. Isso por si só não causa erro quando a Opportunity respeita as regras
ativas.

### Tentativa 2 — tentar colocar a Opportunity em estado de violação de `M38` via DML direto

Tentei criar um **segundo** `DSA__c` vinculado à mesma Opportunity (que já tinha um),
esperando que isso deixasse `N_mero_de_DSA__c = 2`, violando `M38_Valida_Numero_DSA`
(`N_mero_de_DSA__c >= 2`).

- **Resultado: a criação do 2º `DSA__c` foi bloqueada na hora**, com o erro
  `FIELD_CUSTOM_VALIDATION_EXCEPTION: Esta Oportunidade já possui um DSA. Revise o DSA já
  existente (Msg38)`.
- Confirmado por query que o 2º `DSA__c` **não foi persistido** (rollback automático da
  transação) — nenhum registro órfão ficou para trás.

**Conclusão desta tentativa (achado relevante, não previsto no design):** como
`DSA__c.Oportunidade__c` é **Master-Detail** (não lookup simples), inserir o filho que
levaria a Opportunity à violação **já dispara a validação da Opportunity no mesmo DML do
insert do `DSA__c`** — o erro aparece na criação do 2º DSA, não depois, numa edição
qualquer de um terceiro objeto. Isso significa que, **nesta sandbox, não é possível chegar a
uma Opportunity com 2+ DSAs através de inserção normal via API/UI**, porque a própria
tentativa de criar o segundo registro já seria barrada — exatamente a mesma regra que
supostamente bloquearia depois a edição de `Renova_o__c`.

Isso **não descarta** a hipótese do design, mas a **torna mais específica**: se `M38` for
mesmo a causa em produção, o estado de violação ali (2+ DSAs numa mesma Opportunity) precisa
ter sido alcançado por um caminho que não passa pela validação normal de criação — por
exemplo, um `DSA__c` criado antes de `M38` existir/estar ativo, uma carga em lote com algum
bypass de validação, ou dado migrado. Não há como confirmar isso sem acesso a produção
(passo 2 do design, ação humana).

### Tentativa 3 — M35 e M17/M18/M19/M20/M39

**Não executada.** Os campos que essas regras referenciam
(`Qtde_Propostas_SOW__c`, `Mapeamento_esta_valido_com_fabricante__c`, etc.) não existem no
describe ao vivo de `Opportunity` nesta sandbox (ver achado em §2), então não há como
configurá-los via `sf data create/update record` sem inventar metadata — o que o guardrail
#3 proíbe. Ficam como hipóteses **indefinidas**, não enfraquecidas nem fortalecidas.

## 5. Avaliação da hipótese do design

| Elemento da hipótese (03-design.md §2) | Status após esta etapa |
|---|---|
| Mecanismo técnico da cascata (RFV → Resultado__c → Opportunity via roll-up) | **Confirmado** — reproduzido de ponta a ponta nesta sandbox |
| `M38` como causa específica | **Indefinida, mas mais específica.** A regra existe, está ativa, bloqueia exatamente como descrito — mas o estado de violação não é alcançável por inserção normal nesta sandbox. Se for a causa em produção, o dado violador chegou lá por outro caminho (import, bypass, ordem histórica), não por uso normal da tela. |
| `M35`/`M17`-`M20`/`M39` como causa | **Indefinida** — não testável nesta sandbox, campos referenciados pelas regras não existem no describe ao vivo (achado novo, §2) |
| Subflow `Preencher_DSA_Flow` sem fault path (hipótese secundária) | **Não testada nesta etapa** — exigiria forçar uma falha dentro do subflow (ex.: múltiplas `DSA__c` retornadas pela busca por oportunidade, ou ausência de dado que o subflow espera), o que não foi tentado porque o foco era a hipótese principal; fica como próximo passo se os passos 1/2 do design não fecharem a causa |

**Conclusão geral:** a hipótese do design não foi nem confirmada nem derrubada. O
diagnóstico avançou — o mecanismo técnico da cascata está provado, e a lista de hipóteses
testáveis nesta sandbox ficou mais estreita (só `M38` é operável; as demais exigem dados
que não existem aqui) — mas a causa raiz continua dependendo dos passos 1 e 2 do design
(mensagem de erro exata do cliente; humano autorizado olhando a oportunidade pai em
produção).

## 6. Limpeza (sem lixo de teste)

Todos os 5 registros sintéticos foram apagados ao final, na ordem filho → pai
(`Realizacao_Financeira_de_Venda__c` → `DSA__c` → `Resultado__c` → `Opportunity` →
`Contact`). Confirmado por `sf data query` que:
- `Realizacao_Financeira_de_Venda__c`: 0 registros na org
- `Opportunity` com `Name='TESTE DIAGNOSTICO SOMOSAGILITY-23'`: 0 registros
- `Contact` com `LastName='TESTE DIAGNOSTICO SOMOSAGILITY-23'`: 0 registros

Nenhum registro sintético permanece em `sbx-somos-agility-dev`.

## 7. O que NÃO foi feito nesta etapa (como previsto no design)

- **Nenhuma metadata foi criada ou alterada.** Não há diff em `force-app/` nesta sessão.
- Nenhum deploy (`sf project deploy start`) foi executado — não havia o que implantar.
- Nenhuma correção de dado ou de regra foi aplicada em produção — fora do alcance do agente
  (guardrail #1).
- Nenhum dado de produção foi lido, copiado ou referenciado.

## 8. Próximos passos (ação humana, fora desta sessão)

1. **Passo 1 do design:** pedir ao cliente (via card) o texto integral da mensagem de erro
   em produção. Se aparecer "Msg38", "Msg35" ou "Favor descrever (MsgNN)", a causa fica
   identificada quase com certeza.
2. **Passo 2 do design:** humano autorizado confere, em produção, se a Opportunity pai do
   lançamento `a6UU40000000Ue1MAE` tem 2+ `DSA__c`, 2+ propostas SOW marcadas como "Proposta
   Fechada pelo Cliente", ou algum campo "Sim" (mapeamento/condições especiais) sem a
   descrição obrigatória.
3. Se a causa confirmada for M38 (ou equivalente), confirmar também **como** a Opportunity
   chegou a esse estado (import, bypass, histórico) — achado desta etapa (§4, Tentativa 2)
   mostra que isso não acontece por uso normal da tela.
4. Se M35/M17-M20/M39 forem suspeitas após o passo 1, confirmar em produção se os campos que
   essas regras referenciam realmente existem lá — nesta sandbox de dev eles não existem
   (achado §2), o que pode ser uma divergência de ambiente a resolver separadamente.
5. Conforme a causa confirmada, este design é refeito (ou se mantém "sem build" se for só
   correção de dado) e o fluxo volta ao gate do arquiteto se mudar para build declarativo.

---

Artefato de diagnóstico, não de construção — nenhum componente de `force-app/` foi criado
ou alterado nesta etapa, exatamente como `03-design.md` previu.
