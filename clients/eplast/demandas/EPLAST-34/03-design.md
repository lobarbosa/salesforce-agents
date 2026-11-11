# EPLAST-34 — Design: resumos automáticos para reuniões comerciais, GDD, S&OP e Board

**Cliente:** Eplast · **Tipo:** projeto · **Onda 3 (Comercial), não contratada** (`contrato.md`)
**Org do recon:** `sbx-eplast-dev` (sandbox confirmada, `02-recon.md`, coleta de 2026-11-11)
**Entradas:** `demanda.md`, `01-analise.md` (aprovada no gate `aguardando_gate_analise` em 2026-11-11, ver `gates.md`), `comentarios-do-card.md`, `assessment.md` (2026-09-30), `02-recon.md`, RAG do cliente.

**Status deste design: condicional. Não libera build.**

A análise foi aprovada no gate, e isso não está em discussão. A própria análise, porém, marca sete perguntas como bloqueantes (1, 2, 4, 5, 6, 7 e 10) e recomenda não acionar o arquiteto antes delas. `comentarios-do-card.md` registra só a aprovação do gate, sem resposta a nenhuma das sete. Elas decidem o nível da solução (configuração, Flow com IA ou Apex), se há escrita em Account, Opportunity ou Order, e se dado de cliente sai para um provedor de modelo. São decisões de negócio, de contrato e de LGPD. Não cabe ao arquiteto agente tomá-las.

Este documento entrega:
1. o que o recon acrescentou a cada pergunta bloqueante (seção 0);
2. as decisões que valem para qualquer resposta (seção 1);
3. as três arquiteturas possíveis, cada uma com a condição que a escolhe (seção 2);
4. riscos, permissões, governador e o que fica fora (seções 3 a 8).

Há precedente nesta conta para esse formato: os designs de EPLAST-27 e EPLAST-31 foram entregues condicionais pelo mesmo motivo [RAG: demandas/EPLAST-27/03-design.md; demandas/EPLAST-31/03-design.md]. E há um caso que mostra o custo de não fazer assim. Na EPLAST-23, a arquitetura foi aprovada sem as regras de negócio e o resultado foi `CustomerSummaryService`, que está na org como scaffold que só lança erro (`02-recon.md` §4.3).

---

## 0. Perguntas bloqueantes: o que segue em aberto e o que o recon acrescentou

| # | Pergunta (01-analise §5) | Situação | O que o recon acrescentou | Quem responde |
|---|---|---|---|---|
| 1 | Onda 3 contratada? (aditivo, backlog ou descarte) | **Sem resposta** | Nada técnico. `contrato.md` continua com Ondas 1–2 (120 h, fim em 2026-11-30) | Gestor de conta |
| 2 | Sobreposição com `eplast-ent-10` / `eplast-ent-08` | **Sem resposta** | **Agrava.** O subagente `insights_comerciais` do `SFAgent2_v4` já monta um "resumo de cliente" com seções fixas, oportunidades paradas, pedidos pendentes e comparação de períodos (`02-recon.md` §4.2). Um "resumo para reunião comercial" por cliente já existe, ao menos em rascunho, no território do entregável contratado | Gestor de conta + consultor |
| 4 | Texto gerado por IA, agregação determinística ou combinação? | **Sem resposta** | A org suporta as duas. Prompt Templates e Agentforce estão habilitados (`enableEinsteinGptPlatform = true`, licenças ativas). Há 374 relatórios, 19 painéis e forecast `Opportunity_Amount` ativo | Cliente (negócio) |
| 5 | Formato e canal; grava em Account/Opportunity/Order? | **Sem resposta** | **Gravar em Account reenvia a conta ao Protheus.** `AccountTriggerHelper` enfileira `SendAccountToProtheus` em todo update sem mudança de CNPJ, sem filtro de campo (`02-recon.md` §3.3). Gravar em Task dispara `TaskCreatedOrUpdated` | Cliente; a parte técnica está fechada em D1 |
| 6 | Público e conteúdo de cada um dos 4 tipos | **Sem resposta** | OWD: Account é público leitura/gravação, Opportunity é público leitura (`02-recon.md` §2). Para usuário interno, o recorte por público vem de filtro do resumo e de FLS, não de compartilhamento | Cliente (negócio) |
| 7 | Fontes e métricas (meta, carteira, faturamento, GDD, S&OP) | **Sem resposta** | **Não há objeto de meta na org de dev** (`02-recon.md` §6). Há relatórios de carteira na pasta `ANALISTAS` e painéis `Leads & Oportunidades` e `Pedidos` na pasta `Eplast`. Nada tem S&OP, GDD ou Board no nome. 153 de 223 campos sem descrição | Cliente (negócio) |
| 10 | LGPD e envio a terceiros, se houver IA | **Sem resposta** | Os provedores externos de modelo **não estão desligados** em `EinsteinGptSettings` (OpenAI, Azure OpenAI, Bedrock e Vertex com `disable… = false`). Se a resposta da pergunta 4 incluir IA, o conteúdo pode ser processado fora da Salesforce, através da camada dela | Cliente (jurídico/DPO) |

