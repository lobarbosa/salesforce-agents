**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-39 — Testes na QA (Origem dos leads e retorno das campanhas)

Org conectada (`sf org list`): `sbx-eplast-qa`, Sandbox, Connected (QAS da Eplast, Partial Copy, tem dado real copiado: só agregados e registros `TESTE EPLAST-39`). Deploy da esteira `0AfHa00000EJDRLKA5` (Succeeded, commit `6404ff3e`). Os critérios seguem o `03-design.md` seção 9 (CA revistos). Rodada anterior (`rodada-anterior/05-testes-rodada-1.md`, painel sem dado) já estava coberta pelo CA-07 abaixo. Falhas: nenhuma.

## Componentes do deploy conferidos na org
Consulta Tooling/SOQL: campos `Lead.MKT_Origem_Agrupada__c`, `Opportunity.MKT_Origem_Agrupada__c`, `Campaign.MKT_ROI_Situacao__c` existem; pastas `Marketing_Origem_Retorno` (relatórios) e `Marketing_Origem_Retorno_Dash`; 6 relatórios `MKT_*`; painel `MKT_Origem_e_Retorno_Campanhas` (`01ZHa000001uI4vMAE`); permission set `PS_Marketing_AnaliseCampanhas`. Todos presentes. O grupo `Marketing_Origem_Retorno` consta no deploy (não consultado).

## Mudanças no meu usuário de execução (`005bJ00000piKAaQAM`) e desfeitas
- Atribuí `PS_Marketing_AnaliseCampanhas` (0 atribuições antes; para enxergar o campo novo): removida, consulta devolve 0.
- `UserPermissionsMarketingUser` false para true e `ProtheusSellerId__c` vazio para `TESTE39` (para criar Campanha e Oportunidade): devolvidos a false e vazio, conferido por consulta.

## Massa de teste
13 leads (Campanha x2, WhatsApp, Google Ads, vazio, "Origem Inventada XYZ", Site, Meta Ads, Parceiros, "feiras", SDR, Indicação, Busca orgânica), conta/filial/condição de pagamento, 2 campanhas (Com Custo 1000; Sem Custo) com início hoje e 2 oportunidades ganhas (R$ 2.500 e R$ 700), pelo script `fixtures/campanha_oportunidade_ganha_qa.apex` (com `StartDate` acrescentado só na cópia em /tmp) e script de leads equivalente. Apagados ao fim: Lead, Campaign, Opportunity, Account de teste = 0; Lead total 716 e Campaign 5 (os que já existiam). Sem conversão de lead nesta rodada.

## O que pode ter saído da org
Nada. Contas com `TriggerUtility.bypassTrigger=true` (sem BrasilAPI nem Protheus); nenhum e-mail, Flow de disparo ou chamada externa. Cases de pós-vendas gerados pela automação existente: 0 restantes (apagados).

## Resultados

| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| CA-04'/CA-03' | SOQL `LeadSource` x `MKT_Origem_Agrupada__c` nos 13 leads de teste | Sinônimos no grupo certo (minúsculo incluso); vazio = Sem origem; não reconhecido = Outros | Site/formulário, Meta Ads, Parceiros, "feiras" para Eventos/feiras, SDR para Prospecção ativa/SDR, Indicação, Busca orgânica, Google Ads certos; vazio para Sem origem; "Origem Inventada XYZ", Campanha e WhatsApp para Outros | passou |
| CA-01'/CA-02 | `PUT` e `GET` do painel; componente Leads por Origem | Soma dos grupos = total do mês; sem linha "-" | 10 grupos somando 21, total 21 (8 existentes no mês + 13 de teste); Sem origem 6; nenhuma linha "-"; tela do painel mostra as barras (`02-ca-07-painel-origem-e-retorno-segunda-te.jpg`) | passou |
| CA-05' | `describe` dos 6 relatórios | Mês atual como padrão | Leads, Oportunidades, Conversão e Origem Original: `CREATED_DATE` `THIS_MONTH` (01 a 30/11/2026); Desempenho e Resposta: `START_DATE` = ESTE MÊS. POST com `THIS_QUARTER` no Desempenho recalcula (2 campanhas de teste). Campanha de mês anterior não criada nesta rodada: exclusão por mês provada na dev (04-verificacao V-03/V-04) | passou (parcial na QA) |
| CA-07 | `PUT` e `GET` do painel com a massa; tela | 5 componentes com dado, sem erro | Atualização concluída (`componentDataStatus` DATA nos 5); Leads 10 grupos, Conversão 10 grupos, Desempenho 2 campanhas (R$ 3.200), Oportunidades por origem com valor, Respondentes sem agrupamento (sem membros de campanha criados, limite da massa) | passou |
| CA-08' | Relatório Desempenho com detalhe | ROI nativo, sem coluna de retorno paralela | Colunas ACTUAL_COST, BUDGETED_COST, NUM_*, AMOUNT_WON, ROI; Com Custo: custo R$ 1.000, receita R$ 2.500, ROI 150% | passou |
| CA-09' | Campo `MKT_ROI_Situacao__c` e relatório | Sem custo = Não calculável, ROI em branco, sem erro | Com Custo = Calculável; Sem Custo = Não calculável, ACTUAL_COST "-", ROI "-"; relatório executou sem erro | passou |
| CA-15 | Oportunidades por origem; fórmulas | Mesmos grupos | Componente agrupa por `Opportunity.MKT_Origem_Agrupada__c` (Sem origem; opps de teste sem origem). Igualdade do texto das fórmulas provada na dev (V-06), não repetida na QA | passou (parcial) |
| CA-16 | POST em `MKT_Origem_Original_por_Grupo` (grupo + `LeadSource`) | Valor original visível dentro do grupo | Outros: Campanha 2, WhatsApp 1, Origem Inventada XYZ 1, e um valor de dado real; Eventos/feiras: "feiras" 1; Sem origem: "-" 6 | passou |
| CA-17 | `dashboardMetadata` e `description` | Texto "Não é faturamento" | Rodapé do componente: "Receita atribuída = valor das oportunidades ganhas vinculadas à campanha. Não é faturamento."; description do relatório com "NAO e faturamento" | passou |
| CA-10 | `git diff main -- force-app` | Só pasta, 3 campos, PS, relatórios, painel | 14 arquivos, os mesmos de `05-deploy-qa.md` | passou |
| CA-12/CA-13 | Lista de arquivos do pacote; colunas | Sem Flow, Apex, trigger, e-mail; sem dado pessoal | 0 arquivos de flows, classes, triggers ou e-mail entre os 14; relatórios Summary sem nome, e-mail ou telefone | passou |
| CA-11 | Acesso só com o PS | Lê relatórios e não edita Lead, Oportunidade, Campanha | Não executado: o único usuário ativo é Administrador do sistema; o outro (`005bJ00000hBJmYQAW`) está inativo. Metadata do PS só traz leitura (verificação da dev) | não executado |

CA-14: resolvido pela regra 5 da conta (dev e QA são orgs distintas).

## Limites
- CA-11 sem prova de acesso negado por falta de usuário; fica para a homologação (roteiro, Teste 8).
- "Respondentes por campanha" sem massa de membros.
- Relatórios de Lead (Summary sem coluna) devolvem 203 no GET direto; abrem pelo painel e na tela.
- Sugestão: incluir `StartDate=Date.today()` em `fixtures/campanha_oportunidade_ganha*.apex`.
