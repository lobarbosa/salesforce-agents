**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (00DHa000006vfMLMAY)

# EPLAST-41 · Verificação na dev (rodada 3 do build)

Org conferida com `sf org list`: alias `sbx-eplast-dev` (sandbox "QA" da Eplast, regra 5). Nada em QA, nada ativado, nenhuma metadata alterada, nenhum dado criado nem alterado.

## Resumo
O critério principal (percorrer o Screen Flow "Rascunho com IA" até o texto e "Salvar como tarefa") não pôde ser exercitado. Screen Flow só roda com interface; não há como dirigi-lo por `sf`, Apex ou API. A correção da FALHA 2 (botão de avanço) existe só na v2, que está em Draft. A versão ativa é a v1, que tem o defeito. Isto não é falha nova: é o passo de ativação que o plano de build já registra.

## Versão ativa de fato (Tooling, `Flow`)
| Flow | Versões na dev |
|---|---|
| `Task_Screen_RascunhoRelacionamento` | v1 **Active**, v2 Draft |
| `Opportunity_Screen_RascunhoComercial` | v1 **Active**, v2 Draft |

Telas com `allowFinish=true` (Metadata via Tooling):
- v1 Active: 9 de 13 telas. A quick action abre esta versão.
- v2 Draft: 13 de 13 telas. Esta é a correção do builder, presente mas inativa.

Conclusão: a correção está no repositório e na dev como Draft, e **não está ativa**. Quem usar a ação na dev hoje cai na v1. Se a v1 reproduz o rodapé vazio da QA (rodada 2) não foi confirmado em tela, porque não há interface. A diferença de metadata (4 telas intermediárias) é coerente com a hipótese do builder.

## Casos (design, seção 11)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Conta A, relacionamento, texto editável, nenhum registro antes de salvar | Não há como abrir o Screen Flow. Contas `TESTE EPLAST-41` também não existem na dev (0 registros). | Texto na tela | Sem execução | não executado |
| 2 | Salvar gera 1 Task com campos esperados | Dependia do caso 1. Contagem de Task `Rascunho%(IA)` na dev: 0. | 1 Task | Sem execução | não executado |
| 3 | Account não muda | Dependia do caso 2 | Campos iguais | Sem execução | não executado |
| 4 | Opportunity, relacionamento e comercial | Sem fixture (falta `ProtheusSellerId__c` e CPQ) e sem UI | Texto e Task | Sem execução | não executado |
| 5 | Conta B, aviso sem texto | Sem UI | Aviso | Sem execução | não executado |
| 6 | Falha do modelo, sem Task | Sem UI | Erro, 0 Task | Sem execução | não executado |
| 7 | Acesso negado sem o PS | Atribuições de `PS_Comercial_RascunhoRelacionamento` na dev: 0 (PermissionSetAssignment). Execução do Flow sem o PS não testável sem UI. | Flow não executa | Só a contagem | não executado |
| 8 | Parâmetros do template | Apex anônimo com `generateMessagesForPromptTemplate('Rascunho_Relacionamento')` e só as 3 entradas (`DadosConta`, `DadosOportunidade`, `ObjetivoMensagem`), valores sintéticos | Texto sem erro | Devolveu 567 caracteres | passou |
| 9 | Intactos | `BotDefinition` com `DeveloperName='SFAgent2'`: 1. Revalidação de versões acima: v1 do comercial continua Active (reativável). Não comparei por diff `Task_Agente_CriarTarefa`, templates nem `et4ae5`. | Sem alteração | Bot único; resto não verificado | passou em parte |
| 10 | Tempo ≤ 30 s | Mesma chamada Apex do caso 8, medida | ≤ 30 s | 1,9 s (só a geração, não o Flow completo) | passou em parte |
| FALHA 2 (rodada 2) | Botão de avanço corrigido | Comparação de metadata v1 x v2 | Versão ativa com botão | Ativa é a v1 (9/13); v2 Draft (13/13) | não executado (correção não ativa) |

Usuário de teste da conta (conta de serviço da Konecta, localizada por Username na org): existem 2 usuários, `005bJ00000piKAaQAM` (ativo, Administrador do sistema, também o de execução) e `005bJ00000hBJmYQAW` (inativo). Nenhum foi alterado.

## O que ficou sem prova
- Todo o percurso do Screen Flow (casos 1 a 7): interface necessária, e a versão ativa é a v1 defeituosa.
- Confirmação em tela de que a v2 mostra o botão de avanço.
- Caminho comercial (casos 4 e 5): falta fixture (usuário sem `ProtheusSellerId__c`, Filial, CPQ) e licença CPQ para o PSG.

## O que uma pessoa precisa fazer
1. Na dev, abrir `Task_Screen_RascunhoRelacionamento` v2 no Flow Builder, depurar para confirmar o botão e ativar (passo separado, desfaz reativando a v1). Alternativa de pacote: `status` Active no XML.
2. Rodar `fixtures/eplast41_dados_teste.apex` e executar os casos 1 a 7 pela interface com usuário que tenha o PS. Fazer o mesmo na QA depois da ativação.

## O que pode ter saído da org
Nada. Nenhum registro foi criado. Uma chamada ao modelo (Einstein) com texto sintético; sem Task, sem e-mail, sem Marketing Cloud. Sem job agendado.
