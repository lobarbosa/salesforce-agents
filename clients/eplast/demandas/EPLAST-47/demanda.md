# Corrigir o Fluxo Agendado – Oportunidade (valor de compras e classificação de contas)

Corrigir o fluxo agendado "Fluxo Agendado – Oportunidade" (ScheduledFlowOpportunity), que calcula o valor de compras e a classificação (ranking) das contas todo dia 14.

CONTEXTO
Cliente Eplast. Sem Apex. Os nomes de API dos campos são levantados na análise de impacto (H1). Na esteira: build em sbx-eplast-dev, testes em sbx-eplast-qa. A promoção para QAS e produção é humana e está no card EPLAST-48.

O QUE O REPOSITÓRIO JÁ MOSTRA (baseline de 17/10 — reconfirmar na org antes de desenhar)
- O fluxo parte de Opportunity com IsWon = true e atualiza a conta uma vez por oportunidade ganha.
- Soma Amount das oportunidades com ThisYear__c = true e grava em Account.LastMonthPurchaseValue__c (soma anual no campo de último mês).
- A consulta GetOpportunities2 filtra só LastMonth__c = true, sem conta, e o resultado não é usado.
- A regra PP testa "igual a 10.000": valor abaixo de 10.000 cai no resultado padrão, que é GG.
- A classificação lê Account.AveragePurchasesThisYear__c (média), não a soma que o fluxo grava.
- Opportunity.ThisYear__c usa CreatedDate, não a data de fechamento.
- Account.Ranking__c tem 5 valores (PP, P, M, G, GG); faltam MP e 3G.
- Faixas atuais: 10.000 / 70.000 / 150.000 / 500.000. O fluxo roda todo dia e só segue quando o dia é 14.
- O fluxo não tem caminho de falha nem e-mail: o alerta para o ex-parceiro deve estar na configuração da org.
- Também usam esses campos: fluxo OpportunityFlow, permission set Protheus, layout e página de registro de Conta, tipos de relatório Gestao e GestaoDeVisitas. Relatórios e painéis não estão no repositório.

H1 – ANÁLISE DE IMPACTO (análise, recon e desenho)
- Mapa do fluxo e das dependências.
- Confirmar ou refutar os 4 pontos do diagnóstico: execução por oportunidade; soma anual no campo de último mês; consulta sem filtro de conta; alertas para ex-parceiro.
- Campos lidos e gravados, com nome de API.
- Onde valor de compras e ranking são usados: relatórios, painéis, automações, integração Protheus.
- Confirmar se os 7 valores de classificação existem.
Gate: aprovação do Leo no desenho antes de H2 a H5.

H2 – EXECUÇÃO POR CONTA
- O fluxo itera por conta, não por oportunidade.
- A consulta de oportunidades é filtrada pela conta.
- Zero erro UNABLE_TO_LOCK_ROW.

H3 – CÁLCULO DO VALOR DE COMPRAS
- O período é lido de configuração.
- Premissa provisória: base anual, só oportunidades ganhas.
- Conta sem compra: zero ou vazio, configurável.
Pendência: a premissa aguarda resposta da Tatiana. Construir configurável com a premissa provisória; não promover para QAS antes da resposta.

H4 – CLASSIFICAÇÃO POR FAIXAS
- Faixas em metadados personalizados: MP até 10.000; PP até 35.000; P até 80.000; M até 160.000; G até 500.000; GG até 1.000.000; 3G acima.
- Cada faixa começa "acima de" o limite da anterior.
- Faixas antigas removidas do fluxo.
- Relatório com a quantidade de contas que mudam de classificação.

H5 – ALERTAS DE ERRO
- Remover o e-mail do ex-parceiro.
- Caminho de falha com destinatário configurável.
Pendência: o endereço será informado pela Eplast. Construir configurável; não inventar endereço.

H6 – TESTES (etapa de QA)
- 15 cenários de borda das faixas, mais zero e vazio.
- Teste de volume.
- Evidência por cenário na sandbox de QA.

DEPENDÊNCIAS
H1 libera H2 a H5. H6 depende de todas. EPLAST-48 depende desta demanda e da resposta da Tatiana.
