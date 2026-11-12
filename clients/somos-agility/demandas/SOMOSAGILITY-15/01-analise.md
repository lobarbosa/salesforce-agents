# 01 — Análise: SOMOSAGILITY-15 — Layout de página inicial

**Status:** BLOQUEADA aguardando respostas às pendências P1 e P2 (seção "Pendências bloqueantes").
Esta análise não deve ser usada para desenho até as pendências serem respondidas.

## 1. Contexto de negócio

O cliente (Somos Agility) quer limpar a aba **Início** de todos os usuários, retirando visualizações
de objetos/painéis que hoje poluem a tela inicial. A origem do pedido é a Governança/PMO do cliente,
que enviou o pedido por e-mail, anexado ao card.

Fontes usadas nesta análise:
- `demanda.md`: pedido do consultor. Diz "retirar de todos os usuários" e "retirar da aba início",
  mas a lista de objetos termina abruptamente e não aparece no texto.
- `comentarios-do-card.md`: comentário do cliente de 2026-10-19 dizendo apenas "Documento anexo com os detalhes".
- Anexo PDF do card (e-mail da Governança/PMO do cliente para a Agility Sistemas): repete o pedido e diz
  que a lista real dos objetos/painéis está embutida como imagem. A extração de texto não a alcança,
  e nesta sessão não há OCR. Não abri o PDF neste agente: ele contém dados pessoais de terceiros e não
  consta liberação de anexo para a sessão. Se a lista precisar ser lida, quem libera é delivery, depois de
  confirmar que o arquivo não tem dado pessoal, ou o cliente envia a lista em texto no card.

## 2. Objetivo

Remover da aba Início a exibição dos objetos/painéis indicados pelo cliente, para todos os usuários
(ou para os perfis que o cliente confirmar), sem apagar os objetos nem os dados.

Objetivo mensurável (a confirmar com a lista): ao abrir a aba Início, nenhum dos componentes da lista
aparece, para nenhum dos perfis do escopo confirmado.

## 3. Regra de negócio

- RN-1: os componentes a ocultar são os que o cliente listar (pendência P1). Hoje a lista é desconhecida.
- RN-2: o escopo de usuários é o que o cliente confirmar (pendência P2). O pedido diz "todos os usuários",
  e isso é uma premissa, não um fato.
- RN-3: a ocultação é de exibição na aba Início. Os objetos, relatórios, dashboards e dados continuam
  existindo e acessíveis pelas abas e fluxos próprios. Não é exclusão nem mudança de dado.
- RN-4: a mudança não pode afetar outras abas, outros apps nem outros componentes da mesma página
  que não estão na lista.

## 4. Critérios de aceite (Gherkin)

Os critérios são genéricos de propósito, porque o componente exato ainda é desconhecido. Cada componente
da lista de P1 vira um cenário concreto antes do design.

```gherkin
Funcionalidade: Remoção de componentes da aba Início

  Cenário: Componente listado não aparece na aba Início para o perfil no escopo
    Dado um componente X listado na aba Início (pendência P1 respondida)
    E um usuário com o perfil Y no escopo (pendência P2 respondida)
    Quando o usuário abre a aba Início
    Então o componente X não é exibido

  Cenário: Componente listado continua acessível fora da aba Início
    Dado um componente X removido da aba Início
    Quando o usuário com perfil Y acessa o objeto ou relatório de origem pela aba própria
    Então o objeto ou relatório continua acessível e com os mesmos dados

  Cenário: Usuário fora do escopo mantém a aba Início atual
    Dado um perfil Z fora do escopo confirmado
    Quando o usuário abre a aba Início
    Então os componentes da página permanecem como estavam antes da mudança

  Cenário: Componentes não listados permanecem visíveis
    Dado a página Início com componentes além dos listados
    Quando a mudança for aplicada
    Então esses componentes continuam visíveis para os mesmos perfis

  Cenário: Mudança é verificável em sandbox antes de ir para QA
    Dado a configuração aplicada na sandbox de dev
    Quando o agente de QA abre a aba Início com um usuário de teste de cada perfil do escopo
    Então o resultado de cada perfil é registrado em 05-testes.md com print sem dado de cliente
```

