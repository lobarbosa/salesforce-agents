---
name: mc-arquitetura-da-conta
description: Revisão de arquitetura e configuração de uma conta do Salesforce Marketing Cloud contra as diretrizes e boas práticas da ferramenta — unidades de negócio, acesso, autenticação do domínio de envio, conformidade, modelo de dados, integração com o Sales Cloud e operação — com diagnóstico por severidade e plano de correção com dono. Use ao assumir uma conta de Marketing Cloud, antes da primeira demanda de Marketing Cloud de um cliente, e quando a entrega ou a conformidade da conta for questionada.
---

# Arquitetura da conta de Marketing Cloud

Leia antes `.claude/skills/marketing-cloud-doutrina/SKILL.md` e a skill `divida-tecnica`
(como classificar severidade e escrever recomendação que vira demanda).

## O que a revisão entrega

`clients/<cliente>/mc-assessment.md`: o diagnóstico da conta, um achado por linha, e o plano
de correção na ordem de ataque. Cada achado crítico ou alto vira proposta de demanda, como no
assessment da org do Sales Cloud.

**Corrigir, nesta versão, é escrever a correção, não aplicá-la.** A conta é produção e o
agente não se conecta a ela (versão 1). Cada correção diz o passo exato, onde fica no Setup,
quem faz (cliente, consultor, Salesforce, provedor de DNS) e como conferir depois. O que é do
Sales Cloud (Marketing Cloud Connect, campos de consentimento) vira demanda na esteira, com as
regras de sempre.

## De onde vem a evidência

| Fonte | Como | O que cobre |
| --- | --- | --- |
| DNS público do domínio de envio | workflow `mc-dns-remetente.yml` (roda `scripts/mc_dns_remetente.py`) | SPF, DMARC e, com o seletor, DKIM |
| Levantamento no Setup | o consultor preenche `clients/<cliente>/mc-levantamento.md`, a partir do modelo abaixo, olhando as telas do Setup | o resto da tabela de verificação |
| Exportações do cliente | lista de DEs, automações, jornadas, usuários (sem dado de contato) | volume, nomes, erros |
| Org do Sales Cloud | `sf` na sandbox de dev, só metadata | Marketing Cloud Connect (objetos `et4ae5`), consentimento |

Nunca use captura de tela de registro de contato, de envio ou de relatório com dado pessoal
(guardrail #2). Item sem evidência fica "não verificado", com o que falta para verificar.

## Tabela de verificação

| Área | O que conferir | Boa prática | Severidade se não atende |
| --- | --- | --- | --- |
| Estrutura | Unidades de negócio | Uma por marca, país ou operação que precisa de remetente, dado ou acesso separado; uma unidade de **teste** sem dado real; a unidade principal (Enterprise) não usada para envio do dia a dia | média; alta sem unidade de teste |
| Acesso | Usuários e papéis | Login individual (sem conta compartilhada), papel com o mínimo necessário, usuários de quem saiu desativados, SSO ou verificação em duas etapas | alta |
| Acesso | Pacotes instalados (integrações de API) | Um por integração, com nome do dono, escopo mínimo, sem credencial em planilha ou e-mail | alta |
| Entregabilidade | Domínio de envio | Domínio próprio autenticado (Sender Authentication Package ou domínio privado), não o domínio padrão da plataforma | alta |
| Entregabilidade | SPF, DKIM, DMARC | SPF válido e com menos de 10 consultas, DKIM publicado, DMARC presente e caminhando de `p=none` (com relatório `rua`) para `quarantine` ou `reject` | crítica sem SPF ou DKIM; alta sem DMARC |
| Entregabilidade | Respostas e rejeições | Reply Mail Management configurado; rejeições permanentes saindo da base | média |
| Entregabilidade | IP dedicado | Quando há, aquecimento feito e volume constante | média |
| Conformidade | Sender Profile e Delivery Profile | Remetente com domínio autenticado; rodapé com endereço físico e nome da empresa | alta |
| Conformidade | Send Classifications | Comercial e transacional separadas; transacional só para mensagem de serviço | alta |
| Conformidade | Descadastro | Central de descadastro ou de preferências funcionando, listas de publicação por assunto, lista de supressão automática do cliente | crítica sem descadastro |
| Conformidade | LGPD | Campo de consentimento com origem e data; retenção nas DEs com dado pessoal; exclusão de contato (Contact Delete) configurada e testada | alta |
| Dados | Subscriber Key | Id do Contato ou do Lead do Sales Cloud, não o e-mail | crítica se é o e-mail com o Connect ligado |
| Dados | Data Extensions | Nomes no padrão, pastas por área, chave primária onde há Update ou lookup, retenção nas temporárias, nenhum campo pessoal sem uso | média |
| Dados | Contact Builder | Relações das DEs de público com as de apoio definidas; grupos de atributos coerentes | baixa |
| Integração | Marketing Cloud Connect | Usuário de integração dedicado no Sales Cloud, só os objetos e campos que o marketing usa sincronizados, rastreamento de envio voltando ao CRM quando o cliente usa | alta |
| Operação | Automações | Notificação de erro para um e-mail do time, nenhuma automação em erro há mais de uma semana, Verificação antes de envio (skill `mc-automacao`) | média |
| Operação | Jornadas | Versões antigas paradas, reentrada definida, meta e critério de saída | média |
| Operação | Fuso e idioma | Fuso da conta conhecido e documentado; cultura (pt-BR) nas formatações | baixa |

Severidade: **crítica** (risco legal ou de bloqueio de envio agora), **alta** (risco de
entrega, segurança ou conformidade), **média** (custo de operação, erro provável), **baixa**
(organização).

## Modelo do levantamento (`clients/<cliente>/mc-levantamento.md`)

Uma linha por item da tabela acima, preenchida pelo consultor: `Área | Item | Como está |
Onde vi (tela do Setup ou exportação) | Data`. Só configuração, nunca dado de contato.

## Formato do diagnóstico (`clients/<cliente>/mc-assessment.md`)

```markdown
# Marketing Cloud – <cliente>: arquitetura da conta

**Data:** AAAA-MM-DD · **Fontes:** DNS (workflow, data), levantamento de <papel>, exportações

## Achados

| # | Área | Achado | Severidade | Evidência | Correção | Dono |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Entregabilidade | DMARC ausente no domínio de envio | alta | workflow mc-dns-remetente, 28/11 | publicar `_dmarc` com `p=none` e `rua`, subir para `quarantine` em 30 dias | TI do cliente (DNS) |

## Ordem de ataque

1. Críticos, depois altos de segurança e conformidade, depois entregabilidade.

## Não verificado

| Item | O que falta para verificar |
| --- | --- |
```

`python3 scripts/mc_validar_pacote.py --assessment clients/<cliente>/mc-assessment.md`
confere as colunas, a severidade (crítica, alta, média, baixa) e que todo achado tem
evidência, correção e dono.

## Antes de fechar

- [ ] Todo item da tabela de verificação aparece como achado, como "atende" ou em "Não verificado".
- [ ] Toda severidade segue a tabela; mudar a severidade exige o porquê na linha.
- [ ] Toda correção diz onde fica (tela, DNS, org) e como conferir depois.
- [ ] Achado crítico ou alto tem proposta de demanda ou dono de fora da esteira.
- [ ] Nenhum dado de contato, credencial ou endereço pessoal no arquivo.
