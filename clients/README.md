# Workspaces de cliente

Cada cliente tem seu próprio diretório aqui: `clients/<nome-do-cliente>/`,
contendo um projeto Salesforce DX padrão:

```
clients/<nome-do-cliente>/
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
```

Para criar o workspace de um novo cliente:

```bash
sf project generate --name clients/<nome-do-cliente>
```

Autentique o org do cliente com um alias igual ao nome do diretório, para
que `sfagents run --client <nome> --deploy` funcione sem configuração extra:

```bash
sf org login web --alias <nome-do-cliente>
```

Nenhum workspace de cliente é versionado neste template inicial — cada um
é adicionado conforme o cliente entra no fluxo.
