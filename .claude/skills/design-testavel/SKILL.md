---
name: design-testavel
description: Como o arquiteto escreve um design que o verificador e o QA conseguem provar — plano de prova por critério, pré-condições de ambiente, ativação e limites. Use na etapa de design, antes de fechar o 03-design.md.
---

# Design que dá para provar

Medição de 2026-11-25, em 36 demandas que chegaram ao QA: 45 roteiros reprovados contra 31
aprovados, e 22 de 54 verificações inconclusivas. Das 71 falhas registradas, cerca de 27
não eram defeito: o teste **não conseguiu executar** (sem dado, sem licença, versão inativa,
tela que não abriu). Outras 14 eram de ambiente ou ativação. Quase todas eram previsíveis
na hora do design.

O design não termina em "o que construir". Termina em "como cada critério será provado, e o
que precisa existir para isso".

## 1. Plano de prova por critério

Para cada critério de aceite de `01-analise.md`, uma linha no design:

| Critério | Como se prova na dev | Como se prova na QA | O que precisa existir |
|---|---|---|---|
| CA-01 | chamada do Flow com registro de teste | mesma chamada, mais a tela | conta de teste com tal campo preenchido |

Se você não consegue dizer como um critério será provado, ele não está pronto: ou a análise
volta, ou o critério vira "o que só o cliente confere", escrito assim.

Critério que depende de agendamento, de e-mail, de integração ou de resposta de modelo
precisa dizer qual é a prova aceita (registro criado, log, contagem), porque "funcionou" não
é evidência.

## 2. Pré-condições de ambiente

Confira no recon e escreva no design. Cada item abaixo já reprovou QA:

- **Dado de teste.** Qual registro o teste cria e o que as validation rules do objeto
  exigem para criá-lo. Se já existe fixture em `clients/<cliente>/fixtures/`, cite.
- **Usuário e licença.** O teste de perfil precisa de um usuário com aquele perfil. Há
  licença livre na sandbox de QA? (SOMOSAGILITY-27: sem licença, sem teste.)
- **Fila, grupo, aprovador.** Fila sem membros e aprovador inativo fazem o caminho feliz
  falhar (EPLAST-40). Diga quem precisa existir.
- **Permissão de quem executa.** Job agendado e Flow rodam como alguém; se esse alguém
  precisa de um permission set da demanda, isso é passo do design (EPLAST-33).
- **O que precisa estar desligado.** Automação antiga que a demanda substitui continua
  ativa no destino até alguém desativar (EPLAST-47). Diga qual e em que passo.
- **Diferença entre dev e QA.** Validation rule ou automação que existe numa e não na
  outra muda o resultado do teste (SOMOSAGILITY-10).

O que não puder ser garantido pelo build vira item de "Pré-requisitos" no topo do design,
com o nome de quem resolve. Pré-requisito sem dono é falha de QA marcada para daqui a dias.

## 3. Versões e ativação

Para cada Flow, agente ou modelo de prompt alterado: versão atual ativa, versão nova, e a
ordem de ativação em dev, QA e produção. Na QA, o QA ativa para testar; diga o que ele deve
ativar. Versão nova inativa foi causa de falha em pelo menos seis rodadas (EPLAST-27, 29,
35, 41).

Se outra demanda aberta mexe no mesmo componente (`00-preflight.md`), diga a ordem entre
elas e o que a segunda precisa conferir (SOMOSAGILITY-17 e 22: ordem de processos de
aprovação invertida).

## 4. Limites, com número

Não basta "bulkificado". Diga o pior caso real, medido no recon, e o limite que ele toca:

- **CPU síncrono**: um pai com muitos filhos na mesma transação (SOMOSAGILITY-10, 150
  filhos).
- **Jobs em fila**: atualização em massa que enfileira um job por registro estoura em 50
  (EPLAST-47: "Too many queueable jobs added to the queue: 51").
- **Consultas**: cadeia de automações do objeto pai somadas na mesma transação.

Se o pior caso passa do limite, o design muda (assíncrono, lote, agregação) ou declara o
teto aceito pelo responsável. Não deixe para o QA descobrir.

## 5. Perguntas de negócio

Seis builds voltaram bloqueados por pergunta que só o cliente responde. Antes de fechar,
liste o que você **assumiu** sobre a regra de negócio. Cada premissa: ou tem resposta
escrita no card, ou vira pergunta em destaque no topo do design, para ser respondida no
gate. Build não começa com pergunta aberta sobre regra.

## Antes de entregar o design

- [ ] Todo critério tem linha no plano de prova.
- [ ] Pré-requisitos de ambiente listados, com dono.
- [ ] Versões e ordem de ativação escritas.
- [ ] Pior caso de volume com número e limite.
- [ ] Premissas de negócio respondidas ou em destaque.

Se o desenho envolve agente Agentforce, leia também
`.claude/skills/agentforce/SKILL.md`.
