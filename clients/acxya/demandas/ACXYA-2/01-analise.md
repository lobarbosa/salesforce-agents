# Análise ACXYA-2: Campo Nova Descoberta

## Contexto de negócio

O cliente Konecta necessita registrar e armazenar insights e descobertas coletadas durante reuniões com potenciais clientes. Atualmente, essas informações não têm local centralizado no CRM, dificultando o acompanhamento e contextualização posterior na jornada de venda.

## Objetivo

Criar um campo customizado no objeto Lead que permita armazenar as descobertas e insights coletados durante reuniões com potencial cliente, facilitando o histórico e a próxima etapa do processo de vendas.

## Regra de negócio

- O campo deve residir no objeto Lead (padrão Salesforce)
- Deve capturar informações sobre descobertas feitas em reuniões com potenciais clientes
- Deve ser persistido e recuperável para consulta posterior

## Critérios de aceite (Gherkin)

```gherkin
Scenario: Campo customizado "Descobertas" criado no objeto Lead
  Given que um campo customizado será adicionado ao objeto Lead
  When o administrador ou desenvolvedor faz deploy do artefato
  Then o campo aparece no objeto Lead e é acessível via API
  And o campo pode ser populado via interface (record page ou layout de Lead)
  And o valor preenchido é persistido no banco de dados
  And o campo permanece visível em consultas de Lead

Scenario: Usuário preenche descobertas na reunião
  Given um usuário de vendas acessa um registro de Lead
  When ele vê o formulário/record page do Lead
  Then o campo para registro de descobertas está visível
  And ele consegue inserir/editar/limpar o conteúdo da descoberta
  And ao salvar, o valor é armazenado sem erro
```

## O que a demanda NÃO diz (lacunas críticas)

1. **Tipo de campo** — Qual tipo exato de campo Salesforce?
   - Texto curto (Text)?
   - Texto longo (Long Text Area)?
   - Texto rico (Rich Text Area)?
   - Área de texto (Textarea)?
   - Data?
   - Outro?

2. **Tamanho/Restrições** — Se texto:
   - Quantos caracteres máximo?
   - Há restrição de formato ou validação especial?

3. **Obrigatoriedade** — É campo obrigatório (Required)?

4. **Quem preenche e quando?**
   - Sales rep durante reunião?
   - Após reunião?
   - Administrador?
   - Automação?

5. **Visibilidade e Layouts**
   - Deve aparecer em qual layout de Lead?
   - Deve aparecer em alguma Lightning Record Page específica?
   - Todas as profiles conseguem ver/editar, ou há restrição de campo level?

6. **Nomeclatura do campo**
   - Qual rótulo (label) deve ter?
   - Qual nome da API (field name)?
   - Português (`Nova_Descoberta__c`) ou inglês (`Discoveries__c`)?

7. **Integrações**
   - Há alguma automação dependente? (Flow, Process Builder, etc)
   - Se um Lead converter em Opportunity, o campo deve viajar/replicar?
   - Precisa estar em alguma API ou integração externa?

8. **Dados históricos**
   - Existem Leads criados que precisam ter esse campo populado? (data migration)

9. **Indexação/Busca**
   - Precisa ser indexado (searchable)?

10. **Duração e contexto**
    - Este é um campo de ciclo único (apenas pro Lead) ou continua na Opportunity?

## Premissas a validar (PENDENTES)

- [ ] **Tipo de campo**: texto curto, texto longo, texto rico ou outro — impacta armazenamento e UI
- [ ] **Tamanho máximo**: se texto, quantos caracteres?
- [ ] **Obrigatoriedade**: é campo Required ou opcional?
- [ ] **Quem preenche**: sales rep, admin, automação ou terceiro?
- [ ] **Quando preenche**: durante/após reunião? quando exatamente?
- [ ] **Visibilidade**: todas as profiles veem? há restrição FLS?
- [ ] **Layouts**: deve aparecer em qual(is) layout(s) de Lead?
- [ ] **Nomenclatura**: português ou inglês? qual label exato?
- [ ] **Automações dependentes**: há Flows, validações ou processos que precisam ler/escrever este campo?
- [ ] **Migração**: existem Leads históricos que devem ter este campo populado?
- [ ] **Jornada pós-conversão**: se Lead vira Opportunity, o campo deve ser copiado? é descartado?

## Estimativa de complexidade

**Complexidade: P (Pequena)**

Justificativa: criação de um campo custom isolado em sObject padrão, sem lógica de negócio complexa, automações ou integrações aparentes — é operação de metadados pura (XML no force-app, 1-2 linhas, deploy via MDAPI).
