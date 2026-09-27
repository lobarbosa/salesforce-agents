---
name: conectar-ambiente
description: Passo a passo para conectar um ambiente Salesforce (dev ou qa) de um cliente à esteira — Connected App JWT, GitHub Environment, secrets e teste de conexão. Use ao integrar um cliente novo ou uma sandbox de QA nova, e sempre que "testar conexão" falhar ou a org autenticada não bater com a esperada.
---

# Conectar um ambiente Salesforce à esteira

Só existem dois ambientes possíveis: `dev` e `qa` (`ambientes.py` recusa qualquer outro).
Conectar um deles envolve **dois lugares diferentes**, e confundir os dois é o erro mais comum:

| Onde | O quê | Quem lê |
|---|---|---|
| Squad OS → aba do cliente | `orgAlias`, login URL, username, consumer key | Ninguém automatizado — é documentação pra humano |
| GitHub → Settings → Environments → `<cliente>-<ambiente>` | `SF_CLIENT_ID`, `SF_USERNAME`, `SF_JWT_KEY` | O workflow, na autenticação de verdade |

**Preencher só a tela do Squad OS não conecta nada.** A autenticação real do
`test-connection.yml` e do `run-demand.yml` usa os secrets do GitHub Environment, com o
alias sempre `sbx-<cliente>-<ambiente>` — hardcoded no workflow, independente do que estiver
digitado no campo `orgAlias` da UI.

## Passo a passo

1. **Salesforce**: crie (ou confirme) uma Connected App com JWT Bearer Flow habilitado na
   sandbox certa — dev ou qa, nunca a mesma Connected App reaproveitada entre ambientes de
   propósito diferente sem confirmar que o cliente permite. Gere o par de chaves e faça
   upload do certificado na Connected App.
2. **GitHub**: em Settings → Environments, crie (ou confirme que existe) o Environment
   `<cliente>-<ambiente>`. Ele também se cria sozinho na primeira vez que algum workflow o
   referencia via `workflow_dispatch` — mesmo que a execução falhe depois por falta de
   secret.
3. Adicione os 3 secrets nesse Environment:
   - `SF_CLIENT_ID` — Consumer Key da Connected App
   - `SF_USERNAME` — o usuário de integração da sandbox
   - `SF_JWT_KEY` — o **conteúdo do arquivo da chave privada** (nunca o Consumer Secret —
     é um erro fácil de cometer e o JWT Bearer Flow não usa Consumer Secret)
4. No Squad OS, preencha os campos informativos da aba do cliente (orgAlias, login URL,
   username, consumer key) — não autenticam nada, mas são a referência que qualquer pessoa
   do time consulta antes de mexer na org.
5. Dispare **testar conexão** no Squad OS. Isso roda `test-connection.yml`
   (`workflow_dispatch`, inputs `{client, ambiente}`), autentica via JWT e reporta o
   resultado para `/api/sync/conexao`.
6. Confira o resultado no card do cliente: `conectado` ou `erro`. Em caso de erro, os logs
   do job (`sf org login jwt`) dizem o motivo real — geralmente Consumer Secret usado no
   lugar da chave, certificado não batendo, ou usuário sem o perfil de integração.
7. **Só para o ambiente `dev`**: uma conexão bem-sucedida dispara sozinho o
   `org-assessment` — não precisa pedir.

## Antes de dar como concluído: confira contra copy-paste

Achado real (Eplast, 2026-09): o campo `orgAlias`/`loginUrl`/`username` de um cliente novo
apareceu com os dados **de outro cliente** (Acxya), quase certamente copiados de um card
como ponto de partida e nunca trocados. O sintoma não aparece em nenhum teste automático —
o teste de conexão só valida os secrets do GitHub, que são independentes desses campos.

Antes de marcar um ambiente como conectado, compare visualmente os campos da aba do cliente
contra os de outro cliente já conectado. Se dois clientes mostram exatamente o mesmo
`loginUrl` ou `username`, é copy-paste, não coincidência — pare e corrija antes de seguir.

## Nunca

- Nunca aceite ou peça a **Consumer Secret** para os 3 secrets do GitHub — JWT Bearer Flow
  usa a chave privada, não o secret da Connected App.
- Nunca marque um ambiente como conectado só porque a UI do Squad OS está preenchida — só o
  resultado de `test-connection.yml` confirma.
- Nunca reutilize o alias de outro cliente ou ambiente — o formato é sempre
  `sbx-<cliente>-<ambiente>` e as três camadas de guardrail (`ambientes.py`,
  `guard-prod.sh`, `guarda.py`) dependem disso.
