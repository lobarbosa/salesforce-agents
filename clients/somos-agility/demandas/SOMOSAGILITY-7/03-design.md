# SOMOSAGILITY-7 — Design (sustentação, enxuto)

**Cliente:** somos-agility · **Org de referência:** `sbx-somos-agility-dev` · **Data:** 2026-10-21
**Entradas:** `01-analise.md` (aprovada em `gates.md`), `comentarios-do-card.md` (P1, P2, P3),
`02-recon.md` (coleta de 2026-10-21).

---

## 1. Problema, já com o que a org mostrou

`Lancamento_de_Atividades__c` guarda até 3 executores no mesmo registro. Cada um tem um status
secundário (`Status_de_aprovacao_1__c`, `_2__c`, `_3__c`). O Status Geral (`Status__c`) deveria
ser a consolidação deles, conforme a regra P1.

Hoje ninguém recalcula o geral quando o GP **aprova um executor e ainda há outros pendentes**,
nem quando o GP **rejeita**. Nesses dois casos o geral fica preso em "Pendente - Gerente de
projeto". O único recálculo que existe (`Atualiza_o_status_final_de_aprovacao_do_LAT` v4) só cobre
o caso "todos aprovados → Aprovado". Detalhes e tabela de transições em `02-recon.md` §3.

## 2. Regra de consolidação proposta

Vale só para as posições em uso (N ≤ `Qtd_de_executores__c`). Avaliar na ordem abaixo: a primeira
linha que bater define o valor.

| # | Condição nos secundários em uso | `Status__c` resultante | Fonte |
|---|---|---|---|
| R1 | algum = Pendente - Gerente de projetos | Pendente - Gerente de projeto | P1 + approval atual |
| R2 | todos = Aprovado | Aprovado | P1 + flow v4 |
| R3 | algum = Pendente - Preenchimento do executor | Pendente - Preenchimento do(s) executor(es) | P1 ("volta para Pendente para o próximo executor") |
| R4 | algum = Rejeitado (e nenhum caso acima) | Pendente - Preenchimento do(s) executor(es) | **Proposta do agente, não confirmada (L1)** |
| R5 | nenhum dos casos acima (ex.: todos Rascunho, Qtd vazia) | não altera | Preserva o comportamento atual |

O flow só grava se o valor calculado for diferente do atual (idempotente, sem save à toa).

## 3. Decisão: nova versão do Flow existente (declarativo)

**Alterar `Atualiza_o_status_final_de_aprovacao_do_LAT`** criando a v5, que passa a calcular o
Status Geral completo pela tabela §2 em vez de só promover para Aprovado.

### Por que não configuração (o nível acima)
A alternativa de configuração foi avaliada. Seria criar um field update "Status geral = Pendente -
Preenchimento do(s) executor(es)" e anexá-lo às ações de aprovação final e rejeição final dos 3
approval processes ativos, deixando o flow v4 promover para Aprovado no fim. Foi descartada
porque:
1. **A regra ficaria espalhada em 4 lugares** (3 approval processes + 1 flow). E a próxima
   divergência viria pelo mesmo caminho da de hoje: alguém mexe num ponto e esquece os outros.
2. **Gera estado intermediário falso.** No último executor aprovado, o geral iria para "Pendente -
   Preenchimento" e logo depois para "Aprovado". `Status__c` tem `trackHistory=true`, então isso
   poluiria o histórico.
3. **Não cobre a auto aprovação do GP.** `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos`
   grava o secundário direto, sem passar por approval process.
4. Alterar ações de approval process **ativo** por deploy de metadata tem restrições na
   plataforma. O risco é maior que versionar um flow.

Ela fica registrada como **plano B**, caso o arquiteto humano prefira não versionar o flow.

### Por que não código
Não há nada que um flow não resolva: é uma consolidação de 3 picklists do próprio registro, sem
SOQL, sem cálculo entre registros e com volume baixo. O objeto não tem nenhum Apex trigger nem
classe. Introduzir um trigger agora criaria uma segunda tecnologia de automação no objeto, sem
ganho.

### Mudança de modelo de dados
**Nenhuma.** Nenhum campo, valor de picklist ou objeto é criado ou alterado. Por isso não há
escalonamento de arquitetura sênior.

