**Resultado do build:** bloqueado

# SOMOSAGILITY-18 — Plano de build

Org conferida com `sf org list`: só `sbx-somos-agility-dev` conectada (Sandbox). Nada foi
implantado, nenhum componente foi criado ou alterado. Branch `feature/SOMOSAGILITY-18`.

## Por que está bloqueado

O design (seção 1) trava o build até a causa ser confirmada (H1 a H4). Nenhuma causa foi
confirmada com evidência:

- O comentário do card de 2026-11-24 22:32 **descreve como a fórmula
  `Horas_nao_comerciais_totais_da_atividade__c` funciona** (HNC do executor 1 em branco zera
  tudo; executores 2 e 3 só somam com Shadow desmarcado) e pede que se teste. Confirmei na
  org de dev que a fórmula é exatamente essa. Isso não responde às perguntas 1 a 4 do card de
  2026-11-12 (sinal no registro do marco em produção) e não diz qual valor está errado.
  Também não pede mudança de regra: o comportamento descrito já é o atual.
- A sandbox de dev não tem marcos nem lançamentos, então não há como reproduzir o caso aqui.
- O anexo (PDF, 1 página) é só imagem: `pdftotext` não extrai texto e não foi lido. Não
  confirma causa.
- A leitura "HNC do executor 1 em branco zera a soma" é um possível comportamento a avaliar,
  mas nenhuma hipótese do design a cobre como defeito, e o cliente não disse que é o erro.
  Mudar a fórmula sem esse aceite seria improvisar fora do design.

## O que falta e quem responde

| Pergunta | Quem responde |
|---|---|
| 1. Lançamento aprovado do marco com início/fim em dias diferentes ou HNC desproporcional (H1)? | Consultor com acesso à produção |
| 2. Lançamento com o 1º "Shadow?" (`Shadow_1__c`) marcado (H2)? | Idem |
| 3. Lançamento com "Qtd. de executores" menor que o nº de pares início/fim (H3)? | Idem |
| 4. Qual campo da tela está errado e qual valor era esperado (H4)? | Idem / cliente |
| 5 a 7. Valor correto e data, quais horas entram, valor já usado em fechamento (decide H2/H1) | Cliente |

Se a resposta for "o comportamento descrito no comentário de 24/11 é o defeito" (por exemplo,
executor 1 em branco e executores 2/3 preenchidos), o design precisa registrar essa causa nova
(H5) e a regra esperada, antes do build.

## Roteamento por causa (para o orquestrador)

- H2 e H3: declarativas, este agente constrói (fórmula; nova versão em Draft do Flow
  `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades`).
- H1: exige código em `BusinessHoursFlowHelper` (+ `BusinessHoursFlowHelperTest`, cobertura
  >= 85%). **Precisa do `dev-apex`**; fora do escopo do construtor declarativo.
- H4: sem build.

## Componentes criados

Nenhum.
