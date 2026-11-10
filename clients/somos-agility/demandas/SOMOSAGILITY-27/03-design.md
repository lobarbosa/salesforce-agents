# Design — SOMOSAGILITY-27 (sustentação, design enxuto)

- **Cliente:** Somos Agility
- **Org consultada:** `sbx-somos-agility-dev` (sandbox, confirmada no recon e de novo nesta etapa via `sf org list`)
- **Pré-requisito:** gate `aguardando_gate_analise` aprovado em `gates.md` (2026-11-10T23:13, commit `2cdd0f97`).
- **Escopo deste design:** **parcial, de propósito.** Cobre a parte de relatório (salvar e extrair, critérios A1–A4 e A6). A parte "criar modelo" (A5) **continua bloqueada** pela pergunta 1 da análise, que não foi respondida. Ver a seção 6.

## 1. Confirmações feitas nesta etapa (além do `02-recon.md`)

Todas são metadata ou contagens. Nenhuma consulta identificou a colaboradora, o perfil dela ou a licença dela (guardrail #2).

| Item | Resultado |
|---|---|
| `Full_Access_and_Management_of_Reports` | Sem licença vinculada. Tem `RunReports`, `CreateCustomizeReports`, `ExportReport`, `CreateReportInLightning`, `ScheduleReports`, `SubscribeToLightningReports`, **`ManageReportsInPubFolders`** e **`CreateReportFolders`**. Não tem ViewAll/ModifyAll. 2 atribuições ativas. Criado em 2024-06. |
| `Grupo_Opera_es_Relat_rios` | **Vazio**: nenhuma permissão de sistema de relatório (nem `RunReports`), 0 `ObjectPermissions`, 0 `FieldPermissions`, 0 `SetupEntityAccess`. **0 atribuições** (ativas ou não). Vinculado à licença `Salesforce`. Criado em 2018-10, descrição sem significado (`jn09102018`). Não está em nenhum Permission Set Group. |
| Permission sets com `ExportReport=true` | 3: `Comunidade_TI`, `DiretorComercial`, `Full_Access_and_Management_of_Reports` |
| Permission sets com `CreateCustomizeReports=true` | 5: os 3 acima mais `AncMarketingIntegrationUser` e `AncPersonalizationIntegrationUser` (usuários de integração) |
| Perfis com `CreateCustomizeReports` **e** `ExportReport` | 54 de 77 (agora confirmado que é o mesmo conjunto, o que a análise deixou em aberto). Perfis com `RunReports`: 60. |
| Grupo público `Relatorios` | Existe (tipo `Regular`), 7 membros. Não consegui ver em quais pastas ele é usado (`FolderShare` não é consultável nesta API). |
| Permission sets com prefixo `PS_` | 2 (`PS_Rollup_Helper_*`, de pacote). A convenção `PS_<Area>_<Funcao>` da skill `padrao-entrega` praticamente não é usada nesta org. O `CLAUDE.md` do cliente não define convenção própria. |

RAG: consultado com "permission set relatórios exportar salvar relatório perfil por pessoa Modelo__c". Nenhuma demanda anterior deste cliente trata de permissão de relatório. A única fonte que volta é a própria análise desta demanda. Nenhuma decisão anterior pesa aqui.

## 2. Decisão: configuração (permission set novo, mínimo, por função). Sem Flow, sem Apex.

**Nível escolhido:** configuração nativa, o primeiro nível da doutrina. O problema é de acesso. Acesso em Salesforce se resolve com permissão de sistema e compartilhamento de pasta. Não há regra de negócio, cálculo, gatilho nem integração, então Flow e Apex não têm o que fazer aqui. Não há descida de nível para justificar.

**Forma:** criar um permission set novo, `PS_Relatorios_ExtrairSalvar`, com o mínimo para salvar e exportar relatório, e atribuí-lo à colaboradora. **Não** ajustar o perfil individual dela.

### Por que permission set e não ajuste no perfil (achado #6 do assessment)

O assessment registra 20 de 26 perfis em uso com um único usuário ativo. Pôr a permissão no perfil da colaboradora resolve o caso dela e mantém o antipadrão. A próxima pessoa com a mesma necessidade cai num perfil diferente e o ajuste se repete. Com um permission set por função, a próxima pessoa recebe uma atribuição. A pergunta "quem pode exportar relatório?" também passa a ter uma resposta consultável. Permission set é aditivo, então não muda nada para quem já tem a permissão pelo perfil.

**Não há exceção ao perfil individual nesta demanda.** Isso responde ao A4.

### Por que não os dois caminhos que o recon encontrou

| Opção | Motivo de não usar |
|---|---|
| (a) Atribuir `Full_Access_and_Management_of_Reports` | Concede `ManageReportsInPubFolders`, que permite **editar e apagar relatórios de outras pessoas em pastas públicas**, e `CreateReportFolders`. Isso vai além de "salvar e extrair" e viola o A3 ("sem ampliação de acesso além do necessário"). O nome e a descrição deixam claro que o escopo é gestão de relatórios, não análise. |
| (b) Pôr as permissões em `Grupo_Opera_es_Relat_rios` | Parecia o caminho certo pelo nome. A verificação nesta etapa mostrou que ele está **vazio e sem nenhuma atribuição desde 2018**. Reaproveitá-lo não traz ganho real e tem três custos. Primeiro, o nome amarra a área "Operações", e a área da colaboradora não foi confirmada. Segundo, ele está preso à licença `Salesforce`, e a licença dela também não foi confirmada (pergunta 5 da análise; achado #9, licença em 97%). Se ela tiver outra licença, a atribuição falha. Terceiro, a descrição não diz para que ele foi criado. Fica intocado nesta demanda (seção 7). |
| (c) **Novo `PS_Relatorios_ExtrairSalvar`**, escolhida | Escopo mínimo e explícito. Sem licença vinculada, então serve a qualquer licença que suporte as permissões. Segue a convenção `padrao-entrega`. Ninguém além de quem receber a atribuição ganha acesso, o que atende o A3. |

**Ponto para o arquiteto humano revisar:** se preferir não criar o 143º permission set, a alternativa aceitável é a (b), mas só se o consultor confirmar que a colaboradora é de Operações e tem licença `Salesforce`. Nesse caso, o permission set também deve ganhar uma descrição real. A (a) não é aceitável por causa do A3.

## 3. Componentes

### Criar

| Tipo | API name | Conteúdo |
|---|---|---|
| `PermissionSet` | `PS_Relatorios_ExtrairSalvar` | Label "Relatórios - Extrair e Salvar". Sem licença (`license` vazio). **Descrição obrigatória** (DoD), por exemplo: "Executar, criar/salvar e exportar relatórios. Não inclui gestão de pastas públicas. SOMOSAGILITY-27." Permissões de sistema: `RunReports`, `CreateCustomizeReports`, `ExportReport`. Nenhuma permissão de objeto, de campo, de app ou de pasta. |

Observações de build:
- `CreateReportInLightning` aparece ligada em `Full_Access_and_Management_of_Reports`. Não confirmei se ela é necessária para salvar pelo Report Builder Lightning nesta org (premissa P2 da análise). O build **não** a inclui por padrão. Se o teste A1 falhar com as três permissões acima, ela é a primeira candidata a acrescentar, com registro em `05-testes.md`. Não acrescentar nada além disso sem voltar ao design.
- As dependências entre permissões (Export e CreateCustomize dependem de RunReports) são validadas pelo `sf project deploy validate` (`ci-salesforce-validate.yml`) antes do deploy.
- Em `force-app/` entra só este arquivo `.permissionset-meta.xml` (`padrao-entrega`, "O que nunca entra no PR").

### Alterar

Nenhum metadata existente é alterado. Nenhum perfil é alterado.

### Depreciar

Nada nesta demanda (ver seção 7).

### Passos manuais (não são metadata, ficam no `06-entrega.md`)

1. **Atribuir** `PS_Relatorios_ExtrairSalvar` à colaboradora. Quem faz é um humano de delivery, porque a atribuição é dado (`PermissionSetAssignment`) e exige identificar a usuária (guardrail #2). Em produção a atribuição também é humana (guardrail #1).
2. **Pasta de relatório:** dar à colaboradora (ou ao grupo dela) acesso de **Editor** na pasta onde ela precisa salvar. Pasta é compartilhamento, não permission set, e a permissão sozinha não resolve sem ela (premissa P5). A pasta não é definida neste design: são 315 pastas e a pergunta 7 da análise segue aberta. O grupo público `Relatorios` (7 membros) existe e pode ser o veículo, mas não confirmei em que pastas ele é usado. O consultor decide e registra.
3. **Regularizar a alteração já feita pela equipe:** o card diz "adicionado uma permissão para salvar relatórios", sem dizer onde. Não há registro disso no `SetupAuditTrail` da dev. Se foi no perfil individual da colaboradora, em qualquer ambiente, o consultor deve revertê-la depois que o permission set for atribuído e testado. Assim o acesso fica num lugar só e o A3 continua verdadeiro. Se foi em produção, quem reverte é o humano (guardrail #1).

## 4. Impacto em permissões

- **Perfis:** nenhum alterado.
- **Permission sets:** 1 novo, atribuído a 1 usuária (e ao usuário de teste em qa). Nenhum usuário ativo existente ganha acesso novo por efeito colateral. Isso atende o A3.
- **Licença:** permission set sem licença vinculada, então não consome nem exige licença. Se a licença da colaboradora não suportar `ExportReport` ou `CreateCustomizeReports` (licenças do tipo Chatter ou Community limitadas), a atribuição será recusada pela plataforma. Nesse caso o problema é de licença, não de permissão, e volta ao humano (achado #9).
- **Pastas:** depende do passo manual 2.

## 5. Automação, ordem de execução e governador

- **Conflito de automação:** não se aplica. A solução não cria nem altera Flow, trigger, validation rule ou qualquer coisa com evento de registro. Permission set não participa da ordem de execução.
- **Governador e CPU:** não se aplica. Não há transação de registro. Nenhum cenário de volume (carga em massa, ou um pai com muitos filhos, achado SOMOSAGILITY-10) passa por esta mudança. Exportar um relatório grande é limitado pela própria plataforma no export, não por esta configuração.

### Riscos do assessment

| Achado | Como este design lida com ele |
|---|---|
| #6 Perfil por pessoa (média) | **Tratado diretamente:** a correção vai em permission set por função, não no perfil. Passo manual 3 remove o ajuste de perfil se ele existir. Não migra os outros 19 perfis: isso é escopo de outra demanda. |
| #9 Licença `Salesforce` em 97% (média) | Permission set sem licença vinculada, nenhuma licença nova consumida. Risco residual na seção 8 (R3). |
| #8 Metadata morta (baixa) | O caso de `Grupo_Opera_es_Relat_rios` (vazio desde 2018) é mais um exemplo. Fica registrado, mas a remoção **não** entra nesta demanda. |
| #1 Oportunidade (alta), #2 Process Builder (alta), #3 cobertura 40% (alta), #4/#5 Apex (média) | Não se aplicam à parte de relatório: sem automação, sem objeto de negócio, sem Apex. Se a pergunta 1 levar "modelo" para um objeto com automação ou para Oportunidade, o #1 volta a valer e o design é revisto. `Modelo__c` não tem trigger nem validation rule (recon). |
| #7 Rollup (baixa) | Não se aplica. |

## 6. "Criar modelo" (A5): bloqueado, sem metadata proposta

A pergunta 1 da análise ("criar um modelo Salesforce — o que exatamente?") **não foi respondida**. Ela não aparece nem no card nem em outro artefato. A análise a marcou como parada de design. A aprovação do gate liberou esta etapa, mas não responde a pergunta. Por isso este design **não propõe metadata, permissão nem atribuição para "modelo"**.

**Hipótese concreta para o consultor confirmar ou descartar** (do `02-recon.md`):

> Na org existe um objeto custom chamado **`Modelo__c`** (label "Modelo"), com Tab. Ele tem Create liberado em 8 perfis/permission sets e só Read nos demais. Está **vazio** (0 registros na dev) e **não tem nenhum campo custom** além de `Name`. Também não tem trigger nem validation rule.
>
> **Pergunta objetiva:** quando a colaboradora diz "criar um modelo", ela está tentando criar um registro na aba **"Modelo"**?
> - **Sim:** ela recebe erro de permissão ao clicar em "Novo", ou o objeto não tem os campos de que ela precisa?
> - **Não:** "modelo" é outra coisa? Por exemplo, um modelo de relatório (Report Type), um modelo de documento ou e-mail (há Conga e SDocs instalados), ou um dashboard.

O que cada resposta faz com o design:
- **"Sim, falta só permissão de Create em `Modelo__c`":** adendo curto a este design para acrescentar `Create`/`Read` em `Modelo__c` a um permission set (provavelmente este mesmo ou um irmão). Custo de mais ou menos 1 h.
- **"Sim, mas faltam campos" (o objeto está vazio de campos):** isso é **mudança de modelo de dados** e, por regra, **decisão de arquitetura sênior**. Volta para análise com escalonamento ao humano. Não decido aqui.
- **"Não, é Report Type, template ou dashboard":** o recon precisa ser refeito para esse tipo de metadata. O retrieve de `ReportType` falhou nesta CLI (`02-recon.md`, seção 4). Depois sai um design próprio.

**Recomendação de fluxo:** a parte de relatório pode ir para build sem esperar o A5, porque não depende dela. Se o arquiteto humano preferir não entregar a demanda pela metade, a alternativa é segurar o gate até a resposta. A decisão é dele.

## 7. O que NÃO será feito nesta demanda

- Nada sobre "criar modelo" (seção 6) até a resposta da pergunta 1.
- Nenhuma alteração de perfil, inclusive o da colaboradora.
- Nenhuma alteração ou remoção de `Full_Access_and_Management_of_Reports` ou `Grupo_Opera_es_Relat_rios` (o vazio fica registrado como candidato à limpeza do achado #8).
- Migração dos outros perfis de um usuário só (achado #6 completo).
- Criação ou reorganização de pastas de relatório, além de compartilhar a pasta que o consultor indicar.
- Qualquer atribuição feita pelo agente a usuário real, em qualquer ambiente. Qualquer coisa em produção.
- Decisão de licença.

## 8. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **O perfil da colaboradora talvez já tenha as permissões** (54 de 77 perfis têm). Nesse caso a causa é pasta (P5), tipo de relatório ou licença, e o permission set não muda nada. | **alta** | Antes do build, o consultor confirma na UI em qa o perfil da colaboradora e a mensagem de erro exata (perguntas 5 e 8 da análise). O teste A1 em qa usa um usuário de teste **com o mesmo perfil dela sem o permission set** primeiro, para reproduzir o erro, e depois com o permission set. Se não reproduzir, a causa é outra e o design volta. |
| R2 | A alteração já feita pela equipe, em local e ambiente desconhecidos, mascara o resultado do teste ou deixa o acesso duplicado (perfil + permission set). | média | Passo manual 3. O consultor informa onde foi (pergunta 3) antes do teste em qa. |
| R3 | A licença da colaboradora não suporta as permissões, e a atribuição é recusada. | média | Aparece na hora da atribuição. Se acontecer, para e escala (achado #9), sem contornar. |
| R4 | Três permissões não bastam para salvar no Report Builder Lightning (`CreateReportInLightning`, premissa P2). | baixa | Acrescentar só essa, registrar em `05-testes.md`. Qualquer coisa além volta ao design. |
| R5 | A demanda fecha a parte de relatório e o "modelo" fica esquecido. | média | O A5 segue explícito como bloqueado no card. `06-entrega.md` deve dizer que a demanda foi entregue parcialmente, se for o caso. |

## 9. Critérios de aceite cobertos

- **A1, A2:** cobertos por `PS_Relatorios_ExtrairSalvar` + compartilhamento da pasta (passo manual 2). O formato de exportação segue a pergunta 2 da análise. O teste usa o formato padrão de exportação do relatório se não houver resposta.
- **A3:** comparar o inventário antes e depois em qa. A única diferença esperada é um permission set novo com 3 permissões de sistema (4, se o R4 acontecer) e as atribuições dele.
- **A4:** permission set por função, sem exceção de perfil.
- **A5:** bloqueado (seção 6).
- **A6:** roteiro de A1–A3 executado em qa pela colaboradora ou pelo consultor com o perfil dela.

## 10. Estimativa

**Estimativa de esforço:** 3–6 h

O que mudou em relação à análise (2–8 h) e por quê:
- **O teto caiu de 8 para 6 h** porque o A5 saiu do escopo desta estimativa. A faixa da análise já previa reavaliar se "modelo" virasse objeto ou Report Type. Agora isso é um adendo ou um design próprio, estimado quando a pergunta 1 for respondida (cerca de 1 h a mais se for só permissão em `Modelo__c`; sem estimativa se for modelo de dados).
- **O piso subiu de 2 para 3 h** porque o recon mostrou que nenhum permission set existente serve como está. Há um permission set novo a construir e validar (cerca de 0,5–1 h). Também há o R1: reproduzir o erro em qa antes e depois exige um usuário de teste com o mesmo perfil e a ida e volta com o consultor (1,5–3 h). Somam-se a regularização da alteração já feita e o compartilhamento de pasta (0,5–1 h) e a documentação (0,5 h).

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
