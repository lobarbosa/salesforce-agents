# Roteiro de teste — Relatórios: salvar e extrair dados (SOMOSAGILITY-27)

Foi entregue um conjunto de permissões chamado "Relatorios - Extrair e Salvar". Quem o recebe passa a poder executar relatórios, criar e salvar relatórios e exportar os dados deles. Ele não dá acesso a gerenciar pastas públicas nem a ver todos os dados da organização. A criação de "modelos" não faz parte desta entrega.

**Situação do teste automático:** o time comprovou na sandbox de QA que o conjunto de permissões existe, tem só as três permissões previstas e não está atribuído a ninguém. Os testes de salvar e exportar de verdade (Testes 1 a 3) **não foram executados**: a sandbox não tem licença livre que permita relatórios (30 de 30 em uso) para criar um usuário de teste sem as permissões. Ficam para quem segue este roteiro.

## Antes de começar
- **Ambiente:** sandbox de QA (login em test.salesforce.com). Nunca em produção.
- **Perfil:** use um usuário de teste que **ainda não** consiga salvar nem exportar relatórios, e que tenha licença Salesforce. Quem administra a sandbox precisa indicá-lo ou liberar uma licença.
- **Preparação (administrador):** crie uma pasta de relatórios chamada "TESTE SOMOSAGILITY-27", compartilhe com o usuário de teste como Editor, crie 3 contas com nome "TESTE SOMOSAGILITY-27 A", "B" e "C", e um relatório de contas nessa pasta filtrando por esse nome.

## Teste 1 — Antes: o usuário sem a permissão não salva nem exporta
1. Entre na sandbox de QA com o usuário de teste, **sem** o conjunto de permissões.
2. Abra Relatórios e tente criar um novo relatório de Contas.
3. Tente salvá-lo na pasta "TESTE SOMOSAGILITY-27".
4. Abra o relatório existente da pasta e procure a opção Exportar.

**Resultado esperado:** não consegue criar ou salvar, e a opção Exportar não aparece ou dá mensagem de privilégio insuficiente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Depois: salvar relatório
1. O administrador atribui "Relatorios - Extrair e Salvar" ao usuário de teste (Configuração, Conjuntos de permissões, Gerenciar atribuições).
2. O usuário sai e entra de novo.
3. Em Relatórios, crie um novo relatório de Contas, filtrando por nomes que começam com "TESTE SOMOSAGILITY-27".
4. Clique em Salvar, dê o nome "TESTE relatorio 27" e escolha a pasta "TESTE SOMOSAGILITY-27".

**Resultado esperado:** o relatório é salvo sem erro e aparece na pasta, mostrando 3 linhas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Depois: exportar dados
1. Abra "TESTE relatorio 27".
2. Clique em Exportar e escolha o formato que a sua função usa (por exemplo, Excel .xlsx).
3. Abra o arquivo baixado.

**Resultado esperado:** o arquivo é gerado sem erro e tem 3 linhas de dados, o mesmo número da tela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Sem acesso a mais do que o necessário
1. Com o usuário de teste, abra um relatório de uma pasta que não foi compartilhada com ele.
2. Tente criar uma nova pasta pública de relatórios.

**Resultado esperado:** ele não vê a pasta não compartilhada e não consegue gerenciar pastas públicas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Confirmação pela colaboradora (homologação)
1. Depois do administrador atribuir o conjunto à colaboradora no ambiente definido, ela repete os Testes 2 e 3 com um relatório da função dela.

**Resultado esperado:** salva e exporta sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Ao terminar
O administrador remove a atribuição do conjunto de permissões do usuário de teste, apaga a pasta, o relatório e as contas de teste.

## O que não dá para conferir pela tela
A composição exata do conjunto de permissões (só as três permissões, nenhuma atribuição, nenhum perfil alterado) foi conferida pelo time técnico em `05-testes.md`. A criação de "modelos" está fora desta entrega.
