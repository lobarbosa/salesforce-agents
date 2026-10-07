# Assessment da org — Mais Polímeros

**Org auditada:** sbx-mais-polimeros-dev (https://maispolimeros--devkonecta.sandbox.my.salesforce.com) · **API:** v67.0 · **Data:** 2026-10-07
**Saúde geral:** vermelho

## Veredito em três linhas

A org de dev da Mais Polímeros tem automação acumulada sem curadoria: os objetos Pedido e Produto de Cotação chegam a ter 4 Flows ativos disparando no mesmo evento, dois Process Builders (fim de vida) ainda rodam, e a cobertura de teste Apex está em 20% — bem abaixo do mínimo de 85% do squad e do piso de 75% que a própria Salesforce exige pra deploy em produção. O modelo de dados cresceu no mesmo ritmo: Account já tem 381 campos, e 96,5% dos campos custom não têm descrição, então hoje ninguém sabe pra que metade deles serve. Antes de desenhar qualquer demanda nova em Pedido, Conta ou Oportunidade, vale consolidar essa automação — do contrário a próxima mudança vira só mais uma camada em cima da bagunça.

## Inventário

| Métrica | Valor |
|---|---|
| Edição / tipo de org | Unlimited Edition, sandbox, instância BRA4S |
| API version da org | v67.0 |
| Pacotes gerenciados instalados | 16 (destaque: DevOps Center, DLRS, Custom Quote Sync/`quotesync`, ChatIntegration/WhatsApp, beeCnpj, ChatGPT LWC/`aibp`, Power BI Dashboard, Sales Insights, Salesforce Data Cloud - Flow Integration) |
| Flows cadastrados (total / ativos / inativos) | 290 / 229 / 61 |
| Process Builders (`ProcessType=Workflow`) ativos / total | 2 / 11 |
| Workflow Rules clássicas | 7 (status ativo/inativo não confirmado — ver "Não pôde ser medido") |
| Apex Triggers | 42 |
| Combinações objeto+evento com mais de 1 Flow ativo | 10 |
| Classes Apex custom (sem namespace) | 168 |
| Classes com `<Classe>Test` correspondente | 67 |
| Classes sem teste dedicado | 47 |
| Cobertura de teste Apex (org-wide) | 20% |
| Objetos custom nativos (sem namespace de pacote) | 53 |
| Objetos custom vindos de pacotes gerenciados | 57 |
| Campos em Account / Opportunity / Order | 381 / 177 / 185 |
| Campos custom em Account sem descrição | 418 de 433 (96,5%) |
| Perfis totais / perfis custom de negócio (estimado) | 57 / ~21 |
| Permission Sets / Permission Set Groups | 249 / 21 |
| Validation Rules (total / ativas / inativas) | 202 / 141 / 61 |
| Record Types | 15 |
| Page Layouts | 420 |
| Data Storage usado | ~2 MB de 200 MB (≈1%) |
| File Storage usado | 0 MB de 200 MB (0%) |
| Licença Salesforce (full) em uso | 30 de 32 (93,8%) — cópia de sandbox, ver ressalva no achado |

## Achados

### 1. Flows duplicados disparando no mesmo evento do mesmo objeto
- **Severidade:** alta
- **Área:** automação
- **Evidência:** `sf data query --query "SELECT ApiName, ProcessType, TriggerType, RecordTriggerType, TriggerObjectOrEventLabel, IsActive FROM FlowDefinitionView"` — 229 Flows ativos; agrupando por (objeto, evento) há 10 combinações com mais de um Flow ativo simultâneo. Pior caso: **Produto de Cotação** e **Pedido**, cada um com **4** Flows ativos em `RecordAfterSave` (`Altera_oCota_oDataEntrega`, `AnaliseCota_oesPerdidas`, `MP_COTA_O_WPP`, `PB_OLI_01_Recorrente_1` em Produto de Cotação; `Atualizar_data_de_Entrega`, `Atualizar_vendedor_loja`, `FLOrder02_AtualizaUltimaAtividadeGrupoEconomico`, `PB_Order_01` em Pedido). Também Conta (3 em after-save + 2 em before-delete) e Tarefa (3 em after-save).
- **Risco:** ordem de execução entre Flows do mesmo evento não é garantida pelo administrador (só por ordem de criação/prioridade interna); qualquer novo Flow nesses objetos aumenta a chance de condição de corrida, loop de atualização ou efeito colateral difícil de depurar — e cada demanda nova nesses objetos esbarra nessa pilha.
- **Recomendação:** consolidar os Flows de Pedido e Produto de Cotação em um Flow por evento (ou um framework de orquestração por Apex), nessa ordem de prioridade; documentar o que cada trecho faz antes de fundir.
- **Esforço:** alto

### 2. Cobertura de teste Apex em 20% (org-wide)
- **Severidade:** alta
- **Área:** código
- **Evidência:** `sf data query --query "SELECT PercentCovered FROM ApexOrgWideCoverage" --use-tooling-api` → `PercentCovered: 20`.
- **Risco:** abaixo do piso de 75% que a Salesforce exige pra qualquer deploy real em produção, e bem abaixo do mínimo de 85% por classe que o squad pratica. Qualquer release futuro desta org vai esbarrar nisso antes mesmo de chegar a homologação.
- **Recomendação:** priorizar testes nas classes que sustentam integração e trigger handlers (`OrderTriggerHandler`, `OrderItemTriggerHandler`, `Product2TriggerHandler`, `*IntegrationBO`, `*DAO`) antes de qualquer novo build tocar nesses fluxos.
- **Esforço:** alto

### 3. 96,5% dos campos custom de Account sem descrição
- **Severidade:** alta
- **Área:** modelo de dados
- **Evidência:** `sf data query --query "SELECT COUNT() FROM CustomField WHERE TableEnumOrId='Account'" --use-tooling-api` → 433; `... AND Description = null` → 418.
- **Risco:** ninguém hoje consegue saber pra que serve a maioria dos campos de Account só olhando o Setup; qualquer demanda nova em Account corre risco de recriar um campo que já existe, ou de mexer num campo crítico sem saber que é usado por integração.
- **Recomendação:** campanha de documentação mínima nos campos mais referenciados por Flow/Apex antes de qualquer novo build em Account; usar Field Usage (quando disponível) pra priorizar.
- **Esforço:** alto

### 4. Dois perfis de administrador coexistindo
- **Severidade:** média
- **Área:** segurança
- **Evidência:** `sf data query --query "SELECT Name, UserType FROM Profile"` — entre 57 perfis totais (34 `UserType=Standard`, ~21 não correspondem aos perfis-padrão da Salesforce), aparecem **"Mais Polimeros Admin"** e **"Mais Polimeros Admin - sMFA"** como dois perfis distintos de administrador.
- **Risco:** dois perfis administrativos significam duas superfícies de permissão pra manter sincronizadas; drift entre eles (um ganha um objeto novo, o outro não) é silencioso até alguém precisar daquele acesso.
- **Recomendação:** mover a diferença de "sMFA" para uma Permission Set (ou política de autenticação específica), manter um único perfil de Admin como base.
- **Esforço:** médio

### 5. Validation Rules quase duplicadas ativas simultaneamente
- **Severidade:** média
- **Área:** config
- **Evidência:** `sf data query --query "SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Opportunity'" --use-tooling-api` — `DataDeFechamento` (Active=true) e `data_de_fechamento` (Active=true) coexistem ativas na mesma entidade. (Não li o corpo das fórmulas — a duplicação é de nome/intenção, não confirmei se a lógica interna também se repete.)
- **Risco:** duas regras com nome quase idêntico ativas ao mesmo tempo é sinal de que uma deveria ter substituído a outra e não foi desativada; mantém dúvida sobre qual é a "oficial" pra quem for alterar.
- **Recomendação:** revisar as duas regras, manter uma, desativar a redundante.
- **Esforço:** baixo

### 6. 47 classes Apex sem classe de teste dedicada
- **Severidade:** média
- **Área:** código
- **Evidência:** `sf data query --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = null"` → 168 classes; 67 têm nome de teste (`*Test`); 47 das 101 classes de produção não têm `<Classe>Test` correspondente — entre elas `OrderTriggerHandler`, `OrderItemTriggerHandler`, `Product2TriggerHandler`, `OrderBO`, `OpportunityBO`, `EstoqueBO`, `FreteIntegrationBO`, `QuoteIntegrationBO`.
- **Risco:** lógica de trigger handler e integração sem teste dedicado some na cobertura agregada de outra classe, mascarando buraco real — é parte do motivo da cobertura de 20% do achado #2.
- **Recomendação:** mapear as 47 e criar `<Classe>Test` para as que sustentam trigger handlers e integrações primeiro.
- **Esforço:** médio

### 7. Classes Apex em API version muito atrasada
- **Severidade:** média
- **Área:** dívida
- **Evidência:** `sf data query --query "SELECT Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null"` — 5 classes em API v36, 16 em v45, enquanto a org roda v67.0.
- **Risco:** classes em API muito antiga preservam comportamento legado de sharing/validação que a Salesforce já corrigiu em versões novas; dificulta raciocinar sobre comportamento real do código e aumenta a distância pra qualquer modernização futura.
- **Recomendação:** depois de garantir cobertura de teste (achado #2/#6), recompilar essas classes bumping a API version e validar comportamento.
- **Esforço:** médio

### 8. Account se aproximando de ~400 campos
- **Severidade:** média
- **Área:** modelo de dados
- **Evidência:** `sf sobject describe --sobject Account` → 381 campos totais (330 custom).
- **Risco:** manutenção de layout, relatório e automação em Account fica cada vez mais difícil; aproxima-se do limite prático recomendado por objeto.
- **Recomendação:** antes de criar qualquer campo novo em Account, confirmar que não existe equivalente entre os 330 já existentes (achado #3 é pré-requisito disso).
- **Esforço:** alto

### 9. Process Builder ainda ativo em produção de automação
- **Severidade:** média
- **Área:** automação
- **Evidência:** `sf data query --query "SELECT ApiName, ProcessType, IsActive FROM FlowDefinitionView WHERE ProcessType='Workflow'"` → 11 processos cadastrados, 2 ativos (`AutomacaoQueue`, `Produto_Cod`), 9 inativos (prefixo `PB*`).
- **Risco:** Process Builder está em fim de vida — Salesforce não investe mais nele, e performance/observabilidade é pior que Flow.
- **Recomendação:** migrar os 2 processos ativos para Flow; os 9 inativos podem ser removidos (ver achado #10).
- **Esforço:** baixo

### 10. Licença Salesforce (full) em 93,8% de uso
- **Severidade:** média
- **Área:** limites
- **Evidência:** `sf data query --query "SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense"` → `Salesforce: 30/32`.
- **Risco:** perto do limite contratado — qualquer onboarding novo de usuário full pode travar até compra de licença adicional. Ressalva: este número vem da cópia de sandbox (reflete o estado de produção no momento do último refresh, não necessariamente o de hoje).
- **Recomendação:** confirmar com o cliente o número atual em produção antes de qualquer demanda que preveja novos usuários full.
- **Esforço:** baixo

### 11. Metadata inativo acumulado sem limpeza
- **Severidade:** baixa
- **Área:** config
- **Evidência:** 61 de 290 Flows cadastrados estão inativos (`FlowDefinitionView.IsActive=false`); 61 de 202 Validation Rules estão inativas (`ValidationRule.Active=false` via Tooling).
- **Risco:** ruído em qualquer retrieve/deploy futuro, dificulta saber o que está realmente em uso pra quem chega na org agora.
- **Recomendação:** rodar uma limpeza confirmando com o time de negócio que cada item inativo pode ser removido, antes de arquivar.
- **Esforço:** baixo

## Não pôde ser medido

- **Sharing settings / Organization-Wide Defaults por objeto** — não encontrei um objeto consultável via SOQL que exponha o OWD atual (`EntityDefinition` não tem campo `SharingModel` nesta API); confirmar isso exigiria recuperar o metadata `Settings` completo e inspecionar manualmente, fora do escopo desta sessão de recon read-only.
- **Status ativo/inativo das 7 Workflow Rules clássicas** — o objeto Tooling `WorkflowRule` não expõe um campo `Active` consultável via SOQL; confirmar exigiria retrieve do XML de metadata de cada regra.
- **Page layouts órfãos (sem perfil/record type associado)** — dos 420 layouts cadastrados, não cruzei atribuição por perfil e record type; é uma análise maior do que o tempo desta sessão permitiu.
- **Uso real de cada campo custom** (quantos dos 330 campos custom de Account têm algum dado preenchido) — mediria com `SELECT COUNT()` por campo, mas são centenas de combinações; não rodei.
- **Deploy-validate completo (dependências quebradas, componentes inexistentes)** — não rodei `sf project deploy validate` porque exigiria recuperar o metadata inteiro da org para um projeto local primeiro; os sinais de dívida técnica reportados aqui (API version antiga, Process Builder vivo, metadata inativo) vêm de consultas indiretas, não de uma checagem de deploy real. Recomendo rodar esse validate como primeiro passo da etapa de recon de qualquer demanda que toque nesses objetos.
- **Detalhe de quais dos 47 "classes sem teste" realmente precisam de teste dedicado** (algumas podem ser interfaces ou classes utilitárias sem lógica de risco) — listei os nomes, mas não abri o corpo de cada uma para confirmar.
