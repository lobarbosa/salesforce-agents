# 01 — Análise funcional: SOMOSAGILITY-12

**Cliente:** somos-agility
**Tipo:** sustentação (melhoria de regra de preenchimento)
**Título:** JST - Preenchimento obrigatório Classificação gerencial e Denominação
**Fonte:** `demanda.md` (história do consultor, não editada)
**Status desta análise:** rascunho aguardando validação humana. Não há design técnico aqui.

---

## 1. Contexto de negócio

A demanda pede que os campos **Classificação gerencial** e **Denominação** passem a ser de
preenchimento obrigatório antes que um registro siga para a aprovação da diretoria (citada
na demanda como "diretoria / Walmor"). Hoje, segundo a história, esses campos podem ficar
vazios e o registro chega à aprovação sem eles.

A motivação implícita é garantir que a aprovação da diretoria seja feita sobre um registro
completo. A própria demanda não explica o motivo de negócio além disso.

## 2. Objetivo

Impedir que um registro avance para a aprovação da diretoria sem que **Classificação
gerencial** e **Denominação** estejam preenchidos.

Fora do objetivo (até confirmação): alterar a aprovação em si, mudar o fluxo de quem aprova,
ou alterar regras de outros campos.

## 3. Regra de negócio (como entendida hoje)

- RN-01: Classificação gerencial é obrigatória antes da submissão para aprovação da diretoria.
- RN-02: Denominação é obrigatória antes da submissão para aprovação da diretoria.
- RN-03: A obrigatoriedade vale para o registro como um todo, e não só para quem está
  aprovando. **Pendente de confirmação** (ver dúvida D-04).

Os nomes dos objetos, dos campos de API e do processo de aprovação **não foram informados**.
Eles não são inventados aqui. Serão confirmados via `sf` CLI na etapa de recon (`org-recon`),
e a análise não pode ser considerada fechada antes disso.

## 4. Critérios de aceite (Gherkin)

Os cenários usam `<Objeto>`, `<Campo Classificação>`, `<Campo Denominação>` e `<Etapa de aprovação>`
como placeholders. São substituídos pelos nomes reais depois que D-01 e D-02 forem respondidas.

**CA-01 — Bloqueio sem Classificação gerencial**
```gherkin
Dado que existe um <Objeto> com Denominação preenchida e Classificação gerencial vazia
Quando o usuário tenta enviar o registro para a aprovação da diretoria
Então o envio é bloqueado
E é exibida mensagem indicando que Classificação gerencial é obrigatória
E o registro permanece na etapa anterior
```

**CA-02 — Bloqueio sem Denominação**
```gherkin
Dado que existe um <Objeto> com Classificação gerencial preenchida e Denominação vazia
Quando o usuário tenta enviar o registro para a aprovação da diretoria
Então o envio é bloqueado
E é exibida mensagem indicando que Denominação é obrigatória
E o registro permanece na etapa anterior
```

**CA-03 — Bloqueio com os dois campos vazios**
```gherkin
Dado que existe um <Objeto> com Classificação gerencial e Denominação vazias
Quando o usuário tenta enviar o registro para a aprovação da diretoria
Então o envio é bloqueado
E a mensagem indica os dois campos
```

**CA-04 — Envio liberado com os dois campos preenchidos**
```gherkin
Dado que existe um <Objeto> com Classificação gerencial e Denominação preenchidas
Quando o usuário envia o registro para a aprovação da diretoria
Então o envio é aceito
E o registro segue para a etapa de aprovação
```

**CA-05 — Não bloqueia edição fora da aprovação**
```gherkin
Dado que um <Objeto> está com Classificação gerencial vazia
Quando o usuário salva alterações em outros campos sem enviar para a aprovação
Então a gravação é aceita
```
> Observação: CA-05 é um critério de *não-regressão* e depende de D-03 (se a obrigatoriedade
> vale só na submissão, ou também em salvamentos). Se a resposta for "sempre obrigatório",
> CA-05 deve ser reescrito.

**CA-06 — Registros já em aprovação ou aprovados**
```gherkin
Dado que um <Objeto> já foi enviado para aprovação antes da mudança e está com algum campo vazio
Quando a regra entra em vigor
Então o registro não é reprocessado nem bloqueado retroativamente
```
> Depende de D-05. Este cenário é uma premissa (P-03) até ser confirmado.

**CA-07 — Permissão**
```gherkin
Dado um usuário sem permissão para editar Classificação gerencial ou Denominação
Quando tenta enviar um registro para aprovação com esses campos vazios
Então o comportamento é o definido em D-06
```
> Placeholder. A regra de negócio para esse caso ainda não existe na demanda.

## 5. O que a demanda NÃO diz (dúvidas em aberto, bloqueantes para o design)

