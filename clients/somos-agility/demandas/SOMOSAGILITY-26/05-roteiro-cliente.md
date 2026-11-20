# Roteiro de teste — SOMOSAGILITY-26: texto longo para o caminho do PFP

Foram criados três campos novos de texto longo, chamados "PFP 1", "PFP 2" e "PFP 3", no BluePrint, na Proposta de Solução (PSL) e no Fluxo de Venda de Produtos. Cabem até 32.768 caracteres, para colar links e caminhos longos. Quando uma PSL é criada ou salva, o sistema copia automaticamente o texto do BluePrint da Oportunidade para esses campos novos, e continua copiando os campos antigos "PFP (UNC Path)".

**Situação do teste automático:** o time comprovou na QA a gravação e a leitura dos campos, a cópia do BluePrint para a PSL (texto completo e caminhos antigos, sem apagar valor digitado à mão) e que os dados existentes não mudaram. **Ficou reprovado** que os campos novos ainda não aparecem em 9 dos 16 layouts da QA (por exemplo, a tela principal da PSL); o Teste 3 só vai passar depois da correção. A fórmula "*PFP 1 (UNC Path)" do Fluxo de Venda de Produtos na QA mostra sempre a letra "a" (Teste 5); o time vai conferir.

## Antes de começar
- Ambiente: sandbox de QA (Sandbox AW). Nunca teste em produção.
- Perfil: Administrador do sistema, ou o perfil de quem usa a PSL no dia a dia.
- Dado de teste: crie uma Conta com "Agility" no nome (ex.: "TESTE SOMOSAGILITY-26 Agility"), um Contato dela com "Trabalha atualmente na empresa" = Sim e telefone preenchido, uma Oportunidade com esse Contato em "Orçamentista" e "Conversão de Lead" = Não, e um BluePrint ligado a ela (Autor = esse Contato). Preencha no BluePrint os campos "PFP 1", "PFP 2", "PFP 3" com textos de 600, 300 e 50 caracteres e "PFP 1/2/3 (UNC Path)" com `\\srv\a1`, `\\srv\a2`, `\\srv\a3`. Na Oportunidade, aponte o campo BluePrint para ele.

## Teste 1 — Campo aceita texto longo
1. Abra o BluePrint de teste e clique em Editar.
2. Cole no campo "PFP 1" um texto de 32.768 caracteres e clique em Salvar.
3. Reabra o registro.

**Resultado esperado:** salva sem erro e o texto aparece inteiro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Texto acima do limite é recusado
1. Edite o BluePrint de teste.
2. No campo "PFP 1", cole 32.769 caracteres e clique em Salvar.

**Resultado esperado:** mensagem de erro dizendo que o valor é grande demais; nada é gravado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Campos novos visíveis nas telas
1. Abra a PSL de teste (criada no Teste 4) na tela de detalhes.
2. Procure, em cada cenário, o campo "PFP 1/2/3" logo abaixo de "PFP 1/2/3 (UNC Path)".
3. Abra o BluePrint e um Fluxo de Venda de Produtos de teste e repita.

**Resultado esperado:** os campos novos "PFP 1", "PFP 2" e "PFP 3" aparecem logo abaixo dos antigos nas três telas, em qualquer layout de PSL usado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Cópia do BluePrint para a PSL
1. Na Oportunidade de teste, crie uma Proposta de Solução (PSL) nova.
2. Abra a PSL criada.

**Resultado esperado:** "PFP 1", "PFP 2" e "PFP 3" trazem os textos do BluePrint completos (600, 300 e 50 caracteres) e "PFP 1/2/3 (UNC Path)" mostram `\\srv\a1`, `\\srv\a2`, `\\srv\a3`.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Valor digitado à mão não é apagado
1. Na PSL de teste, apague o campo "PFP 1" e escreva `MANUAL-TESTE` em "*PFP 1 (UNC Path)". Salve.
2. Reabra a PSL.
3. Abra o Fluxo de Venda de Produtos ligado a essa PSL e veja o campo "*PFP 1 (UNC Path)".

**Resultado esperado:** na PSL, "PFP 1" volta com o texto do BluePrint e "*PFP 1 (UNC Path)" continua `MANUAL-TESTE`; "PFP 2 (UNC Path)" e "PFP 3 (UNC Path)" não mudam. No Fluxo de Venda de Produtos, o campo "*PFP 1 (UNC Path)" mostra `MANUAL-TESTE`.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Registros existentes não mudaram
1. Abra uma lista de PSLs e de BluePrints antigos (sem editar nada) e confira que os campos antigos continuam preenchidos como antes.

**Resultado esperado:** campos antigos intactos; os campos novos aparecem vazios em registros antigos.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Permissões por perfil (contagem agregada de acesso aos campos) e a ativação do processo automático: evidência em `05-testes.md`.
- Relatórios, documentos gerados (Conga/SDocs) e integração SnapERP que usam esses campos: a validar na homologação.
