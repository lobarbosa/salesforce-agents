# SOMOSAGILITY-26 — Design (arquiteto)

**Cliente:** somos-agility · **Tipo:** sustentação (design enxuto) · **Refeito em:** 2026-11-20
**Org consultada:** `sbx-somos-agility-dev` (sandbox), confirmada com `sf org list` nesta sessão. Só leitura: describe filtrado, Tooling, contagens agregadas e retrieve para `/tmp` (fora de `force-app/`). Nenhum registro lido.
**Entradas:** `01-analise.md` (aprovada em 2026-11-10), `02-recon.md` (2026-11-20), `comentarios-do-card.md` (especificação da equipe de 17/11), `00-preflight.md` (sem bloqueio, sem outra demanda nos mesmos componentes).

Este desenho **substitui** o de 10/11. O anterior convertia 4 campos de "Cenário 1" e escalava a cadeia PFP; a especificação de 17/11 trocou o pedido para **campos novos PFP 1/2/3 em Long Text Area nos 3 objetos + ajuste do Flow, lógica igual**. A conversão dos 4 campos de "Cenário 1" sai desta demanda (seção 9).

---

## 1. Decisão

1. **Configuração (campos, layouts, FLS) + nova versão de um Flow que já existe. Sem Apex.**
2. **9 campos novos `LongTextArea`**, 3 por objeto, com API name `PFP_1_Texto__c`, `PFP_2_Texto__c`, `PFP_3_Texto__c` e rótulos "PFP 1", "PFP 2", "PFP 3". O mesmo API name nos 3 objetos para o Flow e o suporte lerem a cadeia sem tradução.
3. **Nenhum campo antigo é alterado, excluído ou tirado de layout.** Os novos entram nos mesmos layouts, logo abaixo do antigo correspondente.
4. **Flow `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`: versão nova (v2) em `Draft`**, com a mesma lógica apontando para os campos novos. A v1 (ativa, única) não é editada. Ativação da v2 é passo separado, depois da verificação.

**Mudança de modelo de dados (destaque).** Criar 9 campos é mudança de modelo de dados, que a regra do papel manda escalar. A especificação veio da equipe no card (17/11) e o desenho segue a leitura literal dela, mas **o aceite deste gate precisa confirmar explicitamente o modelo** (a leitura literal tem a consequência da seção 6, R1).

### Por que não outro nível
- **Configuração pura não basta:** o valor do BluePrint precisa chegar à PSL, e quem faz isso hoje é o Flow. Fórmula não serve: campo fórmula não lê nem devolve Long Text Area (é o motivo de não converter os campos antigos, que alimentam fórmulas; ver 2.3).
- **Flow já existe e resolve.** É só trocar campos, sem lógica nova. Nenhum critério da doutrina para Apex se aplica (sem callout, sem rollback complexo, sem volume alto, sem recursão nova).

## 2. O que esta etapa confirmou na org, além do recon

