**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, conferida com `sf org list`; sandbox, conectada)

# EPLAST-30 · Verificação (rodada 2 do build)

Nada foi tocado na QA nem em produção. Nenhum registro foi criado, alterado ou apagado na dev (a dev tem 0 Opportunity). Nenhuma permissão de usuário foi alterada.
Usuário de teste (conta de serviço Konecta): `005bJ00000piKAaQAM`, ativo, perfil Administrador do sistema, é o usuário do job. Existe também um registro inativo com o mesmo prefixo (`005bJ00000hBJmYQAW`), não usado. Perfil, papel e permissões não foram alterados.

## O que ficou sem prova (e por quê)
O critério principal é o Screen Flow `Opportunity_Screen_RascunhoComercial` rodando na aba "Rascunho IA". Não deu para exercitá-lo:
- Screen Flow só executa pela interface. A CLI, o Apex anônimo e a API REST de ações não o rodam.
- Não há fixture em `clients/eplast/fixtures/` (a pasta não existe), e a dev não tem Opportunity, conta nem cotação CPQ.
- Atribuir `PS_Comercial_RascunhoIA` ao usuário do job é permitido na dev. Não tentei: o plano registra que a atribuição foi recusada na QA por falta da licença CPQ (`SalesforceCPQ_CPQStandardPerm`). Mesmo com a atribuição, o job não renderiza a aba, e os casos de acesso (CA-08/09) pedem um usuário diferente, com login, que não existe.
- Não montei massa sintética, porque sem como abrir a página ela não provaria o Flow.

O que uma pessoa precisa fazer: atribuir a licença CPQ e o `PSG_Comercial_RascunhoIA` a um usuário de teste com login (ou executar `05-roteiro-cliente.md`, C-09 a C-12) e conferir CA-01 a 10 e CA-13 na página, com oportunidade sintética.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | CA-04 / follow-up com data de fechamento (FALHA 1 da rodada 1) | `POST /einstein/prompt-templates/Rascunho_Followup_Comercial/generations` com entradas sintéticas (`TESTE EPLAST-30`, data 31/12/2026, cotação `sem cotação`) | Texto cita conta, etapa e data; sem cotação tratado; contato só `[nome do contato]` | Texto cita conta, etapa `Proposta` e `31/12/2026`; diz que não há cotação; assina `[nome do contato]`. A rodada 1 reprovada (data em 0 de 3) foi corrigida: a versão `_2` está efetiva | passou |
| V-02 | Follow-up: uso dos dados | Mesma chamada | O valor fornecido aparece | O modelo listou "Valor" em "Campos vazios" embora a entrada trouxesse `Valor: 1000,00 BRL`. Qualidade do modelo, em texto sintético e rascunho editável; não reprova | observação |
| V-03 | Qualidade do template | Leitura do campo `prompt` devolvido pela API | Sem entidades HTML | A regra 1 ainda chega ao modelo com `&quot;[dado ausente: ...]&quot;` literal (o plano disse ter trocado as entidades). O modelo ignorou isso na chamada acima; sinalizo ao builder | observação |
| V-04 | CA-14 PromptFlows depreciados | Tooling: `SELECT COUNT(Id) FROM Flow WHERE ProcessType='PromptFlow'` | 0 | 0 | passou |
| V-05 | Flow ativo | Tooling `FlowDefinition` `Opportunity_Screen_RascunhoComercial` | Versão ativa | Versão 1, Active | passou |
| V-06 | CA-11/12 sem gravação/e-mail | Grep de `recordCreates`/`recordUpdates`/`recordDeletes` no Flow da branch | 0 | 0 (verificação estática; execução não feita) | passou (estático) |
| V-07 | PSG existe | `PermissionSetGroup` `PSG_Comercial_RascunhoIA` | Updated | `0PGHa000000IzjNOAS`, Updated | passou |
| V-08 | Plano item 11: página mantém campos da EPLAST-26 | Grep de `PriorityScore__c`/`PriorityBand__c` em `Opportunity_Record_Page.flexipage-meta.xml` da branch | Presentes | 2 ocorrências (só o arquivo da branch; a versão da dev não foi baixada) | passou (estático) |
| V-09 | Atribuição do PS ao usuário do job | `PermissionSetAssignment` do `PS_Comercial_RascunhoIA`: contagem | Informativo | 0 | informativo |
| V-10 | CA-01 a 03 (3 tipos, tempo, argumentos), CA-05 a 07, CA-13 (50 linhas) | Não executado | Conforme `01-analise.md` | Exigem o Screen Flow na página e massa CPQ | não executado |
| V-11 | CA-08 (negativa sem acesso), CA-09 (sem PSG não vê a aba) | Não executado | Conforme `01-analise.md` | Exigem usuário de teste com login e licença CPQ | não executado |
| V-12 | CA-10 (erro sem travar o registro) | Não executado | Tela de erro | Exige o Flow na interface | não executado |

## O que pode ter saído da org
Nenhum registro foi criado na org. Foram feitas 4 chamadas à API de geração de prompt (1 com resposta lida, 3 sem leitura de saída por falha minha no filtro de saída; as 3 foram com texto sintético `TESTE EPLAST-30`) ao modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini`. Nada a desfazer. Nada de Marketing Cloud foi acionado.

## Limpeza
Nada a apagar. Nenhuma atribuição de permission set, opção de usuário ou campo foi alterado.
