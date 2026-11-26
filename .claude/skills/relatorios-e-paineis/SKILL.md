---
name: relatorios-e-paineis
description: Checklist do builder declarativo para entregar relatório e painel que respondem à pergunta do cliente — formato, agrupamento, filtro, pasta, quem enxerga e conferência antes do QA. Use no build de toda demanda que cria ou altera relatório ou painel.
---

# Relatórios e painéis

O formato do XML, os enums que o deploy recusa e o que a Analytics API devolve estão na
skill `salesforce-doutrina`, seção "Relatórios e painéis por metadata" (EPLAST-39). **Leia
aquela seção primeiro**; aqui está o que conferir como entrega, não como sintaxe.

## Comece pela pergunta

Cada relatório responde a uma pergunta do cliente. Escreva a pergunta no plano de build, ao
lado do nome do relatório: "quantas oportunidades cada vendedor ganhou no trimestre". Se não
dá para escrever a pergunta, o critério de aceite está vago: pare e reporte.

Da pergunta saem as decisões:

| Decisão | De onde vem |
|---|---|
| Tipo de relatório | Os objetos que a pergunta cruza. Confira pelo describe do tipo que as colunas existem e que o usuário tem acesso |
| Formato | Alimenta gráfico de painel? Então resumo ou matriz, nunca tabular puro |
| Agrupamento | O "por" da pergunta ("por vendedor", "por mês") |
| Filtro de data | Relativo ("este trimestre"), não data fixa, para o relatório não envelhecer |
| Escopo | "Meus", "do meu time" ou "todos": é regra de negócio, confirme no design |
| Colunas | Só as que respondem à pergunta. Coluna com dado pessoal só se o critério pedir |

## Vazio e fora da lista

Decida, com o design, o que acontece com registro sem valor no campo de agrupamento e com
valor fora da lista esperada. O que a metadata não consegue fazer (rótulo próprio para o
vazio, linha única "fora da lista") é ajuste manual na tela ou limitação declarada no
plano, nunca promessa.

## Pasta e acesso

- Relatório e painel ficam em pasta própria da entrega, com nome que o cliente reconhece.
  Nunca na pasta pessoal nem em pasta pública geral.
- O acesso à pasta vai a grupo ou papel, conforme o design. Diga no plano quem enxerga.
- Quem não tem permissão ao campo ou ao objeto vê o relatório vazio ou com erro. Escreva no
  plano o que cada perfil afetado vê, e inclua os campos no permission set da demanda.
- Painel roda como um usuário fixo ou como quem está olhando. Fixo mostra a todos o que
  aquele usuário vê, inclusive o que o observador não poderia ver: é decisão do design, e
  o usuário fixo não pode ser uma pessoa que sai da empresa.

## Painel

- Cada componente tem título que diz o que mede e o período.
- Um componente, uma pergunta. Painel com vinte componentes ninguém lê: se o critério pede
  tanto, proponha dois painéis.
- Componentes que comparam a mesma medida usam a mesma unidade e o mesmo período.

## Antes de escrever "concluído"

- [ ] Cada relatório tem a pergunta que responde, escrita no plano.
- [ ] Deploy passou e cada relatório **executa** na dev (Analytics API), sem erro.
- [ ] Cada componente do painel renderiza: sem `errorCode`, e com dado quando há dado de
      teste.
- [ ] Há dado de teste que cobre cada agrupamento, inclusive o vazio, e o plano diz de
      onde veio e quem apaga.
- [ ] Pasta, quem enxerga e o usuário de execução do painel estão no plano.
- [ ] O que é ajuste manual na tela está listado como passo pós-deploy.

Na conferência, leia só rótulos e contagens agregadas. Nunca copie linha de detalhe de
relatório para artefato ou captura (guardrail #2).