Perguntas não bloqueantes (3, 8, 9, 11 a 16) seguem em aberto e entram no próximo ciclo do design. A 16 (separação dev/qa, achado 6) **vira bloqueante para o build**, porque o recon confirmou de novo que o alias de dev aponta para a instância com "qa" no nome e que `sbx-eplast-qa` não está autenticada.

---

## 1. Decisões que valem para qualquer resposta

Estas restrições não dependem das sete perguntas. São técnicas, sustentadas pelo recon, e qualquer opção da seção 2 precisa respeitá-las.

**D1. Somente leitura em Account, Opportunity, Order, OrderItem e Contact.** O resumo é calculado e entregue sem DML nesses objetos: nenhum campo novo de "último resumo", nenhum update de carimbo de data.
- Motivo 1: todo update de Account enfileira `SendAccountToProtheus` (`02-recon.md` §3.3). Gravar um resumo em Account reenviaria a conta ao ERP. Em lote, estouraria o limite de 50 `enqueueJob` por transação.
- Motivo 2: os três objetos têm trigger custom, trigger do CPQ e Flows after-save no mesmo evento, sem ordem garantida (achado 1, reconfirmado em `02-recon.md` §3.1–3.2).
- Mesma decisão da EPLAST-27 (D1), pelo mesmo motivo [RAG: demandas/EPLAST-27/03-design.md].
- Se o cliente responder à pergunta 5 que quer o resumo "no registro", a leitura em tela (componente ou agente na página) atende sem gravar. **Se a resposta for "precisa ficar gravado", o design volta ao gate.** Esse caso exige mapear a ordem de execução e, provavelmente, um objeto novo (D2).

**D2. Nenhuma mudança de modelo de dados sem escalar.** Se alguma resposta levar a guardar resumos (histórico de resumos, objeto `Resumo` com versão por reunião), isso é mudança de modelo de dados: **decisão de arquitetura sênior, escalada ao humano**, não tomada aqui. O mesmo vale para criar uma fonte de "meta", que hoje não existe na org (pergunta 7).

**D3. Número não é gerado por modelo de linguagem.** Em qualquer opção com IA (B ou C abaixo), totais, contagens, somas e variações são calculados de forma determinística (relatório, consulta agregada ou Apex), antes do modelo. O modelo só redige texto em torno de números que recebe prontos e cita a fonte de cada um. Isso torna testável o critério de aceite "números conferem com o relatório de referência" (bloco B da análise). Em Board e S&OP, número errado é o risco mais caro.

**D4. Execução no contexto de quem pede.** Toda consulta respeita permissão de objeto e FLS do usuário: `WITH USER_MODE` em Apex, Flow rodando no contexto do usuário, relatório sem "executar como" outro usuário. Para painéis, isso implica **não usar painel com usuário em execução fixo com privilégio maior** para públicos que não deveriam ver o consolidado. Com OWD público em Account e Opportunity, a proteção relevante é FLS mais o recorte definido na pergunta 6.

