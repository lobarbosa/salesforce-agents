---
name: modelo-de-dados-e-acesso
description: Critérios do arquiteto para decidir campo, relacionamento, tipo de registro, compartilhamento e permissão, e o que escalar ao humano. Use na etapa de design sempre que a demanda cria ou altera objeto, campo, relacionamento, tipo de registro ou quem enxerga o quê.
---

# Modelo de dados e acesso

Automação se refaz numa versão nova. Modelo de dados não: campo criado com o tipo errado,
relacionamento errado ou acesso aberto demais fica na org e vira dado. Por isso mudança de
modelo é decisão que o design **destaca e escala** ao arquiteto humano; esta skill serve
para levar a ele uma proposta fundamentada, não para decidir no lugar dele.

## Antes de criar um campo

- **Já existe?** Procure no recon campo com o mesmo significado, inclusive com outro nome.
  Campo duplicado é a dívida mais comum de org antiga.
- **Fórmula ou campo gravado?** Fórmula não ocupa armazenamento e nunca fica desatualizada,
  mas não dispara automação, tem limite de tamanho compilado e pesa em relatório e filtro
  de volume alto. Se o valor precisa disparar algo, ser filtrado em massa ou ser
  preservado como era na data, é campo gravado.
- **Picklist ou texto?** Se o valor será agrupado, filtrado ou comparado, é picklist, e
  restrita. Texto livre não se agrupa.
- **Obrigatório onde?** Obrigatório no campo vale para toda entrada, inclusive integração
  e carga; obrigatório no layout vale só para a tela. Regra que depende de fase ou de tipo
  é validation rule, com mensagem que diz o que preencher.
- **O que acontece com os registros que já existem?** Campo novo nasce vazio neles. Diga
  se isso é aceitável ou se há carga.
- Todo campo novo tem descrição e texto de ajuda, e entra no permission set da demanda e
  nos layouts que o design nomear.

## Relacionamento

| Pergunta | Lookup | Master-detail |
|---|---|---|
| O filho existe sem o pai? | sim | não |
| O acesso ao filho segue o pai? | não | sim |
| Apagar o pai apaga o filho? | não (configurável) | sim |
| Precisa de campo de resumo nativo no pai? | não | sim |

- Master-detail em objeto que já tem registros exige que todos tenham pai; diga como.
- Um pai com muitos filhos (dezenas de milhares) no mesmo registro causa bloqueio e
  lentidão na gravação. Se o recon mostra esse volume, declare o risco.
- Resumo em lookup precisa de automação; conte isso como componente e como risco de CPU.

## Tipo de registro

Tipo de registro serve para processo, layout ou valores de picklist diferentes. Não serve
para classificar: classificação é campo. Cada tipo novo multiplica layouts, atribuições por
perfil e casos de teste; diga quantos.

## Quem enxerga

Responda nesta ordem, e escreva a resposta no design:

1. **Padrão da organização** do objeto: privado, leitura ou leitura e gravação? Mudar o
   padrão de um objeto que já tem dados recalcula o compartilhamento de tudo e muda o que
   cada pessoa vê. É sempre item de escalada.
2. **Hierarquia de papéis**: o gestor deve ver o que é do time?
3. **Regras de compartilhamento**: quem mais precisa ver, e por qual critério.
4. **Permissão de objeto e de campo**: por permission set, nunca por perfil. O design nomeia
   o permission set da demanda e o que ele concede.
5. **Quem não deve ver**: dado sensível tem a permissão de campo negada por padrão e
   concedida só a quem precisa.

Escreva também o que cada perfil afetado vê quando **não** tem o acesso: painel vazio,
campo ausente do layout, botão que não aparece (EPLAST-39: painel vazio para quem não
tinha o campo).

## Dado pessoal

Campo novo que guarda dado pessoal (documento, contato, saúde, financeiro de pessoa) é
decisão do cliente e do responsável. Diga no design a finalidade, quem acessa e se o campo
aparece em relatório ou integração. Não crie por conveniência.

## Apagar e renomear

- Não se apaga campo nem objeto dentro de uma demanda comum: tira-se de uso (layout,
  permissão, descrição "em desuso desde...") e a remoção vira demanda própria, com backup.
- Renomear o nome de API quebra tudo o que o referencia. Mude o rótulo.

## O que vai em destaque para o arquiteto humano

- objeto novo, relacionamento novo ou mudança de tipo de campo;
- mudança de padrão de compartilhamento ou regra de compartilhamento nova;
- campo com dado pessoal;
- qualquer coisa que altere registros que já existem.

Cada item com as alternativas consideradas e a recomendada, em poucas linhas.
