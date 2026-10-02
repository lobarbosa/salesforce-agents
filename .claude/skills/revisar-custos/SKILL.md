---
name: revisar-custos
description: Analisa logs/custos_agentes.csv para decidir se a seleção de modelo por agente (haiku/sonnet/opus) ainda faz sentido, ou se algum agente está caro demais para o que faz ou errando por estar num modelo barato demais. Use depois que uma demanda completar (ou avançar bastante) o ciclo, e antes de propor qualquer mudança na tabela de modelos do CLAUDE.md.
---

# Revisar custo e escolha de modelo por agente

O CLAUDE.md é explícito: a tabela de modelo por agente (haiku/sonnet/opus) é **"hipótese
reversível, não doutrina validada"** — ninguém tem sinal empírico ainda, e não deve ser
ajustada "com a heurística sozinha". Esta skill é o processo pra virar isso em dado.

## Onde está o dado

`logs/custos_agentes/*.csv` — **um arquivo por sessão de agente**, versionado no git (até
2026-10-02 era um único `logs/custos_agentes.csv` crescendo; mudou pra arquivo-por-sessão
depois de um conflito de merge real entre duas demandas de clientes diferentes appendando no
fim do mesmo arquivo — ver CLAUDE.md § Telemetria de custo). `logs/custos_agentes.csv`
(singular, sem o diretório) pode continuar existindo como arquivo **legado**, com dado de
antes da mudança — some para quem só lê os arquivos novos, por isso use sempre
`salesforce_agents.costs.ler_todas_as_linhas()` (Python) em vez de abrir um arquivo só, ou,
na mão, leia o legado **e** o diretório. Cada arquivo tem as colunas:

```
timestamp,client,demand_id,etapa,session_id,model,input_tokens,output_tokens,
cache_read_tokens,cache_creation_tokens,cost_usd,duration_ms,num_turns,is_error
```

Repare que **uma sessão pode gerar várias linhas** no mesmo arquivo (uma por modelo que ela
efetivamente usou dentro do turno — já teve sessão de `design` com linhas separadas para
haiku, opus e sonnet). Agrupe por `session_id` quando quiser custo total de uma etapa, e por
`model` quando quiser saber quem pesa no total.

## Como agregar

Sem precisar de nenhuma dependência nova. Via Python, use o helper que já existe (cobre
legado + arquivos novos sem você precisar saber do layout):

```python
from collections import defaultdict
from salesforce_agents.costs import ler_todas_as_linhas

totais = defaultdict(lambda: {"custo": 0.0, "sessoes": set(), "erros": 0})
for linha in ler_todas_as_linhas():
    chave = (linha["client"], linha["etapa"], linha["model"])
    totais[chave]["custo"] += float(linha["cost_usd"] or 0)
    totais[chave]["sessoes"].add(linha["session_id"])
    if linha["is_error"] == "True":
        totais[chave]["erros"] += 1

for (cliente, etapa, modelo), dados in sorted(totais.items()):
    print(f"{cliente:12} {etapa:10} {modelo:28} "
          f"${dados['custo']:.4f}  {len(dados['sessoes'])} sessão(ões)  "
          f"{dados['erros']} erro(s)")
```

Sem Python (`csvkit`, `awk`), concatene antes de agregar: `cat logs/custos_agentes.csv
logs/custos_agentes/*.csv 2>/dev/null` (o primeiro pode não existir em instalação nova — o
`2>/dev/null` cobre isso) e descarte linhas de cabeçalho repetidas.

## O que perguntar aos números

1. **Algum agente em haiku (`ba-discovery`, `doc`) tem `is_error=True` com frequência, ou
   produz artefato que o gate humano rejeita/pede muita correção?** Isso é sinal de "barato
   demais para o que faz" — o CLAUDE.md previu exatamente esse risco.
2. **O custo de `opus` no `arquiteto` é uma fração pequena ou grande do custo total da
   demanda?** Ele já paga a latência de revisão humana de qualquer forma — a pergunta não é
   "opus é caro", é "opus mudou o resultado o suficiente pra justificar o gap de custo pro
   sonnet".
3. **`num_turns` muito alto num agente sonnet indica ele girando em círculo** (re-tentando,
   pedindo confirmação, refazendo) — às vezes sinal de que precisaria de mais contexto
   (subiria pra opus) ou de um prompt mais restrito (ficaria mais barato sem trocar de
   modelo).
4. **Cache**: `cache_read_tokens` alto e `cache_creation_tokens` baixo é o caso bom (contexto
   reaproveitado). Se toda sessão recria cache do zero, o achado do council de 2026-09-07
   ainda se aplica — o custo dominante é reprocessamento de `CLAUDE.md`/skills, não o modelo.

## Antes de propor mudar a tabela do CLAUDE.md

- Precisa de **pelo menos um ciclo completo** (uma demanda que passou pelas 7 etapas, não só
  uma etapa isolada) — uma amostra de uma etapa só não separa "esse agente está no modelo
  errado" de "essa demanda específica era difícil".
- A mudança proposta tem que apontar pra uma linha específica do CSV como evidência, não pra
  intuição — é literalmente o que o CLAUDE.md pede ("ajuste com dado, não com a heurística
  sozinha").
- Depois de mudar `model:` no frontmatter de um `.claude/agents/*.md`, registre no próprio
  CLAUDE.md (seção "Seleção de modelo por agente") o que motivou, com o número — do jeito que
  os achados de council anteriores já estão registrados lá.
