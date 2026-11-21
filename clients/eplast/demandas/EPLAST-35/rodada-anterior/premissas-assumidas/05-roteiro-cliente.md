# EPLAST-35 — Roteiro de teste: distribuição de Leads por região

Foi entregue a distribuição automática de Leads: cada Lead novo vai para a fila da sua região (pelo Estado), e os que não têm Estado reconhecido vão para uma fila de triagem. Também foi criado um relatório de aprovações pendentes. Para quem usa, muda que o Lead novo deixa de ficar com quem o criou e passa para a fila da região, de onde o vendedor assume.

**Situação do teste automático:** o time já comprovou, na sandbox de homologação, a distribuição por região, a fila de triagem, o histórico de mudança de proprietário, os testes técnicos e que as três aprovações existentes continuam ativas. Ficaram para quem segue este roteiro: a caixa de atribuição na tela de novo Lead (a tela não abriu na automação), a criação de Lead por usuário de integração e a conversão de Lead.

## Antes de começar
- Ambiente: sandbox de homologação (QAS, `eplast--qas`). Nunca em produção.
- Perfil: um vendedor ou administrador que possa criar Leads.
- Use só dados de teste. Nome do Lead: "TESTE EPLAST-35 ..." e empresa "TESTE EPLAST-35". Não preencha telefone, e-mail nem CPF.
- Ao final, apague os Leads de teste.

## Teste 1 — Lead de São Paulo vai para a fila de SP
1. Abra a aba Leads e clique em Novo.
2. Confira se a caixa "Atribuir usando regra ativa" está marcada.
3. Preencha Sobrenome "TESTE EPLAST-35 SP", Empresa "TESTE EPLAST-35" e Estado "SP".
4. Salve.

**Resultado esperado:** o campo Proprietário mostra "Leads SP".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Outras regiões
Repita o Teste 1 trocando o Estado.

**Resultado esperado:** RJ vai para "Leads RJ"; MG para "Leads MG"; ES para "Leads ES"; PR, SC ou RS para "Leads Sul (PR, SC, RS)"; GO, DF, MT, MS ou TO para "Leads Centro-Oeste"; BA (ou outro Estado do Norte e Nordeste) para "Leads Norte e Nordeste".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Estado vazio ou escrito por extenso vai para a triagem
1. Crie um Lead sem Estado.
2. Crie outro com Estado "Sao Paulo" (por extenso).

**Resultado esperado:** os dois ficam com Proprietário "Leads Triagem". Nenhum fica sem proprietário.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Desmarcar a caixa mantém o Lead com você
1. Clique em Novo em Leads, desmarque "Atribuir usando regra ativa".
2. Preencha como "TESTE EPLAST-35 MEU", Empresa "TESTE EPLAST-35", Estado "SP". Salve.

**Resultado esperado:** o Proprietário é o seu próprio usuário.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Encaminhar o Lead e ver o histórico
1. Abra o Lead do Teste 1 e clique em "Alterar proprietário".
2. Escolha a fila "Leads RJ" e confirme.
3. Na aba Detalhes, abra o histórico do Lead (lista relacionada "Histórico do Lead").

**Resultado esperado:** o proprietário passa a "Leads RJ" e o histórico mostra a mudança de Proprietário, com data e quem alterou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Lead criado por integração
Só se houver um usuário de integração com o acesso "Distribuição de Lead (integração)" (veja "O que assumimos").
1. Peça ao time técnico para criar um Lead de teste (Estado "MG") por esse usuário, sem aplicar a regra de atribuição.
2. Aguarde cerca de 1 minuto e abra o Lead.

**Resultado esperado:** Proprietário "Leads MG", e não o usuário da integração. Um usuário de integração sem esse acesso mantém o Lead com ele.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Conversão de Lead não afeta Conta e Oportunidade
1. Converta o Lead "TESTE EPLAST-35 SP" criando Conta e Oportunidade de teste.

**Resultado esperado:** a conversão funciona normalmente, sem erro e sem aprovação disparada sozinha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Aprovações existentes e relatório de pendentes
1. Em Configuração, procure "Processos de aprovação" e confira Quote, Opportunity e Order.
2. Na aba Relatórios, na pasta Geral, abra "Aprovacoes Pendentes Por Processo".

**Resultado esperado:** continuam existindo "Atribuir ao Pricing", "Análise financeira" e "Liberação Financeiro", sem um quarto processo. O relatório abre, agrupado por processo (pode estar vazio se não houver aprovação pendente).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Não criamos aprovação nova: os três processos atuais ficam como estão; os aprovadores continuam os atuais. Se quiserem alçada por desconto, é outra demanda.
- A distribuição é por região do Estado (as 7 regiões dos seus relatórios do Marketing Cloud, mais a triagem). Dentro da região, o Lead vai para a fila e o vendedor o assume, sem rodízio.
- O "encaminhamento" é passar o Lead para outra fila ou vendedor, com o histórico gravado. Sem prazo nem escalonamento automático.
- Lead criado pela tela vai para a fila por padrão (a caixa vem marcada); o vendedor desmarca quando o Lead é dele.
- Leads de integração só são distribuídos se o usuário tiver o acesso "Distribuição de Lead (integração)".
- Estado escrito de forma diferente (por extenso, em branco) vai para a triagem.
- Não há e-mail de aviso ao novo dono; o acompanhamento é pela lista da fila. E-mails e campanhas ficam com o Marketing Cloud.
- Antes de usar de verdade, o administrador precisa colocar os vendedores nas 8 filas.

## O que não dá para conferir pela tela
Testes técnicos da regra (100% de cobertura na classe), distribuição em lote de 200 Leads e o teste da integração estão em `05-testes.md` e na verificação do build. Lead por integração com usuário real e conversão são conferidos aqui pelos Testes 6 e 7.
