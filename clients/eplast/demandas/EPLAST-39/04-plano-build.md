**Resultado do build:** bloqueado

# EPLAST-39 — Plano de build (bloqueado)

**Org conectada nesta sessão:** `sbx-eplast-dev` (Sandbox, `IsSandbox = true`, instância BRA8S), usuário `projetos@konectabr.com.eplast2.qa`, `instanceUrl` `https://eplast--qa.sandbox.my.salesforce.com`. `sf org list` mostra só esse alias; não há `sbx-eplast-qa` conectado para comparar.

**Nada foi construído, implantado ou escrito na org.** Nenhum metadata em `force-app/` foi alterado.

## Motivo do bloqueio

O bloqueio B1 do `03-design.md` (seção 0 e passo 0 da seção 12) está sem resolução. O desenho diz que o build não escreve nada na org enquanto alguém da equipe não confirmar que `sbx-eplast-dev` é de fato a sandbox de dev. Isso é guardrail #1 (só dev e QA, nunca misturar), e não é pergunta de negócio: as regras de premissa assumida da conta não se aplicam.

Evidência de que continua aberto:
- O alias de dev aponta para uma instância e um usuário que se identificam como `qa` (confirmado nesta sessão por `sf org display`; é o achado 6 do `assessment.md`).
- Não achei confirmação em `gates.md`, `comentarios-do-card.md` nem no `CLAUDE.md` da conta. O gate de design foi aprovado em lote em 2026-11-15 (Leonardo Barbosa, via Claude), e o comentário do card diz que o desenho e as premissas não foram revisados um a um. Aprovar o desenho não equivale a confirmar o ambiente.
- A validação da esteira confere o nome do alias, não o conteúdo da org (assessment, achado 6). Por isso a checagem `IsSandbox` passar não resolve o ponto.
- O desenho traz indício de que a org é distinta da QA testada na rodada 1 (painel com Id diferente, 0 leads contra 712), mas ele próprio classifica isso como indício e não confirmação.

E1 (campo fórmula `Lead.MKT_Origem_Agrupada__c`): o gate de design está registrado em `gates.md` (aprovação de 2026-11-15, commit `2bbf06ec`, `03-design.md` com hash `7ccb48cb33a60a99`). E1 não é o motivo do bloqueio.

## O que falta e quem responde

| Pendência | Quem responde |
|---|---|
| Confirmar por escrito que `https://eplast--qa.sandbox.my.salesforce.com` (alias `sbx-eplast-dev`) é a sandbox de dev e não a QA. Alternativa: reconectar `sbx-eplast-dev` à sandbox de dev correta. | Responsável pelas sandboxes da Eplast (BASIS / time do cliente), via Leonardo Barbosa ou Carlos Sordi |
| Confirmar que existe uma sandbox distinta para `sbx-eplast-qa` | Mesmos |

Com isso resolvido, o build segue a ordem da seção 12 do design, a partir do passo 1: campo fórmula com `--dry-run`, relatórios de origem, `MKT_Desempenho_Campanhas` em Summary, painel, permission set e massa sintética com verificação pela Analytics API.

## Premissas assumidas

PA-01 a PA-07 não são motivo de bloqueio e seguem como estão no design.
