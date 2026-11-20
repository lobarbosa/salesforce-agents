# SOMOSAGILITY-26 — Roteiro de teste

Foram criados três novos campos de texto longo, "PFP 1", "PFP 2" e "PFP 3", em BluePrint, Proposta de Solução e Fluxo de Venda de Produtos. Eles aceitam links e caminhos longos (até 32.768 caracteres). Ao criar ou atualizar uma Proposta de Solução, o sistema copia os textos do BluePrint para os campos novos e continua preenchendo os campos antigos "PFP 1/2/3 (UNC Path)", sem sobrescrever o que alguém já digitou.

**Situação do teste automático:** o time já comprovou na sandbox de QA, com dados de teste: os 9 campos e o limite de 32.768 caracteres, a recusa acima do limite, a permissão dos campos, a presença dos campos nos 16 layouts (conferida por download do layout), e a cópia do BluePrint para a Proposta de Solução. Ficou para este roteiro a conferência visual dos campos nas telas e a verificação do Fluxo de Venda de Produtos (a fórmula do campo antigo na QA mostra um valor fixo, fora desta entrega).

## Antes de começar
- Ambiente: sandbox de QA (não é produção).
- Perfil: o seu perfil de uso normal (por exemplo, Gerente de Contas ou Solutions Architect).
- Dado de teste: use uma Oportunidade de teste com Orçamentista preenchido e um BluePrint ligado a ela. Preencha no BluePrint os campos "PFP 1", "PFP 2" e "PFP 3" com textos longos de teste (um deles com mais de 500 caracteres) e os campos "PFP 1/2/3 (UNC Path)" com caminhos como `\\servidor\pasta1`. Use só dados fictícios.

## Teste 1 — Campos novos aparecem no BluePrint
1. Abra o BluePrint de teste.
2. Vá até a seção onde ficam os campos "PFP 1 (UNC Path)".
3. Procure "PFP 1", "PFP 2" e "PFP 3" logo abaixo dos antigos.

**Resultado esperado:** os três campos novos aparecem e são editáveis.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Texto longo é salvo por inteiro
1. No BluePrint de teste, clique em Editar.
2. Cole em "PFP 1" um texto de teste com cerca de 600 caracteres e salve.
3. Reabra o registro.

**Resultado esperado:** o texto aparece completo, sem corte e sem mensagem de erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Campos novos na Proposta de Solução
1. Abra uma Proposta de Solução de teste, em cada layout que você usa (por exemplo, "Criação da Proposta" e "Especificação Técnica").
2. Procure "PFP 1", "PFP 2" e "PFP 3" abaixo dos campos "PFP 1/2/3 (UNC Path)".

**Resultado esperado:** os três campos novos aparecem em todos os layouts usados.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nova Proposta recebe os textos do BluePrint
1. Na Oportunidade de teste ligada ao BluePrint do Teste 1, crie uma nova Proposta de Solução.
2. Abra a Proposta criada.

**Resultado esperado:** "PFP 1/2/3" vêm com o mesmo texto do BluePrint (inclusive o de mais de 500 caracteres), e "PFP 1/2/3 (UNC Path)" vêm com os caminhos do BluePrint.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Valor digitado não é sobrescrito
1. Na Proposta do Teste 4, edite "PFP 1 (UNC Path)" e digite `MANUAL-TESTE`; apague o texto de "PFP 1" e salve.

**Resultado esperado:** "PFP 1 (UNC Path)" continua `MANUAL-TESTE`; "PFP 1" volta a ser preenchido com o texto do BluePrint; "PFP 2 (UNC Path)" e "PFP 3 (UNC Path)" seguem como estavam.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Fluxo de Venda de Produtos
1. Abra um Fluxo de Venda de Produtos de teste ligado à Proposta do Teste 4.
2. Confira os campos "PFP 1/2/3" e o campo antigo "PFP 1 (UNC Path)" em cada layout (por exemplo "Produtos na PFP" e "Validação Fiscal").
3. Digite um texto longo em "PFP 1" e salve.

**Resultado esperado:** os campos novos aparecem e salvam o texto completo. O campo antigo mostra o "PFP 1 (UNC Path)" da Proposta (hoje na QA ele pode mostrar um valor fixo; se for o caso, avise o time, é fora desta entrega).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Limite máximo
1. Em um campo "PFP 3" de teste, cole um texto com mais de 32.768 caracteres e salve.

**Resultado esperado:** o sistema recusa com mensagem de valor grande demais e nada é gravado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Relatórios, documentos gerados (Conga, SDocs) e integração SnapERP que possam usar esses campos: só a homologação com o cliente confirma. Não testável na sandbox.
- Permissão por perfil (contagem de 573 permissões) e os 16 layouts por download: evidência em `05-testes.md`.
