# SOMOSAGILITY-6 — Análise (BA discovery)

**Cliente:** Somos Agility
**Tipo:** sustentação (melhoria/alteração de configuração de aprovação)
**Fonte:** `demanda.md` (história enviada pelo consultor, não editada)
**Status desta análise:** rascunho para validação humana. Há perguntas bloqueantes em aberto (ver seção final).

---

## 1. Contexto de negócio

No objeto **FVP (Fluxo de Venda de Produtos e Serviços)** existe uma aprovação em que o aprovador atual é a usuária **Kelly**. A demanda pede que essa aprovação passe a ser feita por **Sales Op**, retirando a Kelly do fluxo.

A demanda não explica o motivo da troca (mudança de responsabilidade, afastamento, reorganização do time comercial etc.). O motivo não muda o escopo técnico, mas fica registrado aqui para rastreabilidade.

## 2. Objetivo

Trocar o aprovador do processo de aprovação do objeto FVP: a Kelly deixa de aprovar, e a aprovação passa a ser de **Sales Op**, sem alterar a regra de negócio da aprovação em si (critérios de entrada, campos, ordem de etapas), salvo se a validação indicar o contrário.

## 3. Regra de negócio (como entendida hoje)

- RN-1: Registros de FVP que entram na etapa de aprovação devem ser aprovados por **Sales Op** após a alteração.
- RN-2: A usuária Kelly não deve mais figurar como aprovadora do FVP após a alteração, em nenhuma etapa do processo de aprovação em que hoje ela aparece.
- RN-3: A regra de negócio da aprovação (quando ela é disparada, quais critérios, o que acontece ao aprovar/rejeitar) permanece igual. **Premissa a validar (P-3).**

Termos não confirmados contra a org (não tratar como nomes técnicos ainda):
- "Sales Op" — pode ser um usuário, um grupo público ou uma fila. Não assumido.
- "FVP" — nome de objeto/sigla informado pelo consultor. O nome de API do objeto, o nome do processo de aprovação e o nome da etapa não foram informados e não foram confirmados.

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo usam marcadores entre `<>` para os nomes que dependem de confirmação na org (ver perguntas P-1 a P-4). Não são executáveis até os marcadores serem preenchidos.

```gherkin
Funcionalidade: Aprovador do FVP passa de Kelly para Sales Op

  Cenário: Kelly não é mais aprovadora do processo de aprovação do FVP
    Dado que o processo de aprovação "<NOME_PROCESSO_APROVACAO>" do objeto FVP está ativo na org de dev
    Quando eu consulto as etapas e os aprovadores desse processo via metadata
    Então nenhuma etapa ativa tem a usuária Kelly como aprovador
    E nenhuma regra de atribuição de aprovador resolve para a Kelly

  Cenário: Sales Op é o aprovador da etapa alterada
    Dado que o processo "<NOME_PROCESSO_APROVACAO>" está ativo na org de dev
    Quando eu consulto a etapa "<NOME_ETAPA>" desse processo via metadata
    Então o aprovador dessa etapa é "<SALES_OP_ID_CONFIRMADO>" (<tipo: usuário | grupo | fila>)

  Cenário: Um FVP enviado para aprovação após a mudança cai para Sales Op
    Dado um registro de teste de FVP em ambiente de dev, sem dado real de cliente
    Quando o registro é submetido ao processo de aprovação
    Então o item de aprovação aparece na fila de "<SALES_OP_ID_CONFIRMADO>"
    E o item não aparece para a Kelly

  Cenário: Regra de negócio da aprovação permanece inalterada
    Dado que a alteração foi feita apenas no aprovador
    Quando comparo os critérios de entrada, as ações de aprovar/rejeitar e os campos do processo antes e depois
    Então não há diferença além do aprovador

  Cenário: Alteração não atinge a org de produção
    Dado que a alteração é feita pela esteira
    Quando o pipeline executa a etapa de build
    Então a alteração é aplicada somente na sandbox de dev e, depois, na sandbox de qa
    E nenhum comando de deploy é executado contra produção

  Cenário: Itens de aprovação já pendentes na Kelly têm destino definido
    Dado que existem itens de aprovação pendentes atribuídos à Kelly no momento da mudança
    Quando a alteração entra em produção
    Então existe uma decisão registrada sobre o destino desses itens (redistribuir para Sales Op, manter, ou rejeitar) — ver P-5
```

Observação: o último cenário depende de decisão de negócio (P-5). Sem ela, o critério não é testável e fica como pendente.

## 5. O que a demanda NÃO diz

