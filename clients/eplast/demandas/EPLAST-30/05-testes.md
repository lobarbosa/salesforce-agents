**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy, Org Id `00DHa000006vZtmMAE`, conferida com `sf org list`; usuário do job `005bJ00000piKAaQAM`, Administrador do sistema)

# EPLAST-30 · Testes (rodada 4) — Rascunho comercial pelo Screen Flow, sem cotação

Pacote: `05-deploy-qa.md` (deploy `0AfHa00000EIB6bKAH`, commit `313e3572`). Nada em produção, nada no Marketing Cloud. Aviso do preflight: EPLAST-41 mexe nos mesmos componentes (Flow, 3 templates, PS/PSG, custom permission) e EPLAST-26 na `Opportunity_Record_Page`; nada abaixo foi atribuído a elas.

**Limites do aprovado (leia):** a ferramenta de navegador continua sem conseguir trocar o rádio da tela (mesmo erro da rodada 3: "Clicking the checkbox did not change its state"; a correção do PR #214 não estava ativa neste job). Por isso Follow-up e Argumentos **não foram exercitados pela tela**; foram provados chamando os templates na QA (modelo real) e conferindo o mapeamento no Flow. CA-08 (compartilhamento), CA-10 (falha da IA) e CA-11 (debug log) ficam para a homologação, por decisão do responsável (16/11, registrada em `03-design.md`): não reprovam o QA.

## Rodada anterior (reteste)
- Rodada 3, FALHA 1 (follow-up/argumentos pelo Flow): **não corrigida por ferramenta**, mas a evidência equivalente por template foi obtida (C-07, C-08). Passa a conferência de homologação.
- Rodada 3, FALHA 2 (CA-08/10/11): rebaixada a conferência de homologação pela decisão acima.

## Ativação do Flow (regra de 2026-11-16)
- Antes: v5 **Active** (`301Ha000016VOn3IAG`, ativada na rodada 3) e v6 **Draft** (`301Ha000016VVrNIAW`, criada pelo deploy desta rodada).
- Ação: reimplantei só `Opportunity_Screen_RascunhoComercial` com `<status>Active</status>` (deploy `0AfHa00000EIB8DKAX`, Succeeded); arquivo da branch restaurado, nada commitado.
- Depois (Tooling `Flow`): v6 **Active**, v5 Obsolete. Fica ativa.
- Aviso EPLAST-41: a v4 antiga expunha `varTextoGerado` ao Flow `Task_Screen_RascunhoRelacionamento`; a v5/v6 não tem essa saída. Não verifiquei esse Flow. Conferir antes de liberar as duas demandas juntas.

## Mudanças no meu usuário (QA)
- Atribuí `PS_Comercial_RascunhoIA` (`0PaHa00000EK8USKA1`) ao usuário do job; **removida ao fim** (0 atribuições conferido). Nenhuma outra mudança em usuário, perfil ou permissão.

## Falhas
Nenhuma falha de caso executado.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C-01 | Pacote presente | Tooling `Flow` (versões), `PermissionSetAssignment`, abrir a Opportunity de teste | Flow ativo; aba aparece com o PS | v6 Active; aba "Rascunho IA" visível ao lado de "Detalhes" e "Histórico Da Oportunidade" (screenshot) | passou |
| C-02 | Acesso: aba só com PS | Antes de atribuir: 0 atribuições do PS (query) | Sem PS, sem acesso | 0 atribuições antes da atribuição; evidência de aba ausente sem PS e de Flow direto negado ("Privilégios insuficientes") nas rodadas 2 e 3 | passou (evidência anterior, não reexecutado) |
| C-03 | Proposta pela tela, tempo (CA-01) | Aba "Rascunho IA" > Proposta comercial > Avançar | Texto em até 15 s com conta | Texto apareceu em cerca de 10 s (carregando, depois texto); título "Rascunho gerado por IA: revise antes de usar. Nenhum campo deste registro foi alterado."; texto começa "Proposta Comercial / Cliente: TESTE EPLAST-30 Conta" (screenshot) | passou |
| C-04 | Proposta: etapa, valor ausente, `[a preencher]`, contato (CA-01/04/05/07) | Template `Rascunho_Proposta_Comercial` na QA com entrada sintética sem data e sem valor | Etapa citada; `[dado ausente: valor]`; `[a preencher]` para desconto/prazo/condição; `[nome do contato]`; sem e-mail/telefone | Citou Oportunidade, Conta, Etapa "Qualificação"; "Valor da oportunidade: [dado ausente: valor]"; desconto/prazo/condição "[a preencher]"; "[nome do contato]"; lista de campos usados e vazios; e-mail/telefone sintéticos não aparecem | passou (template) |
| C-05 | Follow-up (CA-02, CA-04) | Template `Rascunho_Followup_Comercial` na QA, mesma entrada | Conta e data de fechamento; sem dado pessoal | Citou conta e etapa; "data de fechamento ... [dado ausente: data de fechamento]"; "[nome do contato]"; sem e-mail/telefone; lista usados/vazios. Pela tela: **não executado** (limite da ferramenta) | passou (template); tela fica para homologação |
| C-06 | Argumentos com fonte (CA-03) | Template `Argumentos_Comerciais_Oportunidade` na QA | Cada item com fonte; sem dado ausente | Cada item termina com "(fonte: ...)"; campos vazios não geraram argumento. Pela tela: **não executado** | passou (template); tela fica para homologação |
| C-07 | Mapeamento do Flow | Leitura do arquivo do Flow (branch) | Cada escolha chama o template certo | `Escolha_Proposta`, `Escolha_Followup`, `Escolha_Argumentos` ligados às ações `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade` | passou (estático) |
| C-08 | Observação de conteúdo | C-04 a C-06 | — | Em `Argumentos`, com entrada sintética que continha e-mail/telefone, o modelo escreveu "contato disponível por e-mail/telefone" (sem os valores). O Flow real não envia dado de contato (PS sem Contact), então não ocorre na prática. Registrado como observação branda | observação |
| C-09 | Nada é gravado/enviado (CA-12) | `COUNT(Task)` e `COUNT(Event)` com `WhatId`=Opp de teste; Task criadas hoje pelo usuário do job; `LastModifiedDate` da Opp | 0 / 0 / 0 / inalterada | 0 / 0 / 0; Opp `LastModifiedDate` 2026-11-15T22:44:22Z (= criação, antes desta rodada) | passou |
| C-10 | Sem PromptFlow (CA-14) | Tooling `COUNT()` de Flow `ProcessType='PromptFlow'` | 0 | 0 | passou |
| C-11 | Compartilhamento (CA-08), falha da IA (CA-10), debug log sem trigger/Flow (CA-11) | — | — | Sem usuário de teste ativo com login (conta de serviço `005bJ00000hBJmYQAW` inativa) e sem debug log | não executado: homologação (decisão do responsável) |

## O que pode ter saído da org
- Dado de teste (criado na rodada 2/3, reutilizado): Opportunity `006Ha00000QWnWTIA1` "TESTE EPLAST-30 Opp" e Conta "TESTE EPLAST-30 Conta". Nada novo criado nesta rodada.
- Três chamadas diretas aos templates (uso de crédito de IA, sem gravação em registro). Nenhum e-mail, Task ou Event. Nenhuma chamada a sistema externo além do serviço de IA da plataforma.

## Sem prova
CA-02 e CA-03 pela tela (rádio), CA-08, CA-10, CA-11, e o texto completo da proposta lido na tela (a caixa mostra só as primeiras linhas). Constam no roteiro do cliente.
