# SOMOSAGILITY-8 — DEPV: ajuste no fluxo de aprovação

- **Cliente:** somos-agility
- **Tipo:** Sustentação (melhoria)
- **Fontes:** `demanda.md` (história do consultor) + resumo funcional do anexo PDF (e-mail de Governança/PMO, higienizado: nomes, e-mails, telefones e valores removidos).
- **Status:** rascunho para validação humana. Nada aqui foi confirmado contra a org ainda.

---

## 1. Contexto de negócio

O processo de aprovação de **Despesa Extraordinária de Venda (DEPV)** passa por três aprovações. Governança/PMO pede dois ajustes:

1. Garantir que a **Classificação gerencial** seja preenchida na aprovação feita pelo Diretor Financeiro, para que o registro não avance sem essa informação.
2. Padronizar o **layout e os destinatários das notificações** de 1ª/2ª aprovação, 3ª aprovação e aprovação final, para que cada aprovador receba os campos de decisão e o aviso certo.

O anexo sugere que DEPV é um objeto customizado (há um link de registro com prefixo `a2C...`). Isso **não está confirmado** e fica para o recon.

## 2. Objetivo

Fazer com que (a) nenhuma DEPV passe pela aprovação do Diretor Financeiro sem Classificação gerencial preenchida, e (b) as notificações de cada etapa tragam os campos listados no template de referência e cheguem aos destinatários definidos pelo solicitante, sem alterar as regras de quem aprova o quê.

## 3. Regras de negócio (como entendidas)

- **RN1 — Campo obrigatório na aprovação do Diretor Financeiro.** Ao aprovar, o Diretor Financeiro deve preencher "Classificação gerencial". A etapa exata em que isso ocorre (1ª, 2ª ou 3ª) **não está definida**.
- **RN2 — Notificação de 1ª e 2ª aprovação** (ao aprovador seguinte, para qualificação):
  - Campos: ID da solicitação DEPV, Proprietário, Oportunidade, Justificativa do Investimento, Recuperação do Investimento, Valor Total Nominal Terceiros, Valor Total Nominal Agility, Valor Total, link de acesso ao registro.
  - Destinatários adicionais: duas pessoas nomeadas no anexo (a obter do solicitante, ver seção 6) e o grupo **Agility GOV**.
- **RN3 — Notificação de 3ª aprovação** (aprovação final):
  - Mesmos campos da RN2, mais campo **Comentários**.
  - Aviso ao grupo **Operações** lembrando que a Classificação gerencial precisa estar preenchida.
  - Destinatários adicionais: quatro pessoas nomeadas no anexo (a obter do solicitante) e os grupos **Operações** e **Agility GOV**.
- **RN4 — Notificação "final / Aprovada"** ao solicitante, com saudação nominal, comentários e link. Campos bem mais reduzidos que RN2/RN3. **Não está claro se é um template distinto ou uma variação da RN3** (ver pergunta 8).

## 4. Critérios de aceite (rascunho, testáveis após as respostas da seção 5)

Os cenários usam `[PENDENTE]` onde a demanda não diz. Não são executáveis até o pendente ser resolvido.

```gherkin
Funcionalidade: Classificação gerencial obrigatória na aprovação do Diretor Financeiro

  Cenário: Diretor Financeiro tenta aprovar sem Classificação gerencial
    Dado uma DEPV na etapa [PENDENTE: 1ª, 2ª ou 3ª] aguardando a decisão do Diretor Financeiro
    E o campo "Classificação gerencial" está vazio
    Quando o Diretor Financeiro tenta concluir a aprovação
    Então a aprovação não é concluída
    E a DEPV permanece na mesma etapa
    E é exibida mensagem de erro no campo "Classificação gerencial" [PENDENTE: texto da mensagem]

  Cenário: Diretor Financeiro aprova com Classificação gerencial preenchida
    Dado uma DEPV na etapa [PENDENTE] aguardando a decisão do Diretor Financeiro
    Quando o Diretor Financeiro preenche "Classificação gerencial" com valor [PENDENTE: valor válido da lista] e conclui a aprovação
    Então a aprovação é concluída
    E a DEPV avança para a próxima etapa

  Cenário: Aprovador que não é o Diretor Financeiro não é bloqueado pelo campo
    Dado uma DEPV aguardando a decisão de um aprovador que não é o Diretor Financeiro
    Quando o aprovador conclui a aprovação sem preencher "Classificação gerencial"
    Então a aprovação é concluída normalmente
```

