---
name: health-check-seguranca
description: Como o agente de assessment lê o Security Health Check da org (nota e configurações de segurança fora do padrão da Salesforce) pela Tooling API, só leitura, e transforma cada risco alto em achado com evidência. Use na área "Segurança" do assessment de um cliente, e ao refazer o diagnóstico depois de uma mudança grande de configuração.
---

# Security Health Check no assessment

O Health Check compara as configurações de segurança da org (senha, sessão, rede, acesso)
com o padrão recomendado pela Salesforce e dá uma nota de 0 a 100. Ele existe em toda org e
se lê por consulta, sem alterar nada: é a evidência mais barata que a área "Segurança" do
`org-assessment` tem, e hoje o assessment olha só perfis e permission sets.

Fontes, lidas em 2026-11-28 (Tooling API Developer Guide):
- `SecurityHealthCheck`
  (https://developer.salesforce.com/docs/platform/api-tooling/references/tooling-objects/tooling-securityhealthcheck.html)
- `SecurityHealthCheckRisks`
  (https://developer.salesforce.com/docs/platform/api-tooling/references/tooling-objects/tooling-securityhealthcheckrisks.html)

A tela do Health Check, o padrão de referência (baseline) e como importar um padrão próprio
estão na ajuda (help.salesforce.com), que não abriu nesta revisão: **não conferidos**. Nada
abaixo depende deles.

## Regras

- **Só leitura**, como todo o assessment. A correção de cada risco é recomendação, nunca
  ação do agente (regra 1 do `org-assessment`).
- Só na org do job (`$TARGET_ORG`, sandbox de dev), com a org explícita no comando. A nota
  da sandbox pode diferir da produção: diga no achado que é a nota da sandbox e que o
  consultor confere a da produção na tela.
- O usuário da esteira precisa de "View Setup and Configuration" para ler os dois objetos.
  Sem a permissão, a consulta falha: isso vai para "Não pôde ser medido", com o motivo.
- Nenhum dado pessoal sai daqui: são configurações da org. Mesmo assim, não copie para o
  artefato nome de usuário, endereço de IP liberado ou domínio interno que apareça em
  `OrgValue`; escreva o nome da configuração e o risco.

## Comandos

```bash
# nota (0 a 100) e o padrão usado no cálculo
sf data query --use-tooling-api --target-org "$TARGET_ORG" \
  --query "SELECT Score, CustomBaselineId, DurableId FROM SecurityHealthCheck"

# só o que está fora do padrão, do mais grave para o menos
sf data query --use-tooling-api --target-org "$TARGET_ORG" \
  --query "SELECT SettingGroup, Setting, RiskType, SettingRiskCategory, OrgValueRaw, StandardValueRaw FROM SecurityHealthCheckRisks WHERE RiskType != 'MEETS_STANDARD' ORDER BY RiskType LIMIT 50"
```

Os campos que importam, como a documentação os define:

| Campo | O que é |
| --- | --- |
| `Score` | nota da org, de 0 a 100 |
| `CustomBaselineId` | qual padrão foi usado no cálculo (o da Salesforce ou um importado) |
| `Setting` | nome da configuração (ex.: tamanho mínimo da senha) |
| `RiskType` | `HIGH_RISK`, `MEDIUM_RISK` ou `MEETS_STANDARD`: o quanto o valor da org foge do padrão |
| `SettingRiskCategory` | `HIGH_RISK`, `MEDIUM_RISK`, `LOW_RISK` ou `INFORMATIONAL`: o peso da configuração em si |
| `OrgValueRaw` / `StandardValueRaw` | valor da org e valor recomendado, sem unidade |

O valor de `DurableId` pode mudar entre releases: não guarde para comparar depois.

## Como vira achado (skill `divida-tecnica`)

| Resultado | Severidade no assessment |
| --- | --- |
| Configuração com `RiskType = HIGH_RISK` | alta, área segurança |
| `MEDIUM_RISK` em configuração com `SettingRiskCategory = HIGH_RISK` | alta |
| Demais `MEDIUM_RISK` | média, agrupados num achado só ("N configurações de risco médio") |
| Nota abaixo de 80 sem nenhum risco alto | média, com a nota como evidência |
| Tudo `MEETS_STANDARD` | não é achado: vai no Inventário ("Health Check: nota N, sem risco") |

A faixa de 80 é régua da esteira, não da Salesforce. Achado de segurança alto deixa a saúde
geral vermelha (regra do `org-assessment`), então confira a linha antes de escrever.

Cada achado traz: o comando (evidência), a configuração, o valor da org e o recomendado, e a
recomendação em uma linha ("subir o tamanho mínimo de senha para o valor recomendado, em
Setup, pela política de senha"). Mudança de política de sessão ou de senha afeta todos os
usuários: a recomendação diz isso e quem decide (o cliente), e vira demanda própria.

## Antes de fechar

- [ ] A nota e o padrão usado (`CustomBaselineId`) estão no Inventário, com a data.
- [ ] Todo `HIGH_RISK` virou achado, com valor da org e valor recomendado.
- [ ] Os médios estão agrupados, não um achado por linha.
- [ ] O texto diz que a nota é da sandbox de dev e que a produção se confere na tela.
- [ ] Se a consulta falhou, o motivo está em "Não pôde ser medido".
