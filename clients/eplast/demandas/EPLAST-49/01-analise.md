# EPLAST-49 — Análise

- **Cliente:** Eplast
- **Etapa:** análise (`ba-discovery`), 2026-11-20
- **Org conectada e conferida:** `sbx-eplast-dev` (sandbox `eplast--qa`, Org Id `00DHa000006vfMLMAY`), confirmada com `sf org list`. Só metadata e contagens foram lidas.
- **Divergência de rótulo:** o `00-preflight.md` diz "Etapa que vai rodar: `backlog`". A etapa executada foi a análise, como pedido pelo orquestrador.
- **Fonte do pedido:** `demandas/EPLAST-49/demanda.md` (registro do consultor, sem outro briefing).

## 1. Contexto de negócio

O consultor pede um atalho, dentro do LWC `Central_Comercial`, que leve o usuário ao painel (Dashboard) de leads e oportunidades. Hoje o painel só é alcançado navegando até a pasta de painéis. O link informado aponta para o ambiente de testes (`eplast--qas`). O consultor pede a confirmação do link de produção, pois o Id do painel pode mudar entre orgs.

## 2. Objetivo

Um clique no componente `Central_Comercial` abre o painel "Leads & Oportunidades", sem mudar o painel nem os dados.

## 3. Regra de negócio e comportamento

- O componente mostra um atalho com rótulo e abre o painel. Não exibe nenhum número do painel dentro do componente.
- O painel é lido como está. Nenhum campo, relatório, pasta, compartilhamento ou usuário executor é alterado.
- Nenhum dado de registro é lido nem gravado pelo componente. Não há Apex, Flow, e-mail nem envio de mensagem.
- Quem não tem acesso à pasta do painel continua sem acesso: o atalho não concede permissão.

## 4. O que a org confirma (dev, `sbx-eplast-dev`)

| Item | Resultado | Fonte |
|---|---|---|
| Painel `01ZbJ000000OFifUAG` | Existe na dev, título "Leads & Oportunidades", developer name `NhOdYqGFEXVWsiQHpYIWRuilgCgMfy`, pasta "Eplast". O Id é o mesmo do link do consultor (qas). | Consulta `Dashboard` |
| Pasta "Eplast" (painéis) | Tipo Dashboard, acesso `Hidden`: quem vê o painel depende do compartilhamento da pasta. `FolderShare` não é consultável por SOQL aqui, então a lista de quem tem acesso não foi confirmada. | Consulta `Folder` |
| Usuário executor do painel | Tipo de execução: usuário específico (Id `005Hp00000gijVrIAI`). Configuração existente, fora desta demanda. | Consulta `Dashboard.RunningUserId` |
| Componente `Central_Comercial` | **Não encontrado na dev.** Nenhum `LightningComponentBundle` com esse nome ou nome parecido. Os 4 bundles da org são `quoteTermEditorPage` e `themePage` (SBQQ) e `opportunityLostReason` e `opportunityLostReasonModal`. | Consulta Tooling `LightningComponentBundle` |
| Página, aba ou app com esse nome | Nenhuma aba (`CustomTab`) nem FlexiPage com "Central" ou "Comercial" na listagem de metadata da dev. Aplicativo com "Central" só existe como "Central de políticas" (`DataGovernanceConsole`), que não tem relação. | `sf org list metadata` e `AppDefinition` |
| Repositório | Nenhum arquivo com `Central_Comercial` no repositório. O `force-app/main/default/lwc` tem só `opportunityLostReason` e `opportunityLostReasonModal`. | Grep |
| Componente na QAS | **Não confirmado.** Só a dev está conectada nesta sessão. | — |
| Usuário de teste (Konecta) | Ativo: `005bJ00000piKAaQAM` (perfil Administrador do sistema). Há outro registro com o mesmo prefixo de username, inativo (`005bJ00000hBJmYQAW`), que não será usado. | Consulta `User` |

Observação: o painel da dev não deve mostrar números, porque a dev não tem registros. A verificação de dados é feita na QAS ou com dados de fixtures na dev.

## 5. Critérios de aceite

