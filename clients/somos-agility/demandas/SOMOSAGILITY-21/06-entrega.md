# 06 — Entrega — SOMOSAGILITY-21: Campo origem do Lead

Cliente: somos-agility
Demanda: SOMOSAGILITY-21 — "Campo origem do Lead"
Tipo: sustentação (design enxuto)
Branch: `feature/SOMOSAGILITY-21`
Consultor: Juliana Mendes
Demandante (cliente): Guilherme — Departamento Marketing
Chamado interno Agility: `20250918-032`

---

## 1. Resumo para o cliente

**Situação:** leads que chegam ao Salesforce a partir do site institucional da Agility não
saem com a origem "Web Site Agility" preenchida no campo "Origem do lead".

**O que foi feito nesta demanda:** diagnóstico completo, feito sobre a sandbox de dev e os
metadados da org. A causa provável foi identificada e a correção foi desenhada. Nenhuma
alteração foi feita no Salesforce.

**Por que nada foi alterado no Salesforce:** a correção principal está na integração que
envia os leads do site. Essa integração não passa pelo Web-to-Lead, nem por Flow ou Apex do
Salesforce. Ela grava o lead direto pela API REST, autenticando pelo aplicativo conectado
"Lead Site Agility". O ajuste precisa ser feito por quem administra essa integração (TI
Agility, no middleware). Não há o que o Salesforce faça sozinho para corrigir isso com
segurança, sem risco para os outros canais de entrada de leads.

**O que o cliente precisa fazer para a demanda fechar:**

1. Ajustar o middleware do site para enviar o campo de origem com o valor
   **`Web Site Agility Networks`** (nome interno; aparece na tela como "Web Site Agility").
2. Confirmar com Marketing que esse é o valor desejado (ver pergunta P-1, seção 7).
3. Informar quem faz o ajuste e em que prazo (pergunta P-4, seção 7).

**Estado de CA-01 (lead do site com a origem correta): não resolvido em produção.** A
demanda só fecha de fato quando o ajuste do middleware estiver em produção e um lead real
comprovar o resultado. Esta esteira não consegue validar isso de ponta a ponta.

**Efeitos que o cliente deve conhecer antes do ajuste entrar em produção:**

- Relatórios de Marketing vão mostrar uma quebra na série histórica a partir da data do
  ajuste. Leads antigos continuam com o valor anterior (pergunta P-5).
- Oportunidades convertidas a partir desses leads passam a acionar o Flow
  `Atualizar_Descri_o_com_Informa_es_do_Lead`, que preenche a descrição da oportunidade.
  Esse Flow já existe e espera exatamente esse valor. Hoje ele quase nunca dispara para
  esses leads, porque o valor não chega.

---

## 2. Status dos critérios de aceite

| CA | Descrição resumida | Status ao fim desta demanda |
|---|---|---|
| CA-01 | Lead do site recebe a origem "Web Site Agility" | **Não resolvido em produção.** Depende do ajuste externo no middleware (P-4). Não testado de ponta a ponta. |
| CA-02 | Outros canais não mudam | **Garantido por construção**: nenhuma regra do Salesforce foi alterada. Não testável nesta rodada. |
| CA-03 | O valor do site sobrepõe o default | **Comprovado na sandbox de dev** (casos 1 e 2 do teste): valor explícito vence o default. |
| CA-04 | Teste em QA com payload simulado | **Não executado formalmente.** A sandbox `sbx-somos-agility-qa` não está conectada à esteira. Foi feita uma demonstração equivalente na sandbox de dev (ver seção 5). |

---

## 3. Componentes técnicos

### 3.1 Criados ou alterados no Salesforce

**Nenhum.** Nenhum metadado foi criado, alterado ou removido em `force-app`. Nenhum
`sf project deploy` foi executado. Nenhum `package.xml` foi gerado. Nenhum comando `sf` de
escrita foi executado contra a sandbox de QA, que não está conectada. Na sandbox de dev,
houve apenas criação e exclusão de três leads de teste fictícios (seção 5).

Motivo: a correção principal (Opção A) é externa ao Salesforce.

