# EPLAST-2 — Análise funcional: Estabelecer baseline dos indicadores comerciais do projeto

Fonte: `demandas/EPLAST-2/demanda.md` (registrada pelo planejador a partir do contrato de projeto).
Estágio: analise. Este documento não toca em nenhuma org Salesforce, não executa SOQL e não
assume quais clouds, objetos ou fontes de dados a Eplast usa. Tudo que depende disso está em
"Dúvidas em aberto" ou em "Premissas a validar", marcado como pendente.

## 1. Contexto de negócio

O projeto com a Eplast tem três ondas planejadas: produtividade, gestão e marketing. A demanda
diz que essas ondas prometem melhorar indicadores comerciais, mas hoje não existe registro do
valor atual desses indicadores. Sem uma linha de base datada, o impacto de cada onda não pode
ser medido de forma objetiva, e a discussão de sucesso do projeto fica sujeita à percepção.

Exemplos citados pelo consultor (não confirmados como escopo): tempo médio de resposta a lead,
oportunidades paradas, taxa de conversão.

## 2. Objetivo

Produzir, antes do início da primeira onda, um registro único e datado com:
- a lista de indicadores comerciais que o projeto usará para medir sucesso;
- a definição operacional de cada um (o que conta, como calcula, de onde vem, em qual janela);
- o valor atual de cada um, na data de corte;
- a confirmação por escrito do cliente de que essa é a lista oficial de medição.

Fora do objetivo: definir metas das ondas, desenhar solução, construir relatório ou dashboard,
e medir o impacto em si (isso é responsabilidade das ondas seguintes).

## 3. Regras de negócio

- **RN-01.** A lista de indicadores é a lista oficial de medição do projeto só depois da
  confirmação escrita do cliente. Antes disso é rascunho.
- **RN-02.** Cada indicador tem definição operacional completa: nome, fórmula, universo
  (filtros de registro), fonte, janela de tempo, unidade e responsável pela medição do lado
  do cliente.
- **RN-03.** Cada valor atual tem data de corte explícita e fonte rastreável. Valor sem
  fonte não entra como baseline; entra como "não medido", com motivo.
