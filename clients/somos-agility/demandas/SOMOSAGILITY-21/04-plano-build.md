# 04 — Plano de build — SOMOSAGILITY-21: Campo origem do Lead

Org consultada nesta etapa: `sbx-somos-agility-dev` (conferida via `sf org list` em
2026-10-28, `Connected`). Nenhum comando `sf` de escrita foi executado.

## Decisão desta etapa: nenhum metadata é criado ou alterado no Salesforce

Conforme `03-design.md` (seção 1 "Decisão" e seção 4 "Componentes"), esta demanda tem
duas opções:

- **Opção A (correção principal, sempre válida):** ajuste de payload no middleware
  externo que autentica pelo Connected App `Lead_Site_Agility`, para enviar
  `LeadSource = "Web Site Agility Networks"` (API name do valor de picklist, não o
  label "Web Site Agility"). Essa correção é **100% fora do Salesforce** — não há
  Custom Field, Flow, Apex ou qualquer outro metadata a criar ou alterar do lado SF
  para a Opção A.
- **Opção F (rede de segurança declarativa, condicionada):** Custom Permission
  `Lead_Origem_Site_Agility`, Permission Set `PS_Integracao_LeadSiteAgility` e Flow
  before-save `Lead_BeforeSave_OrigemSiteAgility`. O design é explícito: ela **só deve
  ser construída se um humano confirmar, na pergunta P-2 do gate, que existe um usuário
  de integração exclusivo do site Agility** (que não grava Leads de nenhum outro canal,
  inclusive o site Eagle). Sem essa confirmação, o próprio design diz: "a rede de
  segurança não é construída: um critério inventado viola CA-02 e o guardrail #3" e
  "esta esteira não constrói nada em `force-app`".

### Verificação feita nesta etapa

Reli integralmente, nesta sessão, `demandas/SOMOSAGILITY-21/comentarios-do-card.md` e
`demandas/SOMOSAGILITY-21/gates.md`:

- `comentarios-do-card.md` contém apenas: o registro inicial do chamado (demandante
  Guilherme, Marketing) e quatro notas da Equipe sobre aprovação de gates/estimativa.
  **Não há nenhuma resposta às perguntas P-1 a P-5 da seção 8 do design**, nem
  especificamente à P-2 (existência de usuário de integração exclusivo do site
  Agility).
- `gates.md` registra a aprovação do `aguardando_gate_design` por Leonardo Barbosa em
  2026-10-27, com o hash de `02-recon.md` e `03-design.md` — ou seja, **aprovação do
  documento de design como um todo** (incluindo a condicional descrita nele), não uma
  confirmação explícita de "sim, existe usuário exclusivo, construa a Opção F".

**Conclusão: a condição da P-2 não está satisfeita. A Opção F não é construída nesta
etapa.** Isso não é "o design não fechou" — é o design fechando exatamente como
escrito: a condição para a Opção F simplesmente não se cumpriu ainda.

## O que foi (e não foi) feito nesta etapa de build

- **Criado em `force-app`:** nada. Nenhum Custom Permission, Permission Set, Flow ou
  qualquer outro componente de metadata.
- **Alterado em `force-app`:** nada.
- **Nenhum `sf project deploy start`** foi executado — não há metadata para implantar.
- Nenhum comando `sf` de escrita/gravação foi rodado contra `sbx-somos-agility-dev`
  nesta etapa.

## O que precisa acontecer para a demanda fechar de fato

A correção efetiva de CA-01 depende de uma ação **fora desta esteira**:

- O dono/administrador do middleware que alimenta o Connected App `Lead_Site_Agility`
  (TI Agility — ver P-4 do design) precisa ajustar o payload do `POST
  /services/data/vNN.0/sobjects/Lead` para enviar o campo `LeadSource` com o valor
  **`Web Site Agility Networks`** (API name — não o label "Web Site Agility" exibido
  na UI).
- Enquanto esse ajuste não for feito, Leads criados pelo site Agility continuam
  recebendo o default de org (`Prospecção - Gerente de Contas`) ou, se o payload hoje
  manda o label em vez do API name, um valor de texto solto fora da lista de picklist
  (H1/H2 do design).

## Perguntas em aberto que bloqueiam fechar com certeza total (seção 8 do `03-design.md`)

- **P-1** — Marketing/Guilherme precisa confirmar que o valor-alvo é mesmo "Web Site
  Agility" (`Web Site Agility Networks`), e não "Web Site Agility – E-mail".
- **P-2** — TI Agility precisa confirmar se o usuário de integração do middleware é
  **exclusivo** do site Agility (não grava Leads de nenhum outro canal, inclusive
  Eagle). É a resposta que decide se a Opção F chega a ser construída. **Não
  confirmada até esta etapa.**
- **P-3** — evidência da causa-raiz real em produção (print do campo `LeadSource` de um
  Lead afetado, ou agregado `LeadSource, COUNT(Id) ... GROUP BY LeadSource`), para
  separar H1 de H2/H3. Produção está fora do alcance desta esteira (guardrail #1); essa
  evidência só pode vir de alguém com acesso a produção.
- **P-4** — quem é o dono da correção do payload do middleware, e em que prazo. A
  demanda só fecha de fato (CA-01 valendo em produção) quando essa alteração externa
  acontecer.
- **P-5** — se Marketing aceita a quebra na série histórica de relatórios sem corrigir
  retroativamente os Leads antigos (fora de escopo desta demanda, conforme seção 7 do
  design).

## Implicação para a etapa de QA (5)

Não há metadata novo para testar em QA — não existe Custom Permission, Permission Set
ou Flow desta demanda em `force-app` para implantar em `sbx-somos-agility-qa`. O
roteiro de QA desta demanda deve seguir o que `03-design.md` já descreve em "Cobertura
dos critérios de aceite" (CA-04): simular o payload REST (`POST
/services/data/vNN.0/sobjects/Lead`, dados fictícios, sem dado pessoal — guardrail #2)
contra `sbx-somos-agility-qa`, cobrindo os casos:

1. `LeadSource = "Web Site Agility Networks"` explícito → valor mantido (prova que,
   quando o middleware mandar o valor certo, o resultado é o esperado).
2. Sem `LeadSource` no payload → mostra o default de org `Prospecção - Gerente de
   Contas` (comprova H1 na plataforma).
3. `LeadSource = "Web Site Agility"` (label, não API name) → mostra o valor solto fora
   da lista (comprova H2 na plataforma, já que o picklist não é restrito).

Isso é **validação de comportamento da plataforma** (default de picklist, aceitação de
valor fora da lista), não validação de metadata construído por esta esteira — porque
não há metadata construído por esta esteira nesta demanda. Caso a Opção F venha a ser
aprovada no futuro, os casos (iv) e (v) descritos no CA-04 do design (usuário com/sem o
Permission Set) passariam a fazer parte do roteiro também.

## Se no futuro alguém confirmar P-2

Se, depois desta etapa, surgir confirmação de que existe um usuário de integração
exclusivo do site Agility, isso **não autoriza construir a Opção F retroativamente a
partir de um comentário ambíguo**. O design exige confirmação explícita da P-2 no gate
de design; se essa confirmação chegar depois, o caminho correto é voltar ao gate de
design (ou abrir uma nova decisão formal) para registrar a confirmação e então, só
então, uma etapa de build subsequente constrói os três componentes da Opção F listados
na seção 4 do `03-design.md`. Este agente não assume essa decisão sozinho.
