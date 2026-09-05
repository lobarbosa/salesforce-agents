#!/usr/bin/env bash
# Bloqueia qualquer comando destrutivo apontado para org de produção.
# Registrado como PreToolUse hook do Bash em .claude/settings.json

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json;print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Comandos que alteram estado
DESTRUTIVO='sf project deploy|sf apex run|sf data (create|update|delete|import)|sf org delete|force:mdapi:deploy'

# Alvos de produção
PROD='prod|prd|production'

if echo "$CMD" | grep -Eq "$DESTRUTIVO"; then
  if echo "$CMD" | grep -Eiq "$PROD"; then
    echo "BLOQUEADO: comando destrutivo apontado para org de produção. Deploy em produção é ato humano." >&2
    exit 2
  fi
  if ! echo "$CMD" | grep -q -- "--target-org"; then
    echo "BLOQUEADO: comando destrutivo sem --target-org explícito. Declare a org alvo." >&2
    exit 2
  fi
fi

exit 0