### 3.2 Componentes externos (fora desta esteira)

| Componente | Responsável | Alteração necessária |
|---|---|---|
| Middleware do site Agility que autentica pelo Connected App `Lead_Site_Agility` (label "Lead Site Agility") | TI Agility (P-4) | Enviar `LeadSource = "Web Site Agility Networks"` (API name) no `POST /services/data/vNN.0/sobjects/Lead`. |

### 3.3 Componentes propostos e não construídos (Opção F)

A Opção F é uma rede de segurança declarativa. Ela só será construída se a pergunta P-2 for
confirmada no gate de design. **Hoje ela não existe na org.** Os nomes abaixo são propostos,
não criados:

| Tipo | API name proposto | Função prevista |
|---|---|---|
| Custom Permission | `Lead_Origem_Site_Agility` | Marca o usuário de integração exclusivo do site Agility. |
| Permission Set | `PS_Integracao_LeadSiteAgility` | Concede apenas a Custom Permission acima. Atribuição manual por admin. |
| Flow (record-triggered, before-save, create, `Lead`) | `Lead_BeforeSave_OrigemSiteAgility` | Se o lead veio do usuário marcado com `$Permission` e `LeadSource` está vazio, com o default `Prospecção - Gerente de Contas` ou com o texto solto `Web Site Agility`, grava `Web Site Agility Networks`. Não faz SOQL nem DML. |

### 3.4 Objetos e metadados de referência (não alterados)

- Campo `Lead.LeadSource` (Origem do lead): picklist **não restrito**, `nillable = true`,
  default de org `Prospecção - Gerente de Contas`. Vem do Standard Value Set `LeadSource`.
- Valor `Web Site Agility Networks` (label "Web Site Agility"). É o valor-alvo.
- Valor `Web Site Agility – E-mail` (label "Web Site Agility – E-mail"). **Não** é o valor-alvo.
- Connected App `Lead_Site_Agility`: `isAdminApproved = false` ("All users may self-authorize").
  Perfis associados: Administração, Marketing, Administração para Alta Gestão (idênticos aos do
  Connected App `Lead_Site_Eagle`).
- Validation rule `Lead_Novo`: exige `Status = "Novo"` em qualquer insert de Lead.
- Flow `Atualizar_Descri_o_com_Informa_es_do_Lead`: before-save em `Opportunity` (create),
  filtra por `LeadSource = 'Web Site Agility Networks'`. Copia `Descricao_do_Lead__c` para
  `Opportunity.Description`.

---

## 4. Como funciona

### 4.1 Mecanismo do campo `LeadSource`

1. **Picklist não restrito.** A API aceita qualquer texto em `LeadSource`, mesmo fora da
   lista de valores ativos. Um valor fora da lista é gravado como texto solto, sem erro.
2. **Default de org.** O Standard Value Set `LeadSource` tem o default `Prospecção - Gerente
   de Contas`. Quando uma inserção (via UI ou via API) não envia `LeadSource`, o Salesforce
   preenche com esse default. O campo **não fica vazio**.
3. **Valor explícito vence o default.** Quando a inserção envia um valor, o default não é
   aplicado.
4. **Record types.** Os quatro record types de Lead (`Lead_Interno`, `Lead_Marketing`,
   `Lead_Partner`, `Requisi_o_de_Conta`) têm o mesmo default e incluem `Web Site Agility
   Networks` como opção. Não há separação de canal por record type.
5. **Uso do mesmo value set.** `LeadSource` também existe em `Opportunity` e `Contact`,
   herdando o mesmo value set. Mudar o value set afeta os três objetos.

### 4.2 O que acontece conforme o payload do site (sandbox de dev, 2026-10-28)

| Payload do site | `LeadSource` gravado | Consequência |
|---|---|---|
| Envia `Web Site Agility Networks` (API name) | `Web Site Agility Networks` | Correto. |
| Não envia `LeadSource` | `Prospecção - Gerente de Contas` (default) | Origem errada. Causa mais provável do relato (H1). |
| Envia `Web Site Agility` (label) | `Web Site Agility` como texto solto | Parece correto na tela, mas não agrupa com o valor oficial em relatório e não aciona o Flow de Opportunity (H2). |
| Envia outro valor | Esse valor | Origem errada (H3). |

