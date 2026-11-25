---
name: pacote-e-rollback
description: Como o agente de release monta o pacote da demanda, valida, registra o que foi implantado e escreve um plano de rollback que alguém consegue executar. Use na etapa de release, antes de qualquer deploy, e ao preparar o material que o consultor leva para produção.
---

# Pacote e rollback

O release fecha a demanda na sandbox de QA e deixa pronto o que o consultor precisa para
subir em produção. Produção nunca é alvo do agente: ele prepara, o humano executa
(`.claude/skills/subir-producao/SKILL.md`).

## 1. O pacote tem só o que é da demanda

- Parta do plano de build: a lista de componentes criados e alterados é a fonte. Compare
  com o que mudou na branch `feature/<DEMAND-ID>` em `force-app/`. Diferença entre as duas
  listas se resolve antes do deploy: componente na branch e fora do plano não entra sem
  explicação; componente no plano e fora da branch é falha de build.
- Nomeie os componentes um a um no `package.xml`. Nada de curinga.
- Permission set e perfil levam só o que a demanda acrescenta. Perfil inteiro no pacote
  sobrescreve acesso que outra demanda deu.
- Layout, página e valor de picklist também são componente: confira que entraram.
- Se outra demanda aberta alterou o mesmo componente (`00-preflight.md`), o pacote leva a
  versão que contém as duas, ou a ordem entre elas está escrita. Nunca sobrescreva o que
  a outra entregou.

## 2. Ordem e dependência

O deploy resolve a ordem dentro de um pacote, mas não entre pacotes nem com passo manual.
Escreva a sequência quando houver:

1. o que precisa existir antes (objeto e campo antes do Flow que os usa, classe antes do
   Flow que a chama);
2. o deploy;
3. passos manuais que o pacote não leva (`.claude/skills/carga-e-migracao/SKILL.md`);
4. ativação das versões novas, conforme "Versões e ativação" do plano;
5. desativação do que a demanda substitui.

Ativação é passo separado e posterior ao deploy. Versão nova entra inativa.

## 3. Valide antes

- Validação sem gravar (`--dry-run`) contra a org alvo, com a org explícita no comando, e
  com os testes Apex das classes da demanda quando há código.
- Falhou: leia o erro inteiro e classifique (`.claude/skills/triagem-de-deploy/SKILL.md`).
  Não tire componente do pacote para a validação passar.
- Classe com job agendado pendente não aceita deploy (EPLAST-33): confira o preflight.

## 4. Remoção

Nenhuma remoção de campo, objeto ou classe entra no pacote de uma demanda comum. Se o
design pede remover algo, isso vai num `destructiveChanges` separado, com aprovação nominal
e backup, e é sempre escalado. Tirar de uso (layout, permissão, desativar) não é remover.

## 5. Plano de rollback que funciona

"Reverter o deploy" não é plano. Para cada componente, diga como voltar:

| O que foi feito | Como desfazer |
|---|---|
| Versão nova de Flow, agente ou modelo de prompt ativada | Reativar a versão anterior, com o número dela |
| Classe ou trigger alterado | Reimplantar a versão anterior, que está no commit tal da `main` |
| Componente novo (campo, objeto, Flow novo) | Desativar ou tirar de uso; não apagar na hora |
| Permissão concedida | Tirar a atribuição ou reimplantar o permission set anterior |
| Passo manual (membro de fila, registro de configuração) | O passo inverso, com o valor de antes |
| Carga ou correção de dado | De onde restaurar o valor anterior |

Diga também:

- **o sinal de que é preciso voltar**: o que observar depois do deploy, e em quanto tempo;
- **o que não tem volta**: dado gravado pela automação nova enquanto esteve ativa, mensagem
  já enviada, chamada já feita a outro sistema. Rollback de metadata não desfaz dado;
- a ordem do rollback, que é a inversa da do deploy.

O estado de antes precisa estar registrado **antes** do deploy: versão ativa de cada Flow e
agente (está no preflight e em "Versões e ativação"). Sem isso não há para onde voltar.

## 6. O que fica no `06-entrega.md`

- componentes implantados, um por linha, com o tipo;
- org, data e hora, identificador do deploy, resultado dos testes;
- versão ativa antes e depois, para cada item versionado;
- passos manuais feitos e os que ficam para produção, com dono;
- o plano de rollback;
- o material para produção: o mesmo pacote, a sequência e os passos manuais, escritos para
  o consultor executar.

## Nunca

- Alvo com `prod`, `prd` ou `production` no nome, ou qualquer org fora das duas sandboxes
  do cliente.
- Comando de deploy de produção pronto para alguém colar.
- Deploy que apaga componente sem o processo de remoção.
- Pacote com componente de outro cliente ou de outra demanda.
