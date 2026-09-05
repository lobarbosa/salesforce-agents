# Workspaces de cliente

Cada cliente tem seu próprio diretório aqui: `clients/<nome-do-cliente>/`, contendo:

```
clients/<nome-do-cliente>/
  CLAUDE.md              # "Conhecimento do Cliente" — briefing, fonte de verdade da conta
  sfdx-project.json
  force-app/
    main/
      default/
        objects/
        flows/
        classes/
        lwc/
        permissionsets/
        ...
  demandas/
    <DEMAND-ID>/          # uma por demanda registrada, ver raiz do repo: CLAUDE.md
```

## Criar um novo cliente

```bash
sf project generate --name clients/<nome-do-cliente>
cp clients/_template/CLAUDE.md clients/<nome-do-cliente>/CLAUDE.md
```

Preencha o `CLAUDE.md` do cliente a partir do template — é o que os agentes leem antes
de desenhar qualquer solução para essa conta (segmento, contatos, convenções próprias,
integrações existentes, regras específicas). Mantenha atualizado; é a mesma função que a
página "Conhecimento do Cliente" teria num painel visual — aqui vive como arquivo, no
mesmo repositório onde o trabalho acontece.

Autentique o org do cliente com um alias igual ao nome do diretório, para que os comandos
de deploy funcionem sem configuração extra:

```bash
sf org login web --alias <nome-do-cliente>
```

## Registrar e acompanhar demandas

```bash
sfagents demanda nova --client <nome-do-cliente> --titulo "..." --texto caminho/da/historia.md
sfagents demanda listar --client <nome-do-cliente>
sfagents demanda avancar --client <nome-do-cliente> <DEMAND-ID> analise   # inicia o ciclo
```

Veja a tabela de estágios e o fluxo completo de gates no `CLAUDE.md` da raiz do repositório.

Nenhum workspace de cliente é versionado neste template inicial — cada um é adicionado
conforme o cliente entra no fluxo.