**Qual dos casos acontece hoje em produção: não confirmado.** A sandbox de dev tem zero leads,
e produção está fora do alcance desta esteira. A evidência que separa H1, H2 e H3 é o valor
de `LeadSource` de um lead real do site, em produção (pergunta P-3).

### 4.3 Fluxo da correção

1. O lead do site chega via REST API, autenticado pelo Connected App `Lead_Site_Agility`.
2. O middleware monta o payload. Hoje não envia o API name correto (ou não envia o campo).
3. **Correção (fora do Salesforce):** o middleware passa a enviar
   `LeadSource = "Web Site Agility Networks"`.
4. O Salesforce grava o valor enviado. Nenhuma regra do Salesforce interfere.
5. Ao converter o lead, o Salesforce copia `LeadSource` para a oportunidade. O Flow
   `Atualizar_Descri_o_com_Informa_es_do_Lead` então dispara e preenche a descrição.

Se a Opção F for construída no futuro, entra um passo a mais entre 2 e 4: o Flow
`Lead_BeforeSave_OrigemSiteAgility` corrige `LeadSource` somente quando o usuário que gravou
o lead tem a Custom Permission, o evento é create e o valor é default, vazio ou o texto solto.

---

## 5. Verificação executada

Feita em `sbx-somos-agility-dev` em 2026-10-28, com três leads fictícios criados e apagados
(`LastName` prefixado `QA-SOMOSAGILITY-21 CasoN`, `Company = 'QA Teste SOMOSAGILITY-21'`,
`Status = 'Novo'`). Nenhuma consulta retornou dado de lead real.

| Caso | Payload | Resultado | Situação |
|---|---|---|---|
| 1 | `LeadSource = 'Web Site Agility Networks'` | `Web Site Agility Networks` | Passou |
| 2 | Sem `LeadSource` | `Prospecção - Gerente de Contas` | Passou (comprova H1) |
| 3 | `LeadSource = 'Web Site Agility'` (label) | `Web Site Agility`, texto solto | Passou (comprova H2) |

**Limitação:** esta é uma demonstração de comportamento da plataforma, feita em dev. Não é o
teste formal de CA-04, que deve rodar em `sbx-somos-agility-qa`. Esse teste ainda não pôde
ser executado (seção 8, item 4).

---

## 6. Release (conteúdo registrado pelo agente `release`)

### 6.1 Pré-requisito

`gates.md` registra a aprovação do gate `aguardando_homologacao` por Juliana Mendes em
2026-10-28T23:19:45Z, sobre `05-testes.md` (sha256 `a4292c7ac9b060aa`). O pré-requisito está
satisfeito.

Observação: essa homologação foi registrada sobre o teste de demonstração feito em dev
(seção 5). O teste formal em QA não foi executado, porque a sandbox de QA não está conectada.

### 6.2 Verificação de ambiente

Via `sf org list`, em 2026-10-28:

- `sbx-somos-agility-dev`: conectada.
- `sbx-somos-agility-qa`: não conectada.

### 6.3 Componentes implantados

**Nenhum.** Esta demanda não criou nem alterou metadado em `force-app`. O `release` releu
`03-design.md` e `04-plano-build.md` e verificou que nenhum commit desta branch toca
`force-app`. Nenhum `package.xml` foi gerado e nenhum `sf project deploy` (dry-run ou real)
foi executado, porque não havia conteúdo a validar.

### 6.4 Plano de rollback

**Não aplicável.** Nada foi implantado em nenhuma sandbox.

Se a Opção F for construída e implantada no futuro, o rollback será: desativar ou excluir o
Flow `Lead_BeforeSave_OrigemSiteAgility`, remover o Permission Set
`PS_Integracao_LeadSiteAgility` e remover a Custom Permission `Lead_Origem_Site_Agility`.
Esse procedimento deve ser detalhado na entrega daquela rodada.

---

## 7. Configuração pós-deploy e pendências

