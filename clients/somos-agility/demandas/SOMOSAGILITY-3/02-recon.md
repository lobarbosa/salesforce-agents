# Recon da Org — SOMOSAGILITY-3

**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, instância
`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API v67.0, `isSandbox: true`
confirmado via `sf org display`).
**Data da coleta:** 2026-10-07.
**Cobertura:** apenas metadata e contagens agregadas (guardrail #2) — nenhuma consulta trouxe
dado de registro real.

## 1. O "Status" da demanda não é o StageName — são dois campos diferentes

A demanda pede para mudar o "Status" de "Encerrado Win" para "Aberta". `sf sobject describe
--sobject Opportunity` mostra que a org tem **dois campos distintos** que podem ser confundidos
com "status":

| Campo | Label | Tipo | Observação |
|---|---|---|---|
| `StageName` | **Fase** | picklist padrão | Controla `IsClosed`/`IsWon` nativamente. |
| `Status__c` | **Status** | picklist **restrito** (custom) | Independente do StageName. |

Os valores ativos de `Status__c` (restricted picklist — só aceita exatamente um destes):

- `Aberto` (default)
- `Desengajada`
- `Encerrado Loss`
- `Encerrado Win`
- `Encerrado Win - Processada Financeiro`

**Achado importante:** a demanda escreve "Aberta", mas o valor ativo do picklist é **"Aberto"**
(sem o "a" final). Por ser restricted picklist, `Status__c = "Aberta"` seria rejeitado pela
plataforma — o valor exato a usar é `Aberto`.

A existência do valor `Encerrado Win - Processada Financeiro` é um sinal de alerta: sugere que,
quando uma oportunidade fecha ganha, existe (ou existiu) um processamento financeiro/ERP
posterior (a org tem o pacote **SnapERP** instalado, achado do assessment) que consome esse
status. Reabrir `Status__c` para `Aberto` **sem saber se esse processamento já rodou** para o
registro `006U400000YnxGHIAZ` pode destravar o front (vendas vê "aberta" de novo) enquanto o
back-office (financeiro/ERP) já tratou o fechamento — inconsistência que o arquiteto precisa
endereçar, não a recon.

`StageName` (picklist não-restrito) tem 26 valores cadastrados nesta org; os ativos incluem
estágios abertos (`Registro da Oportunidade`, `Engajamento`, `Qualificação`, `Desenvolvimento`,
`Negociação e Proposta`, `Proposta Comercial`, `Fechamento`, `NEC`, `FPR`, `Ação DIA`) e dois
estágios fechados: `Fechado Ganho` (`IsClosed=true`, `IsWon=true`) e `Fechado Perdido`
(`IsClosed=true`, `IsWon=false`). Não existe hoje um `StageName` ativo chamado literalmente
"Encerrado Win" — esse texto é valor de `Status__c`, não de `StageName`. **Conclusão:** não dá
para confirmar, só com isto, se a demanda quer mexer em `Status__c`, em `StageName`, ou nos
dois — ver seção "Pergunta em aberto" abaixo.

## 2. Automação em Opportunity: 31 ativas, já mapeadas no assessment

O assessment (achado #1) já documentou que Oportunidade concentra 31 automações ativas — a
maior concentração de qualquer objeto nesta org. Para esta demanda, a relevante é:

- **`Oportunidade_Encerrada`** (`RecordAfterSave`, Create+Update) — migrada de uma Workflow
  Rule clássica. `Description`: "alerta de oportunidade encerrada, encaminhamento para Sales
  Operation". É notificação, não sincroniza campo — **não bloqueia nem teria que ser desfeita**
  por uma reabertura, mas provavelmente dispara de novo se `StageName` mudar de volta para algo
  não fechado e depois fechar de novo (fora do escopo desta demanda).

Nenhuma das outras 30 automações do objeto tem nome que sugira leitura/escrita de `Status__c`
diretamente (nomes visíveis: alertas, preenchimento de campos "anteriores", atualização de
owner, notificações de prazo). Não foi aberto o XML de cada uma (não há `sfdx-project.json`
neste workspace ainda — retrieve de metadata exige criar o projeto primeiro, fora do escopo
read-only desta etapa); se o design decidir tocar em `StageName` além de `Status__c`, vale
reconsiderar fazer esse retrieve antes do build.

## 3. Validation Rules ativas em Opportunity: 26, três relevantes

`SELECT ... FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Opportunity' AND
Active=true` (Tooling API) devolveu 26 regras ativas (de um total de 387 ativas na org, achado
#8 do assessment). As três com formula lida na íntegra, por tocarem `StageName` em contexto de
encerramento/sequência:

### `M21_Fase_Encerrada` — a mais relevante para este pedido

```
AND(
  $Profile.Name <> "Gerente de renovações",
  $Profile.Name <> "Renovações",
  $Profile.Name <> "Administração",
  ISPICKVAL(PRIORVALUE(StageName), "Encerrada"),
  (ISCHANGED(StageName) || ISCHANGED(CloseDate) || ISCHANGED(Name) || ISCHANGED(Motivo_encerramento__c))
)
```

Mensagem: "Não é possível alterar a oportunidade (Msg21)". Descrição: "Após alterar para a fase
encerrada não será possível editar novamente".

- Dispara só se o **perfil** de quem edita não for Gerente de renovações / Renovações /
  Administração **e** o `StageName` **anterior** (antes da edição atual) era literalmente
  `"Encerrada"` **e** um de `StageName`/`CloseDate`/`Name`/`Motivo_encerramento__c` mudou.
- **Não inclui `Status__c` na lista de campos monitorados.** Uma edição que toque só em
  `Status__c` (sem tocar `StageName`/`CloseDate`/`Name`/`Motivo_encerramento__c`) **não aciona
  esta regra**, mesmo que o estágio anterior fosse "Encerrada".
- O valor literal checado é `"Encerrada"` — que não aparece na lista de `StageName` ativos
  lida na seção 1 (os fechados ativos hoje são `Fechado Ganho`/`Fechado Perdido`). Pode ser
  valor legado de picklist renomeado/inativado que ainda existe em registros antigos, ou a
  regra já estar desatualizada frente ao picklist atual — não confirmado; o arquiteto não deve
  assumir nenhuma das duas sem checar o registro real (fora do alcance desta sandbox, que tem
  zero registros de Opportunity).
- Repara automaticamente por perfil: um usuário com perfil `Administração` já passa por cima
  dela hoje — relevante para decidir "preciso de Flow/correção ou um humano autorizado edita
  direto".

### `M36_Trava_avanco_nao_sequencial`
Bloqueia mudar `StageName` para `"OEG"` quando o valor anterior não era `"CVS/RVS"`, para
perfis fora de Administração/Service Manager/Gerente de renovações/Renovações. Relevante só se
o design decidir mexer em `StageName` (não em `Status__c`).

### `M49_NaoAtualizaOppPsl`
Bloqueia mudar `StageName` quando o valor anterior era `"PSL"` e `CountPsl__c >= 1`. Mesma
ressalva: só relevante se o design tocar `StageName`.

**Nenhuma das 26 validation rules ativas em Opportunity tem `Status__c` no nome ou (nas três
lidas) na fórmula.** Não foi possível, no tempo desta recon, ler a fórmula das outras 23 uma a
uma — se o design final decidir automatizar via Flow algo que grava em `Status__c`, vale
confirmar as 23 restantes antes do build (lista completa abaixo).

<details>
<summary>Lista completa das 26 Validation Rules ativas em Opportunity</summary>

M48_PreencheOrcamentista, M49_NaoAtualizaOppPsl, M31_Qualificacao_de_fase_PFC_para_NEC,
M30_Qualificacao_de_fase_NEC_para_FPR, M02_Alterar_fase_OEG,
M07_Coment_sobre_a_visao_estabeleci_CVS, M09_Confirmada_Efetivid_pelo_Cliente_CVS,
M11_Contat_do_cliente_que_confir_efe_CVS, M12_Cont_do_cliente_que_confirm_orc_CVS,
M39_Descreva_condi_especiais_forneci_OEG, M17_Descreva_mapeam_esta_valido_OEG,
M18_Descreva_necess_envolver_compras_OEG, M19_Descrev_proce_compras_OEG,
M20_Descreva_processo_decisao_OEG, M21_Fase_Encerrada, M40_Ha_Budget_disponivel_CVS,
M22_Ha_Budget_disponivel_OEG, M25_Oportunidade_criada_somente_em_OQF,
M35_Somente_pode_existir_um_SOW_atual, M36_Trava_avanco_nao_sequencial,
M41_Qualificacao_de_fase_NEC_para_FPR, M38_Valida_Numero_DSA,
Atualizar_Estagio_se_Cerimonia_Realizada, Atualizar_Estagio_se_Blueprint_Aprovado,
Atualizar_Estagio_se_PSL_Aprovada, Alteracao_do_Owner_se_Renovacoes

</details>

## 4. Record Types em Opportunity

12 Record Types, 10 ativos: `FPR`, `Encerramento_PSL_e_PFC`, `CVS`, `Encerrada`, `NEC`, `OQF`,
`PSL`, `PFC`, `Parceiros`, `Acao_DIA` (ativos); `Encerramento_NEC` e `OEG` inativos. Existe um
Record Type chamado **`Encerrada`**, ativo — se a oportunidade em produção estiver atribuída a
esse Record Type, reabrir o `Status__c`/`StageName` sem revisitar o Record Type pode deixar o
registro com layout/picklists de um RT de "encerrada" enquanto o status diz "aberta". Não
confirmável por esta recon (zero registros nesta sandbox); o arquiteto deve tratar como
pergunta aberta para quem aprovar o design, não como premissa.

## 5. O registro citado na demanda não existe nesta sandbox

`SELECT COUNT() FROM Opportunity` nesta org retornou **0** — a sandbox de dev está sem massa de
dados (mesmo achado do assessment, seção "Modelo de dados"). O link da demanda
(`agilitynetworks.lightning.force.com`, sem o sufixo `--sbxdev` da URL de sandbox) e o Id
`006U400000YnxGHIAZ` são de outra org — consistente com a suspeita já registrada em
`01-analise.md` de que é a **produção** do cliente. Esta recon não tentou (e não teria como)
confirmar o registro em si: seria produção, fora do alcance do agente (guardrail #1), e ainda
que fosse esta sandbox, consultar o registro traria risco de dado real (guardrail #2). Com
`COUNT()=0`, nem haveria o que consultar aqui.

## Perguntas em aberto para o design (arquiteto)

1. **Qual campo a demanda quer mudar de fato — `Status__c`, `StageName`, ou os dois?** O texto
   da demanda ("Status" "Encerrado Win" → "Aberta") bate em vocabulário com `Status__c`
   (`Encerrado Win` → `Aberto`, não `Aberta`), não com `StageName`. Se for só `Status__c`,
   nenhuma das validation rules lidas bloqueia a escrita. Se também envolver `StageName`, as
   três regras acima (especialmente `M21_Fase_Encerrada`) entram em jogo dependendo do valor
   anterior real do registro (não visível nesta sandbox).
2. **O processamento financeiro/ERP já rodou para este registro?** A existência do valor
   `Encerrado Win - Processada Financeiro` sugere um estado pós-financeiro que `Aberto` não
   reflete — reabrir sem checar isso pode gerar inconsistência entre Salesforce e o sistema
   financeiro/ERP integrado (SnapERP, achado do assessment).
3. **O Record Type do registro é `Encerrada`?** Se for, reabrir sem revisar o RT pode deixar
   layout/picklists inconsistentes com o novo status.
4. **Quem vai aplicar a mudança e com qual perfil?** `M21_Fase_Encerrada` já não bloqueia
   perfis `Administração`/`Gerente de renovações`/`Renovações` — pode ser mais simples (e mais
   seguro, dado o volume de automação no objeto) um humano autorizado editar o registro direto
   em produção do que construir uma automação nova num objeto que já tem 31 automações ativas
   e 26 validation rules ativas.

## Não pôde ser medido

- Fórmula das outras 23 Validation Rules ativas em Opportunity (além das 3 lidas) — tempo de
  recon, listadas na seção 3 para quem precisar.
- Conteúdo XML das 31 automações ativas de Opportunity (se alguma lê/escreve `Status__c`) —
  exigiria `sf project retrieve`, que por sua vez exige criar `sfdx-project.json` neste
  workspace (ainda não existe); não foi feito por ser read-only além do escopo rápido desta
  etapa. Se o design envolver automação nova, vale fazer esse retrieve antes do build.
- Qualquer dado do registro real `006U400000YnxGHIAZ` — está em produção (fora do alcance do
  agente) e, mesmo que estivesse aqui, seria dado de cliente (guardrail #2). A sandbox de dev
  está com `COUNT()=0` em Opportunity, então nem um registro equivalente existe para inspecionar.
