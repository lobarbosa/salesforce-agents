# ACXYA-1 — Criação de campo: Data de aniversário do prospect (Lead)

## Contexto de negócio
A operação comercial precisa registrar a data de nascimento (aniversário) do prospect
diretamente no cadastro de Lead. Hoje, segundo a demanda registrada, esse dado não tem um
campo dedicado no objeto Lead. Não há, na demanda original, indicação de para que essa
informação será usada além de "inserção" — presume-se uso comercial (ex.: campanhas de
relacionamento, contato em data comemorativa), mas isso é suposição e está registrado como
pendência abaixo, não como fato.

## Objetivo
Disponibilizar no objeto **Lead** um campo para registrar a data de nascimento do prospect,
permitindo que usuários (ou processos de integração) preencham essa informação durante o
ciclo de vida do Lead.

## Regra de negócio
Nenhuma regra de negócio foi explicitada na demanda além da existência do campo. Não há
menção a:
- validação de valor (ex.: impedir data futura, impedir idade implausível);
- obrigatoriedade de preenchimento;
- quem preenche o campo (usuário manual, integração, formulário web-to-lead, import);
- comportamento na conversão do Lead (se o valor deve ser copiado para Contact/Account).

Por não haver regra de negócio explícita, nenhuma regra foi inventada. Todos os pontos
acima estão listados em "Premissas a validar" e "Perguntas abertas".

## Critérios de aceite (Gherkin)

```gherkon
Cenário: CA-01 — Campo de data de aniversário existe no Lead
  Dado que estou visualizando um registro de Lead
  Quando acesso o layout de página do Lead (layout a confirmar — ver pendências)
  Então existe um campo do tipo Date rotulado como aniversário/data de nascimento do prospect
  E o campo está disponível para edição por usuários com permissão de edição de Lead

Cenário: CA-02 — Campo aceita datas passadas válidas
  Dado que estou editando um registro de Lead
  Quando informo uma data de nascimento válida no passado (ex.: 01/01/1990)
  E salvo o registro
  Então o valor é persistido no campo sem erro
  E o valor é exibido corretamente no formato de data padrão da org ao reabrir o registro

Cenário: CA-03 — Campo é do tipo correto
  Dado o campo de data de aniversário criado no objeto Lead
  Quando inspeciono o metadata do campo
  Então o tipo é Date (não Date/Time) — a confirmar com o solicitante (ver pendências)

Cenário: CA-04 — [PENDENTE DE DEFINIÇÃO] Validação de data futura
  Este critério não pode ser escrito como testável até que se defina se datas futuras
  devem ser bloqueadas. Não incluído na entrega até resposta do solicitante.

Cenário: CA-05 — [PENDENTE DE DEFINIÇÃO] Comportamento na conversão de Lead
  Este critério não pode ser escrito como testável até que se defina se o valor deve
  ser mapeado para Contact e/ou Account na conversão do Lead. Não incluído na entrega
  até resposta do solicitante.
```

Observação: CA-04 e CA-05 são mantidos como "cenários pendentes" propositalmente, para
deixar explícito que são lacunas de critério de aceite, não critérios já definidos.

## O que a demanda NÃO diz (perguntas abertas para o solicitante)

1. **Nome/API name do campo.** A convenção de prefixo de campo custom do cliente Konecta
   ainda não está definida no `CLAUDE.md` do workspace acxya (está como "a confirmar").
   Sem prefixo definido, não é possível propor o API name final (`<Prefixo>_<Contexto>__c`
   conforme skill `padrao-entrega`). **Bloqueia o desenho do arquiteto.**
2. **Tipo do campo: Date ou Date/Time?** A demanda diz apenas "data de aniversário", o que
   sugere Date, mas não foi confirmado explicitamente pelo solicitante.
3. **Validação de data.** É necessário impedir data futura? Impedir datas implausíveis
   (ex.: idade > 120 anos)? Nenhuma regra foi mencionada.