1. **Qual é exatamente o processo de aprovação** no objeto FVP (nome de API e nome exibido). Pode haver mais de um processo ativo no mesmo objeto.
2. **Em quantas etapas a Kelly aparece** e se ela aparece como aprovador direto (usuário), via fila/grupo, ou via campo de hierarquia (gestor, proprietário). A demanda fala só em "usuário da Kelly".
3. **O que é "Sales Op"**: usuário nominal, grupo público, fila de aprovação ou perfil. Se for grupo ou fila, não está claro quem são os membros.
4. **Se a Kelly deve sair também de outras regras** (ex.: fila de notificação, campo de responsável, regra de compartilhamento) ou só do processo de aprovação.
5. **O que acontece com itens de aprovação já pendentes** atribuídos à Kelly no dia da troca.
6. **Se a mudança vale para todos os registros ou só para FVPs novos** (ou para os que estão em uma etapa específica).
7. **Prazo e janela de entrega**, e se há dependência com outra demanda ou release.
8. **Quem aprova a própria alteração** do lado do cliente (quem pediu é consultor; não há indicação de aprovador do negócio para a mudança).
9. **Se a Kelly deve ser desativada** ou apenas removida do fluxo. Só a remoção do fluxo está pedida; desativação de usuário não entra no escopo sem confirmação.
10. **Se há regra de negócio na aprovação que depende de quem é o aprovador** (ex.: alçada por valor, desconto), o que mudaria a análise de impacto.

## 6. Premissas a validar

Todas abaixo estão **pendentes**. Nenhuma foi confirmada e nenhuma deve ser tratada como fato antes da validação.

- **P-1 (pendente):** o objeto FVP existe na org de dev e tem um processo de aprovação ativo que inclui a Kelly. Confirmar via `sf` CLI (metadata), sem consultar dados de registro.
- **P-2 (pendente):** "Sales Op" existe como usuário, grupo ou fila na org de dev. Confirmar o tipo e o ID antes de desenhar.
- **P-3 (pendente):** a alteração é só do aprovador, sem mudança em critérios de entrada, ações ou campos da aprovação.
- **P-4 (pendente):** a Kelly é aprovadora apenas via atribuição direta no processo (não via hierarquia, fila compartilhada ou regra de outro processo).
- **P-5 (pendente, decisão de negócio):** destino dos itens pendentes da Kelly no momento da troca.
- **P-6 (pendente):** a alteração será feita por metadata (declarativo, dentro da esteira), sem código Apex. A escolha final cabe ao arquiteto na etapa 3.
- **P-7 (pendente):** a Kelly continua ativa como usuária, só sai do fluxo. Desativação fica fora do escopo.

## 7. Estimativa de complexidade

**P (pequena).** Mudança de atribuição de aprovador em um processo de aprovação, sem código e sem integração; o esforço real depende de quantas etapas e regras citam a Kelly (P-1 e P-4), o que só a etapa de recon confirma. Se a Kelly aparecer em mais de um processo ou em regras de atribuição, a estimativa sobe para M.

## 8. Perguntas bloqueantes (precisam de resposta antes do design)

Pelas regras do squad, estas perguntas mudam o desenho (aprovação declarativa, fila, usuário ou grupo), por isso o arquiteto não deve ser acionado antes das respostas:

1. **[P-2] "Sales Op" é usuário, grupo público, fila ou perfil?** Se for usuário, qual? Se for grupo ou fila, quais são os membros e quem responde por eles?
2. **[P-1] Qual é o nome do processo de aprovação do FVP** (API e nome exibido) e quantas etapas ele tem?
3. **[P-4] Em quais etapas a Kelly aparece e como ela é atribuída** (usuário direto, fila, hierarquia, regra de atribuição)?
4. **[P-5] O que fazer com os itens pendentes da Kelly** no dia da troca: redistribuir para Sales Op, manter com a Kelly até concluir, ou rejeitar?
5. **[Escopo] A mudança vale para todos os FVPs ou só para os novos?**
6. **[Escopo] A Kelly deve sair de outras regras além do processo de aprovação** (fila de notificação, campo de responsável)?

Não há ambiguidade de arquitetura que exija escolha entre sistemas externos (e-mail, WhatsApp, Marketing Cloud). A pergunta de tipo de destinatário (item 1) é a única que muda a forma da solução e precisa ser respondida.

## 9. Próximos passos (após validação)

- Etapa 2 (`org-recon`): confirmar P-1, P-2, P-4 via `sf` CLI contra a org de dev, sem consultar dados de registro (guardrail #2).
- Etapa 3 (`arquiteto`): decidir o mecanismo de alteração e registrar o tratamento dos itens pendentes (P-5).
- Etapas 4 a 7 seguem o fluxo de sustentação: build em `feature/SOMOSAGILITY-6`, teste em sandbox, release para sandbox/UAT. Produção fica com o humano.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.

## Estimativa de esforço

**Estimativa de esforço:** 3–6 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). P: troca de aprovador num processo de aprovação, sem código. Sobe se a Kelly aparecer em mais de um processo ou em regra de atribuição.

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
