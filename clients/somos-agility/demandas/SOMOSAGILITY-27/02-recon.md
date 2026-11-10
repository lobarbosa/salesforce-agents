# Recon da org — SOMOSAGILITY-27

**Data da coleta:** 2026-11-10
**Org:** `sbx-somos-agility-dev` (confirmada via `Organization.IsSandbox = true`, `InstanceName = BRA8S`, API v68.0) — mesma org usada na análise.

Todas as consultas abaixo são metadata e contagens agregadas. Nenhuma trouxe nome, e-mail, perfil específico de usuário ou qualquer dado de negócio da colaboradora (guardrail #2) — a análise já havia decidido não consultar o usuário dela diretamente, e este recon manteve a mesma linha.

## 1. Achado novo: existe um objeto custom literalmente chamado "Modelo"

A análise deixou a pergunta 1 ("criar um modelo Salesforce" — o que exatamente?) como parada de design. O recon encontrou um candidato concreto que a análise não tinha como ver sem listar os objetos da org:

- **`Modelo__c`** (label "Modelo", sem namespace de pacote gerenciado — é nativo desta org, não veio de um pacote instalado).
  - `sf sobject describe --sobject Modelo__c`: `createable=true`, `queryable=true`, key prefix `a0a`.
  - Um único Record Type: `Mestre` (default).
  - Campos: só os padrão (`Name`, `OwnerId`, datas de sistema) — **nenhum campo custom além de `Name`**.
  - **0 registros** na sbx dev (`SELECT COUNT() FROM Modelo__c`).
  - **Sem Apex Trigger** (`ApexTrigger WHERE TableEnumOrId='Modelo__c'` → vazio).
  - **Sem Validation Rule** (`ValidationRule` via Tooling → vazio).
  - **Tem uma Tab registrada** (`TabDefinition WHERE SobjectName='Modelo__c'` → existe), então é navegável na UI, não é um objeto órfão sem exposição.
  - Permissão de `Create` em `Modelo__c` está concedida em **8** perfis/permission sets (`ObjectPermissions WHERE SobjectType='Modelo__c' AND PermissionsCreate=true`); outros perfis/permission sets têm só `Read`.

**Leitura:** `Modelo__c` existe, está exposto por Tab, tem Create liberado para parte da org, mas está vazio e sem nenhum campo além do nome — parece um objeto criado e nunca desenvolvido, ou abandonado. É um candidato plausível para "criar um modelo", mas **não é confirmação**: o nome bater não prova a intenção de negócio, e um objeto sem campo custom nenhum dificilmente serve pra qualquer função sozinho. Isto não resolve a pergunta 1 da análise — só dá ao consultor/colaboradora algo concreto para confirmar ou descartar ("é isso que você tentava criar?"), em vez de uma pergunta aberta.

Não encontrei nenhum outro objeto, Report Type custom ou metadata com nome que sugira "modelo" fora deste. Busca feita por `sf sobject list | grep -iE "model|template|modelo"` — os demais resultados são `EmailTemplate`/`*Template*` padrão ou de pacotes gerenciados (Conga, SDOC, snap_finan), sem relação óbvia com o pedido.

## 2. Permissões de relatório (pergunta A4/A5 da análise — permission set vs. perfil)

A análise já tinha confirmado que as permissões `PermissionsCreateCustomizeReports` e `PermissionsExportReport` são amplamente distribuídas por perfil (54 de 77) e pouco por permission set (5 e 3 de 142). O recon foi atrás de **permission sets de função já existentes** que poderiam ser reaproveitados em vez de criar um novo ou mexer no perfil individual:

- **`Full_Access_and_Management_of_Reports`** ("Full Access and Management of Reports") — já tem `PermissionsCreateCustomizeReports=true`, `PermissionsExportReport=true` e `PermissionsManageReportsInPubFolders=true`. Atribuído a **2 usuários ativos** hoje (`PermissionSetAssignment` agregado por `PermissionSetId`, sem identificar quem). O nome sugere escopo mais amplo do que "salvar e exportar relatório" — "Full Access and Management" pode liberar mais do que a função da colaboradora precisa (ver critério A3 da análise, "sem ampliação de acesso além do necessário").
- **`Grupo_Opera_es_Relat_rios`** ("Grupo Operações - Relatórios") — nome sugere agrupamento por área/função (o padrão que o achado #6 do assessment recomenda), mas **não tem** nenhuma das duas permissões hoje (`false`/`false`). Se a função da colaboradora for "Operações", este é o permission set mais alinhado ao nome da área dela — mas precisaria ganhar as duas permissões, não ser trocado por um novo.

**Leitura para o design:** existem dois caminhos declarativos sem Apex nem Flow — (a) atribuir `Full_Access_and_Management_of_Reports` já pronto, aceitando que ele dá mais do que só "salvar e exportar", ou (b) adicionar as duas permissões em `Grupo_Opera_es_Relat_rios` (ou outro permission set por função a confirmar) e atribuir esse. Nenhuma das duas exige objeto novo, Flow ou Apex. A escolha entre elas depende de qual é a função real da colaboradora — dado que este recon não foi atrás de propósito (guardrail #2).

## 3. Pastas de relatório

`SELECT COUNT() FROM Folder WHERE Type='Report'` → **315 pastas de relatório** na org. Não consultei nomes nem conteúdo — a pergunta 7 da análise (qual pasta a função usa, e compartilhamento) ainda depende do consultor; com 315 pastas não dá para adivinhar qual é a certa sem a resposta.

## 4. Limitações desta coleta

- Tentei `sf project retrieve start --metadata ReportType --output-dir /tmp/recon` para listar Report Types custom (candidato alternativo para "modelo"). A CLI instalada neste runner recusou com `OutputDirOutsideProjectError` por `/tmp/recon` estar fora da raiz do projeto DX (`clients/somos-agility`, onde está `sfdx-project.json`) — divergência de versão da CLI em relação ao que a skill `org-recon` documenta. Não tentei redirecionar para dentro de `clients/somos-agility/` porque isso arriscaria o retrieve entrar no commit da etapa (achado SOMOSAGILITY-23 que a própria skill cita). Fica em aberto: se a pergunta 1 apontar para Report Type em vez de `Modelo__c`, este levantamento precisa ser refeito num ambiente onde o retrieve para `/tmp` funcione.
- Não consultei `EntityDefinition.CreatedDate`/`PublisherId` de `Modelo__c` (campo não existe nessa entidade na versão de API consultada) — não dá pra saber quando ou por quem o objeto foi criado.
- Não consultei perfil, permission set nem licença da colaboradora (dado pessoal/identificável, fora do escopo deste agente — guardrail #2, mesma decisão já tomada na análise).

## Resumo para o arquiteto

- Org certa, confirmada de novo.
- A pergunta 1 da análise continua sem resposta confirmada do consultor, mas agora há um candidato concreto (`Modelo__c`) a apresentar para validação, em vez de ficar só com a pergunta aberta.
- Para a parte de relatório (perguntas A1-A4), dois caminhos declarativos existem na org hoje: estender `Grupo_Opera_es_Relat_rios` ou atribuir `Full_Access_and_Management_of_Reports`. Nenhum exige Apex, Flow ou objeto novo.
- Nenhuma automação (trigger, validation rule) foi encontrada em `Modelo__c` — se a solução envolver esse objeto, não há risco de concorrência com automação existente ali (diferente do que aconteceria em Oportunidade, achado #1 do assessment, que não se aplica aqui).
