# Análise — SOMOSAGILITY-2: Criação de usuários de integração

## Contexto de negócio

Somos Agility necessita de contas de serviço (service accounts) para integrar sistemas externos com o Salesforce. Essas contas permitem autenticação baseada em credenciais fixas ou bearer tokens, sem depender de usuários humanos. Uma conta é solicitada para ambiente de produção (destino final) e outra para ambiente de teste (HML/AW), para desenvolvimento e validação de integrações.

## Objetivo

Criar dois usuários de integração (service accounts) de acordo com o padrão de nomenclatura interno:
1. Em Produção: `svc_integ_api_prd`
2. Em Sandbox HML (AW): `svc_integ_api_hml`

## Regra de negócio

- **Padrão de nomenclatura**: `svc_integ_api_<ambiente>`
- Usuários de integração devem ser contas de serviço, não usuarios humanos (sem UI login esperado)

## Critérios de aceite

```gherkin
Funcionalidade: Criar usuários de integração

Cenário: Usuário em sandbox de teste criado com sucesso
  Dado que a sandbox HML (AW) está conectada e mapeada na esteira
  Quando o agente builder cria o usuário svc_integ_api_hml
  Então o usuário existe na sandbox com esse exato nome
  E o usuário tem profile de integração atribuído
  E o usuário pode ser consultado via SOQL: SELECT Id, Username FROM User WHERE Username = 'svc_integ_api_hml'
  E não há erros de validação de duplicação

Cenário: Usuário em produção flagado como escopo fora da esteira
  Dado que a demanda solicita criação em Produção
  Quando a análise é revisada contra os guardrails
  Então o status marca que essa ação não pode ser executada por agente (guardrail #1 — produção proibida)
  E o bloqueador é escalado para decisão humana: qual é o processo que a org usa para contas de integração em Produção?
```

## O que a demanda NÃO diz

1. **Qual é a sandbox HML (AW)?** — O cliente refere-se a "HML (AW)" mas o `CLAUDE.md` do cliente só têm as sandboxes da esteira mapeadas: dev (`sbx-somos-agility-dev`) e qa (`sbx-somos-agility-qa`). É HML um alias diferente? Qual é o alias ou instance URL exato?

2. **Qual é o método de autenticação esperado?** — O usuário vai usar:
   - Credenciais username/password clássicas?
   - OAuth 2.0 com JWT bearer flow?
   - IP whitelist?
   - Consumer key/secret (connected app)?

3. **Quais são as permissões mínimas?** — Qual permission set (ou custom profile) deve ser atribuído? "Integração" é muito genérico; cada serviço integrado precisa de acessos diferentes.

4. **Qual tipo de usuário** — Standard, Chatter Free, Platform, etc.?

5. **Como lidar com produção?** — O guardrail #1 (nenhum agente executa escrita em produção) bloqueia a criação em Produção. Qual é o processo que o cliente usa hoje para contas de integração em Produção? Quem cria? (O agente pode ajudar com sandbox, mas não Prod.)

6. **Integração com qual sistema?** — A conta vai integrar com quê? A pergunta afeta permissões mínimas, possivelmente o tipo de autenticação, e se há restrições de IP ou horário.

7. **Está dentro do escopo do contrato?** — Qual é o tipo de contrato (AMS ou Projeto)? Se for projeto, qual entregável da proposta cobre essa demanda?

## Premissas a validar

- [ ] **BLOQUEADOR: Guardrail #1 — Produção proibida.** Nenhum agente (builder, dev-apex, release) pode executar deploy, DML ou Apex anônimo em produção. Criar um usuário é uma escrita. A esteira opera apenas em dev e qa. Produção será executada manualmente fora do pipeline ou há um processo específico do cliente?

- [ ] **BLOQUEADOR: Qual é o alias e instance URL de "HML (AW)"?** O CLAUDE.md do cliente não tem essa sandbox mapeada. Preciso confirmar:
  - É uma das sandboxes da esteira (dev ou qa) com outro apelido?
  - É uma terceira sandbox fora da esteira que o cliente gerencia?
  - Qual é o alias SF exato que deve ser usado (`sbx-somos-agility-hml` ou outro)?

- [ ] Qual permission set deve ser atribuído a cada usuário de integração?

- [ ] Qual é o método de autenticação esperado (credenciais, OAuth, JWT, etc.)?

- [ ] Qual sistema externo cada conta integrará?

- [ ] Precisa de IP whitelist, restrições de horário ou assinatura SAML?

## Estimativa de complexidade

**P** — Se ambiente e permissões forem validados, criar usuários é operação simples e declarativa (nenhum código). Bloqueador: Produção sai fora do escopo do agente (guardrail #1); será preciso intervenção manual ou processo separado.

---

**Notas para o humano que vai validar:**

1. A demanda toca em um guardrail inegociável da squad (guardrail #1: nenhum agente executa em produção). Preciso da sua clarificação sobre como o cliente quer proceder — sandbox pode ser feita imediatamente pelo agente, mas Produção sai do escopo do pipeline.

2. O ambiente "HML (AW)" precisa ser mapeado no CLAUDE.md do cliente antes que qualquer build comece. Sem clareza sobre qual sandbox é essa, não há como executar nem mesmo a sandbox.

3. Uma vez validadas essas duas decisões, o resto é direto (criar usuário + atribuir profile/permission set).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