## 4. Componentes

### Alterar
| Componente | Tipo | Mudança |
|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow record-triggered (after save, Update) | Nova versão v5. (a) Entrada: manter `Status__c` ∈ {Rascunho, Pendente - Preenchimento do(s) executor(es), Pendente - Gerente de projeto}; não incluir Aprovado nem os valores legados (Rejeitado, Recall, Pendente, Aguardando Aprovação). (b) Formula resource texto `fxStatusGeralCalculado` implementando §2 sobre `$Record` (CASE/IF por `Qtd_de_executores__c`, mapeando os rótulos geral ↔ secundário valor a valor). (c) Decision: calculado não vazio **e** diferente de `$Record.Status__c`. (d) Um único Update Records em `$Record` gravando `Status__c`. (e) Definir `triggerOrder` alto (ex.: 900) para rodar depois de `Fluxo_de_auto_aprovacao_...` no mesmo save. (f) Descrição da versão citando SOMOSAGILITY-7. |

### Criar
Nenhum componente de metadata. Só massa de teste em `sbx-somos-agility-dev` (Projeto, Marco,
contatos executores e LATs com Qtd 1, 2 e 3). É dado sintético e não vira metadata do pacote.

### Depreciar
Nenhum nesta demanda. A v4 vira Obsolete automaticamente ao ativar a v5, e fica disponível para
rollback (reativar a v4).

## 5. Conflito de automação e ordem de execução

**RISCO DE ORDEM DE EXECUÇÃO: há 4 flows after-save de Update ativos no mesmo objeto, todos sem
`triggerOrder`:** `Atualiza_o_status_final_de_aprovacao_do_LAT`,
`Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos`,
`Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` e
`Subtrai_Horario_de_Almo_o`. **Existe também um Process Builder ativo
(`Lancamento_de_Atividades_GP`) que grava o registro em todo save.**

**O conflito direto é com `Fluxo_de_auto_aprovacao_...`, que grava os mesmos secundários que o
flow de status lê, e grava sem critério de entrada (em todo update).**

Mitigação no design:
- O flow de status calcula a partir do estado final de `$Record`, sem depender de quem gravou
  antes, e só grava quando o valor muda. Se rodar antes da auto aprovação, o save recursivo
  disparado por ela recalcula e corrige.
- O `triggerOrder` alto deixa a ordem determinística dentro do mesmo save.
- Nada nos outros flows é alterado.

Não há Apex trigger no objeto (confirmado), então não existe conflito trigger x flow.

## 6. Limites e escala
- O flow não faz nenhuma consulta: usa só campos do `$Record` e fórmula. Faz no máximo 1 DML
  condicional por registro, que a plataforma agrupa em lote.
- Volume em dev: 0 registros (sem dados do processo). O volume em produção é desconhecido para o
  agente. A operação é por registro alterado e não percorre filhos, então o volume não muda a
  abordagem.
- Recursão: a cadeia "approval grava secundário → auto aprovação regrava secundário → Process
  Builder grava GP → flow de status" já existe hoje. A v5 não acrescenta save quando o valor já
  está certo, e o caso normal acrescenta no máximo um.

## 7. Impacto em permissões
- **Sem mudança em perfis ou permission sets.** O flow roda em contexto de sistema.
- Para build e QA em `sbx-somos-agility-dev`: o usuário da sessão não tem FLS nos campos de 3
  executores (`02-recon.md` §1). Para criar massa de teste e conferir resultado vai precisar do
  permission set `Lancamento_de_atividades_admin` atribuído. Para exercitar os approval processes
  de verdade, vai precisar ser submissor permitido/aprovador, ou usar um usuário da sandbox que já
  seja. **Decisão do humano**, porque atribuir permissão é mudança de setup na sandbox.

