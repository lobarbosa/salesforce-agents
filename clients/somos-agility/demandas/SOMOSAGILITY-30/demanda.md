# Revisar o critério do total de despesas realizadas: somar só na aprovação final da Solicitação de Reembolso

Pedido do consultor da Acxya, a partir do card SOMOSAGILITY-10 (Erro no campo total de despesas realizadas - PRJ).

Regra definida: o campo Total de despesas realizadas do projeto só deve receber valor quando a Solicitação de Reembolso for aprovada na etapa final, ou seja, quando ficar com a situação "Aprovado". Os Lançamentos de Despesa são criados dentro da Solicitação de Reembolso, então o valor de todos os Lançamentos dela entra no total do projeto quando a solicitação é aprovada. Só contam os Lançamentos vinculados a um projeto.

Diferença em relação ao design atual do SOMOSAGILITY-10: hoje o design soma já na aprovação do gerente de projeto (quando a solicitação chega a "Pendente - Gestor" ou "Pendente - Diretor"). Com esta regra, a soma só acontece na aprovação final.

O que precisa ser feito:
- Rever o critério do fluxo que atualiza o total no projeto, para considerar só a situação "Aprovado".
- Refazer os cenários de teste. Eles hoje partem da aprovação do gerente de projeto.
- Manter a regra de que rejeição ou recolhimento tiram a despesa do total, e confirmar o comportamento quando uma solicitação aprovada volta atrás.
- Confirmar com o cliente que um projeto sem despesa aprovada fica com 0.

Observação: o SOMOSAGILITY-10 está esperando aprovação e deve ser revisado antes de seguir, para refletir esta regra. Este card não altera o SOMOSAGILITY-10.
