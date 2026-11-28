---
name: revisar-apex
description: Revisão de código e de segurança que o desenvolvedor faz no próprio Apex antes de dar o build por concluído — acesso a dados, injeção, compartilhamento, tratamento de erro e legibilidade. Use no build com código, depois de os testes passarem e antes de escrever "Resultado do build: concluído".
---

# Revisar o próprio Apex antes do PR

`construir-apex` trata de limite de plataforma e de teste. Esta é a segunda leitura, com
outra pergunta: se alguém mal-intencionado, ou só distraído, usar esta classe, o que ela
deixa passar? Leia o código inteiro de novo, do começo ao fim, com esta lista ao lado. Os
itens de reprovação automática da skill `padrao-entrega` continuam valendo; aqui está o
que eles não cobrem.

## Quem pode o quê

- **Compartilhamento declarado.** Toda classe diz `with sharing`, `without sharing` ou
  `inherited sharing`. Sem declaração não passa. `without sharing` só com o motivo escrito
  num comentário e no plano de build.
- **Permissão de objeto e de campo: depende da versão da classe.** Na API 67.0 em diante, o
  Apex roda as operações de banco em **modo de usuário por padrão** (permissão de objeto, de
  campo e compartilhamento de quem executa); na 66.0 e anteriores, o padrão é o modo de
  sistema, que lê e grava o que o usuário não poderia. Fonte: Apex Developer Guide, "Set an
  Access Mode for Database Operations"
  (https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-classes-enforce-usermode.html,
  lida em 2026-11-28). Leia a `<apiVersion>` do `-meta.xml` antes de revisar:
  - **67.0 ou mais:** código chamado por tela, agente ou API já respeita quem chamou; deixe
    explícito com `WITH USER_MODE` / `as user` mesmo assim, para a regra não depender da
    versão. Onde o modo de sistema é intencional (trigger ou job que grava campo que o
    usuário não edita), escreva `WITH SYSTEM_MODE`, `as system` ou
    `AccessLevel.SYSTEM_MODE` na operação e o motivo no plano. Sem isso, a automação falha
    para o usuário comum e passa no teste do administrador.
  - **66.0 ou menos:** o padrão é sistema; código chamado por tela, agente ou API precisa de
    `WITH USER_MODE` na consulta e modo de usuário na gravação.
  - Em modo de usuário a operação sempre respeita o compartilhamento; em modo de sistema,
    quem decide é a palavra `with`/`without`/`inherited sharing` da classe (mesma página).
  - Erro de permissão em modo de usuário: `QueryException.getInaccessibleFields()` na
    consulta e `DmlException.getDmlFieldNames()` na gravação dizem quais campos faltaram.
  - Não suba a `<apiVersion>` de classe antiga para 67.0 dentro de uma demanda sem testar
    com o usuário que executa: muda o comportamento.
- **O que volta para a tela.** Método `@AuraEnabled` e método invocável devolvem só o que
  quem chamou pode ver. Não devolva o registro inteiro por comodidade.

## Injeção

- Nenhuma consulta dinâmica montada com texto de entrada. Use variável de ligação; quando
  o nome de campo ou de objeto precisa ser dinâmico, confira contra a descrição do objeto
  antes de usar.
- O mesmo vale para busca textual e para qualquer texto que vire parte de comando.

## Segredo e dado

- Nenhum token, senha, chave ou endereço de sistema no código, em Custom Metadata, em
  Custom Setting ou em comentário. Credencial é Named Credential.
- Nenhum Id fixo de registro, perfil, usuário ou fila.
- Mensagem de log e de exceção não leva dado pessoal nem corpo de requisição com dado de
  cliente. Registre o Id e o que falhou.
- Nada de `System.debug` com registro inteiro esquecido no caminho.

## Erro

- Nenhum `catch` vazio. Erro tratado é registrado ou devolvido com mensagem que a pessoa
  entende.
- Gravação em lista com sucesso parcial permitido: os erros de cada registro são lidos e
  tratados, não ignorados.
- Trabalho assíncrono que falha deixa rastro consultável; ninguém descobre falha de job
  olhando o que não aconteceu.
- Exceção para o agente ou para o Flow que chamou vira saída com código de resultado
  (`.claude/skills/agentforce/SKILL.md`), não estouro.

## Trigger

- Um trigger por objeto, sem regra dentro: ele só chama a classe.
- Protegido contra reentrada: a gravação que a própria classe faz não roda a lógica de novo
  sem necessidade.
- Compara valor novo com valor antigo antes de agir: só trabalha quando o campo que
  importa mudou.
- Respeita o mecanismo de desvio de trigger da org, se o cliente tem um (veja o `CLAUDE.md`
  da conta e as fixtures).
- Lote: o trigger recebe até 200 registros por vez; consulta e gravação fora do laço, com
  os Ids num conjunto e uma consulta com `IN` (Apex Developer Guide, "Trigger and Bulk
  Request Best Practices",
  https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-triggers-bestpract.html).
- Dois triggers no mesmo objeto e evento rodam em ordem não garantida (skill
  `salesforce-doutrina`, "Ordem de execução"): mais um motivo para um trigger só.

## Leitura

- Nome de classe, método e variável diz o que é, na convenção do cliente.
- Método faz uma coisa. Método que não cabe numa tela pede divisão.
- Comentário explica o porquê e a regra de negócio, não repete o código.
- Nada fora do escopo: nenhuma refatoração que a demanda não pediu.
- Versão de API da classe igual à do projeto.

## Analisador estático

Se o projeto do cliente tem analisador de código configurado (PMD ou Code Analyzer) e a
ferramenta existe no ambiente da sessão, rode sobre as classes da demanda e trate o que for
de segurança. Se não existe, não instale nada: diga no plano que a revisão foi manual.

## Registre no plano de build

Seção "Revisão de código", curta: o que foi conferido, cada `without sharing` e cada uso
intencional de modo de sistema com o motivo, e o que ficou como dívida para o
`06-entrega.md`.
