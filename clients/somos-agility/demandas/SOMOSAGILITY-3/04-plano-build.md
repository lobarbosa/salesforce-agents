# Plano de Build — SOMOSAGILITY-3

## Não há build de metadata nesta demanda

**Nenhum componente é criado, alterado ou depreciado.** Ver `03-design.md`, seção 1
("Decisão") e seção 3 ("Componentes"): a tabela de componentes lista **Nenhum** para
Criar, Alterar (metadata) e Depreciar. A única mudança é de **dado**, em um único
registro de produção (`Opportunity` `006U400000YnxGHIAZ`), fora do alcance do agente —
guardrail #1 proíbe qualquer DML de agente em produção, e a sandbox de dev não tem o
registro (`COUNT() = 0` em Opportunity, confirmado no design). Não existe metadata a
construir nem a testar em nenhum ambiente da esteira.

Este arquivo é, portanto, o **runbook de execução manual** que a seção 4 do design já
definiu, formalizado como o artefato da etapa 4. Nenhuma branch de código em
`force-app/` foi aberta e nenhum `sf project deploy` será executado para esta demanda.

---

## Quem executa

Um **humano autorizado do cliente**, nunca o agente. Precisa ter FLS de edição em
`Opportunity.Status__c`. Pelo design (seção 1), hoje isso vale para os perfis
`Administrador do sistema`, `Admin`, `Administração`, `Administração para Alta Gestão`,
`adminPMO`, `Compras Financeiro`, `Diretor Financeiro`, `Grupo Operações` e os
permission sets `PMO acessa OPT`, `Projeto-DSA-Oportunidade`.

Preferência declarada no design: perfil **`Administração`** — além da FLS, esse perfil
é isento de `M21_Fase_Encerrada` caso a pergunta P1 (abaixo) conclua que a Fase também
precisa mudar.

Não conceder FLS nova a ninguém para esta demanda (seção 5 do design, "Impacto em
permissões": Nenhum). Se o solicitante não tiver acesso, quem executa é alguém que já
tem.

---

## Condições bloqueantes — confirmar ANTES de executar

As perguntas P1–P3 da seção 6 do design condicionam a execução, não a aprovação do
design (já aprovada). **P2 é bloqueante para a execução** e deve ser respondida antes
do passo 1 abaixo:

- **P2 — O financeiro/ERP já processou? (BLOQUEANTE)** Confirmar com o financeiro do
  cliente se o fechamento desta oportunidade já gerou algo no SnapERP/ERP (pedido,
  faturamento, contrato). Se sim, reabrir só no Salesforce cria divergência
  Salesforce × ERP; a reversão do lado financeiro é responsabilidade do cliente e
  precisa estar combinada **antes** de qualquer edição. Esta é a mesma checagem do
  passo 2 do runbook abaixo (valor `Encerrado Win - Processada Financeiro` é o sinal
  em campo de que isso já aconteceu).
- **P1 — Qual campo?** Confirmar com o solicitante que a Fase (`StageName`) não precisa
  voltar a um estágio aberto. Se precisar, o design atual **não cobre** esse caso
  (`IsClosed`/`IsWon` mudam, `M21_Fase_Encerrada`, `M36_Trava_avanco_nao_sequencial` e
  `M49_NaoAtualizaOppPsl` entram em jogo, vários Flows de fase disparam) — isso volta ao
  arquiteto para revisão do design antes de executar qualquer coisa.
- **P3 — Por que reabrir?** Erro de digitação ou negócio voltou à negociação? Se for
  padrão recorrente, não execute este runbook como solução permanente — abrir demanda
  nova para desenhar um processo de reabertura (fora do escopo desta demanda).

Se P1 indicar mudança de Fase, ou P2 não puder ser respondida com segurança, **pare e
devolva ao arquiteto/solicitante** — não prossiga com os passos abaixo.

---

## Passo a passo (runbook de execução na UI, em produção)

1. **Antes de editar**, anotar — no ticket do cliente, **nunca neste repositório**
   (guardrail #2, LGPD) — os valores atuais de: `Status__c`, `StageName`, Record Type,
   `Certeza_de_Conclus_o__c`, `Certeza_de_Vit_ria__c`, `CloseDate`. Importante:
   `Status__c` tem `trackHistory = false` — a plataforma **não** guarda histórico dessa
   mudança. A anotação manual é o único rastro que vai existir.
2. Confirmar que o valor atual do campo é exatamente `Encerrado Win` e **não**
   `Encerrado Win - Processada Financeiro`. Se for o segundo valor, **parar** a
   execução e devolver para a pergunta P2 acima — não editar o campo.
3. Editar `Opportunity.Status__c` (label "Status") do registro `006U400000YnxGHIAZ`
   de `Encerrado Win` para **`Aberto`** (não "Aberta" — ver risco R2 do design: o
   picklist é restrito e "Aberta" não é um valor válido). Não alterar nenhum outro
   campo na mesma edição.
4. Salvar. Se ocorrer erro de validação, **não contornar**: registrar a mensagem
   exibida e devolver ao arquiteto (a análise de validation rules no design diz que
   isso não deveria ocorrer — divergência aqui é sinal de que algo não foi mapeado).
5. **Conferência pós-execução** (substitui a etapa de QA em sandbox, que não se aplica
   porque o registro só existe em produção):
   - `Status__c = Aberto` persistiu depois de recarregar a página (nenhuma automação
     reverteu o valor).
   - `StageName` e `CloseDate` não mudaram.
   - Avaliar com o solicitante se `Certeza_de_Conclus_o__c` / `Certeza_de_Vit_ria__c`
     (que ficaram em 100 quando o registro foi encerrado, via Flow `Preenche_Certezas`)
     devem ser ajustadas — isso é decisão de negócio, não do agente (risco R4 do
     design: reabrir não desfaz esses campos automaticamente).

---

## Efeitos colaterais esperados ao salvar (não são erro)

Mapeados na seção 2.3 do design — nenhum deles reverte `Status__c`, mas podem ser
observados na conferência pós-execução dependendo do Record Type/Fase atual do
registro (desconhecidos aqui, pois estão em produção):

- Se o registro for de renovação (`E_Renovacoes__c = Yes`): `Id_do_Owner_se_Renovacoes__c`
  é gravado com o `OwnerId` atual (Flow `Atualiza_Owner_da_Oportunidade_se_Renova_es_ou_Shirlei_v2_1`).
- Se a Fase atual for CVS/RVS ou PSL, ou "Ação DIA": Flows de atualização de data/e-mail
  podem disparar (`Atualiza_Data_de_Alteracao_para_CVS_RVS`, `..._para_PSL`,
  `Atualiza_os_Campos_de_Emails_do_SE_GC_e_BDR`).
- Se o registro for reencerrado no futuro: o e-mail de `Oportunidade_Encerrada` para
  Sales Operation dispara de novo — comportamento esperado, avisar o solicitante.

## O que este runbook não cobre

Conforme a seção 8 do design: nenhuma alteração de `StageName`, `CloseDate`, Record
Type ou campos de certeza (salvo nova decisão via P1/R4); nenhuma reversão do lado
financeiro/ERP (responsabilidade do cliente); nenhum processo reutilizável de
"reabrir oportunidade" criado por esta demanda.
