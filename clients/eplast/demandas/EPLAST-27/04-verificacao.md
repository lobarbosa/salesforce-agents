**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev

# Verificação — EPLAST-27 (a ação aceita o código da conta no lugar do Id)

Org conferida com `sf org list`: só `sbx-eplast-dev` (Sandbox, Connected). Nada fora dela foi tocado. Nenhum DML, nenhum Apex anônimo, nenhum dado de teste criado; nada a apagar. Nada foi ativado.

## Por que inconclusiva
O código novo (busca por `ProtheusId__c`) está só numa versão do Flow que não pode ser executada, e a única executável é a anterior.

Consulta (Tooling, `Flow` de `Account_Agente_ProximaAcao`):
| Versão | Status | Última modificação |
|---|---|---|
| 1 | Obsolete | 2026-11-15 |
| 2 | **Active** | 2026-11-24 12:13 |
| 3 | **Obsolete** | 2026-11-24 12:12 |

- Conteúdo conferido pelo `Metadata` de cada versão (contagem de ocorrências, sem despejar o XML): a **v3** tem `IsAccountIdShape`, `GetAccountsByCode` e `ProtheusId__c`; a **v2 ativa não tem nenhum deles**. A descrição da v3 cita "Versão 4" (nome da conta + código), então a lógica a provar está nela.
- O plano de build dizia v3 em Draft e v2 ativa. A dev hoje mostra a v3 **Obsoleta** (alguém ou a esteira a desativou depois do plano; a v2 foi regravada 1 minuto depois). Não investiguei quem.
- Flow só roda pela versão ativa (`Flow.Interview`, ação do agente). Versão obsoleta não executa, e a instrução desta etapa proíbe ativar. Exercitar a v2 só provaria o comportamento antigo (código cai no caminho do Id), que não é o que o build entregou.
- A dev tem 0 contas `TESTE EPLAST-27` (consulta de contagem), então a massa das fixtures (`conta-oportunidade-proxima-acao.apex` + `conta-codigo-protheus.apex`, esta já gravada pelo builder) teria de ser criada de novo; não criei por não haver o que executar contra ela.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 `recordId` com Id válido (regressão) | Caminho por Id intacto | Nada executado | Ação da conta, sem erro | Sem execução na versão com a mudança | não executado |
| 2 Código que casa uma conta (e conta de outro dono, `NOT_OWNER`) | Código resolve a conta | Nada executado | Ação da conta | Sem execução | não executado |
| 3 Código que casa duas contas | `AMBIGUOUS` com nome e loja | Nada executado | Lista com loja | Sem execução | não executado |
| 4 Código inexistente | `NOT_FOUND` de código | Nada executado | Mensagem "Não encontrei conta com esse código..." | Sem execução | não executado |
| 5 Texto que não é Id nem código | `NOT_FOUND` | Nada executado | `NOT_FOUND` | Sem execução | não executado |
| 6 Vazio com `accountName` (regressão) | Caminho por nome intacto | Nada executado | Uma, várias, nenhuma | Sem execução | não executado |

## O que uma pessoa precisa fazer para provar
1. Ativar na dev a versão com o código (reimplantar o Flow da branch `feature/EPLAST-27` gera versão nova; hoje a v3 está Obsoleta) e, só então, reexecutar esta verificação. Ativação é passo à parte da esteira/QA, não do verificador.
2. Rodar as fixtures `conta-oportunidade-proxima-acao.apex` e `conta-codigo-protheus.apex` (códigos 927001, 927002 duplicado com lojas 001/002, 927004, 927006) e chamar o Flow uma vez por execução de Apex anônimo.
3. Ressalva já registrada no plano: a dev não tem conta real com `ProtheusId__c`, então o formato de 6 dígitos do código segue premissa (validar na homologação).

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma chamada externa.