```gherkin
Funcionalidade: Notificação de 1ª e 2ª aprovação

  Cenário: Aprovador seguinte recebe a notificação com os campos do template
    Dado uma DEPV em que a 1ª [ou 2ª] aprovação foi concluída
    Quando a notificação é disparada
    Então ela contém os campos: ID da solicitação, Proprietário, Oportunidade, Justificativa do Investimento, Recuperação do Investimento, Valor Total Nominal Terceiros, Valor Total Nominal Agility e Valor Total
    E contém link que abre o registro da DEPV
    E [PENDENTE: ordem e formatação dos campos, conforme template de referência]

  Cenário: Destinatários da notificação de 1ª e 2ª aprovação
    Dado a notificação de 1ª [ou 2ª] aprovação disparada
    Então ela é entregue ao aprovador seguinte [PENDENTE: confirmar se entra]
    E aos destinatários adicionais definidos pelo solicitante [PENDENTE: lista de 2 pessoas]
    E ao grupo "Agility GOV"

  Cenário: Campo sem valor na DEPV
    Dado uma DEPV com algum dos campos da notificação vazio
    Quando a notificação é disparada
    Então o campo aparece [PENDENTE: vazio, traço ou ocultado]
```

```gherkin
Funcionalidade: Notificação de 3ª aprovação

  Cenário: Notificação final de aprovação contém campos e comentários
    Dado uma DEPV em que a 3ª aprovação foi concluída
    Quando a notificação é disparada
    Então ela contém os campos da notificação de 1ª e 2ª aprovação
    E contém o campo "Comentários" [PENDENTE: origem do campo, ver pergunta 9]
    E contém link que abre o registro da DEPV

  Cenário: Aviso ao grupo Operações sobre a Classificação gerencial
    Dado uma DEPV em que a 3ª aprovação foi concluída
    Quando a notificação é disparada
    Então o grupo "Operações" recebe aviso de que a "Classificação gerencial" deve estar preenchida
    E o aviso é entregue junto com o restante da notificação [PENDENTE: confirmar canal, ver pergunta 13]

  Cenário: Destinatários da notificação de 3ª aprovação
    Dado a notificação de 3ª aprovação disparada
    Então ela é entregue aos destinatários adicionais definidos pelo solicitante [PENDENTE: lista de 4 pessoas]
    E ao grupo "Operações"
    E ao grupo "Agility GOV"
```

```gherkin
Funcionalidade: Notificação final "Aprovada" ao solicitante

  # BLOQUEADO: não é possível escrever critérios até a pergunta 8 ser respondida.
  Cenário: [PENDENTE]
    Dado [PENDENTE]
    Quando [PENDENTE]
    Então [PENDENTE]
```

```gherkin
Funcionalidade: Não regressão

  Cenário: Notificações e aprovações fora do escopo permanecem como estavam
    Dado uma DEPV em qualquer etapa fora do escopo desta demanda
    Quando a aprovação é concluída
    Então as notificações e os campos obrigatórios dessa etapa são os mesmos de antes da mudança
    E [PENDENTE: lista das notificações atuais, a levantar no recon]
```

## 5. O que a demanda NÃO diz (responder antes do design)