4. **Obrigatoriedade.** O campo é obrigatório no preenchimento do Lead ou opcional?
5. **Layout e Record Type.** Em qual(is) layout(s) de página o campo deve aparecer? Existem
   múltiplos Record Types de Lead nesta org? Não foi possível confirmar — nenhuma org está
   autenticada nesta sessão; fica para a etapa 2 (recon) verificar Record Types e layouts
   existentes de Lead antes do desenho.
6. **Origem do preenchimento.** O campo será preenchido manualmente por usuário, via
   formulário Web-to-Lead, via integração/import, ou todas as anteriores? Isso impacta se
   é necessário campo visível/editável em formulários externos.
7. **Reporting/segmentação.** Há necessidade de relatórios, dashboards ou listas segmentadas
   por essa data (ex.: "aniversariantes do mês")? Isso pode implicar em campo de fórmula
   adicional (ex.: mês do aniversário) para viabilizar filtros — não solicitado, não incluído.
8. **Conversão de Lead → Contact/Account.** Ao converter o Lead, o valor deve ser mapeado
   automaticamente para o campo equivalente em Contact (Contact já tem campo nativo
   `Birthdate`)? Se sim, isso é um mapeamento de conversão de Lead (configuração declarativa
   adicional), não coberto implicitamente pela demanda original.
9. **Campo já existe?** Não foi confirmado via `sf` CLI se já existe um campo equivalente no
   Lead desta org (nenhuma org autenticada nesta sessão). **Fica formalmente como pendência
   para a etapa 2 — org-recon** — antes de qualquer desenho, o recon deve confirmar
   inexistência do campo para evitar duplicidade.

## Premissas a validar (nenhuma foi assumida como definitiva)

| # | Premissa | Status |
|---|----------|--------|
| P1 | Campo é do tipo Date (não Date/Time) | **Confirmado pelo solicitante** |
| P2 | Campo bloqueia data futura (Validation Rule) | **Confirmado pelo solicitante** — sai do escopo P, entra Validation Rule |
| P3 | Obrigatoriedade do campo | Ainda pendente — não perguntado nesta rodada, assumir opcional até dizerem o contrário |
| P4 | Valor deve ser mapeado para `Contact.Birthdate` na conversão do Lead | **Confirmado pelo solicitante** — precisa configurar Lead Conversion Field Mapping |
| P5 | Um único layout de Lead é usado (não há Record Type segregando o layout) | Pendente — depende do recon (etapa 2) |
| P6 | Prefixo de campo custom do cliente | **Resolvido**: nenhum prefixo — registrado em `clients/acxya/CLAUDE.md`. Campo: `Data_Aniversario__c` |

## Decisões do solicitante (registradas em 2026-09-06, via gate de aprovação da análise)
- Tipo do campo: **Date**.
- Validação: **bloquear data futura** — vira `ValidationRule` no design.
- Conversão de Lead: **mapear para `Contact.Birthdate`** — vira configuração de Lead Conversion Field Mapping no design.
- Prefixo de campo: **nenhum** — API name proposto: `Data_Aniversario__c`.

Com P2 e P4 confirmados, a estimativa de complexidade sobe de **P para M**: além do campo,
o design agora inclui uma Validation Rule e a configuração de mapeamento de conversão de Lead
— ambos declarativos, não muda a escolha declarativo vs. código, só o escopo do build.

## Estimativa de complexidade
**P (Pequeno).** Criação de um único campo custom em um objeto padrão, sem lógica de
automação aparente na demanda original — a complexidade real depende das respostas às
perguntas 3, 4 e 8 (validação, obrigatoriedade e mapeamento de conversão), que podem elevar
o escopo para M se exigirem Validation Rule e/ou ajuste de Lead Conversion Field Mapping.

## Dúvidas que mudam a arquitetura — não decididas por este agente
Nenhuma das perguntas acima altera a escolha entre declarativo vs. código por si só (criação
de campo é inerentemente declarativa). Porém, os itens 3 (validação) e 8 (mapeamento de
conversão) podem introduzir a necessidade de Validation Rule ou configuração de Lead
Conversion — decisão que cabe ao arquiteto na etapa 3, após estas respostas.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
