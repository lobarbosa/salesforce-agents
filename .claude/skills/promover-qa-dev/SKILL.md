---
name: promover-qa-dev
description: Como trazer para o repositório e para a sandbox de dev um componente que já existe na sandbox de QA de um cliente, pelo workflow promover-qa-dev. Use quando o cliente criou algo direto na QA, ou quando dev e QA divergiram e uma demanda depende do que só existe na QA.
---

# Promover da QA para a dev

Workflow `.github/workflows/promover-qa-dev.yml`. Serve para equalizar ambientes quando um
componente nasceu na sandbox de QA fora da esteira. Não é caminho de entrega: demanda
construída pela esteira vai da dev para a QA, nunca o contrário.

## Passos

Inputs do workflow: `client` (pasta em `clients/`), `agente`, `componentes` e `modo`
(`trazer`, `comparar` ou `implantar`).

- Para promover um **agente Agentforce**, informe só `agente` (o nome do Bot na QA).
- Para **componentes avulsos**, informe `componentes` no formato `Tipo:Nome,Tipo:Nome`
  (por exemplo
  `LightningComponentBundle:centralComercial,ApexClass:CentralComercialV1Controller`). Aí
  `agente` vira só o nome da promoção: a branch é `promocao/<cliente>-<agente>`.

1. **`modo: trazer`.** Baixa da QA, abre um PR e valida contra a dev.
2. **`modo: comparar`**, se quiser ver a diferença contra a dev antes.
3. **Revisar o PR.** Confira que veio só o pedido e que não há dado de cliente em
   metadata (rótulo com nome de pessoa, e-mail em alerta).
4. **`modo: implantar`.** Implanta na dev. Exige o PR aprovado; aceita PR já mesclado
   quando a ponta da branch é o mesmo commit do PR.

## Armadilhas

- **Nome exato.** LWC começa com minúscula (`centralComercial`), classe Apex com maiúscula.
  Nome errado não dá erro: o workflow "traz" nada. Se o PR vier vazio, confira o nome exato
  na sandbox de QA antes de tentar de novo.
- **Dependências não vêm sozinhas.** Um LWC precisa da classe Apex que ele chama, da classe
  de teste e da página (`FlexiPage`) que o usa. Liste tudo no mesmo `componentes`.
- **Classe de teste junto.** Sem a `<Classe>Test`, a implantação na dev falha na cobertura.
- Os nomes aceitos seguem `^[A-Za-z]+:[A-Za-z0-9_.\-]+$`; qualquer outro caractere é
  recusado pelo script `scripts/manifest_componentes.py`.
- Só sandboxes. O workflow não tem ambiente de produção e não deve ganhar um.
