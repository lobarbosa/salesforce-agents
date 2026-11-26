---
name: quebrar-entregavel
description: Como o planejador fatia um entregável contratado em demandas que cabem na esteira — tamanho, dependência, ordem e o que vira pergunta. Use ao gerar o plano de demandas de um projeto, antes de escrever o plano-demandas.json.
---

# Quebrar entregável em demandas

A esteira roda uma demanda por vez por cliente, e cada demanda atravessa quatro gates e
uma homologação. Demanda grande demais trava a fila inteira do cliente; demanda pequena
demais gasta um ciclo de aprovação com quase nada. O corte certo é o que alguém consegue
aceitar sozinho.

## O teste de uma boa demanda

Uma demanda está bem cortada quando as cinco respostas são "sim":

1. Dá para demonstrar ao cliente sozinha, sem esperar outra?
2. O cliente consegue dizer "aceito" ou "não aceito" olhando só para ela?
3. Cabe em poucos critérios de aceite observáveis (em geral de três a oito)?
4. Um mesmo dono do lado do cliente responde às perguntas dela?
5. Se ela for a última a ser feita, o que veio antes continua tendo valor?

Se alguma é "não", recorte.

## Sinais de corte errado

| Sinal | O que fazer |
|---|---|
| Título com "e" ligando duas coisas | São duas demandas |
| Mais de um processo de negócio ou mais de uma área do cliente | Uma demanda por processo ou área |
| Critérios que dependem de respostas de pessoas diferentes | Separe por quem responde |
| "Fase 1" e "Fase 2" do mesmo assunto | Corte por resultado, não por fase |
| Demanda de "preparação", "estrutura" ou "base" sem nada que o cliente veja | Junte à primeira demanda que usa a base |
| Demanda só de "testes" ou só de "documentação" | Não existe: as etapas do fluxo já são isso |
| Um título que cita componente técnico | Reescreva pelo resultado; a solução é do arquiteto |

## Dependência e ordem

- Diga em `perguntas`, ou no texto, do que a demanda depende: outra demanda, uma resposta
  do cliente, um acesso, um sistema externo disponível.
- Ordene para que cada demanda encontre pronto o que precisa. O que não depende de nada e
  entrega algo visível vem primeiro: o cliente vê resultado cedo e a homologação começa a
  girar.
- O que carrega mais incerteza (integração, regra ainda em discussão, dado a migrar) vem
  cedo o bastante para o risco aparecer, mas não antes de as perguntas terem dono.
- Duas demandas que mexeriam no mesmo objeto ao mesmo tempo ficam em sequência, nunca lado
  a lado: a sandbox é uma só.
- Não crie cadeia longa em que tudo depende da primeira. Se a primeira trava, o projeto
  inteiro para; procure o que pode andar em paralelo no tempo, uma depois da outra, sem
  depender dela.

## O que quase sempre precisa de demanda própria

- cada integração com sistema externo;
- carga ou migração de dado;
- cada perfil ou área com processo próprio;
- relatórios e painéis de gestão, depois que o processo que os alimenta existe;
- treinamento ou material de uso, quando está no contrato como entregável.

## Perguntas, não suposições

Você não conhece a org. Tudo o que depende do que existe lá, ou de regra que o contrato não
detalha, entra em `perguntas`, redigido para caber numa resposta curta. Demanda sem
nenhuma pergunta numa org que você não viu é sinal de suposição escondida.

Escopo que o contrato não cobre e que você percebe ser necessário não vira demanda: vira
uma pergunta em destaque, para quem gere a conta decidir se é aditivo.

## Peso e cobertura

- Toda demanda aponta para um entregável do contrato, e todo entregável tem pelo menos
  uma demanda. Confira os dois sentidos antes de gravar.
- Não infle: entregável que já é uma unidade vira uma demanda.
- Se um entregável pede mais de seis demandas, ele provavelmente são dois; diga isso no
  encerramento em vez de forçar.

## Antes de gravar o plano

- [ ] Cada demanda passa no teste das cinco perguntas.
- [ ] Nenhum título cita componente técnico nem decide declarativo ou código.
- [ ] Dependências escritas e ordem coerente com elas.
- [ ] Todo entregável coberto; nenhuma demanda sem entregável.
- [ ] O que depende da org ou do cliente está em `perguntas`.
