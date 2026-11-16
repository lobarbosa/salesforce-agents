**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-30 · Testes (rodada 2) — Rascunho comercial pelo Screen Flow

**Org:** `sf org list` mostrou só `sbx-eplast-qa` (sandbox, Partial Copy "QAS", conectada). Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EI4hpKAD`). Nada foi feito em produção nem no Marketing Cloud.

## Rodada anterior
Rodada 1 (arquivada em `rodada-anterior/05-testes-rodada-1.md`): FALHA 1 (nenhum componente na QA) **corrigida** (todos existem agora, ver C-01). FALHA 2 (bloqueio do vínculo template Flex x PromptFlow) **corrigida**: o desenho mudou para Screen Flow chamando os templates direto, e os 3 templates respondem na QA (C-12 a C-15).

## Falhas

### FALHA 1 (crítica) — Caminho principal (Screen Flow, aba "Rascunho IA") não pôde ser exercitado de ponta a ponta
- **Reproduzir:** abrir uma oportunidade de teste na QA com um usuário que tenha o PSG `PSG_Comercial_RascunhoIA` e pedir um rascunho na aba "Rascunho IA".
- **Obtido:** não executado. O único login do navegador de QA é a conta de serviço Konecta (`005bJ00000piKAaQAM`, Administrador do sistema, ativa), sem o PSG atribuído (0 atribuições do PS/PSG na org). A regra da conta proíbe alterar permissão desse usuário, e não há outro login. Resultado: não há prova de tempo de resposta do Flow (15 s), citação de valor da cotação no Flow, limite de 50 linhas, compartilhamento (negativa para usuário sem acesso ao registro), falha do serviço de IA sem travar o registro, ausência de trigger/Flow de gravação no debug log, e ausência de Task/Event criados.
- **Esperado:** critérios de aceite do Gherkin (seção 4 de `01-analise.md`) executados pelo Flow.
- **Causa provável:** limitação do ambiente de teste, não defeito do build. Quem corrige: delivery atribui o PSG a um usuário de teste com login, ou o time executa `05-roteiro-cliente.md`. Critério de aceite principal não executado = reprovado, pela regra da esteira.

### FALHA 2 (média) — Template de follow-up não cita a data de fechamento
- **Reproduzir:** POST em `/services/data/v65.0/einstein/prompt-templates/Rascunho_Followup_Comercial/generations` com `Input:DadosOportunidade` contendo `Data de fechamento: 31/12/2026` e conta `TESTE EPLAST-30 Conta`, etapa Qualificação (corpo igual ao usado em C-13).
- **Obtido:** em 3 de 3 chamadas o texto cita conta e etapa, mas **não** a data de fechamento (`31/12/2026` ausente).
- **Esperado:** critério "Follow-up gerado": "texto editável com o nome da conta **e a data de fechamento** de X".
- **Causa provável:** a regra 5 do prompt de `Rascunho_Followup_Comercial` manda citar só conta e etapa; não menciona data de fechamento. Ajustar a regra 5 (ex.: "cite nome da conta, etapa e data de fechamento; se vazia, `[dado ausente: data de fechamento]`").

## Casos

| Caso | Critério (01-analise.md) | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C-01 | Pacote presente na QA | `sf data query -t` em FlowDefinition; `sf org list metadata` para GenAiPromptTemplate, CustomPermission, PermissionSetGroup; query PermissionSet | Componentes de `05-deploy-qa.md` existem | Flow `Opportunity_Screen_RascunhoComercial` com versão ativa `301Ha000016UZkAIAW`; 3 templates (`Argumentos_Comerciais_Oportunidade`, `Rascunho_Followup_Comercial`, `Rascunho_Proposta_Comercial`); custom permission `IA_Rascunho_Comercial`; PSG `PSG_Comercial_RascunhoIA`; PS `PS_Comercial_RascunhoIA` | passou |
| C-02 | Acesso restrito por PS — aba não aparece | Tela: oportunidade de teste `006Ha00000QWnWTIA1` aberta no Lightning com o usuário sem PSG; screenshot | Aba "Rascunho IA" ausente | Página com abas só "Detalhes" e "Histórico Da Oportunidade"; clique em "Rascunho IA" estourou timeout (elemento inexistente); screenshot tirado de registro de teste | passou |
| C-03 | Acesso restrito — chamada direta ao Flow negada | Navegador em `/flow/Opportunity_Screen_RascunhoComercial?recordId=006Ha00000QWnWTIA1` com usuário sem PSG | Negado | Tela "Privilégios insuficientes" (screenshot) | passou |
| C-04 | Proposta com dado ausente / preço sem cotação (template isolado) | POST em `Rascunho_Proposta_Comercial` com data `[dado ausente: data de fechamento]` e cotação `sem cotação` | `[dado ausente: data de fechamento]`; preço, desconto, prazo, condição = `[a preencher]`; listas de campos usados/vazios | Exatamente isso; contato `[nome do contato]`; 5,3 s | passou (template, fora do Flow) |
| C-05 | Preço com cotação vem do registro (template isolado) | POST em `Rascunho_Proposta_Comercial` com cotação "valor total R$ 1.234,56" | Valor idêntico, sem cálculo | `Valor total: R$ 1.234,56`, itens A (10) e B (5) como informados; 4,3 s | passou (template) |
| C-06 | Sem dado pessoal no texto | Mesmas chamadas, entrada com marcador de contato | Sem e-mail/telefone; `[nome do contato]` | Nenhum e-mail ou telefone nos 3 templates; marcador ou "Prezados" no lugar do nome | passou (template) |
| C-07 | Argumentos com fonte | POST em `Argumentos_Comerciais_Oportunidade` | Cada argumento indica fonte | 6 argumentos, todos com "(fonte: ...)" (Cotação, Linha: Produto..., Oportunidade.Etapa, Oportunidade.Data de fechamento) | passou (template) |
| C-08 | Follow-up com conta e data de fechamento | POST em `Rascunho_Followup_Comercial`, 3 repetições | Conta e data de fechamento no texto | Conta sim; data de fechamento nunca | **falhou** (FALHA 2) |
| C-09 | Caminho feliz da Proposta pelo Flow, 15 s, sem DML no log | Não executado | Texto em até 15 s | Sem login com PSG | não executado (FALHA 1) |
| C-10 | Respeito ao compartilhamento | Não executado | Negativa; nada enviado ao modelo | Sem usuário de teste com login | não executado |
| C-11 | Falha do serviço de IA não trava o registro; nenhuma automação disparada (log); nada enviado (Task/Event) | Estático: ver verificação de dev (0 recordCreates/Updates/Deletes, 29 faultConnector). Contagem de Task na oportunidade de teste: 0 (só prova que nada foi criado até aqui) | Mensagem de falha; sem trigger/Flow no log | Não executado dinamicamente | não executado (FALHA 1) |
| C-12 | Limite de 50 linhas da cotação | Não executado | 50 linhas + "e mais N itens" | Exige cotação sintética CPQ com mais de 50 linhas e o Flow | não executado |
| C-13 | Regressão: criação de Opportunity com a cadeia de automação existente | `sf data create record` de Opportunity de teste | Registro criado sem erro novo introduzido pela demanda | Criada `006Ha00000QWnWTIA1` após atender 16 regras de validação já existentes (CNPJ, endereço, CNAE, e-mail, telefone, loja, ID Protheus do proprietário, catálogo de preço da conta). Nenhum erro ligado ao pacote | passou |
| C-14 | Página de Opportunity: EPLAST-26 preservada | Interação: `Opportunity_Record_Page` também é alterada pela EPLAST-26 | Campos/regiões da EPLAST-26 intactos | A página abre normalmente com a Opportunity de teste; campos de prioridade da EPLAST-26 conferidos estaticamente na verificação de dev (2 ocorrências) e não reconferidos aqui | não conferido na tela (registrar para o time) |
| C-15 | Apex | Não se aplica: a solução não tem Apex | — | Sem classe nova | n/a |

## O que pode ter saído da org
- Criados por mim, todos sintéticos, na QA: Account `001Ha000016UimLIAS` ("TESTE EPLAST-30 Conta", proprietário trocado para um usuário Admin ativo que tem ID Protheus, só para passar a validação do proprietário; nenhum usuário foi alterado), Pricebook2 `01sHa000002QbVpIAK` ("TESTE EPLAST-30 Catalogo") e Opportunity `006Ha00000QWnWTIA1` ("TESTE EPLAST-30 Opp"). Passar pela cadeia de automação de Opportunity (trigger custom, CPQ, Flows) é efeito esperado da criação. Não removidos; podem ser apagados pela esteira.
- Chamadas de IA (5 chamadas do serviço de geração dos templates, texto sintético, dado fictício; nada sobre registro real). Nenhuma chamada a ERP, e-mail, Task ou Event. Nada no Marketing Cloud.
- Sem DML meu em registros existentes.

## Observações
- `05-testes-rodada-<n>.md` não foi criado por mim: a esteira arquiva o roteiro reprovado.
- Para aprovar: (1) corrigir FALHA 2 e (2) executar C-09 a C-12 com um usuário que tenha o PSG (o roteiro do cliente cobre esses passos).
