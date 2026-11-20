# SOMOSAGILITY-26 — Roteiro de teste: campos PFP de texto longo

Foram criados três campos novos, **PFP 1**, **PFP 2** e **PFP 3**, nos objetos BluePrint, Proposta de Solução e Fluxo de Venda de Produto. Eles aceitam caminhos e links longos (até 32.768 caracteres), sem o limite de 255 dos campos antigos. Os campos antigos continuam na tela, e a cópia do BluePrint para a Proposta de Solução continua funcionando para eles.

**Situação do teste automático:** comprovei na sandbox de QA que os 9 campos existem, aceitam 32.768 caracteres e recusam 32.769 (BluePrint), e aceitam 32.768 na Proposta de Solução e no Fluxo de Venda de Produto. **Não comprovei** a cópia automática do BluePrint para a Proposta (a automação não está ativa na QA) nem a aparência nas telas. Esses testes ficam para quem segue este roteiro, depois que a automação for ativada na QA.

## Antes de começar
- Ambiente: sandbox de QA (`sbx-somos-agility-qa`). Nunca teste em produção.
- Perfil: um com acesso de edição ao BluePrint e à Proposta de Solução (por exemplo, Administrador do sistema).
- Dado de teste: crie uma Oportunidade chamada "TESTE SOMOSAGILITY-26" (com Orçamentista preenchido e Conversão de Lead = Não) e um BluePrint ligado a ela. O Autor do BluePrint precisa ser um contato de uma conta com "Agility" no nome. Para os textos longos, use um texto qualquer repetido (por exemplo, a letra "a" colada várias vezes). Não use dados de cliente.

## Teste 1 — Os campos novos aparecem no BluePrint
1. Abra o BluePrint de teste.
2. Procure os campos PFP 1, PFP 2 e PFP 3.

**Resultado esperado:** os três campos aparecem logo abaixo de "PFP 1 (UNC Path)", "PFP 2 (UNC Path)" e "PFP 3 (UNC Path)", e os antigos continuam na tela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Texto longo é salvo no BluePrint
1. Edite o BluePrint de teste.
2. No campo PFP 1, cole um texto de 1.000 caracteres (um link seguido de letras).
3. Clique em Salvar.
4. Reabra o registro.

**Resultado esperado:** salva sem erro e o campo PFP 1 mostra o texto inteiro, igual ao colado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Os campos novos aparecem na Proposta de Solução e no Fluxo de Venda de Produto
1. Abra uma Proposta de Solução de teste ligada à Oportunidade de teste.
2. Confira PFP 1, PFP 2 e PFP 3 nas seções dos campos antigos.
3. Abra um Fluxo de Venda de Produto de teste ligado a essa proposta e confira os mesmos três campos.

**Resultado esperado:** os campos PFP 1, 2 e 3 aparecem e podem ser editados, em ambos os objetos.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — O BluePrint copia o texto para a Proposta de Solução
1. No BluePrint de teste, preencha PFP 1 com 600 caracteres e "PFP 1 (UNC Path)" com `\\servidor\pasta\teste`. Salve.
2. Crie uma Proposta de Solução ligada à mesma Oportunidade (ou salve uma que já exista).
3. Abra a Proposta e leia PFP 1 e o campo antigo de PFP 1.

**Resultado esperado:** PFP 1 da Proposta mostra os 600 caracteres completos, e o campo antigo mostra `\\servidor\pasta\teste`.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Valor já preenchido no campo antigo não é sobrescrito
1. Crie uma Proposta de Solução nova e, no campo antigo de PFP 1, digite "MANUAL".
2. Salve (o BluePrint da Oportunidade tem PFP 1 antigo preenchido).

**Resultado esperado:** o campo antigo continua "MANUAL".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — O limite máximo é respeitado
1. No campo PFP 1 do BluePrint de teste, cole um texto de exatamente 32.768 caracteres e salve.
2. Depois, tente salvar com 32.769 caracteres.

**Resultado esperado:** com 32.768 salva sem erro. Com 32.769 aparece mensagem de "valor de dados grande demais" e nada é gravado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Tela do Fluxo de Venda de Produto continua mostrando o caminho antigo
1. Abra o Fluxo de Venda de Produto ligado à proposta do Teste 4.
2. Olhe o campo de PFP 1 antigo (somente leitura).

**Resultado esperado:** mostra `\\servidor\pasta\teste`, igual à Proposta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Registros antigos continuam iguais
1. Abra uma Proposta de Solução de teste já existente e confira que os campos antigos de PFP mantêm o que tinham.

**Resultado esperado:** nenhum valor antigo mudou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Gravação dos campos e limite de 32.768 / 32.769 caracteres: comprovados por consulta pelo time técnico; evidência em `05-testes.md` (casos C3 a C6).
- Permissões por perfil (quem vê e edita os campos): o time técnico confere por consulta; a tela só confirma o seu próprio perfil.
- Relatórios, modelos de documento (Conga/SDocs) e a integração SnapERP que leiam os campos antigos: não foram verificados; confirmar na homologação.