```gherkin
Funcionalidade: Atalho para o painel "Leads & Oportunidades" no Central_Comercial

  Cenário: Atalho visível para usuário com acesso ao painel
    Dado um usuário com acesso à pasta "Eplast" de painéis
    Quando ele abre a página que contém o componente Central_Comercial
    Então o componente exibe o atalho com o rótulo "Leads & Oportunidades"

  Cenário: Atalho abre o painel correto
    Dado um usuário com acesso ao painel
    Quando ele clica no atalho
    Então o painel "Leads & Oportunidades" abre na mesma aba
    E a URL aponta para o painel com título "Leads & Oportunidades" na org em que o usuário está

  Cenário: Sem Id fixo de painel no código
    Dado o código do componente
    Quando é feita a revisão do build
    Então o componente localiza o painel pelo nome do painel e não por um Id fixo
    E o mesmo pacote funciona na sandbox de dev e na de QA sem alteração

  Cenário: Usuário sem acesso ao painel não recebe dado pelo componente
    Dado um usuário do perfil Comercial sem acesso à pasta "Eplast"
    Quando ele abre a página que contém o componente Central_Comercial
    Então o componente não exibe nenhum dado do painel
    E ao clicar no atalho, a plataforma mostra a tela padrão de acesso insuficiente

  Cenário: Componente não altera dado nem permissão
    Dado o build concluído
    Quando é feita a revisão do código e do pacote
    Então não há chamada Apex, DML, Flow, envio de e-mail ou alteração de pasta, compartilhamento ou perfil
    E o pacote contém apenas o componente LWC e a referência de navegação

  Cenário: Demais componentes da página continuam funcionando
    Dado a página que contém o componente Central_Comercial
    Quando o usuário a abre na sandbox de QA
    Então os demais componentes da página renderizam como antes da mudança
```

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda **não cria, altera nem envia** dado de lead, origem, campanha, público ou comunicação. O painel "Leads & Oportunidades" é lido, e o atalho só navega. Por isso não há dado a preparar para o Marketing Cloud nesta demanda:

- **Dados que o MC lê:** nenhum novo.
- **Público identificável no CRM:** não se aplica.
- **O que o MC devolve e onde é gravado:** nada.
- **Consentimento e opt-out:** não se aplica, pois nada é enviado.
- **Para quem opera o MC:** nada.

Se o consultor quiser que o painel passe a filtrar por campanha ou público do Marketing Cloud, a demanda deve ser reaberta e esta seção refeita.

## 7. Riscos do assessment que tocam este pedido

- **Automações concorrentes em Account, Opportunity e Order (saúde vermelha):** a demanda não altera automação, trigger nem Flow desses objetos. Não há concorrência nova. O painel só lê Leads e Oportunidades.
- **Cobertura de teste Apex de 10%:** não se aplica, porque a solução não tem Apex. Se o arquiteto introduzir Apex, a cobertura de 85% por classe passa a valer.
- **Sandbox de dev sem registros:** o painel abre na dev, mas sem números. A verificação de dados precisa ser feita na QAS, que é Partial Copy: não criar nem alterar registro lá. Dado de teste na dev sai pelos scripts de `fixtures/`, se necessário.
- **Integração Protheus (`AccountTrigger`):** não é tocada por esta demanda.

## 8. O que a demanda não diz

1. **Onde fica o componente `Central_Comercial`.** Não existe na dev nem no repositório (seção 4). O texto diz "criar ... no LWC Central_Comercial", o que supõe que o componente existe. Isso muda o build: editar um componente existente em outra org, ou criar um bundle novo e posicioná-lo na página.
2. **Rótulo do atalho.** O texto não define.
3. **Posição do atalho na tela.** O texto não define.
4. **Abrir em nova aba ou na mesma aba.** O texto não define.
5. **Link de produção.** O consultor pede a confirmação. Produção está fora de alcance (guardrail 1). O Id do painel na produção é desconhecido.
6. **Quem deve ver o atalho.** O texto não diz se é para todos que veem o componente ou só para o perfil Comercial. A pasta "Eplast" é `Hidden`, e a lista de quem tem acesso não foi confirmada.

## 9. Premissas a validar (pendências)

- [ ] **Onde está o componente `Central_Comercial`.** Caso (c): a org não confirma a existência do componente, e a escolha errada duplica um componente ou altera o componente errado. Pergunta ao consultor: o componente existe na QAS (e não na dev) ou precisa ser criado do zero? Se existir só na QAS, o time precisa de autorização para trazê-lo à dev pelos meios da esteira, pois o build é feito na dev. Enquanto não houver resposta, o build não tem escopo fechado. As demais premissas resolvidas estão na seção 10.

