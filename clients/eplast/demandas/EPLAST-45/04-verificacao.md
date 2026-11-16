**Verificação:** aprovada
**Org de teste:** sbx-eplast-dev

# EPLAST-45 · Verificação do build

Org conferida com `sf org list`: única conectada, `sbx-eplast-dev` (Org Id 00DHa000006vfMLMAY). Todos os comandos com `--target-org`/`-o`.
Dado de teste: 7 leads `TESTE EPLAST-45 L1..L7` (Company `TESTE EPLAST-45`, e-mail `@example.com`, celular sintético), dono = usuário de teste `005bJ00000piKAaQAM`, criados por `fixtures/lead-nutricao.apex` (gravado nesta verificação). Nenhum registro pré-existente lido ou alterado; só metadata, contagens e os registros TESTE. Nenhuma mudança no usuário de execução (sem permission set atribuído, sem Marketing User, sem campo Protheus).
Faixas obtidas (fórmula): L1 Média, L2/L3/L4/L5 Alta, L6 Sem dados suficientes, L7 Média.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | SOQL dos leads TESTE após insert | L1 elegível e não pronto; L2 elegível e pronto; L6 elegível, não pronto; L7 não elegível | L1 true/false; L2 true/true; L6 true/false; L7 false/false | passou |
| T2 | CA-01 | Relatório `NUTRICAO_LEADS_EMAIL` via Analytics API (includeDetails) vs SOQL agregado | Contagem do relatório = SOQL (`Elegivel=true AND HasOptedOutOfEmail=false AND Email!=null`) | Relatório 3 linhas (L1, L2, L4); SOQL COUNT = 3 | passou |
| T3 | CA-02 | Mesmo relatório, L3 com opt-out de e-mail | L3 fora; L4 dentro | L3 ausente; L4 presente | passou |
| T4 | CA-03 | Relatório `NUTRICAO_LEADS_MENSAGEM`, L4 com opt-out mobile | L4 fora; L3 dentro; contagem = SOQL (`Elegivel AND OptOutMobile=false AND MobilePhone!=null`) | 3 linhas (L1, L2, L3), L4 ausente; SOQL COUNT = 3 | passou |
| T5 | CA-04 | List view `Leads_Prontos_Abordagem` (REST listviews/results, Id 00BHa00000ApcNFMAZ) | L2 presente; L1 (Média), L5, L6 ausentes | size 3: L2, L3, L4; L1, L5, L6 ausentes (L3 e L4 são Alta e elegíveis; o opt-out não filtra a list view, coerente com o design) | passou |
| T6 | CA-04 | L1 é faixa Média, L6 Sem dados | Fora da lista de prontos | Ambos `ProntoAbordagem=false` | passou |
| T7 | CA-05 | `Database.convertLead` em L5 (bypass de trigger de Account) | Elegível e pronto = false; fora dos relatórios e da list view | Conversão ok; L5 `IsConverted=true`, elegível false, pronto false; ausente nos relatórios e na list view | passou |
| T8 | CA-06 | Em L2, gravar engajamento (T9) e comparar | OwnerId continua `005bJ00000piKAaQAM` | OwnerId inalterado | passou |
| T9 | CA-07 | Update de L2: `MKT_MC_Engajamento__c='Alto'` e `MKT_MC_EngajamentoData__c=agora` | Valor gravado; Status, PriorityBand e Owner iguais; L2 continua pronto | Engajamento `Alto`; Status `Contatado`, Faixa `Alta`, pronto true | passou |
| T10 | CA-08 | `git show --stat a5b1b970` e grep de emailAlert/emailSimple/Messaging nos arquivos de force-app do commit | Nenhum Flow, Apex ou trigger novo; nenhuma ação de e-mail | Commit só tem 4 campos, 1 list view, 3 permission sets, 2 relatórios; grep sem ocorrência | passou |
| T11 | CA-09 | Insert de 7 leads na dev com o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` ativo | Inserção sem erro; nenhuma automação nova em Lead | 7 inseridos sem erro; sem Flow/trigger novo no commit | passou |
| T12 | CA-10 | `FieldDefinition` dos 4 campos novos; `PermissionSet.Description` dos 3 sets | Descrições preenchidas, com "EPLAST-45" | 4 campos com "EPLAST-45. ..."; 3 sets com descrição citando EPLAST-45. Relatórios e list view: sem campo de descrição consultado | passou |
| T13 | FLS | `FieldPermissions` dos 4 campos | Leitura nos 4 em `PS_Comercial_ScorePrioridade`, `PS_Marketing_Publicos`, `PS_Marketing_RetornoMC`; edição só em engajamento e data e só no RetornoMC | Confere: edição true só em `MKT_MC_Engajamento__c` e `MKT_MC_EngajamentoData__c` no `PS_Marketing_RetornoMC`; demais false (aparece também `sfdc_a360_sfcrm_data_extract`, set gerado pela plataforma, só leitura) | passou |
| T14 | PD-04 | `PermissionSetAssignment` de `PS_Marketing_RetornoMC` | 0 atribuições | 0 | passou |
| T15 | Picklist | Gravação de `Alto` na restrita (T9) | Valor aceito | Aceito. Os demais valores (Sem engajamento, Baixo, Médio) não foram gravados um a um | passou |
| T16 | CA-11 | Sem Apex | não se aplica | não se aplica | não se aplica |
| T17 | CA-12 | Uso de dado sintético, saída só com nomes TESTE e contagens | Sem dado pessoal exposto | Cumprido | passou |

## O que pode ter saído da org
Nada. A solução não tem automação nova nem callout. O Flow de atribuição existente rodou no insert dos leads TESTE; nenhum e-mail, mensagem ou chamada externa. Marketing Cloud não foi tocado. A conversão do L5 criou uma Account `TESTE EPLAST-45` (Contact criado junto, sem oportunidade), com o trigger de Account em bypass (sem consulta externa).

## Limpeza
Leads `TESTE EPLAST-45` e Account de teste apagados (Contact por cascata); contagens finais: Lead 0, Account 0. Nada ficou. Sem job agendado. Usuário de execução não alterado.

## Observações
- Fixture gravada em `clients/eplast/fixtures/lead-nutricao.apex`; ainda não consta no `README.md` de fixtures (que diz "ainda vazio"), ajuste de texto para a esteira.
- Os relatórios são org-wide; na dev só havia os leads TESTE elegíveis (contagem igual ao SOQL), então a igualdade vale para este estado da org.
