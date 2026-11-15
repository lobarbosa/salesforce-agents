# Roteiro de teste — Origem dos leads e retorno das campanhas (EPLAST-39)

Foi entregue um painel de Marketing, com cinco relatórios, que mostra de onde vêm os leads, quantos viram oportunidade e quanto cada campanha retornou sobre o que custou. Quem tem acesso só consulta: não edita lead nem campanha. Nada é enviado por e-mail e nada muda no Marketing Cloud.

**Situação do teste automático:** o time conferiu que os relatórios, o painel e o acesso existem na sandbox QAS e que as permissões são só de leitura. Não conseguiu abrir os relatórios de origem e de conversão com dado, porque o usuário técnico do teste não tem o acesso de Marketing (e não pode recebê-lo). Hoje dois dos cinco quadros do painel dão erro para quem não tem esse acesso. Os testes 2 a 7 abaixo ficam para quem segue o roteiro, com o acesso atribuído.

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`).
- Perfil: um usuário de Marketing a quem foi atribuído o conjunto de permissões "PS Marketing Análise de Campanhas" e que está no grupo "Marketing Origem Retorno". Peça ao administrador para atribuir (Configuração > Usuários > o usuário > Conjuntos de permissões).
- Dados de teste: crie 6 leads com "TESTE EPLAST-39" no sobrenome e na empresa: 2 com origem "Google Ads", 1 com "SDR", 2 sem origem preenchida e 1 convertido (use "Converter" num dos de Google Ads). Se o valor de origem fora da lista não puder ser digitado, peça ao administrador para criá-lo. Crie uma campanha "TESTE EPLAST-39 Com custo" com Custo real 1.000 e uma "TESTE EPLAST-39 Sem custo" sem custo. Vincule à primeira uma oportunidade de teste ganha de R$ 3.000.

## Teste 1 — O painel abre sem erro
1. Abra Painéis > pasta "Origem e Retorno - Paineis".
2. Abra "Marketing - Origem e Retorno de Campanhas".
3. Clique em Atualizar.

**Resultado esperado:** os 5 quadros mostram dado, nenhum com mensagem de erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — A soma por origem fecha com o total
1. Abra Relatórios > pasta "Origem e Retorno" > "MKT Leads por Origem".
2. Some as contagens de cada origem.

**Resultado esperado:** a soma é igual ao Total geral. Há linhas para as origens usadas, mais "Sem origem" e "Fora da lista".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem origem aparece como "Sem origem"
1. No mesmo relatório, procure a linha dos leads sem origem.

**Resultado esperado:** a linha se chama "Sem origem" (nunca "-") e conta pelo menos os 2 leads de teste.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Origem fora da lista
1. Confira se existe um lead com origem que não é uma das 13 do campo Origem do lead.
2. No relatório, procure a linha "Fora da lista".

**Resultado esperado:** esse lead é contado em "Fora da lista" e o valor não aparece como linha própria.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Mudar o período
1. No relatório de leads, mude o filtro de data de criação para um mês sem leads, e depois para o mês atual.

**Resultado esperado:** o total muda com o período e a soma por origem continua igual ao total.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conversão por origem
1. Abra "MKT Conversão de Leads por Origem".

**Resultado esperado:** para cada origem, taxa = convertidos ÷ total daquela origem. Nos dados de teste, "Google Ads" mostra 50%.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Retorno por campanha
1. Abra "MKT Desempenho de Campanhas".
2. Veja a linha "TESTE EPLAST-39 Com custo" e a "TESTE EPLAST-39 Sem custo".

**Resultado esperado:** na campanha com custo, o retorno é 3,0 (R$ 3.000 ÷ R$ 1.000). Na campanha sem custo, o retorno fica em branco e não aparece erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Só leitura
1. Entre com o usuário que só tem o acesso de Marketing.
2. Abra um lead e uma campanha e tente editar.
3. Abra os relatórios da pasta "Origem e Retorno".

**Resultado esperado:** a edição não é permitida e os relatórios abrem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Os relatórios não mostram dado pessoal
1. Abra "MKT Leads por Origem".

**Resultado esperado:** só há totais por origem e mês, sem nome, e-mail, telefone ou CPF e sem lista de leads.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- A origem vem do campo Origem do lead. Lead sem origem aparece como "Sem origem"; valor fora das 13 origens da lista vira "Fora da lista". Os dados não são corrigidos.
- O retorno da campanha é receita ganha ÷ custo real, e ao lado aparece o ROI nativo ((ganho − custo) ÷ custo). Campanha sem custo fica em branco, não com "n/a".
- O relatório de oportunidades por origem usa a origem da própria oportunidade; vazio aparece como "-".
- O período é escolhido no filtro de data de cada relatório.
- Quem abre os relatórios precisa do acesso de Marketing (inclui executar relatórios), atribuído pela Eplast. Quem não o tem vê erro em dois quadros do painel.
- Quem entra no grupo e recebe o acesso é decidido pela Eplast, depois da entrega.
- Não há métrica do Marketing Cloud nesses relatórios.

## O que não dá para conferir pela tela
- Que nada existente foi alterado, que não há envio nem automação nova e que o acesso é só de leitura nas permissões: o time conferiu por consulta à org e ao repositório, em `05-testes.md`.