## 10. Premissas assumidas (validar na homologação)

- [x] **Rótulo do atalho.** Pergunta: como se chama o atalho? Decisão: "Leads & Oportunidades", que é o título do painel. Evidência: título do painel na dev (seção 4). Como mudar: trocar o texto do rótulo no componente, sem efeito no painel.
- [x] **Abertura na mesma aba.** Pergunta: nova aba ou mesma aba? Decisão: mesma aba. Evidência: padrão de navegação do Lightning, que é o modo mais simples. Como mudar: trocar a opção de navegação do componente.
- [x] **Posição do atalho.** Pergunta: onde fica na tela? Decisão: no topo do componente `Central_Comercial`. Evidência: nenhuma na org; decisão de padrão, a mais simples e fácil de mover depois. Como mudar: mover o bloco do atalho dentro do template.
- [x] **Referência ao painel.** Pergunta: o Id fixo do painel serve em todas as orgs? Decisão: o componente localiza o painel pelo nome do painel (developer name `NhOdYqGFEXVWsiQHpYIWRuilgCgMfy`) e não por Id fixo. Evidência: o Id `01ZbJ000000OFifUAG` é o mesmo na dev e no link da QAS, mas o Id de produção é desconhecido. Como mudar: trocar a forma de localizar o painel, se a QAS apresentar outro developer name na homologação.
- [x] **Acesso ao painel.** Pergunta: o atalho deve esconder o painel de quem não tem acesso? Decisão: não. O atalho aparece para quem vê o componente. Quem não tem acesso à pasta recebe a tela padrão de acesso insuficiente, e o componente não mostra dado do painel. A demanda não muda compartilhamento. Evidência: pasta "Eplast" com acesso `Hidden` (seção 4) e padrão da plataforma. Validação: testar com usuário Comercial sem acesso na QAS. Como mudar: restringir a visibilidade do componente por perfil ou permission set, decisão do arquiteto. Padrão de visibilidade por perfil já discutido em `[demandas/EPLAST-32/01-analise.md]`.
- [x] **Usuário executor do painel.** Pergunta: o atalho deve mudar quem executa o painel? Decisão: não. O painel mantém a configuração atual (usuário executor `005Hp00000gijVrIAI`). Evidência: configuração existente na dev. Observação para o consultor, fora do escopo: se o painel roda como um usuário específico, todos que o abrem veem os dados desse usuário. Compartilhamento por público de pasta de painel já foi tratado em `[demandas/EPLAST-34/rodada-anterior/03-design.md]`.
- [x] **Sem Apex, Flow nem dado novo.** Pergunta: a solução precisa de lógica no servidor? Decisão: não. A solução é só o componente LWC e a referência de navegação. Evidência: o pedido é um atalho de leitura (demanda.md). Como mudar: se o arquiteto precisar de lógica no servidor, a demanda volta à análise.
- [x] **Ambientes e conta de teste.** Pergunta: onde o build é feito e verificado, e qual usuário de teste? Decisão: build e verificação na dev (`sbx-eplast-dev`); homologação na QAS (`sbx-eplast-qa`). Usuário de teste: `005bJ00000piKAaQAM`, ativo, perfil Administrador do sistema. Como o perfil vê tudo, o teste de acesso negado usa um usuário Comercial dos fixtures, não este. Evidência: consulta `User` (seção 4) e regra 5 do cliente.
- [x] **Link de produção.** Pergunta: qual o Id do painel em produção? Decisão: não se resolve nesta demanda. A solução não grava Id, por isso o link de produção fica correto desde que o painel tenha o mesmo nome. Evidência: seção 3 e premissa de referência. Como validar: o consultor confirma o nome do painel em produção antes da implantação de produção, que está fora desta esteira.

## 11. Complexidade e esforço

**Complexidade: P.** Um atalho para um painel existente, sem Apex nem dado. Sobe para M se for preciso criar o componente `Central_Comercial` e posicioná-lo na página.

**Estimativa de esforço:** 3–6 h
Faixa: 3 h se o componente existir na QAS e for só editar. 6 h se for preciso criar o bundle, posicioná-lo na página e testar com usuário sem acesso. Inclui revisão do consultor, verificação de acesso por perfil e homologação. Não inclui a confirmação do link de produção.

## 12. Encerramento

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
