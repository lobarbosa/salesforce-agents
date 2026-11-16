# EPLAST-44 — Roteiro de teste: público de boas-vindas para as jornadas

Foi entregue um novo relatório, "LEADS - BOAS-VINDAS", na pasta MARKETING CLOUD. Ele lista os leads criados nos últimos 7 dias que ainda estão em aberto e não pediram para deixar de receber e-mail. O Marketing Cloud lê esse relatório para a jornada de boas-vindas. O Salesforce não envia nenhuma mensagem. Os demais públicos das jornadas (prospecção, compra, reativação) já existiam e não foram alterados.

**Situação do teste automático:** o time já comprovou na QAS, com leads de teste (depois apagados), que o relatório inclui lead novo e aberto e exclui lead com opt-out de e-mail, lead "Fechado - Não convertido" e lead convertido, e que o público de prospecção exclui opt-out de mensagem. Ficou para quem segue este roteiro: a conferência pela tela, o acesso por perfil e a conferência dos públicos de contatos, que dependem de dado de compra.

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`).
- Perfil: Administrador do sistema, e depois um usuário sem acesso à pasta de relatórios de marketing, se houver.
- Crie 4 leads de teste em Leads > Novo, com Empresa começando por "TESTE EPLAST-44":
  - A: Sobrenome "TESTE EPLAST-44 A", Situação "Aberto - Não contatado".
  - B: igual a A, marcando "Cancelou recebimento de e-mail".
  - C: igual a A, com Situação "Fechado - Não convertido".
  - D: igual a A, e depois converta o lead (se pedirem, informe um CNPJ de teste válido).
- Apague os leads e contas de teste ao final.

## Teste 1 — Lead novo e aberto entra no público
1. Abra Relatórios e a pasta MARKETING CLOUD.
2. Abra "LEADS - BOAS-VINDAS".
3. Procure por "TESTE EPLAST-44 A" (filtro por Empresa).

**Resultado esperado:** o lead A aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Opt-out de e-mail fica de fora
1. No mesmo relatório, procure por "TESTE EPLAST-44 B".

**Resultado esperado:** o lead B não aparece. Desmarque o opt-out em B e atualize o relatório: B aparece. Marque de novo: B sai.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead fechado ou convertido fica de fora
1. No mesmo relatório, procure por "TESTE EPLAST-44 C" e "TESTE EPLAST-44 D".

**Resultado esperado:** nenhum dos dois aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Janela de 7 dias
1. Abra o relatório e veja o filtro de data "Data de criação".

**Resultado esperado:** "Últimos 7 dias". Um lead criado há mais de 7 dias não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Opt-out de mensagem no público de prospecção
1. Crie um lead de teste com "Cancelou recebimento de mensagem de celular" marcado.
2. Abra "LEADS - PRIORIDADE DE PROSPECÇÃO" na pasta MARKETING CLOUD e procure por ele.

**Resultado esperado:** o lead não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nenhum envio pelo Salesforce
1. Crie e salve o lead A.
2. Confira a caixa do e-mail de teste informado.

**Resultado esperado:** nenhum e-mail chegou do Salesforce.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Acesso por perfil
1. Entre com um usuário sem acesso à pasta MARKETING CLOUD.
2. Tente abrir "LEADS - BOAS-VINDAS".

**Resultado esperado:** o relatório não abre ou não é listado. (Na QAS só há usuário administrador; sem usuário de teste, anote como não executado.)
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Públicos de mensagem (conferir existência)
1. Na pasta MARKETING CLOUD, procure "MSG - LEADS CELULAR APTOS" e "MSG - CONTATOS CELULAR APTOS".

**Resultado esperado:** na QAS eles ainda podem não existir, pois pertencem a outra entrega. Anote o que encontrou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Jornadas assumidas: boas-vindas de lead, nutrição de prospecção, primeira compra de potenciais, relacionamento pós-compra, reativação em três faixas (91–180, 181–365, mais de 365 dias) e mensagem como canal alternativo. O Marketing Cloud decide quais ativar.
- Entra no público quem passa a atender o filtro do relatório; sai quem deixa de atender. Nada é gravado no Salesforce como gatilho.
- Boas-vindas: lead criado nos últimos 7 dias, só lead (não contato). A janela se muda no filtro de data do relatório.
- Lead "Fechado - Não convertido" sai das boas-vindas, mas continua no público de nutrição de prospecção.
- Opt-out: e-mail exclui quem cancelou e-mail; mensagem exclui quem cancelou mensagem. Mudar isso exige decisão da Eplast.
- Reativação usa a data da última compra da conta, não o tipo da conta (Inativo/Reativo). O campo não tem descrição: confirme quem o alimenta.
- Sem campanha nem membro de campanha no Salesforce. O disparo é do Marketing Cloud, operado pelo time de marketing da Eplast; indique o responsável.

## O que não dá para conferir pela tela
- Leitura do relatório pelo Marketing Cloud, sincronização de descadastro e pasta oculta para o usuário de integração: passos de quem opera o Marketing Cloud.
- Conferência dos públicos de contatos com dado de compra: a evidência de metadata está em `05-testes.md`.