| # | Achado | Evidência |
|---|---|---|
| 2.1 | `PFP_1_Texto__c`, `PFP_2_Texto__c`, `PFP_3_Texto__c` **não existem** nos 3 objetos. Rótulo "PFP 1/2/3" exato também não. | describe dos 3 objetos, filtro "pfp" |
| 2.2 | `Opportunity.BluePrint__c` existe (lookup para `BluePrint__c`); é o caminho `Oportunidade__r.BluePrint__r` do Flow. `FluxoVendaProdutos__c.PropostaSolucao__c` é lookup para a PSL. | describe |
| 2.3 | Fórmulas que dependem dos campos antigos: `FluxoVendaProdutos__c.PFPNUNCPath__c` = `PropostaSolucao__r.PFP_N__c`; `Propostas_de_Solucao__c.PFP_N_UNC_Path__c` = `Oportunidade__r.BluePrint__r.PFP_N_UNC_Path__c` (N = 1..3). | retrieve dos campos |
| 2.4 | Validation rules: **19 lidas (todas)**, 15 ativas. Só `M03_Obrigatorio_preenchimento_campos_PFP` cita `PFP_N__c`, e está **inativa**. As demais que citam "PFP" usam `PFP_N_Fechada__c`/`Nome_PFP_N__c`. Nenhuma cita campo novo (não existem). | retrieve + grep |
| 2.5 | Dos 12 Flows do recon, 2 são de `Opportunity` (não dos 3 objetos). Por objeto: PSL 5 after-save (`Atualiza_os_Campos_PFP...`, `Cria_o_da_Proposta`, `Margens_e_Condi_es_Especiais`, `Nova_Proposta_de_Solu_o_SOW_CCS`, `Propostas_de_Solu_o`), nenhum com `triggerOrder`; BluePrint 1 (`Atualiza_Campo_Blueprint_da_Oportunidade`, after-save); FVP 4 (`Definir_BOM`, `SolicitacaoPrecos`, `Replica_o_status_da_FVP_para_PSL` after-save; `EmailOrcamentista` before-save). **Só o Flow da demanda cita campos PFP.** `TrgPropostasSolucao` não cita PFP. | retrieve dos 11 Flows + trigger, grep |
| 2.6 | O Flow da demanda: 7 decisões `IsNull` sobre `$Record.PFP_N__c`; 3 fórmulas String com `$Record.Oportunidade__r.BluePrint__r.PFP_N_UNC_Path__c`; 7 `recordUpdates` com `inputReference $Record`, **cada um uma DML separada** no próprio registro. Entrada: `Oportunidade__c` não nulo, sem "só quando mudar". | XML |
| 2.7 | Layouts com os campos antigos: **16** — BluePrint 1 ("Layout de BluePrint"); PSL 10 (todos os 10 do objeto); FVP 5 ("Layout de Fluxo de Venda de Produto", "Produtos na PFP", "Solicitação de Preços", "Validar Cotação", "Validação Fiscal"). | retrieve de Layout + grep |
| 2.8 | FLS dos campos antigos (agregado): `BluePrint__c.PFP_1_UNC_Path__c` 59 perfis + 1 permission set, todos com edição; `PSL.PFP_1__c` 67 perfis + 2 PS, edição; `FVP.PFP1UNCPath__c` 66 perfis + 2 PS, só leitura (é fórmula). | `FieldPermissions` GROUP BY |
| 2.9 | Long Text Area já usada: BluePrint 32.768 (`Observa_es__c`); PSL 70.536; FVP 0. Com +3 × 32.768 cada, o maior fica em ~168.840, longe do teto por objeto da plataforma. Campos custom: 29 / 74 / 12. | describe |

## 3. Componentes

### 3.1 Criar — 9 campos (`CustomField`)

| Objeto | API name | Rótulo | Tipo | Tamanho | Linhas visíveis | Fica abaixo de (layout) |
|---|---|---|---|---|---|---|
| `BluePrint__c` | `PFP_1_Texto__c` / `_2_` / `_3_` | PFP 1 / 2 / 3 | LongTextArea | 32.768 *(hipótese, G3)* | 3 | `PFP_N_UNC_Path__c` |
| `Propostas_de_Solucao__c` | `PFP_1_Texto__c` / `_2_` / `_3_` | PFP 1 / 2 / 3 | LongTextArea | 32.768 | 3 | `PFP_N__c` |
| `FluxoVendaProdutos__c` | `PFP_1_Texto__c` / `_2_` / `_3_` | PFP 1 / 2 / 3 | LongTextArea | 32.768 | 3 | `PFPNUNCPath__c` |

- O tamanho tem de ser **igual nos 3 objetos** (destino ≥ origem), senão o Flow falha com valor longo.
- Descrição obrigatória em cada campo (DoD `padrao-entrega`): "Caminho/link da PFP N sem limite de 255. SOMOSAGILITY-26." Na PSL e no BluePrint, citar que o Flow copia do BluePrint para a PSL.
- Sem `required`, sem histórico, sem valor padrão.

### 3.2 Alterar — 16 layouts
Os 16 da tabela 2.7: incluir o campo novo logo abaixo do antigo, mesma seção, mesmo comportamento de edição que o antigo tem em cada layout (o build replica `Edit`/`Readonly` do antigo). No FVP o antigo é fórmula (só leitura); o novo entra **editável** — premissa P2.

