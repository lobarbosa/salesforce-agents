# Análise — SOMOSAGILITY-4: Criação de Acesso para Nova Gerente de Contas

## Contexto de negócio

Admissão de nova gerente de contas que necessita acessar a plataforma Salesforce com as mesmas permissões, papéis e grupos que o usuário existente Marcia Kondo, garantindo continuidade operacional e paridade de acesso entre gerentes.

## Objetivo

Criar novo usuário Daniella Aiello (daniella.aiello@somosagility.com.br) na sandbox de desenvolvimento, replicando exatamente a configuração de acesso do usuário existente Marcia Kondo (marcia.kondo@somosagility.com.br).

## Regra de negócio

- O novo usuário deve ter acesso idêntico ao usuário espelho (Marcia Kondo)
- A criação ocorre em sandbox dev (`sbx-somos-agility-dev`)
- O novo usuário assume função de gerente de contas, mesmo papel operacional de Marcia
- Nenhuma customização adicional além do espelhamento é esperada

## Critérios de aceite

```gherkin
Funcionalidade: Espelhamento de acesso de usuário
  Dado que o usuário marcia.kondo@somosagility.com.br existe na sandbox com Perfil, Papel e Permission Sets configurados
  Quando a demanda de criação de acesso for executada
  Então o usuário daniella.aiello@somosagility.com.br deve existir na sandbox
  E o usuário daniella.aiello@somosagility.com.br deve ter o mesmo Perfil de marcia.kondo@somosagility.com.br
  E o usuário daniella.aiello@somosagility.com.br deve ter o mesmo Papel (Role) de marcia.kondo@somosagility.com.br
  E o usuário daniella.aiello@somosagility.com.br deve ter exatamente os mesmos Permission Sets de marcia.kondo@somosagility.com.br
  E o usuário daniella.aiello@somosagility.com.br deve ser membro dos mesmos Grupos públicos de marcia.kondo@somosagility.com.br
  E o usuário daniella.aiello@somosagility.com.br deve ter uma licença ativa e habilitada
  E o usuário daniella.aiello@somosagility.com.br deve estar ativo (ativo = true) na org
```

## O que a demanda NÃO diz (Premissas a validar)

1. **Escopo do espelhamento:** A demanda diz "espelhar", mas não especifica se inclui:
   - Apenas Perfil, Papel e Permission Sets?
   - Também Grupos públicos?
   - Também delegações de aprovação, time assignments ou configurações de assinatura?
   - **Status:** Pendente de confirmação no recon (etapa 2)

2. **Estado atual do novo usuário:** 
   - O usuário daniella.aiello@somosagility.com.br já existe desativado na org ou precisa ser criado do zero?
   - Se existir, em que estado está (licença, ativo/inativo)?
   - **Status:** Pendente — será verificado no recon

3. **Convenção de username:**
   - A org usa username == email (daniella.aiello@somosagility.com.br) ou há sufixo obrigatório (.org, .sandbox) nas sandboxes?
   - Qual será o username exato a utilizar?
   - **Status:** Pendente — recon verificará convenção de usuários existentes

4. **Definição do Nome Completo:**
   - O nome completo a registrar deve ser "Daniella Aiello" ou há outro padrão?
   - **Status:** Pendente de confirmação com o solicitante

5. **Tipo de Licença:**
   - Qual será a licença atribuída? (Salesforce, Platform User, etc.)
   - Deve ser idêntica à de Marcia?
   - **Status:** Será confirmado no recon junto com a licença atual de Marcia

6. **Confirmar dados atuais de Marcia:**
   - Qual é o Perfil exato de marcia.kondo@somosagility.com.br?
   - Qual é o Papel (Role) na hierarchy?
   - Quais Permission Sets estão atribuídos?
   - De quais Grupos públicos Marcia é membro?
   - **Status:** Será descoberto no recon (etapa 2)

7. **Data/Timing de ativação:**
   - O novo usuário deve estar ativo imediatamente após a criação ou há data de ativação específica?
   - **Status:** Pendente — assumindo imediatamente ativo por padrão

8. **Notificações e comunicação:**
   - Alguém (novo usuário, Marcia, gestor) deve ser notificado após a criação?
   - Há fluxo de onboarding paralelo ou apenas acesso?
   - **Status:** Fora do escopo da demanda — apenas criação de acesso

## Complexidade estimada

**P (Pequena)** — É um access management declarativo sem desenvolvimento de código. Recon simples (consultar User e metadata de Marcia via SOQL/sf CLI), build apenas UI/API de CRUD de usuário (sem lógica complexa), testes funcionais. O escopo é replicação, não customização.

---

## Próximas ações

- Etapa 2 (Recon): Confirmar Perfil, Papel, Permission Sets e Grupos de Marcia Kondo
- Validar com solicitante: escopo exato do espelhamento, convenções de username, estado atual de Daniella Aiello na org