**D5. Uma fonte de verdade para resumo de cliente.** Esta demanda não cria um segundo resumo por cliente paralelo ao `insights_comerciais` / `eplast-ent-10`. Se o resumo de reunião comercial for por cliente, ele reutiliza ou estende esse território, conforme a resposta da pergunta 2. Dois resumos com regras diferentes para o mesmo cliente é o que a análise da EPLAST-33 já apontou como fonte de número divergente em reunião [RAG: demandas/EPLAST-33/01-analise.md].

**D6. Contato não entra no conteúdo até a pergunta 10 ser respondida.** Nome, e-mail e telefone de Contact ficam fora de qualquer resumo e de qualquer prompt. É a mesma lacuna (D6) que travou `CustomerSummaryService` na EPLAST-23.

**D7. Nada de Task, Chatter ou e-mail gerado por automação nesta versão sem decisão explícita.** Criar Task dispara `TaskCreatedOrUpdated` (`02-recon.md` §3.2), e e-mail com conteúdo de cliente é envio a terceiro. O canal entra pela pergunta 5. Se a resposta for e-mail, o meio preferido é a assinatura nativa de relatório ou painel (opção A), que não grava em objeto de negócio.

**D8. Validação só com dado sintético em `sbx-eplast-dev`**, criado pelo roteiro de QA e identificado como sintético. A sandbox está vazia (0 registros em todos os objetos-fonte). Atenção: o dado sintético vai disparar CPQ, triggers, Flows e possivelmente `SendAccountToProtheus` na criação (`02-recon.md` §3). O plano de build precisa dizer como a carga sintética lida com isso, por exemplo verificando o endpoint do Protheus na sandbox. Não é afirmação: não confirmei para onde a integração aponta em dev.

---

## 2. Estrutura de decisão: três arquiteturas, cada uma com a resposta que a escolhe

Ordem de preferência da plataforma (skill `salesforce-doutrina`): configuração, depois Flow, depois código. Cada opção só desce de nível se a resposta das perguntas exigir.

### Opção A — Configuração: relatórios + painéis + assinatura (sem IA)

**Escolhida se:** pergunta 4 = "agregação determinística"; pergunta 5 = tela no Lightning e/ou e-mail periódico.

- Um painel por tipo de reunião (até 4), em pasta própria com compartilhamento por público (pergunta 6), sobre relatórios novos ou sobre os existentes de carteira e pedidos, se a pergunta 7 os indicar como fonte.
- Entrega periódica pela **assinatura nativa** de painel ou relatório. Não há automação, Flow nem Apex.
- O forecast `Opportunity_Amount`, já ativo, pode atender a parte de previsão de S&OP e Board, se a pergunta 7 confirmar.
- Componentes: relatórios, painéis e pastas. Nomes definidos no plano de build, depois da pergunta 6. Nenhum campo, objeto ou classe.
- **Atende D1–D8 por construção.** Zero toque em automação. Zero Apex, e o achado 2 não se aplica.
- Limite: não gera texto narrativo. Se o cliente quiser "resumo" no sentido de prosa, esta opção não basta.

### Opção B — Declarativo com IA: prompt template com grounding por Flow (texto gerado, números determinísticos)

**Escolhida se:** pergunta 4 = "texto por IA" ou "combinação"; pergunta 10 autoriza o processamento pelo provedor; pergunta 5 = sob demanda, na tela ou no assistente.

- Prompt template (tipo Flex) por tipo de reunião, ou um só com parâmetro de tipo (pergunta 6, premissa P5). Grounding por **Flow autolaunched somente leitura** que devolve os agregados já calculados (D3). Invocado por ação de página ou como ação do `SFAgent2`, se a pergunta 2 disser que é extensão do `eplast-ent-10`.
- Componentes (nomes provisórios, conforme `padrao-entrega`, confirmados no plano de build):
  - `GenAiPromptTemplate` por tipo de reunião (hoje não existe nenhum custom na org);
  - Flow autolaunched de grounding, `Resumo_Autolaunched_AgregaReuniao` (provisório);
  - permission set `PS_Comercial_ResumoReuniao` (provisório), agrupando `EinsteinGPTPromptTemplateUser` (padrão, já presente) e acesso ao Flow.