### 3.3 Alterar — Flow (versão nova)
`Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada`
- **Sai do repositório como v2, `<status>Draft</status>`**. A v1 continua ativa até o passo de ativação.
- Troca, sem mudar estrutura, decisões, conectores nem critério de entrada:
  - decisões: `$Record.PFP_N__c` → `$Record.PFP_N_Texto__c`;
  - `recordUpdates`: campo `PFP_N__c` → `PFP_N_Texto__c`;
  - origem: `$Record.Oportunidade__r.BluePrint__r.PFP_N_UNC_Path__c` → `...BluePrint__r.PFP_N_Texto__c`. **Usar referência direta no `inputAssignments`** (elementReference ao campo do `$Record`) no lugar das fórmulas String, que podem ser removidas ou ficar sem uso. Motivo: não confirmei como fórmula de Flow trata Long Text Area acima do tamanho de texto (incerteza I3); a referência direta evita a dúvida e é a mesma lógica.
- Rótulo/descrição da v2: "v2 SOMOSAGILITY-26: campos PFP N Long Text Area".
- **Ativação (passo separado, no plano de build):** depois de `04-verificacao.md` aprovada em dev, ativar v2 (v1 vira Obsolete). Na QA, a esteira leva a v2 e a ativação segue o mesmo passo, registrado. **Desfazer:** reativar a v1.

### 3.4 Alterar — FLS dos 9 campos
Espelhar, campo a campo, a FLS do campo antigo correspondente (2.8): mesmos perfis e permission sets, mesmo nível. Exceção: no FVP o antigo é só leitura por ser fórmula; o novo recebe **leitura e edição** nos mesmos perfis/PS que têm edição no objeto FVP (premissa P2). Entrega em `force-app/` como `fieldPermissions` nos perfis e PS, sem tocar outra permissão deles.

### 3.5 Depreciar
**Nada.** `PFP_N__c`, `PFP_N_UNC_Path__c` (BluePrint e PSL), `PFPNUNCPath__c` e a v1 do Flow ficam. Aposentar os antigos e migrar dados é demanda futura (seção 9).

## 4. Permissões
- 9 campos novos × ~60–69 grants cada, espelhados (3.4). Nenhum perfil ou PS novo, nenhuma atribuição de usuário.
- **Assessment, perfil por pessoa (20 de 26 perfis com 1 usuário):** espelhar em perfis multiplica a manutenção (é o risco), mas criar agora um PS e atribuir usuários mudaria o modelo de acesso, que ninguém pediu. Escolho não piorar nem consertar: mesmo conjunto de quem já vê o PFP. Registrado como dívida.
- QA: o usuário de integração da esteira precisa ter FLS de edição nos 9 campos para criar massa; se não tiver pelo espelho, usar PS temporário só na sandbox, removido ao fim e registrado em `05-testes.md`.

## 5. Automação concorrente, ordem de execução e escala

**Risco de ordem de execução (já existe, a mudança mantém):** na PSL rodam 5 Flows after-save, nenhum com `triggerOrder`, e o trigger `TrgPropostasSolucao`. O Flow da demanda atualiza o próprio `$Record` com até 3 DMLs separadas por save, e cada uma dispara de novo o trigger e os after-save da PSL. A ordem entre eles é indefinida. A v2 não acrescenta DML, Flow ou trigger; só troca campos. Nenhum outro Flow, trigger ou VR lê os campos novos (2.4, 2.5).

- **Efeito de editar os campos novos:** salvar um BluePrint dispara `Atualiza_Campo_Blueprint_da_Oportunidade` (já acontece com qualquer campo); salvar um FVP dispara os 4 Flows do FVP, e `Replica_o_status_da_FVP_para_PSL` pode atualizar a PSL, que então roda o Flow da demanda. Nada disso é novo.
- **Governador:** sem SOQL nova (a leitura `Oportunidade__r.BluePrint__r` já existe). DML: as mesmas até 3 por PSL. Heap: 3 valores de até 32 KB por PSL na interview; em carga de 200 PSLs, ~19 MB de pior caso teórico se todos estiverem cheios no limite — **irrealista para caminho de rede, mas é o motivo de G3 propor teto menor** (ex.: 2.000).
- **Um pai com muitos filhos (achado SOMOSAGILITY-10):** esta demanda não cria automação pai→filhos. O FVP novo não é alimentado por automação (P2). Se o gate escolher a opção G1-c (alimentar FVP a partir da PSL), esse cenário passa a valer e o desenho volta para cá.
- **Volume:** 0 registros nos 3 objetos em dev. Validação e QA com massa sintética: Opportunity com `BluePrint__c`, BluePrint com `PFP_N_Texto__c`, PSL ligada à Oportunidade, FVP ligado à PSL. A massa precisa satisfazer as 15 VRs ativas (M01, M02, M05, `CNPJ_obrigatorio_se_PFP_fechada*` etc.) e passa pelas 31 automações de Oportunidade do assessment.

