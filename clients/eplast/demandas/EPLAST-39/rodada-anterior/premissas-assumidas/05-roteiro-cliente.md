# Roteiro de teste — Origem dos leads e retorno das campanhas

Foi entregue um painel de Marketing com relatórios que mostram de onde vêm os leads, quais origens viram oportunidade e quanto cada campanha retorna. Para quem usa: leads sem origem aparecem como "Sem origem" e origens fora da lista padrão aparecem juntas como "Fora da lista".

**Situação do teste automático:** o time já executou na QA os testes de soma por origem, "Sem origem", "Fora da lista", período, conversão, retorno da campanha e campanha sem custo, com dado de teste, e todos passaram. Ficou para quem segue este roteiro conferir a tela e o acesso de um usuário real de Marketing (o time só testou com administrador).

## Antes de começar
- Ambiente: sandbox de homologação (QAS).
- Perfil: usuário de Marketing com o conjunto de permissões "PS Marketing Análise de Campanhas" atribuído (a Eplast atribui). Sem ele, dois quadros do painel mostram erro; isso é esperado.
- Dado de teste: crie uma campanha "TESTE EPLAST-39 Com Custo" com Custo real 1.000 e uma oportunidade ganha de 2.500 ligada a ela; outra campanha "TESTE EPLAST-39 Sem Custo" com uma oportunidade ganha de 700. Crie um lead de teste sem Origem e outro com Origem preenchida por um texto fora da lista.

## Teste 1 — Leads por origem somam o total
1. Abra Relatórios e a pasta "Marketing Origem e Retorno".
2. Abra "MKT Leads por Origem".
3. Some as linhas de origem e compare com o total do relatório.

**Resultado esperado:** a soma das linhas é igual ao total.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead sem origem
1. No mesmo relatório, procure a linha "Sem origem".

**Resultado esperado:** existe a linha "Sem origem" com o número de leads sem origem; nenhuma linha aparece com "-".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Origem fora da lista
1. No mesmo relatório, procure "Fora da lista".

**Resultado esperado:** o lead de teste com origem inventada está contado em "Fora da lista", e o texto inventado não aparece como linha própria.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Período
1. No relatório, altere o filtro de data de criação para "Este mês" e depois "Mês passado".

**Resultado esperado:** os números mudam conforme o período e a soma das linhas continua igual ao total.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conversão por origem
1. Abra "MKT Conversão de Leads por Origem".

**Resultado esperado:** a taxa de cada origem é leads convertidos dividido pelo total de leads daquela origem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Retorno da campanha
1. Abra "MKT Desempenho de Campanhas".
2. Localize "TESTE EPLAST-39 Com Custo".

**Resultado esperado:** a coluna "Receita ganha / custo real" mostra 2,50.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Campanha sem custo
1. No mesmo relatório, localize "TESTE EPLAST-39 Sem Custo".

**Resultado esperado:** a coluna "Receita ganha / custo real" fica em branco ("-"), sem mensagem de erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Painel
1. Abra Painéis e "Marketing - Origem e Retorno de Campanhas".
2. Clique em Atualizar.

**Resultado esperado:** os cinco quadros mostram dado, sem mensagem de erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Só leitura
1. Com o usuário de Marketing, tente editar um lead e uma campanha.
2. Abra um relatório da pasta.

**Resultado esperado:** a edição é negada e o relatório abre.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Origem vazia:** decidimos o rótulo "Sem origem". Para mudar, é troca de um texto.
- **Origem fora da lista:** decidimos agrupar em "Fora da lista". Para ver cada uma separada, ajusta-se o relatório.
- **Retorno da campanha:** decidimos receita das oportunidades ganhas dividida pelo custo real. Para usar custo estimado ou margem, ajusta-se a fórmula.
- **Campanha sem custo:** fica em branco, não "n/a". Mostrar texto exigiria um campo novo.
- **Período:** filtro em cada relatório, não no painel; relatórios de desempenho e de resposta ficam sem filtro de período.
- **Origem da oportunidade:** o relatório de oportunidades usa a origem como está, e vazio aparece como "-".
- **Atribuição:** vale a origem do lead (primeiro contato), sem multi-toque.
- **Quem acessa:** a Eplast atribui o conjunto de permissões aos usuários de Marketing depois do deploy.
- **Qualidade da origem:** o painel não corrige dado; quem corrige as origens vazias a Eplast define.
- **Marketing Cloud:** nada foi feito nele; o painel usa só dados do CRM.

## O que não dá para conferir pela tela
Que nenhum relatório ou painel existente foi alterado e que não há envio de e-mail nem automação nova: a evidência está em `05-testes.md` (casos T10 e T12).
