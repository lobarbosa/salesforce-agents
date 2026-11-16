# EPLAST-46 — Roteiro de teste: sugestão de campanhas pelo assistente

O assistente comercial (SFAgent2) agora sugere campanhas para uma conta, com o motivo, o público do Marketing Cloud a usar e quantos contatos podem receber por e-mail e por mensagem. Ele só sugere: nada é enviado, o disparo continua sendo feito pelo Marketing Cloud. Só enxerga a sugestão quem tem o acesso "PS Marketing Sugestão de Campanha".

**Situação do teste automático:** o time já comprovou na QAS, com contas de teste, todos os testes abaixo (reativação, conta recente, opt-out por canal, ampliação de mix, conta sem histórico, acesso negado, nada enviado). Falta apenas a conferência pela tela do Salesforce, por quem homologa.

## Antes de começar
- Ambiente: sandbox QAS (`eplast--qas`).
- Perfil: um usuário com o acesso "PS Marketing Sugestão de Campanha" (testes 1 a 6) e outro sem ele (teste 7).
- Dado de teste: crie contas de teste com "TESTE EPLAST-46" no nome. Use datas de "última compra" conforme cada teste. Crie contatos de teste na conta do Teste 3 (um com "Não receber e-mail" marcado, um com opt-out de mensagem marcado e um sem nenhum). Apague as contas de teste ao final.
- Abra o assistente comercial e pergunte: "Qual campanha você sugere para a conta TESTE EPLAST-46 X?"

## Teste 1 — Conta parada há mais de 90 dias
1. Use uma conta de teste cuja última compra foi há cerca de 100 dias.
2. Pergunte ao assistente a campanha sugerida.

**Resultado esperado:** sugestão de "Reativação", dizendo "sem compra há 100 dias" e o público "SEM COMPRA - 91 A 180 DIAS", e a frase "Nada foi enviado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Conta que comprou recentemente
1. Use uma conta de teste com última compra há 30 dias e sem sugestão de ampliação.
2. Pergunte ao assistente.

**Resultado esperado:** "Nenhuma campanha sugerida ... a conta comprou recentemente". Não aparece reativação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Contatos que não querem receber (opt-out)
1. Na conta do Teste 1, deixe três contatos: um com "Não receber e-mail", um com opt-out de mensagem e um sem restrição.
2. Pergunte ao assistente.

**Resultado esperado:** "Contatos elegíveis: 2 para e-mail; 2 para mensagem".
3. Em outra conta parada, deixe um único contato com "Não receber e-mail".

**Resultado esperado:** "sem contato elegível para e-mail".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Ampliação de mix
1. Use uma conta que comprou recentemente e para a qual existe sugestão de produto de um grupo que clientes do mesmo setor compram (peça ao time para preparar a conta de teste).
2. Pergunte ao assistente.

**Resultado esperado:** "Ampliação de mix", citando o grupo de produto e o público "AMPLIACAO MIX - CONTATOS".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta sem nenhuma compra
1. Use uma conta de teste sem oportunidade ganha nem pedido.
2. Pergunte ao assistente.

**Resultado esperado:** "Sem histórico de compra ... não há reativação nem ampliação de mix a sugerir", sem mensagem de erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta parada e com sugestão de mix
1. Use uma conta com última compra há 200 dias e sugestão de produto.
2. Pergunte ao assistente.

**Resultado esperado:** duas linhas, "Reativação" primeiro (público "SEM COMPRA - 181 A 365 DIAS") e depois "Ampliação de mix".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Usuário sem acesso
1. Entre com um usuário sem o acesso "PS Marketing Sugestão de Campanha".
2. Pergunte ao assistente a campanha de uma conta de teste.

**Resultado esperado:** "Você não tem acesso à sugestão de campanhas. Peça ao administrador o permission set PS Marketing Sugestão de Campanha." Nenhum dado da conta aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nada é enviado
1. Antes dos testes, anote quantas campanhas, membros de campanha e e-mails existem (relatórios).
2. Depois dos testes 1 a 6, confira de novo.

**Resultado esperado:** os números são iguais. Nenhum e-mail ou mensagem foi enviado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- [ ] **Comportamento = histórico de compra.** Não consideramos abertura ou clique de e-mail nesta versão.
- [ ] **Conta parada = mais de 90 dias sem compra.** O prazo vem da regra "Inativo" já existente; mudar o prazo exige ajustar essa regra e os relatórios "SEM COMPRA".
- [ ] **"Necessidade" = produto que clientes do mesmo segmento (Indústria) compram e a conta não.** Reaproveita a regra de venda cruzada já existente (exclui o que a conta comprou nos últimos 180 dias).
- [ ] **Família de produto = o campo "Grupo" do produto**, e não o campo "Família".
- [ ] **Reativação conta a última compra ganha; ampliação de mix conta pedidos.** Cada regra segue o público que já existe.
- [ ] **A sugestão é calculada na hora, sem campo novo na conta**, e só é lida por Marketing e Comercial com o acesso novo.
- [ ] **A sugestão não dispara nada.** O Marketing Cloud importa o público, aplica o opt-out de novo e faz o envio.
- [ ] **Lead fora desta sugestão.** Nutrição de lead continua pelo relatório "LEADS - PROSPECÇÃO PRIORIZADA".
- [ ] **Qualidade dos pedidos vindos do Protheus** afeta a sugestão de mix.

## O que não dá para conferir pela tela
- Nenhum e-mail ou mensagem enviado e nenhuma campanha criada (contagens antes e depois), e ausência de e-mail e telefone no registro de execução: evidência em `05-testes.md` (T10 e T13).
- Ativação da versão nova do agente: registrada em `05-testes.md`.