- Por que não A: A não produz texto. Por que não C: Flow resolve consulta agregada e grounding sem precisar de rollback, callout ou estado.
- Limite técnico: agregação em Flow sobre volume grande é cara (Flow não tem `GROUP BY`; agrega carregando registros). Para Board e S&OP com consolidado da empresa inteira, isso pode empurrar para C. Ver seção 4.

### Opção C — Código: Apex de agregação + geração (agendada ou sob demanda)

**Escolhida se:** B não aguenta o volume do consolidado (Board/S&OP), ou pergunta 5/8 = geração agendada com entrega em arquivo ou e-mail montado, ou regra de métrica (pergunta 7) que Flow não expressa com segurança.

- Classe de serviço `with sharing` com consultas agregadas `WITH USER_MODE`, sem SOQL em loop, chamada por ação invocável ou por Queueable/Schedulable. A saída alimenta o prompt template de B ou um documento.
- Componentes (provisórios): classe `MeetingSummaryService` mais `MeetingSummaryServiceTest` (≥ 85%, padrão do squad); o permission set de B.
- **Não reaproveitar `CustomerSummaryService` sem decisão.** Ela é o contrato da EPLAST-23, por cliente, e está bloqueada por D2–D6 daquela demanda. Estender a classe seria herdar o bloqueio dela.
- Por que não B: só se a medição em sandbox com carga sintética mostrar B acima de ~70% de algum limite (critério de `salesforce-doutrina`), ou se o agendamento e a entrega exigirem.
- Toca o achado 2 (cobertura de 10%): a classe nova traz o próprio teste, mas não melhora o agregado da org. Qualquer deploy futuro para produção continua barrado pelos 75% globais. Isso é fora desta demanda, mas o gestor precisa saber.

### Combinações prováveis

Os quatro tipos não precisam ter a mesma opção. Uma combinação provável, **a validar e não decidida aqui**: reunião comercial por cliente como extensão do agente (B, se a pergunta 2 confirmar), e S&OP e Board como painéis (A). Nesse caso a parte de A pode andar mesmo sem a pergunta 10.

---

## 3. Conflito de automação

**Existe automação concorrente em todos os objetos-fonte prováveis: Account (2 triggers + 2 Flows after-save), Opportunity (3 triggers + 2 Flows after-save), Order (2 triggers com o mesmo nome `OrderTrigger`, um do CPQ e um custom, + 1 Flow before-save + 1 after-save), OrderItem (trigger do CPQ), Task (Flow after-save).** É risco de ordem de execução **se e somente se** a solução gravar nesses objetos. Por D1 e D7, nenhuma das opções grava. Se uma resposta futura derrubar D1, o design volta ao gate com o mapeamento da ordem de execução como pré-requisito, conforme o assessment (achado 1).

O dado sintético do QA (D8) **vai** atravessar essa cadeia na criação. Isso não é risco da solução, mas é risco do teste, e o plano de build precisa tratá-lo.

---

## 4. Governador e escala

Volume de produção desconhecido: dev tem 0 registros e produção não é consultada. Não dá para dimensionar com número. O que fica definido:

- **Dois cenários, como manda a doutrina.**
  - (a) **Consolidado amplo** (Board/S&OP: todas as contas, pedidos e oportunidades do período). Em Apex, consulta agregada conta todos os registros agregados no limite de 50.000 linhas por transação. Em Flow, a agregação carrega os registros, com custo de CPU e heap. Relatório e painel (A) não têm esse limite de transação. **Por isso o consolidado amplo vai preferencialmente para A**, ou para C assíncrono (12 MB de heap, 60 s de CPU), nunca para B síncrono.
  - (b) **Um pai com muitos filhos** (reunião comercial de um cliente com muitos pedidos e itens, achado SOMOSAGILITY-10). Por D1 não há cascata de Flow, então o risco de CPU vem da leitura e montagem, não de automação. Agregar por cliente numa consulta só e limitar a lista detalhada a top-N.
