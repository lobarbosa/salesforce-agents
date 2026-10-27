# 03 — Design: SOMOSAGILITY-15 — Layout de página inicial

**Tipo:** sustentação (design enxuto)
**Org de referência:** `sbx-somos-agility-dev` (recon de 2026-10-21 em `02-recon.md`)
**Base:** `01-analise.md` aprovada no gate de análise (sha256 `361930ceb186090d`, confere com o disco).

## 0. Situação: design de mecanismo aprovável, build bloqueado

A análise foi aprovada no gate, mas declarava duas pendências bloqueantes que **continuam abertas**:

- **P1: lista do que retirar da aba Início.** O anexo foi liberado e lido por extração de texto. A lista
  está numa imagem embutida e não sai por essa via. O texto do e-mail diz só "retirar de todas as
  visualizações os objetivos abaixo:", seguido de linhas em branco. O card não traz outra fonte.
- **P2: escopo de perfis.** "Todos os usuários" continua sendo premissa.

Este design **fecha o mecanismo**: como se faz, onde se mexe e o que não se mexe. Ele vale para
qualquer lista que o cliente mande, desde que caia na interpretação A da seção 2. **Não fecha a
aplicação concreta**, ou seja, quais componentes saem de quais páginas. Não invento a lista (guardrail #3).

**Condição para liberar o build, além do aceite deste gate:**
1. A lista P1 chega **em texto no card**, ou um print sem dado pessoal liberado por delivery, com cada
   item identificável na tabela de componentes da seção 3 do `02-recon.md`.
2. A resposta a P2 chega no card.
3. O arquiteto completa a matriz da seção 4 (item × página) num adendo a este design. Se a lista cair
   na interpretação B ou C da seção 2, o design volta para revisão.

Se o aprovador deste gate souber a lista por outro canal, o caminho é registrá-la no card. Não basta
passá-la ao agente de build fora do registro, porque o build e o QA precisam de critério verificável.

## 1. Decisão

**Nível: configuração (Lightning App Builder / metadata `FlexiPage`).** Sem Flow, sem código, sem
mudança de permissão, sem mudança de modelo de dados.

Mecanismo, na interpretação A ("retirar componentes da Home para todos"):
- Remover o `componentInstance` correspondente de **cada FlexiPage do tipo Home que contém o item**. Pelo
  recon, os componentes padrão se repetem em até 13 das 14 páginas. Para valer "para todos os usuários",
  a remoção tem que ser feita página por página, não só numa delas.
- Não alterar as atribuições app/perfil (`profileActionOverrides` nos `CustomApplication`). Quem vê qual
  página continua igual; muda só o conteúdo das páginas.
- Se P2 restringir o escopo a alguns perfis, há duas formas de atender:
  - **Preferida:** se todos os perfis de uma página estiverem no escopo, remove-se o componente da página.
  - **Quando a página mistura perfis dentro e fora do escopo:** usar filtro de visibilidade do componente
    (`visibilityRule` por `$User.Profile.Name` ou por permissão), sem duplicar páginas. Ainda é
    configuração. Se a mistura for grande, o arquiteto decide no adendo entre o filtro e uma página nova.

**Por que não descer de nível:** página Home é metadata de UI declarativa e o App Builder resolve
remoção e visibilidade de componente. Não há regra de negócio, dado nem evento envolvido. Um Flow ou
um LWC não teria o que fazer aqui.

**Por que não "subir" para permissão:** retirar o acesso ao objeto, relatório ou dashboard (perfil,
permission set, pasta) esconderia o item da Home, mas também o tiraria das abas próprias. Isso viola a
RN-3 da análise ("continua acessível pelas abas e fluxos próprios"). Fica descartado.

## 2. Interpretações do pedido e o que cada uma muda

O pedido fala em "objetos" e "visualizações", e a lista não é legível. Três leituras são plausíveis, e
cada uma tem um mecanismo diferente:

| | Interpretação | Mecanismo | Coberto por este design? |
|---|---|---|---|
| **A** | Componentes da página Início (dashboards embutidos, Chatter, principais negócios, assistente etc.) | Remover `componentInstance` das FlexiPages Home (seção 1) | **Sim** |
| **B** | Abas de objeto na barra de navegação dos apps | `tabs` em `CustomApplication`, sem tocar na Home | Não. Volta ao design |
| **C** | Componentes **de dentro** de um dashboard embutido (gráficos de um painel) | Editar o `Dashboard`, que é compartilhado e aparece fora da Home | Não. Volta ao design, com risco de afetar outros usuários do painel |

O título da demanda ("Layout de página inicial") e o assunto do anexo ("Layout de página inicial x
Painéis") apontam para A, possivelmente com C misturado ("Painéis"). Isso é **indício, não confirmação**.

## 3. Componentes a criar / alterar / depreciar

**Criar:** nenhum. Exceção: uma página nova, se o adendo decidir por isso no caso de escopo parcial.
Sem decisão agora.

**Alterar:** um subconjunto, ainda indefinido (P1), das FlexiPages Home **atribuídas**:

| Id | API name (sanitizado; o completo sai da org pelo Id) | No baseline? |
|---|---|---|
| `0M00z000000GoLuCAK` | `Equipe_vendas_SP` | **Não**. Recuperar antes |
| `0M04z000000g1BHCAY` | `Home_Page_Geral` | Sim |
| `0M0U400000049fpKAA` | `Home_Page_Marketing` | Sim |
| `0M038000000CbqCCAS` | `Home_page_padr_o` | Sim |
| `0M0U40000001G17KAE` | `Homepage_Customer_Success_Painel_de_Relacionamento_Operacional` | Sim |
| `0M0U40000001G2jKAE` | `Homepage_GPs_PMO_<nomes>_Painel_de_Projetos` | Sim |
| `0M0U40000001HhxKAE` | `Homepage_Grupo_Operacoes_Painel_de_Controle_de_Operacoes` | Sim |
| `0M0U40000002p9hKAA` | `Homepage_<prenome>` | Sim |
| `0M0U40000001GnVKAU` | `Homepage_Renovacoes_e_<prenome>_Painel_de_Controle_de_Renovacoes` | Sim |
| `0M0U40000001FzVKAU` | `Homepage_SE_GCs_<nomes>_Painel_Geral` | Sim |
| `0M038000000GmdwCAC` | `P_gina_Inicial_Customizada` | **Não**. Recuperar antes |

Mais a página que for o **default de Home da org**, se não for uma destas. O default não foi confirmado
no recon e o build precisa confirmar antes de começar.

**Não alterar:** as páginas sem atribuição (`0M04z000000g1AxCAI` `Home_Page_GC`, `0M0U40000002p6TKAQ`
`Home_Page_<prenome>`, `0M00z000000fxzFCAQ` `PaginaInicialGerenteContas`), salvo se uma delas for o
default da org. Também não alterar `CustomApplication`, `Dashboard`, `Report`, perfis e permission sets.

**Depreciar:** nenhum. Limpar páginas órfãs está fora de escopo (seção 6).

## 4. Matriz item × página (a preencher no adendo, depois de P1/P2)

Formato que o build vai receber:

| Item da lista do cliente | Componente (API) | Referência (dashboard/relatório, se houver) | Páginas (Id) | Perfis no escopo | Remoção ou filtro |
|---|---|---|---|---|---|
| *pendente P1* | | | | *pendente P2* | |

Regra para preencher: cada item tem que bater com uma linha da tabela de componentes ou de dashboards
do `02-recon.md`. Se não bater, o item não é da Home (interpretação B ou C) e o design é revisto.

## 5. Impacto em permissões

**Nenhum.** Perfis, permission sets, pastas de relatório/dashboard e acesso a objetos ficam como estão.
O filtro de visibilidade por perfil, se for usado, mora na FlexiPage e não concede nem retira acesso.

## 6. O que NÃO será feito nesta demanda

- Remover ou alterar dashboards, relatórios ou objetos, inclusive o conteúdo dos painéis embutidos
  (interpretação C).
- Alterar a navegação dos apps (interpretação B).
- Reatribuir páginas a perfis, consolidar as 14 Home em menos páginas ou excluir as 3 órfãs. Há
  oportunidade clara de higiene aqui (páginas de 2017/2019 sem uso, DeveloperNames com nomes de
  pessoas), mas isso é outra demanda, se o cliente quiser.
- Home no celular: não há atribuição `Small`, e o pedido não menciona mobile.
- Qualquer coisa em produção (guardrail #1). A esteira termina em `sbx-somos-agility-qa`.

## 7. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **Build começar sem P1/P2 e retirar componentes que o cliente não pediu**, ou deixar de retirar algum | **Alta** | Build bloqueado até a matriz da seção 4 estar preenchida a partir de texto no card |
| R2 | Remover de uma página só e o item continuar aparecendo para perfis de outras páginas, deixando "todos os usuários" sem atender | **Média** | A matriz exige listar todas as páginas que contêm o item. O QA testa um perfil por página afetada |
| R3 | Lista cair em B ou C, com mecanismo diferente e, em C, impacto em quem usa o dashboard fora da Home | **Média** | Seção 2. Volta ao design, sem improviso no build |
| R4 | Default de Home da org desconhecido. Perfis sem atribuição (ex.: Administrador do sistema, Gerente de Contas - AI) veem uma página que não está na lista | **Média** | Confirmar o default no início do build e incluí-lo na matriz |
| R5 | Duas páginas atribuídas não estão no baseline do repositório (`Equipe_vendas_SP`, `P_gina_Inicial_Customizada`). Editar a partir do repo apagaria o que não foi recuperado | **Média** | Recuperar da org para `force-app` antes de editar e commitar o estado original separado da alteração |
| R6 | Perfil Admin com duas atribuições no mesmo app (`P_gina_Inicial_Customizada` e `Homepage_SE_GCs_...`). Não se sabe qual o runtime aplica | **Baixa** | Se o item estiver nas duas, remover nas duas. O QA confere com usuário Admin |
| R7 | Sandbox de dev não reflete produção (perfis sem usuário ativo aqui, páginas alteradas em prod depois do refresh) | **Baixa** | O release compara as FlexiPages de destino antes do deploy em QA. Produção é com o humano |

**Conflito de automação:** nenhum. Não há Flow, trigger ou validation envolvidos (recon, seção 5).
**Limites de governador e escala:** não se aplicam, porque não há DML, SOQL nem automação. A mudança
é só de metadata de UI.

## 8. Plano de teste (insumo para o QA)

- Para cada página alterada, um usuário de teste de um perfil atribuído a ela abre a Início nos apps de
  vendas (`standard__LightningSales` e `standard__LightningSalesConsole`) e confirma que o item sumiu e
  que os demais componentes continuam lá (critérios de aceite 1 e 4).
- Para cada item retirado, o usuário acessa o dashboard ou relatório de origem pela aba própria e ele
  continua acessível (critério 2).
- Se houver escopo parcial (P2), um perfil fora do escopo mantém a página igual (critério 3).
- Os prints não podem mostrar registro real. Se o dashboard embutido renderizar dado de cliente, recortar
  ou usar print só da região alterada (guardrail #2).

## 9. Estimativa

**Estimativa de esforço:** 3–8 h

**O que mudou em relação à análise (2–8 h) e por quê:**
- **Mínimo de 2 h para 3 h.** O recon mostrou 11 páginas Home atribuídas, mais o default da org ainda
  desconhecido, e os componentes padrão se repetem em quase todas. Mesmo que a lista tenha um item só,
  "para todos os usuários" significa editar várias páginas e testar um perfil por página. Duas páginas
  ainda precisam ser recuperadas para o repositório antes.
- **Máximo mantido em 8 h.** O mecanismo foi confirmado como configuração pura, sem permissão e sem
  código, o que segura o teto. A faixa só sobe se P1 cair em B ou C, e aí o design é revisto e
  re-estimado.
- Ficam fora da faixa: o tempo de espera pelas respostas P1/P2 e a homologação com a Governança/PMO do cliente.

**Complexidade:** P–M. P se a lista tiver poucos itens e o escopo for "todos". M se o escopo for parcial
e exigir filtro de visibilidade.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Adendo — tentativa de build em 2026-10-27, build segue bloqueado

O gate de design foi aprovado em 2026-10-27 (ver `gates.md`) e a demanda entrou em `build`. O agente
`builder-declarativo` leu `demanda.md`, `comentarios-do-card.md`, `01-analise.md`, `02-recon.md`, este
design e o anexo PDF liberado nesta sessão, e conferiu as três condições da seção 0 antes de tocar em
qualquer metadata ou abrir branch:

1. **P1 (lista do que retirar), em texto no card ou print liberado mapeado à tabela da seção 3:**
   **não satisfeita.** `comentarios-do-card.md` tem só quatro entradas, nenhuma com a lista — a última
   (2026-10-27 22:55) só registra a aprovação do gate de design. Nenhum outro arquivo em disco traz a
   lista em texto.
2. **P2 (escopo de perfis), resposta no card:** **não satisfeita.** Mesma conferência acima — nenhum
   comentário responde "todos os usuários significa todos os perfis?".
3. **Matriz item × página (seção 4), adendo do arquiteto:** **não satisfeita.** A seção 4 acima continua
   com a linha "*pendente P1*" / "*pendente P2*", sem adendo do arquiteto.

Como nenhuma das três condições foi atendida, **nenhuma branch foi criada, nenhum metadata foi escrito
e nenhum deploy foi feito** em `sbx-somos-agility-dev`. Isso segue a própria instrução do agente de
build: quando o design não fecha, parar e reportar, não improvisar.

**Observação para acelerar a resolução de P1 (não é uma resposta, nem deve ser tratada como tal):**
ao reler o PDF do anexo nesta sessão, o agente conseguiu enxergar visualmente a imagem embutida (não
só extrair texto dela) e notou três trechos do print demarcados em destaque amarelo sobre uma página
Home padrão: a lista de ordenação do feed ("Classificar por"), o bloco "Principais negócios -
Oportunidades recentes" e o bloco "Desempenho trimestral". Isso é indício, lido por um agente, de uma
imagem — não confirmação. Não foi usado para decidir nada aqui e **não substitui** a condição 1: a
lista ainda precisa chegar em texto no card (ou print liberado por delivery) para virar critério
verificável para build e QA, e a condição 3 ainda exige que o arquiteto confirme essa correspondência
na matriz da seção 4, inclusive decidindo entre as interpretações A/B/C da seção 2. Nenhum dado pessoal
do e-mail (nome, telefone, e-mail da remetente) foi transcrito aqui, conforme guardrail #2.

Build permanece bloqueado até que delivery/arquiteto resolvam P1, P2 e preencham a matriz da seção 4.