1. **Etapa da Classificação gerencial.** A obrigatoriedade vale só na aprovação do Diretor Financeiro? Em qual das três aprovações ele atua?
2. **Campo "Classificação gerencial".** Já existe no objeto DEPV? Se existe: API name, tipo (picklist, texto?), lista de valores e se está no layout. Se não existe: quem define a lista de valores? A criação entra no escopo desta demanda?
3. **Objeto DEPV.** Qual o API name? É objeto customizado? (O anexo sugere, mas não confirma.)
4. **Mecanismo atual das notificações.** São Flow, Process Builder, Approval Process com email alert, ou Apex? Os templates são Lightning Email Templates ou HTML fixo?
5. **Notificação de 1ª/2ª aprovação.** O aprovador seguinte continua recebendo? Os destinatários novos substituem os atuais ou somam?
6. **Destinatários nomeados (2 + 4 pessoas).** São usuários do Salesforce ou endereços externos? Isso muda a implementação (usuário/grupo versus e-mail livre). A lista precisa vir do solicitante por canal fora deste repositório (ver seção 7).
7. **Grupos "Agility GOV", "Operações".** São Public Groups do Salesforce ou listas de e-mail externas? Quem gerencia os membros?
8. **Template "final / Aprovada".** É um terceiro template distinto ou variação da notificação de 3ª aprovação? Quando dispara (na conclusão da 3ª)? Substitui a RN3 ou convive com ela?
9. **Campo "Comentários" da 3ª aprovação.** É campo existente (comentário do passo de aprovação, por exemplo) ou novo?
10. **Link de acesso.** Aponta para o registro no Lightning? Qual URL base é usada para sandbox e para produção?
11. **Registros em andamento.** A obrigatoriedade e o novo layout valem para DEPVs já aprovadas parcialmente na data da entrega?
12. **Mapeamento de campos.** "Valor Total Nominal Terceiros", "Valor Total Nominal Agility", "Valor Total" e "Recuperação do Investimento" são campos existentes? Formato de moeda e casas decimais?
13. **Aviso ao grupo Operações.** É texto no corpo do e-mail ou também tarefa/alerta no registro?
14. **Template de referência.** O anexo traz um layout de referência, mas só a lista de campos chegou até aqui. Ordem, rótulos e formatação precisam de print ou especificação.
15. **Homologação.** Quem valida o texto e o layout final? Quem é o aprovador de negócio que testa o fluxo em QA?
16. **Prazo.** Há data-alvo ou janela de deploy definida pelo cliente?

## 6. Premissas a validar (PENDENTE, não confirmadas)

- **P1.** DEPV é objeto customizado, a confirmar via `sf` no recon.
- **P2.** O mecanismo das notificações é declarativo (Flow / Approval Process / email templates), sem Apex. Se for Apex, a complexidade sobe.
- **P3.** O campo "Classificação gerencial" já existe. Se não existir, a criação entra nesta demanda.
- **P4.** A obrigatoriedade vale só na etapa do Diretor Financeiro.
- **P5.** A demanda muda conteúdo e destinatários de notificação e o campo obrigatório. Não muda quem aprova cada etapa.
- **P6.** Os destinatários podem ser referenciados como usuários ou grupos existentes. Endereços externos exigiriam config adicional.
- **P7.** Não há migração de dados.

## 7. Dados pessoais

Os nomes e contatos dos destinatários (2 na RN2, 4 na RN3) e os responsáveis pela homologação **não estão neste artefato**, por guardrail #2. O consultor deve responder às perguntas 6 e 15 pelo card (comentários do card são lidos pela sessão, higienizados) ou em canal fora do repositório. A lista de endereços, quando chegar, vai para a configuração da org, não para este documento.

## 8. Complexidade: M

Três pontos de alteração (validação de campo na etapa, dois a três templates de notificação, listas de destinatários) mais um template ainda não esclarecido. Mecanismo e existência do campo ainda desconhecidos.

## 9. Estimativa de esforço

**Estimativa de esforço:** 6–14 h

Premissas que mais pesam na faixa:
- Mecanismo declarativo (Flow / Approval Process / email templates), sem Apex (P2).
- Campo já existe ou a criação é simples, sem lista de valores a definir (P3).
- Até três templates de notificação, com layout de referência já entregue (pergunta 14).
- Destinatários são usuários ou grupos existentes, sem endereço externo (pergunta 6).
- Consultor configura, testa em dev e qa com disparo real das notificações usando dados fictícios, e homologa.

Sobe para 16 h ou mais se: o campo precisar ser criado com lista de valores a definir, o mecanismo for Apex, ou o template "final / Aprovada" for um terceiro fluxo com regra própria.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
