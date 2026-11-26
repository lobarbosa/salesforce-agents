---
name: construir-flow
description: Checklist do builder declarativo para Flow, layout, permissão e relatório — o que conferir antes de dar o build por concluído, a partir dos defeitos que o QA já encontrou. Use na etapa de build declarativo, antes de escrever "Resultado do build: concluído".
---

# Construir declarativo sem voltar do QA

Cada item abaixo é um defeito que o QA encontrou em demanda real. Confira antes de fechar o
plano de build; o verificador roda depois de você, mas ele testa os critérios, não lê o XML.

## Flow

- **Laço e coleção.** Para cada laço, confira de qual coleção ele lê. Dois caminhos de busca
  que desembocam no mesmo laço: o laço lê só uma coleção, a outra não itera, o contador
  fica em zero e a decisão cai no ramo padrão (EPLAST-27: todo código de conta devolvia
  "mais de uma conta" com a lista vazia).
- **Ramo padrão.** Leia o que acontece em cada decisão quando nenhum ramo casa. O ramo
  padrão não pode ser o caso mais comum por acidente.
- **Entrada que não é o que o nome diz.** Entrada chamada `recordId` recebe o que o
  chamador mandar. Valide a forma antes do Get Records; texto que não é Id num filtro por Id
  derruba o Flow.
- **Comparação de Id.** Só igualdade. "Começa com" em campo de Id salva e falha ao rodar.
- **Caminho de falha.** Toda consulta, gravação e ação tem `faultConnector` para uma saída
  com mensagem. Nenhum caminho termina em erro não tratado.
- **Screen Flow.** Cada tela tem como avançar e como sair: confira os botões de navegação
  de cada tela, inclusive a última (EPLAST-41: tela sem botão para avançar, duas rodadas).
- **Critério de entrada** em todo Flow acionado por registro.
- **Quem executa.** Flow agendado ou em contexto de sistema: o usuário que roda precisa das
  permissões da demanda (EPLAST-33).
- **Texto.** Acentuação e rótulos em português conferidos (EPLAST-28: título sem acento).
  Texto fixo como "sem descrição" não pode ser gravado como dado (EPLAST-29).

## Versão e ativação

- Versão nova, nunca edição da ativa. Registre na seção "Versões e ativação" do plano a
  versão que estava ativa e a que você criou.
- O que a demanda **substitui** precisa ser desativado no destino, e isso é componente do
  pacote ou passo escrito. Automação antiga que continua ativa roda junto com a nova
  (EPLAST-47, duas rodadas).
- Modelo de prompt (`GenAiPromptTemplate`) também tem versão: sem versão ativa, a geração
  não funciona (EPLAST-41).
- Processo de aprovação: ao tocar um, confira a ordem (`processOrder`) de todos os
  processos do objeto, inclusive os de outra demanda aberta (SOMOSAGILITY-17 e 22).

## Layout, permissão e visibilidade

- **Campo novo em todos os layouts do objeto**, não só no principal. Liste os layouts
  (inclusive por tipo de registro) e marque um a um (SOMOSAGILITY-26: 9 de 16 sem o campo).
- **Permission set**: edição aditiva sobre o arquivo do repositório. Todo campo, objeto,
  aba e classe que a demanda cria entra no permission set dela.
- **Quem não tem a permissão vê o quê?** Painel e relatório aparecem vazios para quem não
  tem acesso ao campo (EPLAST-39). Diga no plano quem enxerga.

## Relatório e painel

- Valor vazio e valor fora da lista têm destino definido: agrupamento "sem valor" e "fora da
  lista" configurados, não um traço (EPLAST-39).
- Abra o relatório com dado de teste que cubra cada agrupamento antes de dar por pronto.

## Antes de escrever "concluído"

- [ ] Cada critério de aceite tem o componente que o atende, nomeado no plano.
- [ ] Li cada Flow do começo ao fim seguindo um caso feliz e um caso de borda.
- [ ] O deploy na sandbox de dev passou e os componentes existem na org (confira, não
      suponha).
- [ ] "Versões e ativação" preenchida, com o que precisa ser ativado e desativado.
- [ ] Pré-requisitos que o build não resolve (fila sem membro, licença, usuário) estão no
      topo do plano, com dono.

Se o design não fecha, pare e reporte: `**Resultado do build:** bloqueado`, com a pergunta.
Não resolva por conta própria uma regra de negócio.

Demanda com agente Agentforce: leia também `.claude/skills/agentforce/SKILL.md`.
