**Veredito:** reprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes — SOMOSAGILITY-21: Campo origem do Lead (rodada 2)

`sf org list`: única org conectada é `sbx-somos-agility-qa`; `SELECT IsSandbox FROM Organization` = true. Não existe `05-deploy-qa.md` (o build não mudou metadata). `00-preflight.md` sem bloqueios.

## Retestes da rodada anterior
- FALHA 1 (crítica) da rodada 1: **não corrigida**. Nada foi construído em `force-app` (`04-plano-build.md` mantém a decisão de não construir; P-2 sem resposta) e nada mudou na QA.
- FALHA 2 (média) da rodada 1: **não corrigida**. O payload real do middleware continua fora do alcance da esteira.

## Falhas

### FALHA 1 (crítica) — Nenhuma correção entregue no Salesforce: CA-01, CA-02 e CA-03 sem prova
- **Reproduzir:** criar na QA um Lead sem `LeadSource` (como o site envia, hipótese H1 do design) e ler o campo.
- **Obtido:** `Prospecção - Gerente de Contas` (default da org). Com o texto "Web Site Agility" (label), grava-se o texto solto, fora da lista.
- **Esperado:** Lead do site com Origem do lead = `Web Site Agility Networks`, sem afetar outros canais.
- **Causa provável:** a Opção F (Flow before-save + Custom Permission + Permission Set) não foi construída por falta da resposta P-2; a Opção A (ajuste do payload) está fora do Salesforce.
- **Para fechar:** (a) confirmar P-2 no gate de design e construir a Opção F, ou (b) o dono do middleware ajustar o payload e a prova ser refeita com carga fictícia na QA.

### FALHA 2 (média) — CA-04 só parcial
Carga simulando o payload do middleware não executável; só a criação direta de Lead (comportamento da plataforma).

## Pré-checagem de componentes
| Verificação | Obtido |
|---|---|
| PermissionSet `PS_Integracao_LeadSite%` | 0 |
| CustomPermission / Flow `Lead_BeforeSave%` | consulta não suportada / retornou erro do `sf`; sem prova (o build declara que não existem) |
| Leads `Company='TESTE SOMOSAGILITY-21'` antes | 0 |

## Casos
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1 | `sf data create record -s Lead` (`TESTE SOMOSAGILITY-21 R2A`) com `LeadSource='Web Site Agility Networks'`, depois query | Valor mantido | `Web Site Agility Networks` | passou (só plataforma) |
| 2 | Lead sem `LeadSource` (`R2B`) | Default | `Prospecção - Gerente de Contas` | H1 confirmada; é o defeito |
| 3 | Lead com `LeadSource='Web Site Agility'` (`R2C`) | Texto solto aceito | `Web Site Agility`, fora da lista | H2 confirmada; é o defeito |
| CA-01 | Lead do site com origem correta pela solução | `Web Site Agility Networks` | Sem correção construída | não executado / reprovado |
| CA-02 | Outros canais inalterados | Nenhuma regra afetando outros canais | Sem componente a exercitar | não executado |
| CA-03 | Valor do site sobrepõe default | Sobrescrita | Sem componente | não executado |
| CA-04 | Carga com payload real do site | Origem correta | Só simulação direta (casos 1 a 3) | parcial |

## O que pode ter saído da org
3 Leads sintéticos criados e apagados em seguida (contagem final de `TESTE SOMOSAGILITY-21` = 0). Automações after-save de Lead (alertas) podem ter disparado na criação; não observei e-mail nem chamada externa. Nenhum registro existente foi lido ou alterado. Nenhuma mudança em usuário ou permissão. Sem screenshots (sem tela a conferir).

## Sem prova
CA-01, CA-02, CA-03 e CA-04 ponta a ponta. P-1 a P-4 seguem abertas.