- **Critério de escalonamento:** o roteiro de QA mede com carga sintética nos dois cenários. Acima de ~70% de qualquer limite, o design volta para revisão (B passa a C, ou síncrono passa a assíncrono).
- **Token do prompt (B/C):** o grounding precisa caber no limite do modelo. Lista detalhada vai sempre com top-N, nunca o conjunto inteiro. O N vem da pergunta 6.

Não afirmo aqui números exatos de limite de grounding ou de prompt template: conferir na documentação oficial no plano de build.

---

## 5. Impacto em permissões

- **A:** compartilhamento de pasta de relatório e painel por público (pergunta 6). Nenhum perfil ou permission set alterado.
- **B/C:** um permission set novo (`PS_Comercial_ResumoReuniao`, provisório), atribuído aos usuários do público, ou incluído num permission set group. **Nenhum perfil é alterado**, dado o achado 8 (quatro variações de perfil comercial; consolidar perfis não é escopo desta demanda).
- `PS_Comercial_ResumoClienteAgente` (existe, 0 atribuições, só acessa `CustomerSummaryService`): não é reutilizado nem alterado por esta demanda.
- FLS dos campos-fonte: conferida no próximo ciclo do design, depois da pergunta 7.

---

## 6. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Build iniciado sem contrato (pergunta 1) consome horas sem cobertura comercial | **Alta (bloqueante)** | Seção 9: o gate não libera o build |
| R2 | Duplicar o resumo de cliente do `insights_comerciais` / `eplast-ent-10`, com regras diferentes (pergunta 2) | **Alta** | D5; decidir antes do próximo design |
| R3 | Repetir a EPLAST-23: arquitetura aprovada sem regra de negócio vira código que só lança erro | **Alta** | Este design não escolhe opção sem as perguntas 4–7 |
| R4 | Número errado em Board/S&OP gerado por IA | **Alta** se B/C | D3 (número determinístico, IA só redige) |
| R5 | Dado de cliente processado por provedor de modelo sem decisão LGPD (pergunta 10; provedores externos não desligados) | **Alta** se B/C | D6; B/C não seguem sem resposta do jurídico/DPO |
| R6 | Gravação em Account reenvia a conta ao Protheus e estoura `enqueueJob` | Alta (latente) | D1; volta ao gate se D1 cair |
| R7 | Separação dev/qa não confirmada (achado 6, reconfirmado; `sbx-eplast-qa` não autenticada) | **Média (bloqueante para build e QA)** | Confirmação humana antes do build |
| R8 | Métrica sem fonte: "meta" não existe na org; campos sem descrição | Média | D2; pergunta 7; P3 da análise |
| R9 | Consolidado amplo estoura governador em B síncrono | Média | Seção 4: consolidado em A ou C assíncrono |
| R10 | Painel com usuário em execução fixo expõe consolidado a público errado | Média | D4 |
| R11 | Carga sintética de QA dispara CPQ, Flows e integração Protheus | Média | D8; tratar no plano de build |

---

## 7. Riscos do assessment: como este design lida com cada um