### 7.1 Configuração pós-deploy no Salesforce

**Nenhuma.** Nada foi implantado.

### 7.2 Ações fora do Salesforce (necessárias para CA-01)

- **Ajuste do payload do middleware** (dono: TI Agility, P-4). Enviar `LeadSource = "Web Site
  Agility Networks"` (API name). Sem prazo registrado até esta data.

### 7.3 Ações condicionadas (só se a Opção F for aprovada)

- Atribuir `PS_Integracao_LeadSiteAgility` **manualmente** ao usuário de integração exclusivo,
  em cada org (QA na esteira; produção por quem faz o deploy humano). Sem essa atribuição, o
  Flow fica inerte, o que é intencional (falha segura).

### 7.4 Perguntas em aberto (de `03-design.md`, seção 8)

- **P-1 (Marketing / Guilherme):** confirmar que o valor-alvo é "Web Site Agility"
  (`Web Site Agility Networks`), e não "Web Site Agility – E-mail". O recon indica que o texto
  da demanda bate com o label de `Web Site Agility Networks`, mas a confirmação de negócio não
  está registrada em `comentarios-do-card.md`.
- **P-2 (TI Agility) — bloqueia a Opção F:** o usuário de integração do middleware é exclusivo
  do site Agility, sem gravar leads de nenhum outro canal (inclusive o site Eagle)? Se sim:
  qual usuário, e ele existe na sandbox de QA? **Não respondida.**
- **P-3 (evidência de causa-raiz em produção):** valor de `LeadSource` de um lead afetado, ou
  agregado `GROUP BY LeadSource`, feito por quem tem acesso a produção. **Não respondida.**
- **P-4 (dono e prazo da correção externa):** quem altera o middleware e em que prazo.
  **Não respondida.**
- **P-5 (D-4, histórico):** Marketing aceita a quebra na série histórica sem corrigir os leads
  antigos? **Não respondida.**

---

## 8. Limitações conhecidas e dívida técnica

1. **CA-01 não está resolvido em produção.** A correção depende de ação externa da TI Agility
   no middleware. Esta esteira não altera nem valida esse ajuste.
2. **Causa-raiz não confirmada em produção.** H1, H2 e H3 foram separados apenas na sandbox de
   dev, sem dado real. Qual deles acontece hoje depende da pergunta P-3.
3. **Opção F pendente de confirmação (P-2).** Não será construída enquanto P-2 não for
   respondida no gate de design. Mesmo com a resposta, a construção exige um novo ciclo de
   build. Um comentário ambíguo não autoriza a construção.
4. **CA-04 não executado formalmente.** A sandbox `sbx-somos-agility-qa` não está conectada à
   esteira. O roteiro para quando ela conectar está em `05-testes.md`, seção "Roteiro para
   quando `sbx-somos-agility-qa` conectar". Deve ser executado antes de qualquer deploy futuro
   desta demanda. A versão da API no roteiro está como `v68.0`, e o design usa `vNN`. Confirmar
   a versão no momento da execução.
5. **Validação do middleware real ausente.** Não há como confirmar, nesta esteira, que o
   middleware enviará o valor certo depois do ajuste.
6. **Quebra na série histórica (D-4 / P-5).** Relatórios de Marketing vão mostrar leads do
   site em outro bucket a partir da data do ajuste. Leads antigos não são corrigidos.
7. **Efeito colateral no Flow de Opportunity (R-4).** Ao corrigir o valor, o Flow
   `Atualizar_Descri_o_com_Informa_es_do_Lead` passa a disparar em oportunidades convertidas
   desses leads. É o comportamento que o Flow foi escrito para ter, mas é mudança visível.
8. **Default global de `LeadSource` é fonte de risco.** O default `Prospecção - Gerente de
   Contas` vale para toda a org. Qualquer integração que omita o campo recebe esse valor. A
   correção desenhada não muda o default, para não afetar outros canais (decisão B do design).
   A origem do problema continua existindo para outras integrações.
