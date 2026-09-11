#!/usr/bin/env bash
# Guardrail #1, camada Bash: nenhum comando que altere estado sai daqui sem
# uma org alvo que tenha a forma da esteira.
#
# Registrado como PreToolUse hook do Bash em .claude/settings.json. **Só vê o
# que passa pela ferramenta Bash** — as ferramentas MCP `sf_*` chamam `sf` por
# subprocess, de dentro do Python, e não passam por aqui. Quem cobre aquele
# caminho é `src/salesforce_agents/tools.py`, que ainda pergunta à org se ela
# é sandbox (`Organization.IsSandbox`). Esta camada fecha a forma do nome;
# aquela confere o destino.
#
# Era um denylist ('prod|prd|production' no texto do comando) até 2026-09-11.
# Denylist responde a pergunta errada: o problema nunca foi o nome do alias,
# era o destino — uma org de produção autenticada como `sbx-acxya-dev` passava
# limpo. Agora é allowlist, e a regra é a mesma de `ambientes.alias_permitido`
# (duplicada aqui de propósito: o hook precisa rodar sem depender do pacote
# Python estar instalado).

set -uo pipefail

INPUT=$(cat)

if ! command -v python3 >/dev/null 2>&1; then
  echo "BLOQUEADO: python3 não está no PATH e o guard de produção não consegue inspecionar o comando. Na dúvida, não roda." >&2
  exit 2
fi

VEREDITO=$(printf '%s' "$INPUT" | python3 -c '
import json, re, shlex, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "") or ""
except Exception:
    print("BLOQUEADO: não consegui ler o comando para inspecionar. Na dúvida, não roda.")
    sys.exit(0)

DESTRUTIVO = re.compile(
    r"sf\s+project\s+deploy"
    r"|sf\s+apex\s+run"
    r"|sf\s+data\s+(create|update|delete|import|upsert)"
    r"|sf\s+org\s+delete"
    r"|force:mdapi:deploy"
)
if not DESTRUTIVO.search(cmd):
    sys.exit(0)

ALIAS = re.compile(r"^sbx-[a-z0-9][a-z0-9-]*-(dev|qa)$")

try:
    tokens = shlex.split(cmd)
except ValueError:
    print("BLOQUEADO: comando que altera estado com aspas desbalanceadas — não dá pra saber a org alvo.")
    sys.exit(0)

alvos = []
for i, tok in enumerate(tokens):
    if tok.startswith("--target-org="):
        alvos.append(tok.split("=", 1)[1])
    elif tok in ("--target-org", "-o") and i + 1 < len(tokens):
        alvos.append(tokens[i + 1])

if not alvos:
    print("BLOQUEADO: comando que altera estado sem --target-org explícito. Declare a org alvo.")
    sys.exit(0)

for alvo in alvos:
    if ALIAS.match(alvo):
        continue
    if alvo.startswith("$") or "$" in alvo:
        print(
            f"BLOQUEADO: a org alvo veio de uma variável ({alvo}) e o guard não consegue "
            f"saber para onde ela aponta. Escreva o alias literal."
        )
    else:
        print(
            f"BLOQUEADO: org alvo {alvo!r} fora da esteira. Só sao aceitos aliases no "
            f"formato sbx-<cliente>-dev ou sbx-<cliente>-qa (guardrail #1). Producao e "
            f"ato humano, nunca de agente."
        )
    sys.exit(0)
' 2>/dev/null)

if [ -n "$VEREDITO" ]; then
  echo "$VEREDITO" >&2
  exit 2
fi

exit 0
