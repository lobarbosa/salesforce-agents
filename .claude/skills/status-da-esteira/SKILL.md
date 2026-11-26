---
name: status-da-esteira
description: Monta o status da esteira de um cliente ou de todos, a partir do banco do Squad OS — quem age em cada demanda, o que está rodando, o que espera o cliente. Use quando pedirem "status da esteira", "o que está parado" ou "o que tem rodando". Para quem opera a esteira, não para os agentes de etapa.
---

# Status da esteira

A fonte é o banco do Squad OS (Supabase, o mesmo projeto que o portal usa). Só leitura. Não
abra o GitHub Actions para responder isto: o banco já tem status, fila e histórico.

## Consulta base

Uma linha por demanda aberta do cliente. Troque `<CLIENT_ID>`; para todos os clientes, tire
o filtro e acrescente `c.nome` com um `join clients c`.

```sql
select d.code, left(d.titulo, 50) titulo, d.status::text,
       d.estimativa_consultor_horas ec, d.estimativa_aprovada_horas ea,
       d.estimativa_debitada_horas deb, d.entrega_manual_em,
       coalesce(nullif(u.nome, ''), u.email, 'sem dono') dono,
       (select string_agg(x.tipo || '/' || x.ambiente || ' ' ||
               coalesce(to_char(x.disparado_em - interval '3 hours', 'DD HH24:MI'), 'fila'), '; ')
          from disparos_esteira x
         where x.demanda_id = d.id and x.concluido_em is null) abertos,
       (select to_char(max((h->>'em')::timestamptz) - interval '3 hours', 'DD/MM HH24:MI')
          from jsonb_array_elements(d.historico::jsonb) h) ultima_mudanca
  from demandas d
  left join usuarios u on u.id = d.dono_id
 where d.client_id = '<CLIENT_ID>'
   and d.status::text not in ('entregue', 'cancelada')
 order by (regexp_replace(d.code, '\D', '', 'g'))::int;
```

O que está rodando agora, em qualquer cliente:

```sql
select c.nome, d.code, x.tipo, x.ambiente, x.autor,
       to_char(x.disparado_em - interval '3 hours', 'DD/MM HH24:MI') disparado
  from disparos_esteira x
  join clients c on c.id = x.client_id
  left join demandas d on d.id = x.demanda_id
 where x.concluido_em is null;
```

Armadilhas que já custaram erro:
- `status` é enum: compare com `d.status::text`. O nome do cliente é `clients.nome`.
- `demandas` não tem `atualizado_em`; a última mudança sai do `historico`.
- `disparado_em` nulo é fila; preenchido e sem `concluido_em` é execução em andamento.
- Horas no banco estão em UTC; mostre em Brasília (UTC−3).
- Etapa de agente (`build`, `qa`...) **sem** disparo aberto não está rodando: está parada.
- O dono (`dono_id`) é quem responde pela demanda; `autor` é só quem criou. Demanda parada
  e sem dono é a primeira a apontar.

## Como ler cada status

| Status | Quem age |
|---|---|
| `aguardando_gate_analise`, `_design`, `_build` | o time; no design, também o cliente se `ea` for nulo ou diferente de `ec` (AMS) |
| `aguardando_homologacao` | o cliente; com `entrega_manual_em`, é entrega manual |
| etapa de agente com disparo aberto | o agente |
| etapa de agente sem disparo | parada: alguém precisa retomar |
| `backlog`, `planejada` | ninguém ainda |
| `standby` | congelada; o motivo está em `motivo_parada` |

Para saber **por que** um gate está parado, leia os últimos comentários do card
(`comentarios`, por `demanda_id`) e, se o build bloqueou, o topo de `04-plano-build.md` na
branch `feature/<ID>`. O status sozinho não diz.

## Formato da resposta

1. Uma frase com o estado geral e se algo mudou desde o último status.
2. Tabela das que esperam o cliente (homologação), com horas.
3. Tabela das que esperam o time, com o que falta em cada uma.
4. O que depende de quem pediu o status, numerado.

Diga o que você conferiu e o que não conferiu. Não chame de "rodando" o que só tem status
de etapa de agente.