| Achado | Aplica? | Como é tratado |
|---|---|---|
| 1 — automação concorrente em Account/Opportunity/Order | Sim, condicional | D1 e D7: nenhuma opção grava. Reconfirmado e detalhado no recon (§3), incluindo o enqueue para o Protheus |
| 2 — cobertura Apex de 10% | Só na opção C | Classe nova com teste próprio ≥ 85%. O agregado da org segue bloqueando deploy em produção, fora desta demanda |
| 3 — validation rules de Order | Não | Leitura não dispara validation rule. Afeta só a carga sintética do QA (fixture preenche campos exigidos) |
| 4 — campos sem descrição (153/223, reconfirmado) | Sim | Nenhum campo vira fonte sem confirmação do negócio (pergunta 7, P3). Campo novo, se houver, sai com descrição |
| 5 — convenção `<Classe>Test` | Só na opção C | Classe nova segue `<Classe>Test`. Classe existente não é tocada |
| 6 — alias dev em sandbox "qa" | Sim | Bloqueante para build (R7) |
| 7, 8 — perfil Financeiro e perfis comerciais | Indireto | Nenhum perfil alterado; acesso por permission set (seção 5) |
| 9 — API version antiga | Não | Nenhuma classe existente é editada |
| 10 — `OrderTrigger` duplicado | Não | Order não recebe escrita |
| Não medido: OWD | Fechado no recon | Account Edit, Opportunity Read, Contact pelo pai (`02-recon.md` §2) |

---

## 8. O que NÃO será feito nesta demanda

- Nenhuma escrita em Account, Opportunity, Order, OrderItem, Contact ou Task (D1, D7).
- Nenhum objeto ou campo novo sem escalação (D2), incluindo uma fonte de "meta".
- Não ativar, alterar nem reimplementar `SFAgent2` ou `CustomerSummaryService`. Isso é território de `eplast-ent-10` e da EPLAST-23, até a pergunta 2 dizer o contrário.
- Não consolidar a automação de Account, Opportunity e Order (recomendação do achado 1, esforço alto, demanda própria).
- Não subir a cobertura Apex da org (achado 2).
- Não conciliar números com EPLAST-26, 31, 32 e 33 (pergunta 3): só registrar a fonte de cada número (critério do bloco A).
- Não validar com dado real nem com volume de produção.
- Não escolher entre as opções A, B e C. Isso depende das perguntas 4, 5, 6, 7 e 10.

---

## 9. Recomendação ao arquiteto humano

1. **Não liberar o build neste gate.** O design está completo no que dá para decidir sem as respostas (seção 1) e incompleto de propósito no que não dá (seção 2).
2. Levar ao cliente e ao gestor de conta as perguntas **1, 2, 4, 5, 6, 7 e 10** (seção 0), com as três opções da seção 2 como material de conversa. Isso ajuda o negócio a responder "IA ou painel", vendo custo e risco de cada uma.
3. Confirmar o achado 6 (dev x qa) e autenticar `sbx-eplast-qa` no runner.
4. Com as respostas registradas no card, rodar de novo esta etapa. O recon vence em 2026-11-18. Depois disso, refazer o recon.
5. Se a pergunta 1 der "não contratado", a demanda volta ao backlog e este design fica como registro.

Aprovar este design significa aceitar as restrições D1–D8 e a estrutura de decisão. Não significa escolher uma opção.

---

## 10. Estimativa de esforço humano (refinada)

**Estimativa de esforço:** 20–100 h

O que mudou em relação à análise (24–120 h) e por quê:
- **Piso de 24 para 20 h.** O recon mostrou relatórios de carteira, painéis `Leads & Oportunidades` e `Pedidos` e forecast já ativo. Se a resposta for a opção A sobre essas fontes, parte do trabalho é adaptar o que existe.
- **Teto de 120 para 100 h.** Agentforce e Prompt Templates já estão habilitados e licenciados na org, sem provisionamento. D1 elimina regressão na cadeia de triggers e Flows de Account, Opportunity e Order, e na integração Protheus, que pesaria no cenário G da análise.
- Faixa por opção, para orientar a conversa com o cliente: **A ≈ 20–40 h** · **B ≈ 40–70 h** · **C (ou B+C) ≈ 70–100 h**. Quatro conteúdos distintos (pergunta 6) puxam para o topo de cada faixa.
- **Não inclui** as horas das reuniões para responder às perguntas bloqueantes, nem a curadoria de campos com o negócio além das fontes que cada resumo usar, nem horas de agente.
- Continua larga porque a opção não está escolhida. A faixa fecha no próximo ciclo do design.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
