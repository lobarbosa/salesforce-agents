## Contexto
A Acme usa Sales Cloud e quer melhorar o processo de qualificação de Leads.

## Requisitos

1. Adicionar um campo picklist `Nível de Interesse` (Alto/Médio/Baixo) no
   objeto Lead.
2. Quando `Nível de Interesse` = Alto e o Lead não tiver um Owner definido
   como usuário ativo do time de vendas, atribuir automaticamente ao
   próximo vendedor disponível (round-robin simples entre 3 usuários fixos).
3. Bloquear a conversão do Lead para Oportunidade se o campo `Nível de
   Interesse` estiver em branco (Validation Rule).
4. Criar um componente Lightning para a Lead Record Page mostrando um
   resumo do histórico de atividades (tarefas + eventos) dos últimos 30
   dias, já que o related list padrão é considerado poluído pelo time.

## Fora de escopo
Integração com sistemas externos de scoring de leads — ficará para uma fase
futura.