| ID | Dúvida | Por que bloqueia |
|----|--------|------------------|
| **D-01** | Em qual **objeto** Salesforce ficam Classificação gerencial e Denominação? | Sem isso não há como localizar os campos nem escrever os critérios com nomes reais. |
| **D-02** | Qual é o **processo de aprovação** ("aprovação da diretoria") e qual é o gatilho exato de "seguir com a aprovação": clicar em enviar, passar de uma etapa de status, ou a aprovação automática do processo? | Muda a solução: regra de validação, campo obrigatório no layout, Flow ou alteração do processo de aprovação são caminhos diferentes. |
| **D-03** | A obrigatoriedade vale **só na submissão para aprovação** ou também em qualquer salvamento do registro? | Determina se a regra é condicional ao status (mais simples) ou incondicional (afeta toda edição, inclusive de quem não aprova). |
| **D-04** | A regra vale para todos os usuários, ou há perfis/papéis isentos? | Afeta a escolha entre validação global e validação por perfil. |
| **D-05** | Registros já existentes sem o campo preenchido: devem ser corrigidos em lote, ficam como estão, ou só bloqueiam na próxima edição? | Afeta se há necessidade de script de saneamento. Também define o escopo de CA-06. |
| **D-06** | Qual é o comportamento para usuário sem permissão de edição nesses campos? | Hoje não há regra para esse caso (ver CA-07). |
| **D-07** | "Walmor" é o aprovador final ou representa um grupo/papel? Quem é o público que vai receber a mensagem de bloqueio? | Define quem valida a aceitação e onde o texto da mensagem deve aparecer (tela, e-mail, etc.). |
| **D-08** | Qual é o texto esperado para a mensagem de erro? | Necessário para o critério de aceite ser verificável por texto exato. Pode ser definido pelo consultor. |
| **D-09** | Existe um **anexo de detalhamento** citado na demanda ("Detalhamento anexo"). Ele não está no repositório: `demandas/SOMOSAGILITY-12/` contém apenas `demanda.md` e `status.yaml`. | **Lacuna real.** O conteúdo do anexo não foi inventado. Pode conter regras que mudam esta análise inteira. Precisa ser enviado pelo consultor antes do design. |
| **D-10** | Existe um motivo de negócio, prazo ou SLA associado? | Não bloqueia o design, mas é necessário para priorização. |

**Bloqueantes para avançar ao arquiteto:** D-01, D-02, D-03, D-09. As demais podem ser
respondidas durante o design ou o build, mas D-05 e D-06 precisam ser fechadas antes do QA.

## 6. Premissas a validar (pendentes, não confirmadas)

Estas premissas foram assumidas apenas para escrever os critérios acima. Qualquer uma delas
pode estar errada e deve ser confirmada antes do gate.

- **P-01 (pendente):** os dois campos existem na org de dev do cliente e são campos padrão ou
  custom já em uso. *Não confirmado via `sf` CLI.* Esta análise não consultou a org.
- **P-02 (pendente):** existe um processo de aprovação ativo que dispara a "aprovação da
  diretoria" a partir do registro. *Não confirmado.*
- **P-03 (pendente):** registros já enviados antes da mudança não serão afetados
  retroativamente (ver D-05 e CA-06).
- **P-04 (pendente):** a obrigatoriedade é aplicada igualmente a todos os usuários com acesso
  ao registro (ver D-04).
- **P-05 (pendente):** a regra é uma restrição de preenchimento, e não uma mudança de fluxo
  de aprovação.

## 7. Contexto do cliente e restrições conhecidas

Conforme `clients/somos-agility/CLAUDE.md`, o briefing da conta ainda está em branco nos campos
de segmento, contatos, clouds, URLs das sandboxes, convenções de nomenclatura, integrações e
regras específicas. A seção "Saúde da org" também não foi preenchida, porque o assessment
ainda não rodou. **Não há nenhuma informação confirmada sobre a org além de sua existência
como cliente na esteira.**

Restrições de guardrail aplicáveis (do `CLAUDE.md` raiz):

- Nenhuma consulta a produção. Toda verificação de metadata é feita na sandbox de dev.
- Nenhum dado real de cliente pode aparecer em SOQL ou em evidências. A validação dos campos
  será feita só com metadata e contagens agregadas.
- Build em `feature/SOMOSAGILITY-12`, com PR e revisão humana.

## 8. Complexidade estimada

**P (pequena), com ressalva.** A mudança em si (uma regra de validação ou a obrigatoriedade de
um campo) é pequena. Porém, a complexidade real depende de D-02 e D-05. Se a aprovação for feita
por um processo com regras customizadas, ou se for preciso saneamento de registros antigos, a
estimativa sobe para M.

## 9. Próximos passos

1. Consultor responde D-01 a D-10, com prioridade para D-09 (anexo) e D-02.
2. Humano aprova este refinamento (gate da etapa 1).
3. `org-recon` confirma objetos, campos e processo de aprovação via `sf` CLI, e substitui os
   placeholders dos critérios pelos nomes reais.
4. Arquiteto desenha a solução (declarativo: regra de validação, campo obrigatório ou Flow;
   ou alteração do processo de aprovação).

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
