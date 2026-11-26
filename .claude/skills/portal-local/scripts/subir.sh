#!/usr/bin/env bash
# Sobe o Squad OS local com banco descartável, login simulado e dados fictícios.
# Uso (da raiz do repositório): bash .claude/skills/portal-local/scripts/subir.sh
# Para derrubar e apagar tudo:  bash .claude/skills/portal-local/scripts/subir.sh parar
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../../../.." && pwd)"
APP="$RAIZ/apps/squad-os"
PORTA_APP="${PORTA_APP:-3977}"
PORTA_PG="${PORTA_PG:-55432}"
PORTA_AUTH="${PORTA_AUTH:-54399}"
PG_BIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)"
PG_USER="$(id -un postgres 2>/dev/null || true)"
# O diretório de dados fica na casa do usuário postgres: em diretório temporário da sessão
# a permissão dos pais pode ser refeita no meio do uso, e o Postgres cai com "Permission
# denied" em pg_control.
PG_DIR="$(getent passwd postgres | cut -d: -f6)/squad-os-local"

parar() {
  pkill -f "next start -p $PORTA_APP" 2>/dev/null || true
  pkill -f next-server 2>/dev/null || true
  pkill -f "auth-simulada.js" 2>/dev/null || true
  if [ -d "$PG_DIR/dados" ]; then
    su "$PG_USER" -c "$PG_BIN/pg_ctl -D $PG_DIR/dados stop -m fast" >/dev/null 2>&1 || true
  fi
  rm -rf "$PG_DIR"
}

if [ "${1:-}" = "parar" ]; then parar; echo "ambiente local removido"; exit 0; fi
[ -n "$PG_BIN" ] && [ -n "$PG_USER" ] || { echo "Postgres não está instalado nesta máquina"; exit 1; }

parar
mkdir -p "$PG_DIR/run" && chown -R "$PG_USER" "$PG_DIR"
su "$PG_USER" -c "$PG_BIN/initdb -D $PG_DIR/dados -A trust -U app >/dev/null"
setsid su "$PG_USER" -c "$PG_BIN/pg_ctl -D $PG_DIR/dados -o '-p $PORTA_PG -k $PG_DIR/run' -l $PG_DIR/log start" >/dev/null 2>&1 </dev/null
export PGHOST=localhost PGPORT="$PORTA_PG" PGUSER=app
psql -q -d postgres -c "create database squad"
export PGDATABASE=squad
# Papéis e schema que as migrações esperam do Supabase.
psql -q -c "create role anon; create role authenticated; create role service_role; create schema if not exists ops;"
# Migrações na ordem. A do RAG usa pgvector, que não existe aqui: a coluna vira texto e o
# índice vetorial sai. O portal não consulta essa tabela.
for d in "$APP"/prisma/migrations/*/; do
  f="$d/migration.sql"
  if echo "$d" | grep -q rag_chunks; then
    sed -e '/CREATE EXTENSION/d' -e 's/vector(1536)/text/' -e '/rag_chunks_embedding_idx/,/;/d' "$f" | psql -q -v ON_ERROR_STOP=1
  else
    psql -q -v ON_ERROR_STOP=1 -f "$f"
  fi
done
psql -q -v ON_ERROR_STOP=1 -f "$AQUI/dados-ficticios.sql"

# Tudo redirecionado: processo em segundo plano com a saída herdada segura o terminal (ou o
# pipe) de quem chamou, e o script parece travado.
setsid nohup node "$AQUI/auth-simulada.js" "$PORTA_AUTH" >/dev/null 2>&1 </dev/null &

export DATABASE_URL="postgresql://app@localhost:$PORTA_PG/squad" DIRECT_URL="postgresql://app@localhost:$PORTA_PG/squad"
export NEXT_PUBLIC_SUPABASE_URL="http://localhost:$PORTA_AUTH" NEXT_PUBLIC_SUPABASE_ANON_KEY=anon
cd "$APP"
[ -d node_modules ] || [ -d "$RAIZ/node_modules" ] || (cd "$RAIZ" && npm ci >/dev/null 2>&1)
npx prisma generate >/dev/null 2>&1
npx next build >/dev/null 2>&1 || { echo "o build do portal falhou; rode 'npx next build' em apps/squad-os para ver o erro"; exit 1; }
setsid nohup npx next start -p "$PORTA_APP" > "$PG_DIR/portal.log" 2>&1 </dev/null &
for _ in $(seq 1 30); do
  curl -s -o /dev/null "http://localhost:$PORTA_APP/login" && break
  perl -e 'select(undef,undef,undef,1)'
done
curl -s -o /dev/null -w "portal no ar em http://localhost:$PORTA_APP (login: %{http_code})\n" "http://localhost:$PORTA_APP/login"
