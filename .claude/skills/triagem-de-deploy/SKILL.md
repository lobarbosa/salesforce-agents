---
name: triagem-de-deploy
description: Como ler uma falha de deploy ou de validação e dizer de quem ela é — do pacote, do destino, de dependência, de teste ou do pipeline — e o que fazer em cada caso. Use quando um deploy, uma validação de PR ou o passo de deploy em QA falhar, antes de propor qualquer correção.
---

# Triagem de falha de deploy

Falha de deploy tem duas respostas ruins: tentar de novo sem ler, e tirar do pacote o que
deu erro. A primeira gasta uma execução; a segunda entrega a demanda pela metade. Leia,
classifique, e só então proponha.

## 1. Leia tudo

- O log inteiro do job, não só a última linha. O erro que importa costuma ser o primeiro;
  os seguintes são consequência dele.
- A lista de falhas por componente que o deploy devolve: nome, tipo, linha e mensagem.
- Qual org era o alvo e qual passo do pipeline falhou (autenticação, validação, deploy,
  testes). Falha antes do deploy não é falha de metadata.

## 2. Classifique

| Classe | Como reconhecer | De quem é | O que fazer |
|---|---|---|---|
| **Pacote** | Erro de sintaxe ou de valor no XML; componente citado que não está no pacote nem no destino | Build | Volta ao builder, com o componente e a mensagem |
| **Dependência ausente** | "não existe" ou "sem acesso" para campo, objeto, classe ou valor que a demanda usa mas não criou | Build ou ambiente | Se a demanda deveria levar: falta no pacote. Se deveria já existir no destino: é divergência (abaixo) |
| **Destino diferente do repositório** | O componente existe no destino com outra forma: versão ativa mais nova, campo com outro tipo, algo criado direto na org | Ambiente | Não force. Reporte a divergência; trazer o que só existe na QA é a skill `promover-qa-dev` |
| **Versão ativa** | Recusa ao alterar Flow, agente ou modelo de prompt em uso | Build | A regra é versão nova, nunca edição da ativa (skill `salesforce-doutrina`) |
| **Job pendente** | Classe não aceita alteração porque há job agendado ou em fila com ela | Ambiente | Está no preflight. Alguém desagenda; não é defeito do pacote (EPLAST-33) |
| **Teste** | Deploy aceito, teste Apex falhou ou cobertura abaixo do mínimo | Build, ou dívida do destino | Ver passo 3 |
| **Limite ou recurso da org** | Limite de componentes, de campos, de licença, recurso não habilitado no destino | Ambiente | Pessoa resolve; diga qual recurso e em qual org |
| **Permissão do usuário de deploy** | "sem permissão" do usuário de integração para o tipo de metadata | Ambiente | Pessoa ajusta a permissão; a esteira não altera credencial |
| **Pipeline** | Falha de autenticação, de instalação, de rede, tempo esgotado antes do deploy | Pipeline | Uma nova execução é legítima só aqui, e uma vez |

Diga a classe e a evidência (a linha do log). "Erro de deploy" não é diagnóstico.

## 3. Quando o que falha é teste

- **Teste da demanda falha**: construção. Volta ao builder.
- **Teste de outra classe falha, e passava antes**: a demanda quebrou algo. Construção, e
  é grave.
- **Teste de outra classe que já falhava no destino**: dívida da org. Prove (o teste falha
  sem o pacote) e reporte ao humano; a demanda não corrige por conta própria.
- **Falha só no destino, passa na dev**: diferença entre as orgs, quase sempre validation
  rule ou automação ativa só numa delas (SOMOSAGILITY-10). A correção costuma ser a fábrica
  de dados do teste preencher o que a regra exige.
- **Cobertura abaixo do mínimo**: escreve-se teste. Nunca se reduz a exigência, se
  desabilita teste ou se troca o nível de teste do deploy para passar.

## 4. Origem, para a esteira

No QA e na verificação, a classe vira a origem da falha
(`.claude/skills/provar-criterio/SKILL.md`): pacote, versão ativa e teste da demanda são
`construção`; destino diferente, job pendente, limite, permissão e pipeline são
`ambiente`. Isso decide se a demanda volta ao builder ou para com uma pessoa.

## 5. O que nunca fazer

- Tirar componente do pacote para o resto passar.
- Forçar por cima de divergência: sobrescrever o que está no destino sem saber quem pôs.
- Ignorar erros ou avisos do deploy com opção de linha de comando.
- Repetir a execução esperando resultado diferente, fora da classe "pipeline".
- Alterar secret, credencial ou permissão do usuário de integração.
- Qualquer tentativa em org que não seja uma das duas sandboxes do cliente.

## 6. O relato

Curto, para quem vai agir:

- o passo e a org em que falhou;
- a classe, com a linha do log que prova;
- o componente e a mensagem, por falha;
- de quem é e o que essa pessoa ou esse agente precisa fazer;
- o que foi tentado e o que não foi.

Sem nome de usuário da org nem endereço de e-mail copiado do log.
