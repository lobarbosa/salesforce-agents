# Roteiro de teste — Origem dos leads e retorno das campanhas

Foi entregue um painel de Marketing, "Marketing - Origem e Retorno de Campanhas", com relatórios de origem dos leads (agrupados nas 10 origens da Eplast mais "Sem origem" e "Outros"), conversão por origem, oportunidades por origem, desempenho das campanhas (custo, receita ganha e ROI) e um relatório que mostra o valor original de cada origem. Para quem usa: o período padrão é o mês atual e os dados originais dos leads não são alterados.

**Situação do teste automático:** comprovado pelo time na sandbox de QA, com dados de teste já apagados: agrupamento das origens, linha "Sem origem", painel com dado nos 5 componentes, ROI e "Não calculável", texto "Não é faturamento" e o filtro de mês atual. Ficam para quem segue o roteiro: a conferência pela tela, o cálculo de ROI com seus dados e o acesso de quem só tem permissão de leitura (o time não tinha usuário sem acesso de administrador).

## Antes de começar
- Ambiente: sandbox QAS da Eplast (a de homologação).
- Perfil: usuário de Marketing com o conjunto de permissões "Análise de campanhas de Marketing" e que seja membro do grupo da pasta de relatórios (a atribuição é feita pela Eplast).
- Dado de teste: crie 1 lead com nome "TESTE EPLAST-39 A", sem preencher a Origem; 1 lead "TESTE EPLAST-39 B" com Origem "Site"; 1 lead "TESTE EPLAST-39 C" com Origem "Parceiros". Crie 1 campanha "TESTE EPLAST-39 Campanha", com Data de início de hoje e Custo real 1000, e outra "TESTE EPLAST-39 Campanha sem custo", com início hoje e sem custo. Vincule uma oportunidade ganha de R$ 2.500 à primeira.

## Teste 1 — Origem vazia aparece como "Sem origem"
1. Abra o menu Painéis e entre em "Marketing - Origem e Retorno de Campanhas".
2. Clique em Atualizar.
3. Olhe o gráfico "Leads por Origem".

**Resultado esperado:** existe a linha "Sem origem" com pelo menos o lead de teste A. Nenhuma linha aparece com "-".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Origens parecidas viram uma só
1. No mesmo gráfico, procure "Site/formulário" e "Parceiros".

**Resultado esperado:** o lead B conta em "Site/formulário" e o lead C em "Parceiros". Só existem as 10 origens da Eplast, "Sem origem" e "Outros".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — A soma das origens fecha com o total
1. Abra o relatório "MKT Leads por Origem" (pasta Marketing Origem e Retorno).
2. Some as linhas de cada origem.
3. Compare com o total do rodapé.

**Resultado esperado:** a soma das origens é igual ao total de leads criados no mês.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — O valor original do lead é preservado
1. Abra o relatório "MKT Origem Original por Grupo".
2. Procure o grupo "Outros".

**Resultado esperado:** dentro de cada grupo aparece cada valor original de Origem do lead (por exemplo "WhatsApp" e "Campanha" dentro de "Outros"). Abra o lead de teste B: a Origem continua "Site".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Período padrão é o mês atual
1. Abra o relatório "MKT Leads por Origem".
2. Confira o filtro de data de criação.
3. Troque para o trimestre e clique em Executar.

**Resultado esperado:** abre com o mês atual (novembro de 2026); ao trocar para trimestre, os números são recalculados. No relatório "MKT Desempenho de Campanhas" só aparecem campanhas com início no mês atual.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Retorno da campanha (ROI)
1. Abra o relatório "MKT Desempenho de Campanhas".
2. Localize "TESTE EPLAST-39 Campanha".

**Resultado esperado:** custo real R$ 1.000, receita atribuída R$ 2.500 e ROI 150%. Há uma única coluna de retorno.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Campanha sem custo
1. No mesmo relatório, localize "TESTE EPLAST-39 Campanha sem custo".
2. Abra a campanha e veja o campo "Situação do ROI".

**Resultado esperado:** o ROI aparece em branco ("-"), sem erro, e o campo mostra "Não calculável". Na campanha com custo, mostra "Calculável". O painel informa que receita atribuída não é faturamento.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem só tem leitura não edita
1. Entre com um usuário que tenha só o conjunto de permissões de Marketing (sem perfil de administrador).
2. Abra o painel e os relatórios da pasta.
3. Tente editar um lead e uma campanha.

**Resultado esperado:** o painel e os relatórios abrem; a edição do lead e da campanha é negada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- As 10 origens e o agrupamento: Instagram e Facebook viram "Redes sociais orgânicas"; WhatsApp, Campanha, E-mail MKT e Prospecção passiva viram "Outros"; Econodata e SDR viram "Prospecção ativa/SDR". Está certo?
- Valores como "Site", "Meta Ads" e "Parceiros" não existem na lista de origens do lead; foram tratados como equivalentes, sem criar valor novo.
- O período do mês atual das campanhas usa a Data de início da campanha; o das oportunidades, a data de criação.
- O retorno usa só o cálculo padrão do Salesforce (ROI) e a campanha principal da oportunidade; sem custo real, mostra "Não calculável".
- Não corrigimos nenhum lead existente; a limpeza de origem vazia é da Eplast.
- Depois do deploy, a Eplast atribui o conjunto de permissões e inclui os usuários no grupo da pasta.

## O que não dá para conferir pela tela
A igualdade do texto das duas fórmulas de agrupamento (lead e oportunidade) e a ausência de Flow, código ou e-mail no pacote: evidência em `05-testes.md`.