- **RN-04.** O baseline é agregado (contagens, médias, percentuais). Nenhum valor individual
  de cliente final, lead ou pessoa entra no registro (LGPD, guardrail #2 do squad).
- **RN-05.** A extração dos valores é feita por pessoa autorizada na fonte de origem. O agente
  não acessa dados de produção desta demanda (guardrail #1).
- **RN-06.** Após o aceite, o baseline não é reescrito. Correção de um valor errado gera
  versão nova com motivo registrado, preservando a versão anterior.

## 4. Critérios de aceite (Gherkin)

Os critérios propostos pelo consultor foram mantidos no sentido, mas reescritos para serem
verificáveis. Termos entre colchetes dependem de resposta às dúvidas da seção 6.

**CA-01 — Lista de indicadores existe e tem local definido**
```gherkin
Dado que o consultor e o cliente definiram o local oficial do baseline [local a confirmar, ex.: arquivo na pasta da demanda ou documento compartilhado com link fixo]
Quando a lista de indicadores é publicada nesse local
Então ela contém pelo menos [N] indicadores comerciais, cada um com: nome, fórmula, universo, fonte, janela de tempo, unidade e responsável
E nenhum indicador aparece sem essas sete informações preenchidas
```

**CA-02 — Cada indicador tem valor atual datado**
```gherkin
Dado que a lista de indicadores foi publicada
Quando o consultor consulta a linha de cada indicador
Então existe um valor atual com data de corte no formato AAAA-MM-DD
E a data de corte é a mesma para todos os indicadores, ou a diferença de datas está justificada por indicador
E existe a referência da fonte de onde o valor foi extraído (relatório, planilha ou consulta, com nome e data da extração)
```

**CA-03 — Indicador sem valor é declarado, não preenchido**
```gherkin
Dado que um indicador não pôde ser medido na data de corte
Quando o baseline é fechado
Então o valor aparece como "não medido" com motivo registrado
E nenhum valor é estimado, arredondado de memória ou copiado de outra fonte sem indicação
```

**CA-04 — Confirmação escrita do cliente**
```gherkin
Dado que a lista de indicadores com valores está fechada
Quando o cliente responde por escrito [canal a confirmar: e-mail, ata ou assinatura] confirmando que esses são os indicadores usados para medir o sucesso do projeto
Então a confirmação é arquivada na pasta da demanda com data de recebimento
E a confirmação cita a versão da lista (identificador ou data de publicação)
E a confirmação identifica quem a emitiu pelo cargo, com o nome conforme a política de identificação do cliente [a confirmar]
```

**CA-05 — Não há dado pessoal no registro**
```gherkin
Dado que o baseline foi publicado
Quando o ci-pii-scan ou revisão humana é executada sobre os arquivos da demanda
Então nenhum CPF, e-mail, telefone ou valor individual de cliente final aparece no registro
```

**CA-06 — Versionamento**
```gherkin
Dado que um valor do baseline precisa ser corrigido após o aceite
Quando a correção é feita
Então é criada uma nova versão da lista com motivo da correção e data
E a versão anterior permanece disponível sem alteração
```

**CA-07 — Pronto para a primeira onda**
```gherkin
Dado que CA-01 a CA-06 estão atendidos
Quando o gate humano desta demanda é aprovado
Então a primeira onda de produtividade pode referenciar a versão aprovada do baseline
como ponto zero da medição
```

## 5. O que a demanda NÃO diz

1. **Quais são os indicadores.** Os três exemplos são ilustrativos. Não há lista fechada,
   nem quantidade, nem prioridade.
2. **Onde os dados vivem.** Não está dito se os indicadores saem de Salesforce, de outro
   sistema, de planilha ou de processo manual. Não há confirmação de que a Eplast usa
   Salesforce para o comercial.
3. **Quais clouds estão em uso.** O CLAUDE.md do cliente deixa esse campo em branco.
4. **Quem é o cliente que confirma por escrito.** Não há nome de contato, cargo ou
   papel de aprovador.
5. **Qual é a forma aceita de confirmação escrita.** E-mail, ata de reunião ou assinatura
   formal.
6. **Qual é a data de corte.** "Atual" não tem data definida.
7. **Se existe histórico.** Não se sabe se o baseline deve ser só o "hoje" ou uma série
   histórica (ex.: últimos 6 ou 12 meses), o que muda muito o esforço de extração.
8. **Quem extrai os valores e com qual acesso.** Produção não é acessível pelo agente, e
   dev/qa são sandboxes que podem não refletir os dados reais. Isso precisa de decisão
   explícita.
9. **Se as ondas já têm metas.** Sem metas, o baseline é só referência; com metas, o
   baseline precisa ter a mesma definição que a meta usa.
10. **O que fazer se o cliente não confirmar.** Não há regra para bloqueio das ondas
    seguintes nem para aceite parcial.
11. **Periodicidade.** Se o baseline é único ou se será recalculado em marcos do projeto.

## 6. Dúvidas em aberto (resolver antes do design)

| # | Pergunta | Quem responde | Por que importa |
|---|----------|---------------|-----------------|
| D1 | Quais indicadores comerciais entram na medição? Quantos? | Cliente (sponsor do projeto) | Define escopo e esforço de extração |
| D2 | Para cada indicador, qual é a fórmula e o universo de registros? | Cliente + consultor | Sem definição, o valor não é comparável depois |
| D3 | De onde sai cada indicador hoje (sistema, relatório, planilha, manual)? | Cliente | Define se há parte de Salesforce e de qual org |
| D4 | Quais clouds estão em uso no comercial? | Cliente / consultor | Campo vazio no CLAUDE.md; obrigatório antes do recon |
| D5 | Qual a data de corte do baseline? | Cliente | Torna "atual" verificável (CA-02) |
| D6 | O baseline é um ponto ou uma série histórica? Se série, de quando? | Cliente | Muda esforço de extração em ordem de grandeza |
| D7 | Quem extrai os valores e com qual acesso à fonte de produção? | Cliente (TI) + consultor | Agente não acessa produção; precisa de dono humano explícito |
| D8 | As ondas já têm metas por indicador? | Cliente | Baseline e meta precisam da mesma definição |
| D9 | Quem assina a confirmação escrita (cargo) e por qual canal? | Cliente | Fecha CA-04 |
| D10 | A identificação do signatário pode constar no registro da demanda? | Cliente / política interna | LGPD e CA-04 |
| D11 | Existe regra de aceite parcial (ex.: 80% dos indicadores confirmados)? | Consultor + sponsor | Define se a onda pode começar com lista incompleta |
| D12 | Este baseline precisa ser recalculado em marcos (ex.: fim de cada onda)? | Cliente | Define se CA-07 é único ou recorrente |

Nenhuma destas perguntas deve ser respondida por suposição. Até a resposta, a demanda fica
em análise.

## 7. Premissas a validar (pendentes, nenhuma aceita ainda)

- **P1 (pendente).** Os indicadores estão em algum sistema consultável, mesmo que manualmente.
  Se não estiverem, o baseline vira levantamento de processo, com esforço bem maior.
- **P2 (pendente).** O cliente tem uma pessoa responsável pelos números comerciais que responde
  em até 5 dias úteis. Sem isso, CA-04 fica indefinido.
- **P3 (pendente).** A lista tem até 10 indicadores. Acima disso, a faixa de esforço sobe.
- **P4 (pendente).** O baseline é um ponto (não série histórica) na data de corte.
- **P5 (pendente).** A extração é feita por pessoa do cliente com acesso à fonte, e o consultor
  só organiza e valida. Se o consultor precisar fazer a extração, o esforço sobe.

## 8. Complexidade

**P (pequena).** Não há construção em Salesforce nem mudança de código. O trabalho é de
levantamento, definição, extração pontual e confirmação escrita. A complexidade sobe para M
se D3 indicar várias fontes sem relatório pronto, ou se D6 pedir série histórica.

## 9. Pedido ao consultor

Respostas às dúvidas D1 a D12 e confirmação ou correção das premissas P1 a P5. Com isso, a
análise pode ser refinada e o estágio de recon pode começar sobre a fonte real dos dados.

**Estimativa de esforço:** 4–10 h

Premissas que mais pesam na faixa:
- Lista de até 10 indicadores com fonte já existente em relatório ou planilha (P1, P3). Lista
  maior ou fonte manual empurra para o topo ou além da faixa.
- Extração feita pelo cliente com acesso à fonte, e consultor só organiza e valida (P5). Se
  o consultor extrai, soma de 2 a 4 h.
- Baseline de ponto único na data de corte (P4). Série histórica de 6 a 12 meses pode dobrar o
  limite superior.
- Um ciclo de revisão com o cliente e confirmação escrita em até 5 dias úteis (P2). Cada ciclo
  extra soma cerca de 1 a 2 h de consultor.
- Faixa ampla porque as dúvidas D1, D3 e D6 ainda estão em aberto. O arquiteto não é envolvido
  nesta faixa, pois não há desenho técnico; o refinamento vem após as respostas.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
