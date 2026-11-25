---
name: dados-de-teste
description: Como o verificador e o QA criam, reaproveitam e limpam dado sintético de teste numa sandbox — fixtures do cliente, validation rules, dado que dispara automação e o que nunca usar. Use na verificação e no QA antes de criar qualquer registro, e sempre que um caso estiver para ser marcado como não executado por falta de dado.
---

# Dados de teste

"Não há dado para testar" foi a causa mais comum de caso não executado no QA e na
verificação. Quase sempre o dado podia ser criado: o que faltou foi insistir além da
primeira validation rule.

Dado de teste está autorizado em toda demanda, de todo cliente, nas sandboxes da esteira,
salvo se o `CLAUDE.md` do cliente ou um comentário do card disser expressamente que não.

## 1. Comece pelas fixtures do cliente

`clients/<cliente>/fixtures/` guarda scripts de Apex anônimo que outra sessão já provou na
org, com um `README.md` que diz o que cada um cria e o que exige antes. Leia o README
primeiro.

- Existe o que você precisa: rode o script com a org da etapa explícita no comando, e
  troque o identificador de demanda no nome dos registros pelo da sua.
- Existe algo perto: copie e adapte, na pasta da demanda. Não altere o script provado.
- Não existe: monte (passo 2) e, depois de provado, acrescente às fixtures (passo 5).

## 2. Montar dado que passa nas validações

Antes de tentar criar, leia o que o objeto exige:

- campos obrigatórios (descrição do objeto);
- validation rules ativas e a **fórmula** de cada uma (Tooling API), para saber o que
  preencher em vez de adivinhar pelo erro;
- regras de duplicidade, que recusam o segundo registro parecido;
- o que o trigger do objeto valida ou chama, e se o cliente tem desvio oficial de trigger
  (está no README das fixtures ou no `CLAUDE.md` da conta).

Crie do pai para o filho. Uma recusa não encerra a tentativa: leia a mensagem, preencha o
que ela pede e tente de novo. Só depois de esgotar o que as regras pedem o caso é "não
executável", e aí a falha tem origem (`.claude/skills/provar-criterio/SKILL.md`).

Dev e QA podem ter regras diferentes: fixture que passa numa pode falhar na outra. No QA,
confira as validation rules da QA.

## 3. Regras do dado

- Todo registro com `TESTE <DEMAND-ID>` no nome, para ser achado e apagado.
- Documento, telefone, endereço e contato **sintéticos**. Quando a regra valida o formato
  ou o dígito do documento, use um valor de teste gerado para passar na validação, nunca
  um documento real.
- Nenhum endereço de e-mail real. Use o domínio reservado para exemplo, e não o escreva no
  artefato: formato de e-mail no artefato bloqueia o push.
- O menor número de registros que prova o critério. Volume só no teste de volume.
- Nunca use, altere ou apague registro que você não criou. Sandbox copiada de produção tem
  dado real: ele não é dado de teste.
- Nunca consulte registro para "pegar um exemplo". Exemplo se cria.

## 4. Dado que dispara automação

Antes de criar registro em objeto com Flow, trigger ou integração, leia pela metadata o que
a cadeia faz: e-mail, chamada externa, criação de outros registros, aprovação.

- Reduza o que sai da org: poucos registros, e destinatário de teste quando a automação
  envia mensagem.
- Liste no artefato, em "O que pode ter saído da org", cada registro que a cadeia criou e
  cada chamada externa registrada.
- Dado em uma transação e a ação testada em outra, para não somar limites de consulta.

## 5. Teste de volume

Critério com número ("até 200 registros", "pai com 150 filhos") se prova com o número.
Crie em lotes que caibam nos limites, meça a transação que importa e registre o consumo
(consultas, CPU) que a org devolveu.

## 6. Limpar e devolver

- Apague o que criou, do filho para o pai, ao final da etapa, salvo se o roteiro do
  cliente precisa do registro para a homologação: nesse caso, liste o que ficou e por quê.
- Desfaça o que mudou no usuário de execução (permission set da demanda, campo preenchido
  para passar numa validação) e registre o valor de antes e o de depois.
- O que não foi possível apagar (registro bloqueado, criado pela cadeia) fica listado, com
  o Id, para alguém apagar.

## 7. Virar fixture

Dado que deu trabalho para montar e passou na org vira script em
`clients/<cliente>/fixtures/`, com cabeçalho dizendo o que cria, o que exige antes e como
apagar, e uma linha nova na tabela do README com a demanda que o provou. É o que poupa a
próxima sessão.