## 6. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Regressão no FVP e na PSL antiga pela leitura literal.** Com a v2 ativa, o Flow deixa de copiar o BluePrint para `PSL.PFP_N__c`. Em PSL nova, `PFP_N__c` fica vazio, e as fórmulas `FVP.PFPNUNCPath__c` (5 layouts: Solicitação de Preços, Validar Cotação, Validação Fiscal...) também. E o `FVP.PFP_N_Texto__c` novo não é alimentado por nada. Quem trabalha no FVP deixa de ver a PFP sem digitar. | **Alta** | Pergunta G1 ao gate, com opções e custo. Não bloqueia o build da leitura literal; bloqueia a ativação da v2 na QA se G1 não for respondida. |
| R2 | Dados históricos: PSL/BluePrint existentes em produção têm valor nos antigos e vazio nos novos. O Flow v2 copia para a PSL só o que estiver no **novo** campo do BluePrint. | Média | Antigos continuam no layout (3.2). Carga de antigo → novo é fora daqui (seção 9), decisão do cliente. |
| R3 | Dois campos "PFP 1" na mesma tela (antigo "*PFP 1 (UNC Path)" e novo "PFP 1"): usuário pode preencher o errado. | Média | Ajuda de campo no novo; G4 pergunta se o antigo sai do layout. |
| R4 | Long Text Area não filtra em `WHERE`, não ordena, não entra em fórmula nem filtro de list view; em relatório só "contém". | Baixa | Nada na org usa os campos novos (nascem agora). |
| R5 | Consumidores fora da API de dependências (relatórios, Conga/SDocs, SnapERP) que esperam o valor nos antigos. | Média | Não verificável aqui; G5. |
| R6 | Paridade dev x QA não conferida (QA não conectada). | Média | `deploy validate` contra QA no PR (CI). |
| R7 | Reversão: excluir campo novo apaga seus dados; reverter Flow é reativar v1. | Baixa | Antes de valor real gravado, rollback é limpo. |

## 7. Riscos do assessment que tocam esta demanda

| Risco | Como este design lida |
|---|---|
| 31 automações em Oportunidade (24 no mesmo evento) e 59 Process Builders | Não altera Oportunidade nem automação dela. Toca indiretamente só ao **criar massa de teste** (Opportunity com BluePrint): o QA deve esperar efeitos dessas automações e não atribuí-los à demanda. Process Builders nos 3 objetos: não verifiquei (I5). |
| Cobertura Apex 40% | Não se aplica: sem Apex novo ou alterado. `TrgPropostasSolucao` roda como hoje; o deploy de campos, layouts, perfis e Flow não exige rodar testes de cobertura em sandbox. |
| 20 de 26 perfis com 1 usuário | Aplica-se: FLS espelhada em ~60 perfis por campo (seção 4). Não piora o modelo, não conserta. |
| 387 Validation Rules | Nos 3 objetos: 19, todas lidas; nenhuma ativa toca PFP_N (2.4). Pesa só na massa de teste. |

## 8. Premissas (validar na homologação; não bloqueiam o build)

- **P1** — Leitura literal: 3 campos em **cada** um dos 3 objetos (9 campos).
- **P2** — No FVP, os campos novos são de digitação manual (editáveis), sem automação; o Flow só liga BluePrint → PSL, como hoje.
- **P3** — O Flow v2 passa a trabalhar **só** com os campos novos ("ajustar com os novos campos"); os antigos deixam de ser alimentados por ele.
- **P4** — Tamanho 32.768, padrão da plataforma e o mesmo das LTAs já usadas na org.
- **P5** — Validação em dev e QA com massa sintética (0 registros nos 3 objetos).