## 8. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| T1 | **Ordem de execução entre 4 flows after-save + Process Builder no mesmo objeto** (§5) | **Alta** | Cálculo idempotente sobre o estado final + `triggerOrder`; cenário de teste específico de GP-executor |
| T2 | Paridade dev x produção não verificada: a v4 de dev pode não ser a de produção (D2), e P3 cita flows "Somatória" que em dev estão inativos desde 2019 (D1) | **Alta** | Antes de promover, o humano compara a versão ativa do flow em produção com a de dev (o agente não acessa produção) |
| T3 | Disparo do flow pelo field update do approval process não reproduzido (D3). Se não disparar, nem a v4 nem a v5 resolvem o caso de aprovação/rejeição | Média | Primeiro passo do build: reproduzir o bug em dev com massa de teste. Se o flow não disparar, o build para e volta ao arquiteto (plano B passa a ser obrigatório) |
| T4 | R4 (rejeição → Pendente - Preenchimento) é proposta, não regra confirmada (L1) | Média | Confirmar no gate; mudar R4 é trocar um valor na fórmula |
| T5 | Validation rule `Checa_preenchimento_unitario_do_executor` avalia o registro inteiro: um registro que já esteja inconsistente bloqueia a gravação do flow para usuários fora dos perfis Administração/Gerente de Projetos | Baixa | Não ocorre no fluxo normal; incluir no roteiro de teste |
| T6 | Registros que já estão presos em produção não se corrigem sozinhos: a v5 só recalcula quando o registro é salvo de novo | Média | Fora do escopo (§9). O humano decide se haverá correção retroativa |
| T7 | `Fluxo_de_auto_aprovacao_...` sem critério de entrada regrava em todo update (desperdício e recursão) | Baixa | Fora do escopo, registrado para demanda futura |

## 9. O que NÃO será feito nesta demanda
- Correção retroativa de registros já divergentes em produção (P6 da análise segue sem resposta).
  Se for desejada, vira passo separado executado por humano. Agente não toca em produção.
- Alterar approval processes, field updates, Process Builder `Lancamento_de_Atividades_GP` ou
  `Fluxo_de_auto_aprovacao_...`.
- Migrar o Process Builder para Flow, desativar flows "Somatória" ou limpar os valores legados de
  `Status__c` (Pendente, Aguardando Aprovação, Recall, Rejeitado) e o approval process inativo
  `Solicitacao_de_aprovacao_para_atividade`.
- Mudar o mecanismo de bloqueio (trava de registro do approval) ou as notificações.
- Qualquer mudança em `Marcos__c` ou nas somas de horas.

## 10. Lacunas que seguem abertas (da seção 5 da análise)

Respondidas pelo card: P2 (objeto), P3 (mecanismo, com a divergência D1) e, em boa parte, a regra
(P1). Restam:

| # | Lacuna | Bloqueia? |
|---|---|---|
| L1 | Regra para **rejeição** de um executor (R4 é proposta) | **Bloqueia o build.** Confirmar no gate |
| L2 | Registro e passos que reproduzem o erro (pergunta 7). Dev não tem dados | Não bloqueia: o build cria massa e reproduz como primeiro passo (T3) |
| L3 | Correção retroativa (pergunta 6) | Não bloqueia o build. Fora do escopo até o humano decidir |
| L4 | Origem do bug (pergunta 8). Pista: a v4 do flow é de 2026-06-08 | Não bloqueia |
| L5 | Impacto/urgência e janela de deploy (perguntas 9 e 10) | Não bloqueia o build. Afeta o release |
| L6 | O anexo original da demanda nunca chegou (pergunta 1) | Não bloqueia, já que P1 cobre a regra |

## 11. Estimativa

**Estimativa de esforço:** 8–14 h

Esforço humano (consultor revisando, criando massa, testando e homologando; não é o tempo do
agente). A faixa da análise era 6–12 h. O que mudou:
- **Para cima (+2 h nos dois extremos):** a sandbox de dev tem zero registros de Projeto, Marco e
  LAT. Montar a massa de teste da cadeia inteira, com usuário aprovador/submissor e permission set,
  e rodar a matriz Qtd 1/2/3 × aprovar/rejeitar/GP-executor custa mais do que se previa.
- **O que segura o teto:** a correção ficou pequena e localizada (uma versão nova de um flow
  existente, sem código e sem mudança de modelo de dados). A incerteza que puxava para G na
  análise (mecanismo desconhecido, talvez Apex) caiu.
- Não inclui correção retroativa nem a conferência de paridade com produção (T2), que ficam com o
  humano.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
