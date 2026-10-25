---
name: org-recon
description: Como descobrir o que já existe numa org Salesforce antes de desenhar ou construir qualquer coisa. Use sempre antes do design e sempre que precisar confirmar se um objeto, campo, Flow ou classe existe.
---

# Recon da org

A org é a única fonte de verdade. Documentação e memória não são.

## Comandos base

```bash
sf org list                                    # qual org está conectada
sf org display --target-org <ALIAS>            # detalhes, confirmar que NÃO é prod
sf sobject list --target-org <ALIAS>           # objetos disponíveis
sf sobject describe --sobject Opportunity --target-org <ALIAS>   # campos, tipos, picklists
sf project retrieve start --metadata Flow --target-org <ALIAS>   # trazer Flows para o repo
sf project retrieve start --metadata ApexClass:MinhaClasse --target-org <ALIAS>
sf data query --query "SELECT COUNT() FROM Account" --target-org <ALIAS>
```

## O que sempre verificar antes de um design

| Pergunta | Como responder |
|---|---|
| O campo/objeto já existe? | `sf sobject describe` |
| Já há automação neste objeto/evento? | retrieve de Flow + busca por triggers em `force-app` |
| Há validation rule que vai conflitar? | retrieve `ValidationRule` do objeto |
| Qual o volume de registros? | `SELECT COUNT()` — nunca traga os registros |
| Quem enxerga isso? | perfis e permission sets do objeto |

## Proibido
- Query que retorne dados pessoais ou de negócio do cliente (nomes, e-mails, valores, CPF).
  Use `COUNT()` ou registros criados para teste. LGPD não é negociável.
- Escrever no artefato o **username** da org, o e-mail de qualquer usuário ou a saída
  crua de `sf org display` / `sf org list`. Cite a org pelo alias (`sbx-<cliente>-dev`)
  e, se precisar, pelo Org ID. Username tem formato de e-mail: o scan de PII bloqueia o
  push e a etapa inteira é descartada (achado real, SOMOSAGILITY-18).
- Rodar qualquer coisa contra org de produção.
- Afirmar que um componente existe sem ter rodado o comando.

## Saída
Grave o resultado em `demandas/<DEMAND-ID>/02-recon.md` com a data da coleta.
Recon de mais de 7 dias é considerado vencido — refaça.
