# 05 — Testes — SOMOSAGILITY-21: Campo origem do Lead

## Ambiente

Checado via `sf org list` em 2026-10-28, antes de qualquer execução:

- `sbx-somos-agility-dev` — **Connected** (`https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`,
  API 68.0, `isSandbox: true`).
- `sbx-somos-agility-qa` — **não aparece na lista.** A sandbox de QA deste cliente ainda não
  está conectada à esteira.

**Decisão de caminho (doutrina de QA, fallback previsto):** como a sandbox de QA não existe
ainda, a validação formal do CA-04 (que o próprio design manda rodar em
`sbx-somos-agility-qa`) **não pode ser executada** nesta rodada. Não foi tentada conexão
nenhuma com produção, e nenhuma sandbox foi inventada.

O que segue abaixo **não substitui** essa validação formal. É uma demonstração do
**comportamento de plataforma** (como o `LeadSource` se comporta num picklist não restrito
com default de org) rodada contra `sbx-somos-agility-dev`, porque:

1. Não é dado de cliente — são 3 Leads fictícios criados e apagados nesta sessão, só para
   observar o comportamento do campo (guardrail #2 não é violado).
2. Esta demanda não construiu nenhum metadata (`04-plano-build.md`): não há Custom
   Permission, Permission Set ou Flow para "implantar em QA e testar" — o que existe para
   testar é o comportamento nativo do `LeadSource` (picklist não restrito + default de org),
   que é o mesmo em dev e em QA, por ser comportamento de configuração padrão da plataforma,
   não algo específico de uma sandbox.
3. O resultado formal de CA-04 **continua dependendo** de rodar o mesmo roteiro em
   `sbx-somos-agility-qa` quando ela conectar, e de uma validação adicional fora desta
   esteira: o middleware real apontando para QA (ou produção) mandando o payload de verdade
   — isso é trabalho do cliente/TI Agility (P-4 do design), fora do alcance deste agente.

Dados usados: todos fictícios, criados e apagados nesta sessão (`LastName` prefixado
`QA-SOMOSAGILITY-21 CasoN`, `Company = 'QA Teste SOMOSAGILITY-21'`). Nenhuma query retornou
dado de Lead real — a única leitura foi dos 3 registros de teste recém-criados por este
agente.

## Falhas

Nenhuma. Os três casos executados tiveram o resultado esperado pelo design (ver tabela).

## Casos executados (demonstração de plataforma em `sbx-somos-agility-dev`)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| 1 — Payload com API name correto | `sf data create record --sobject Lead` com `LastName='QA-SOMOSAGILITY-21 Caso1'`, `Company='QA Teste SOMOSAGILITY-21'`, `Status='Novo'`, `LeadSource='Web Site Agility Networks'` | `LeadSource` gravado como `Web Site Agility Networks` (valor mantido) | `LeadSource = 'Web Site Agility Networks'` (confirmado por query) | PASSOU |
| 2 — Payload sem `LeadSource` (H1) | Idem, sem o campo `LeadSource` no payload | `LeadSource` assume o default de org `Prospecção - Gerente de Contas` | `LeadSource = 'Prospecção - Gerente de Contas'` (confirmado por query) | PASSOU — comprova H1 (causa-raiz "campo vem com o default", não "vazio") |
| 3 — Payload com label em vez de API name (H2) | Idem, com `LeadSource='Web Site Agility'` (label exibido na UI, não o API name `Web Site Agility Networks`) | Por o picklist não ser `restrictedPicklist`, a API aceita e grava o texto solto, fora da lista oficial | `LeadSource = 'Web Site Agility'` gravado como texto solto (confirmado por query; não corresponde a nenhum dos 18 valores ativos do picklist) | PASSOU — comprova H2 (se o middleware mandar o label em vez do API name, o valor "parece certo" na tela mas não agrupa com `Web Site Agility Networks` em relatório nem ativa o Flow de Opportunity `Atualizar_Descri_o_com_Informa_es_do_Lead`, conforme `03-design.md`) |

Limpeza: os 3 Leads de teste foram apagados (`sf data delete record`) ao final da
verificação — não ficaram registros de teste na sandbox.

## Cobertura dos critérios de aceite (de `01-analise.md`)

| CA | Cobertura nesta rodada | Observação |
|---|---|---|
| **CA-01** — Lead do site recebe o valor correto | **Não testável em produção (fora de escopo do agente).** Demonstrado como comportamento de plataforma: quando o payload manda o API name certo (Caso 1), o valor é mantido. A correção efetiva de CA-01 depende do ajuste do middleware externo (P-4, fora do Salesforce), que esta esteira não controla e não pode validar de ponta a ponta. |
| **CA-02** — outros canais não mudam | **Não aplicável nesta rodada.** Nenhum metadata foi criado ou alterado (`04-plano-build.md`): não existe regra nova que possa interferir em outro canal para testar. Se a Opção F (Flow condicionado à Custom Permission) vier a ser construída no futuro, este critério passa a ser testável e deve comparar um usuário com o Permission Set (Lead corrigido) contra um usuário sem ele (Lead inalterado). |
| **CA-03** — valor do site sobrepõe o default | **Comprovado indiretamente pelos Casos 1 e 2.** Um valor explícito no payload (Caso 1) sempre vence o default do picklist; sem valor explícito (Caso 2), o default prevalece. Isso confirma o mecanismo que a correção (Opção A) depende: bastar o middleware mandar o valor explícito certo. |
| **CA-04** — teste em QA com payload simulado | **Não executado formalmente** — `sbx-somos-agility-qa` não está conectada à esteira (ver seção Ambiente). Demonstração equivalente rodada em `sbx-somos-agility-dev`, documentada acima, com a ressalva explícita de que não substitui a validação formal. |

## Roteiro para quando `sbx-somos-agility-qa` conectar (CA-04 formal)

Repetir os 3 casos acima contra `sbx-somos-agility-qa`, idealmente via chamada REST direta
(`POST /services/data/v68.0/sobjects/Lead`) para reproduzir mais fielmente o payload do
middleware, em vez de `sf data create record`:

```
POST /services/data/v68.0/sobjects/Lead
{
  "LastName": "QA-SOMOSAGILITY-21 CasoN",
  "Company": "QA Teste SOMOSAGILITY-21",
  "Status": "Novo",
  "LeadSource": "<valor do caso>"
}
```

1. `LeadSource = "Web Site Agility Networks"` → esperar valor mantido.
2. Omitir `LeadSource` → esperar `Prospecção - Gerente de Contas`.
3. `LeadSource = "Web Site Agility"` (label) → esperar valor solto gravado como texto.

Apagar os registros de teste ao final. Se a Opção F tiver sido construída até lá, adicionar:

4. Payload do caso 2 ou 3, criado por um usuário com `PS_Integracao_LeadSiteAgility` →
   esperar `LeadSource` corrigido para `Web Site Agility Networks` pelo Flow.
5. Mesmo payload, usuário **sem** o Permission Set → esperar `LeadSource` inalterado
   (prova CA-02).

## Validação fora do alcance desta esteira

- **Middleware real apontado para QA/produção** — depende de TI Agility (P-4 do design).
  Este agente não tem acesso ao middleware nem a produção (guardrail #1). Fica registrado
  como pendência do cliente, não como falha de teste.
- **Evidência de causa-raiz em produção (P-3)** — print do campo `LeadSource` de um Lead
  real afetado, ou agregado `GROUP BY LeadSource` rodado por alguém com acesso a produção.
  Fora do alcance deste agente.

---

Testes executados. Preciso da sua homologação para liberar o release.