Observação: o último cenário é de processo. Ele vem do guardrail de dados reais: a validação não pode
usar registro real de cliente.

## 5. O que a demanda NÃO diz

1. Quais são os objetos, painéis, componentes ou relatórios a retirar. A lista está em imagem no anexo e
   nenhum texto legível a traz. Este é o ponto que bloqueia o design.
2. Para quais usuários ou perfis vale a remoção. "Todos os usuários" pode significar todos os perfis, ou
   só alguns que o cliente considera do uso da aba.
3. Se a remoção é só para a aba Início ou também para outras telas, apps ou páginas que usem os mesmos componentes.
4. Qual mecanismo o cliente espera: remover o componente da página Início (Lightning Page), ocultar por
   permissão, retirar o relatório/dashboard da lista de visualização ou outra coisa. Cada um muda o desenho.
5. Se a Início é uma página Lightning única por app, ou se há páginas diferentes por perfil ou por app.
   Isso não foi confirmado na org.
6. Se algum componente da lista é um painel que depende de dados ou de um Flow. Remover a exibição não
   deve quebrar nada, mas é preciso confirmar.
7. Prazo ou janela de mudança. A org é do cliente e há regra de deploy por horário no CLAUDE.md da conta? Não consta.
8. Quem valida o resultado no lado do cliente (Governança/PMO ou o usuário-chave). Não foi indicado.

## 6. Pendências bloqueantes

**P1 (bloqueante): lista dos objetos/componentes/painéis a retirar da aba Início.**
Pedido ao cliente: enviar a lista em texto, no card (sem dado pessoal). Pode ser um print sem dado de
cliente, liberado no card por delivery. Sem isso não há desenho.

**P2 (bloqueante): escopo de usuários/perfis.**
Pergunta ao cliente: "todos os usuários" significa todos os perfis? Se não, quais perfis, e quais
usuários ficam de fora (por exemplo, administradores ou o time da Governança).

## 7. Premissas a validar (pendentes, não assumidas)

- PV-1: o escopo é "todos os perfis" até P2 ser respondida. **PENDENTE.**
- PV-2: a remoção é de exibição na aba Início, sem exclusão de objeto, campo ou dado. **PENDENTE.**
- PV-3: a Início é uma Lightning Page (App Builder) acessível por perfil/app, e a mudança pode ser feita
  por configuração, sem código. **PENDENTE de confirmação via `sf` CLI na org de dev.** Não confirmado.
- PV-4: não há integração ou painel de terceiros que dependa do componente a retirar. **PENDENTE.**
- PV-5: a validação em QA usa usuários de teste dos perfis do escopo, sem registro real de cliente. **PENDENTE.**

## 8. Complexidade

**M (provisório).** Justificativa: a mudança em si pode ser pequena (retirar N componentes de uma página),
mas o número de componentes, a quantidade de perfis e o mecanismo escolhido (Lightning Page, permissão ou
relatório) ainda são desconhecidos. Se o escopo for só remover componentes de uma página e não houver
dependência, cai para P. Se envolver várias páginas ou perfis com regras diferentes, vai para G.

## 9. Estimativa de esforço

**Estimativa de esforço:** 2–8 h
Premissas que mais pesam na faixa:
- Número de componentes na lista (P1): de poucos a dezenas muda muito o esforço de configurar e testar.
- Quantidade de perfis no escopo (P2): cada perfil é uma rodada de teste em dev e em qa.
- Mecanismo escolhido: configuração de Lightning Page é rápida; ocultar por permissão em vários perfis é mais trabalhoso.
- Homologação com o cliente: fora da faixa, depende de disponibilidade da Governança/PMO.

Faixa larga por causa das pendências P1 e P2. O arquiteto refina no design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
