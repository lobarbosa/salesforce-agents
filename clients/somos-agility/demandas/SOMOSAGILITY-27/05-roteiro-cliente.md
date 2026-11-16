# Roteiro de teste — SOMOSAGILITY-27 (salvar e exportar relatórios)

Foi criado um conjunto de permissões chamado "Relatorios - Extrair e Salvar". Quem o recebe passa a poder executar, criar/salvar e exportar relatórios, sem gerenciar pastas públicas. A parte "criar modelo" ainda não foi entregue (depende de definição do negócio).

**Situação do teste automático:** comprovado que o conjunto de permissões existe na QA com exatamente essas três permissões, sem acesso a objetos ou campos e sem ninguém atribuído. NÃO comprovado: salvar e exportar de fato, porque o usuário disponível ao time já tinha essas permissões pelo perfil. Os testes 2 a 4 ficam para quem segue o roteiro.

## Antes de começar
- Ambiente: sandbox de QA (somos-agility-qa).
- Peça ao administrador para criar um usuário de teste (nome "TESTE SOMOSAGILITY-27") com o mesmo perfil da colaboradora, SEM o conjunto "Relatorios - Extrair e Salvar" no início.
- Uma pasta de relatórios de teste, onde o usuário de teste tenha acesso de Editor.
- Pelo menos 3 contas de teste (nome começando com "TESTE SOMOSAGILITY-27") para o relatório listar.

## Teste 1 — O conjunto de permissões existe
1. Em Configuração, busque "Conjuntos de permissões".
2. Abra "Relatorios - Extrair e Salvar".
Resultado esperado: aparece com a descrição "Executar, criar/salvar e exportar relatorios. Nao inclui gestao de pastas publicas." e nenhuma pessoa atribuída.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Antes de receber o conjunto (situação do problema)
1. Entre como o usuário de teste.
2. Vá em Relatórios e clique em "Novo relatório", escolha "Contas" e tente salvar na pasta de teste.
Resultado esperado: registre a mensagem exata que aparecer (se salvar sem erro, o perfil já tinha a permissão e a causa do problema é outra: avise o time).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Salvar relatório após receber o conjunto
1. O administrador atribui "Relatorios - Extrair e Salvar" ao usuário de teste.
2. Entre como o usuário de teste, vá em Relatórios e clique em "Novo relatório".
3. Escolha "Contas", adicione o relatório e clique em "Salvar".
4. Escolha a pasta de teste e confirme.
Resultado esperado: o relatório salva sem mensagem de privilégio insuficiente e aparece na pasta escolhida.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Exportar relatório
1. Abra o relatório salvo no Teste 3.
2. Anote quantas linhas aparecem na tela.
3. Clique na seta ao lado de "Editar", escolha "Exportar" e o formato usado pela função (confirmar com o time).
4. Abra o arquivo e conte as linhas.
Resultado esperado: o arquivo é gerado sem erro e tem o mesmo número de linhas da tela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Sem acesso a mais do que o necessário
1. Entre como o usuário de teste e tente criar uma nova pasta pública de relatórios.
2. Tente editar um relatório de uma pasta onde ele não é Editor.
Resultado esperado: ambos são negados (o conjunto não dá gestão de pastas públicas).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Que nenhum outro usuário ganhou acesso novo e que o conjunto não tem permissão de objeto/campo: comprovado por contagens, em `05-testes.md` (casos T3 a T5).
- "Criar modelo": não entregue; aguarda resposta do negócio sobre o que é o "modelo".
