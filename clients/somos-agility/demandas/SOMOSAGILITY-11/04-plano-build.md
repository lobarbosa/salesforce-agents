**Resultado do build:** bloqueado

# SOMOSAGILITY-11 — Plano de build

**Org de dev confirmada:** `sbx-somos-agility-dev` (sandbox, Connected, Org Id 00DHa0000070wxfMAA) via `sf org list`. Nada foi implantado, nenhum DML, nada na QA nem em produção.
**Branch:** `feature/SOMOSAGILITY-11`
**Componentes criados:** nenhum (design nível 0, sem metadata). Nenhuma carga executada, porque o design (§7.1) lista perguntas que bloqueiam e o card não traz respostas.

## Por que bloqueia

Comentários do card (último de 2026-11-24) não respondem B-1 a B-5. A planilha foi lida só em estrutura (cabeçalhos, dimensão), sem transcrever dados.

Estrutura da planilha anexada (aba "Controle DSA", ~100 linhas, colunas A:F):
`Nº DSA`, `Data efetiva de chegada na Agility`, `Data de entrega do produto (cliente)`, `Data de envio da licença ao cliente`, `STATUS LOGÍSTICA`, `Observação Logística`.

Conflitos com o design aprovado:
1. **Escalada de modelo de dados (design §1.3):** a planilha traz 3 colunas de data e 1 de observação além do status. O design cobre só `Status_Backoffice__c`. Gravar essas colunas exige campos novos, o que volta ao arquiteto humano. Não criei nenhum.
2. **Chave de cruzamento (B-2):** a planilha traz `Nº DSA` (número de negócio), não o Id do `DSA__c`. O design exige CSV `Id,Status_Backoffice__c`; o cruzamento Nº para Id seria em produção, feito por humano. Falta confirmar qual campo do DSA guarda esse número.
3. **Valores de status (B-3):** não consegui listar com segurança os distintos da coluna de status pela estrutura do arquivo; o que apareceu é "Finalizado" (um dos 5 valores). Falta confirmação de que todas as linhas estão entre os 5 valores; qualquer valor fora disso é nível 1 (`valueSet`, PR + deploy validate).
4. **B-1 (objeto alvo: `DSA__c`, `Novo_DSA__c` ou ambos):** sem resposta.
5. **B-4 (e-mails em massa por `Notifica_se_DSA_Aprovada_por_Operacoes`) e B-5 (reescrita CIF/FOB por `Atualiza_DSA_com_informacoes_da_PFV`, critério de aceite 3):** decisões do arquiteto humano com o negócio, sem resposta.

## O que falta e quem responde

| # | Pergunta | Quem responde |
|---|---|---|
| B-1 | Objeto alvo: `DSA__c`, `Novo_DSA__c` ou os dois? | consultor/negócio |
| B-2 | Qual campo do DSA corresponde a `Nº DSA` (chave de cruzamento) e quem faz o cruzamento para Id? | consultor (Juliana Mendes) |
| B-3 | Todos os status da coluna `STATUS LOGÍSTICA` estão entre os 5 valores atuais? Se não, quais novos? | consultor/negócio |
| B-4 | Mitigação dos e-mails em massa (opções a/b/c/d do design R1) | arquiteto humano + negócio |
| B-5 | Aceita reescrever o critério de aceite 3 por causa do recálculo CIF/FOB (R2)? | arquiteto humano e BA |
| B-6 (novo) | As colunas de data e observação da planilha entram no escopo? Se sim, campos novos (escalada §1.3). Se não, confirmar que só o status é carregado. | arquiteto humano sênior + negócio |

## Versões e ativação
Não se aplica: nenhum Flow, agente ou classe foi criado ou alterado.