9. **Connected App com política "All users may self-authorize".** Qualquer usuário com os
   perfis associados pode autenticar pelo `Lead_Site_Agility`. Isso impede o Salesforce de
   distinguir a origem pelo usuário. Revisar a política é recomendação para o cliente. Não foi
   feito nesta demanda.
10. **Connected App `Lead_Site_Eagle` com o mesmo perfil.** Não investigado a fundo. Pode ser
    usado pelo mesmo usuário de integração. Relevante para P-2.
11. **Usuário de integração não identificado.** Na sandbox de dev não há usuário com os perfis
    de integração. Não foi confirmado qual usuário autentica pelo `Lead_Site_Agility` em
    produção.
12. **Picklist não restrito.** Qualquer texto é aceito em `LeadSource`. Valores errados não
    são barrados pelo Salesforce. Se a origem mudar, é preciso revisar integrações e relatórios.
13. **Inconsistências entre artefatos, sem efeito na entrega:**
    - `02-recon.md` marca D-1 como resolvida. `03-design.md` mantém P-1 aberta, pedindo
      confirmação de Marketing. As duas afirmações coexistem: a evidência técnica está
      resolvida, a decisão de negócio não.
    - `comentarios-do-card.md` identifica a homologação de 2026-10-28 22:53 como "Cliente",
      enquanto `gates.md` registra Juliana Mendes (consultor) como aprovadora. Confirmar quem
      aprovou.
    - A aprovação do gate de design (`gates.md`, 2026-10-27) cobriu o documento inteiro, incluindo
      a Opção F condicionada. Não é uma confirmação explícita da P-2.
    - A estimativa aprovada no card é de 5 h (comentário de 2026-10-27). A faixa do design é 3–7 h.

---

## 9. Rastreabilidade

| Item | Valor |
|---|---|
| ID da demanda | SOMOSAGILITY-21 |
| Título | Campo origem do Lead |
| Cliente | somos-agility |
| Branch | `feature/SOMOSAGILITY-21` |
| Pull request | Não registrado nos artefatos desta demanda. |
| Deploy ID | Não há. Nenhum deploy foi executado. |
| Commits de etapa citados em gates | `8ec3830b` (design), `b986a359` (build), `c180628b` (qa, org qa), `7d3dd948` (qa via CI, dev) |
| Sandbox de dev | `sbx-somos-agility-dev` (`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`, API 68.0) |
| Sandbox de QA | `sbx-somos-agility-qa`: não conectada à esteira em 2026-10-28. |

### 9.1 Histórico de gates (de `gates.md`)

| Gate | Aprovado por | Quando (UTC) | Commit | Artefatos e sha256 |
|---|---|---|---|---|
| aguardando_gate_analise | Leonardo Barbosa | 2026-10-21 02:30 | `6d24ce20` | `01-analise.md` (`f1d45084dd4af433`) |
| aguardando_gate_design | Leonardo Barbosa | 2026-10-27 23:56 | `8ec3830b` | `02-recon.md` (`26a3cb768f64f0e0`), `03-design.md` (`1b542e2c1f520a3b`) |
| aguardando_gate_build | Leonardo Barbosa | 2026-10-28 01:33 | `b986a359` | `04-plano-build.md` (`64eccd634b9a144b`) |
| aguardando_homologacao | Juliana Mendes | 2026-10-28 23:19 | `7d3dd948` | `05-testes.md` (`a4292c7ac9b060aa`) |

Para conferir se os artefatos ainda são os aprovados:
`sfagents demanda conferir-gates --client somos-agility SOMOSAGILITY-21`.

### 9.2 Como retomar esta demanda

- **Se P-2 for confirmada:** voltar ao gate de design para registrar a decisão. Só depois abrir
  uma etapa de build para a Opção F (seção 3.3), com QA dos casos iv e v (`05-testes.md`).
- **Se CA-01 precisar ser comprovado em produção:** P-3 e P-4 precisam ser resolvidas. A
  evidência do lead real (print do campo, sem dado pessoal) fecha H1 versus H2/H3.
- **Antes de qualquer deploy futuro:** conectar `sbx-somos-agility-qa` e executar o roteiro de
  CA-04 (`05-testes.md`).
