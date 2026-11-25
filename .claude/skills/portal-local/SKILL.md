---
name: portal-local
description: Sobe o Squad OS localmente com banco descartável, login simulado e dados fictícios, para ver e medir as telas de verdade (capturas em desktop e celular, por papel). Use antes de revisar ou alterar a interface do portal em apps/squad-os, ou para conferir uma tela depois de uma mudança. Não é para os agentes da esteira.
---

# Portal local

O portal depende de Postgres e de login pelo Supabase, então não abre só com `next dev`.
Este ambiente troca os dois por substitutos locais e carrega dados inventados. Serve para
olhar a tela; não testa o que depende de serviço externo.

Só dados fictícios. Nunca copie dado do banco real para cá, nem para "ver com dado de
verdade" (guardrail #2).

## Subir e derrubar

Da raiz do repositório:

```bash
bash .claude/skills/portal-local/scripts/subir.sh          # sobe; leva 2 a 4 minutos
bash .claude/skills/portal-local/scripts/subir.sh parar    # derruba e apaga o banco
```

O script cria um Postgres descartável, aplica todas as migrações, carrega
`dados-ficticios.sql`, sobe a autenticação simulada, compila e inicia o portal em
`http://localhost:3977`. Derrube ao terminar.

Depois de mudar código do portal, rode `subir.sh` de novo: ele recompila. Para mudança só de
dados, altere `dados-ficticios.sql` e suba de novo.

## Quem existe nos dados fictícios

| Usuário | Papel |
|---|---|
| `admin@teste.local` | admin |
| `consultor@teste.local` | consultor |
| `cliente@teste.local` | cliente da "Aurora Embalagens (fictícia)", id `c1` |
| `financeiro@teste.local` | financeiro |

Cliente `c1` tem contrato AMS e demandas `d1` a `d9` em vários estágios (homologação, gates,
build parado, QA com execução em andamento, congelada, entregue). Cliente `c2` tem contrato
de projeto. Há contas a pagar e uma despesa recorrente.

## Capturar telas

```bash
node .claude/skills/portal-local/scripts/capturar.js <pasta-de-saida> '[
  {"nome":"home","email":"admin@teste.local","url":"/"},
  {"nome":"modal-cel","email":"cliente@teste.local","url":"/clients/c1?demand=d1","mobile":true},
  {"nome":"lancar","email":"financeiro@teste.local","url":"/financeiro/contas","click":["text=Lançar conta"]}
]'
```

Cada item: `nome` do arquivo, `email` (define o papel), `url`, e opcionais `mobile` (390 px;
sem ele, 1440 px), `full` (página inteira) e `click` (seletores a clicar antes da captura).
A saída mostra o status, a rota final, se a página estoura a largura (`overflowX`) e erros
de console. `PAGEERROR` na saída é erro real de página, não ruído: investigue.

Na captura de página inteira, elementos fixos (o botão do Copiloto) aparecem no meio da
imagem. É efeito da captura, não defeito.

## Medir

```bash
node .claude/skills/portal-local/scripts/medir.js
```

Percorre 24 telas em celular e desktop e lista, por tela: rolagem lateral interna, texto
cortado com reticências, alvos de toque pequenos (celular) e fonte abaixo de 11 px. Rode
antes e depois de uma mudança de interface e compare.

## O que este ambiente não prova

- Envio de arquivo (anexo, documento fiscal, evidência de entrega manual): depende do
  armazenamento do Supabase.
- Aprovar gate, materializar demanda, testar conexão: dependem da API do GitHub.
- Copiloto: depende do modelo.
- Telas que leem o banco dos agentes (saúde financeira, divergências, saúde dos agentes)
  mostram só o estado vazio.

Diga isso ao relatar: "aberto e conferido na tela" não é "testado de ponta a ponta".

## Armadilhas que o script já resolve

- O diretório de dados do Postgres fica na casa do usuário `postgres`. Em diretório
  temporário da sessão, a permissão dos diretórios pais é refeita no meio do uso e o banco
  cai com "Permission denied".
- A migração do RAG usa `pgvector`, que não existe localmente: a coluna vira texto.
- Processo em segundo plano com a saída herdada segura o terminal de quem chamou; por isso
  tudo no script é redirecionado.
- `INSERT` com várias linhas falha inteiro se uma linha viola restrição: nos dados
  fictícios, cada contrato é um comando.

Para revisar a interface com critério, use junto a skill `ui-ux-pro-max`
(`.claude/skills/ui-ux-pro-max/SKILL.md`).
