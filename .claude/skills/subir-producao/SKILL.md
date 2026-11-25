---
name: subir-producao
description: Checklist do consultor para levar uma demanda homologada à produção do cliente e registrar a subida. Use quando uma demanda foi homologada e precisa ir para produção. É trabalho de gente — agente e esteira nunca tocam produção.
---

# Subir para produção

**Isto é para o consultor.** A esteira e os agentes só conhecem `sbx-<cliente>-dev` e
`sbx-<cliente>-qa` (guardrail #1). Nenhum agente executa, valida ou simula deploy em
produção, e esta skill não muda isso: um agente pode montar o checklist de uma demanda a
partir dos artefatos, e quem sobe é uma pessoa, com o próprio usuário.

"Entregue" no Squad OS quer dizer homologado, não em produção. A subida precisa ficar
registrada, senão ninguém sabe o que o cliente está usando.

## Antes

- A demanda está `entregue` (homologada pelo cliente) e o PR dela tem CI verde.
- Leia `06-entrega.md`: passos manuais pós-deploy, plano de rollback, permissões.
- Leia a seção "Versões e ativação" do design: em produção a versão nova entra inativa e a
  ativação é passo separado, combinado com o cliente.
- **Ordem entre demandas.** Veja em `00-preflight.md` e no design se outra demanda mexe nos
  mesmos componentes. Processos de aprovação, Flows do mesmo objeto e regras de validação
  têm ordem: suba na sequência em que foram homologadas e confira a ordem depois.
- Confirme usuários citados na solução (aprovador, dono de fila, usuário de integração):
  o que estava ativo na sandbox pode não estar em produção.
- Combine a janela com o cliente. Automação que dispara e-mail ou integração não sobe em
  horário de operação sem aviso.

## Durante

- Valide antes de implantar (`--dry-run` / validação apenas) e rode os testes Apex da
  demanda.
- Implante só os componentes da demanda (o pacote do PR), não a branch inteira.
- Execute os passos manuais de `06-entrega.md`, na ordem.

## Depois

- Confira na org: versão ativa do Flow ou do agente, ordem dos processos, permission set
  atribuído a quem precisa.
- Faça o teste de fumaça do roteiro do cliente com um registro de teste, e apague-o.
- **Registre no card**, em comentário: data e hora, quem subiu, o id do deploy, o que foi
  ativado e o que ficou para depois. Sem esse registro, a subida não aconteceu para o time.
- Se algo divergiu do que foi homologado, avise o cliente e abra uma demanda; não corrija
  direto em produção.
