**Verificação:** inconclusiva
**Org de teste:** sbx-somos-agility-dev

# 04 — Verificação — SOMOSAGILITY-21: Campo origem do Lead

Org confirmada com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected). Todo comando levou `--target-org sbx-somos-agility-dev`. QA e produção não foram tocadas.

## Resumo

O build não criou metadata. A correção principal (CA-01 em produção) é o ajuste do payload no middleware do Connected App `Lead Site Agility`, e isso não dá para exercitar daqui. A plataforma se comporta como o design afirma, e nada na org sobrescreve `LeadSource`. Por isso o veredito é inconclusiva: o critério principal ficou sem prova ponta a ponta. Nenhum caso executado falhou.

A Opção F (Flow before-save com Custom Permission) não foi construída porque a P-2 continua sem resposta. Não há o que testar nela.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Premissa do design (D-1) | `sf sobject describe -s Lead`, só o campo `LeadSource` | Valor `Web Site Agility Networks` com label `Web Site Agility`, ativo; picklist não restrito; default `Prospecção - Gerente de Contas` | Valor e label como esperado, `active=true`; `restrictedPicklist=False`, `nillable=True`; default `Prospecção - Gerente de Contas`. Existe também `Web Site Agility – E-mail` | passou |
| V2 | CA-02 (nada sobrescreve) | Tooling `ApexTrigger` em Lead: contagem | 0 | 0 | passou |
| V3 | CA-02 | `FlowDefinitionView` ativos com objeto Lead | Só after-save, sem before-save | 3 ativos (`Alerta_Diretor_Comercial`, `Alerta_Gerente_de_Contas`, `Notifica_se_Novo_Lead_Criado`), todos `RecordAfterSave` | passou |
| V4 | CA-02 | Tooling `Flow.Metadata` das 3 versões ativas, contagem de referências a `LeadSource` | 0 | 0 nas três | passou |
| V5 | CA-02 | Tooling `WorkflowRule` em Lead: contagem (sem filtro de ativo) | Só as 2 inativas citadas no design | 2 regras. Não conferi o estado ativo nesta sessão, o design as registra como inativas | não executado (estado ativo não reconferido) |
| V6 | CA-01/CA-03 (lado plataforma) | Apex anônimo: insert de Lead sintético com `LeadSource = 'Web Site Agility Networks'` | Valor mantido | `Web Site Agility Networks` | passou |
| V7 | CA-03 / H1 | Insert sem `LeadSource` | Default de org | `Prospecção - Gerente de Contas` (confirma H1 na plataforma) | passou |
| V8 | H2 | Insert com `LeadSource = 'Web Site Agility'` (label) | Aceito como texto solto | Gravado como `Web Site Agility`, fora da lista (confirma H2 na plataforma) | passou |
| V9 | CA-04 (payload REST real do middleware) | Não executável: o middleware está fora da sessão | Lead do site chega com `Web Site Agility Networks` | Sem prova | não executado |
| V10 | CA-01 em produção | Fora do alcance (guardrail #1) | Leads do site com o valor correto | Sem prova | não executado |

V6 a V8 usaram DML de Apex anônimo, não o endpoint REST do Connected App. Provam o comportamento do campo, não o caminho da integração. Os 3 Leads foram `TESTE SOMOSAGILITY-21 C1/C2/C3`, com `Status='Novo'` para passar a `Lead_Novo`. O script rodou dentro de `Savepoint` com `Database.rollback` no fim, então nada foi gravado e os Flows after-save de alerta não chegaram a ser confirmados (nada saiu da org).

## Dados de teste e limpeza

- Contagem de Leads com `Company='TESTE SOMOSAGILITY-21'` depois do rollback: 0 (conferida no Apex e por `sf data query`).
- Nenhuma alteração em usuário, permission set ou opção de usuário.
- Nada ficou na org.

## O que pode ter saído da org

Nada. O rollback desfez os inserts antes do commit, então os Flows after-save de alerta não confirmaram envio.

## O que ficou sem prova e o que uma pessoa precisa fazer

1. **CA-01/CA-04 ponta a ponta.** Alguém da TI Agility (dono do middleware, P-4) precisa ajustar o payload para enviar `LeadSource = "Web Site Agility Networks"` (API name, não o label). Depois, com dados fictícios, deve disparar um `POST /services/data/vNN.0/sobjects/Lead` pelo Connected App na sandbox de QA e mostrar o Lead gravado com esse valor. A causa real em produção (H1, H2 ou H3) só se separa vendo um Lead afetado lá (P-3).
2. **P-2 sem resposta.** Sem a confirmação de usuário de integração exclusivo do site Agility, a rede de segurança segue não construída. Isso é decisão de gate, não falha de build.
3. **V5.** Reconferir se as duas workflow rules de Lead estão inativas. O design já afirma isso, mas esta sessão não reconfirmou.
4. **Efeito colateral a comunicar (R-4).** O Flow `Atualizar_Descri_o_com_Informa_es_do_Lead` (Opportunity) passa a disparar para oportunidades vindas do site depois da correção. Não foi exercitado aqui.
