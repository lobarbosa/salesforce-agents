---
name: carga-e-migracao
description: Como tratar o que a entrega precisa além da metadata — dado de configuração que tem de existir no destino, e correção ou carga de registros que já existem. Use em design e build quando a solução depende de registros (fila com membros, metadata customizada, tabela de apoio) ou altera dados já gravados.
---

# Carga e dado de configuração

Deploy leva metadata. Não leva registro. Solução que funciona na dev porque alguém criou
os registros à mão chega à QA e à produção sem eles, e falha no primeiro teste.

## Separe três coisas

| O quê | Exemplo | Como chega ao destino |
|---|---|---|
| **Configuração que é metadata** | Registro de Custom Metadata Type, valor de picklist, fila, grupo | No pacote, como qualquer componente |
| **Configuração que é dado** | Registro de Custom Setting, tabela de apoio em objeto, membro de fila ou grupo, usuário aprovador | Passo manual ou script, repetido em cada org |
| **Dado de negócio** | Preencher campo novo nos registros existentes, corrigir registros errados | Carga, com decisão do cliente; em produção, sempre por gente |

## Prefira o que viaja no pacote

Parâmetro que a solução lê (limite, faixa, de-para, endereço lógico) fica em **Custom
Metadata Type**: é versionado, vai no deploy e é igual em todas as orgs. Custom Setting e
objeto de apoio só quando o cliente precisa editar o valor no dia a dia sem deploy; nesse
caso o design diz quem edita e por qual tela.

Nunca fixe Id de registro, de perfil, de usuário ou de fila em Flow ou classe: o Id muda de
uma org para outra. Busque pelo nome de API ou pelo nome de desenvolvedor.

## O que o pacote não leva, e alguém precisa fazer

Liste no plano de build, em "Passos manuais", com dono e com a org:

- membros de fila e de grupo público;
- atribuição de permission set a pessoas;
- aprovador de processo de aprovação que é usuário nomeado;
- registros de Custom Setting e de tabelas de apoio;
- credencial de integração;
- ativação de versão (Flow, agente, modelo de prompt), conforme "Versões e ativação".

Fila sem membro e aprovador inativo fazem o caminho feliz falhar no QA (EPLAST-40). Passo
manual sem dono é falha de ambiente marcada para daqui a dias.

Na dev e na QA, o agente pode criar o que for **dado de teste**. Não cria membro de fila
com pessoa real, não atribui permissão a outro usuário, não mexe em credencial.

## Carga em registros que já existem

Mudança que alcança registros já gravados é escopo próprio. O design diz:

- **Quantos**: contagem agregada, por critério (`COUNT()`, nunca a lista).
- **A regra**: de onde vem o valor de cada registro. Se depende de julgamento, não é carga
  automática.
- **O que dispara**: gravar em massa aciona os Flows, triggers e validation rules do
  objeto. Diga o que deve rodar e o que deve ser contornado, e por qual mecanismo oficial
  da org.
- **Como desfazer**: o valor anterior fica guardado onde?
- **Quem executa em produção**: sempre o consultor, com janela. A esteira prepara e prova
  na sandbox; não executa em produção.

Na sandbox, prove a carga com registros de teste criados para isso, nunca sobre os
registros copiados da produção que estiverem na sandbox.

## Script de carga

- Em lotes, com tamanho que cabe nos limites (uma operação por lote, não uma por registro).
- Pode rodar duas vezes sem estragar: confere antes de gravar.
- Registra quantos leu, quantos gravou, quantos falharam e por quê, só em contagem.
- Fica na pasta da demanda, não em `force-app/`, e o plano diz que é para rodar uma vez.

## Antes de escrever "concluído"

- [ ] Parâmetros em Custom Metadata Type, ou o motivo de não estarem.
- [ ] Nenhum Id fixo em Flow ou classe.
- [ ] Passos manuais listados, com dono e org, repetidos para QA e produção.
- [ ] Se há carga: contagem, regra, o que dispara, como desfazer e quem executa.
- [ ] O que foi criado à mão na dev durante o build está listado, para ser recriado na QA.