## 9. O que NÃO será feito nesta demanda

- Converter, excluir, renomear ou tirar de layout `PFP_N__c`, `PFP_N_UNC_Path__c`, `PFPNUNCPath__c`.
- Migrar dados antigos para os campos novos.
- Automação nova para alimentar `FVP.PFP_N_Texto__c` (só se o gate escolher G1-c, com novo desenho).
- A conversão dos 4 campos de "Cenário 1" (`Cotacao__c`, `Proposta_Acabada__c`, `Informa_es_T_cnicas_Complementares__c`, `Aceite_do_cliente__c`) do desenho anterior.
- Mexer no Flow `Concatenacao_download1` (obsoleto) ou em Oportunidade.
- Link clicável ou validação de formato URL/UNC.
- Criar permission set ou consolidar perfis.

## 10. Perguntas para o gate

| # | Pergunta | Bloqueia? |
|---|---|---|
| G1 | **R1:** o que o FVP deve mostrar? (a) leitura literal, como desenhado: FVP digitado à mão, antigos param de ser alimentados; (b) a v2 copia para os novos **e** continua copiando antigo → antigo (BluePrint URL → `PSL.PFP_N__c`), preservando as fórmulas do FVP — +0,5 h, até 6 DMLs por save na PSL; (c) automação nova PSL → FVP para preencher `FVP.PFP_N_Texto__c` — volta ao design (cenário pai com muitos filhos). Recomendo **(b)** se o cliente usa o FVP no dia a dia. | Não bloqueia o build; **bloqueia ativar a v2 na QA** |
| G2 | Confirma o modelo: 9 campos novos, API `PFP_N_Texto__c`? (mudança de modelo de dados) | Sim (aceite do gate) |
| G3 | Teto do campo: 32.768 ou menor (ex.: 2.000)? | Não |
| G4 | Os antigos saem do layout agora ou ficam até uma migração? | Não |
| G5 | Algum relatório, template Conga/SDocs ou integração SnapERP lê `PFP_N__c` ou as fórmulas? | Não |

## 11. Incertezas declaradas

- **I1** Process Builders e FlexiPages (Dynamic Forms) dos 3 objetos: a consulta de FlexiPage devolveu 0, mas filtrei por nome de objeto, que pode não casar com `EntityDefinitionId` de objeto custom; não confirmado.
- **I2** Relatórios, templates e integrações que leem os antigos: não verificado.
- **I3** Comportamento de fórmula de Flow com Long Text Area acima de 255: não confirmado; contornado com referência direta (3.3).
- **I4** Paridade com `sbx-somos-agility-qa`: não comparada.
- **I5** FLS de perfis por nome: só agregados; o build lê os perfis no retrieve para espelhar.

## 12. Estimativa

**Estimativa de esforço:** 5–7 h

- 9 campos com descrição: 0,5 h. 16 layouts: 0,5–1 h. FLS espelhada (~9 × 60–69 grants, gerada a partir do retrieve dos perfis): 0,5–1 h. Flow v2 + ativação: 0,5 h.
- Verificação em dev com massa sintética passando pelas VRs e automações de Oportunidade: 1–1,5 h.
- QA, roteiro do cliente, PR e release: 1,5–2 h.
- G1 (b): +0,5 h. G1 (c): reestimar.

**O que mudou em relação à análise (3–8 h) e por quê:** o pedido mudou (de 5 campos alterados para 9 campos novos em 3 objetos + Flow), e o recon mostrou o custo real: 16 layouts e ~60 perfis por campo para FLS (efeito do perfil por pessoa do assessment), mais a massa de teste que atravessa as automações de Oportunidade. Dependências e VRs foram todas lidas, o que tira o teto de 8 h. **Passa das 3 h aprovadas pelo cliente em 2 a 4 h**, principalmente por layouts e FLS: sem eles os campos ficam invisíveis para o usuário. Para caber mais perto de 3 h, o gate pode cortar os campos do FVP (−1 h aprox.), já que eles não são alimentados por nada (R1).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
