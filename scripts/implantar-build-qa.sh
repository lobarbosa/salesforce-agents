#!/usr/bin/env bash
# Implanta na sandbox de QA o que a demanda mudou no force-app do cliente e
# registra em 05-deploy-qa.md. Usado pelo run-demand.yml antes da sessão de QA
# e, no QA em duas fases, depois da conferência (achado EPLAST-28, 2026-11-16).
# Precisa de CLIENT, DEMAND_ID e TARGET_ORG no ambiente. Sai com 1 se falhar.
set -e
if [ "$TARGET_ORG" != "sbx-$CLIENT-qa" ]; then
  echo "::error::A etapa de QA só implanta em sbx-$CLIENT-qa; o alvo deste job é '$TARGET_ORG'. Nada foi implantado."
  exit 1
fi
git fetch -q origin main
BASE=$(git merge-base origin/main HEAD 2>/dev/null || true)
if [ -z "$BASE" ]; then
  git fetch -q --unshallow origin 2>/dev/null || git fetch -q origin
  BASE=$(git merge-base origin/main HEAD)
fi
set +e
git diff --name-only "$BASE" HEAD -- "clients/$CLIENT/force-app" \
  | python3 scripts/pacote_da_demanda.py "$CLIENT" > /tmp/pacote-args.txt
RC=$?
set -e
if [ "$RC" -eq 3 ]; then
  echo "Esta demanda não mudou metadata — nada a implantar na QA."
  exit 0
fi
[ "$RC" -eq 0 ] || exit "$RC"
mapfile -t ARGS < /tmp/pacote-args.txt
echo "Implantando em $TARGET_ORG: ${ARGS[*]}"
cd "clients/$CLIENT"
set +e
sf project deploy start "${ARGS[@]}" --target-org "$TARGET_ORG" --wait 30 --json > /tmp/deploy-qa.json
RC=$?
set -e
# Nova rodada de QA de demanda cuja versão do agente o QA já ativou na rodada
# anterior (achado EPLAST-27, 2026-11-16): a plataforma recusa reimplantar versão
# de agente ativa ("o agente está ativo" / "versão do bot ativa") e o deploy
# inteiro cai, sem o build ter mudado. Se TODAS as falhas forem essas, a versão
# já está na QA como foi implantada (ativa não aceita edição): reimplanta o
# resto do pacote sem os arquivos do agente.
AGENTE_JA_ATIVO=""
AGENTE_FORA=""
ATIVO='agente est[aá] ativo|vers[aã]o do bot ativa|agent is active|active bot version'
if [ "$RC" -ne 0 ] && jq -e --arg re "$ATIVO" '
      [(.result.details.componentFailures // []) | if type=="array" then .[] else . end]
      | length > 0 and all(.[]; (.problem // "") | test($re; "i"))' /tmp/deploy-qa.json >/dev/null 2>&1; then
  AGENTE_JA_ATIVO=$(jq -r '[(.result.details.componentFailures // []) | if type=="array" then .[] else . end | "\(.componentType) \(.fullName)"] | unique | join(", ")' /tmp/deploy-qa.json)
  # Primeiro tira só as versões que a plataforma recusou e mantém o resto do
  # agente (achado EPLAST-29, 2026-11-17: a v16 ativa derrubou o deploy, o
  # pacote foi sem agente nenhum e a v17, que corrigia as falhas do QA, nunca
  # chegou à sandbox). Se o novo deploy cair por outro motivo, essa é a falha
  # de verdade e é ela que aparece. Só volta a tirar o agente inteiro se a
  # plataforma continuar recusando por versão ativa.
  SO_A_ATIVA=""
  if python3 ../../scripts/pacote_sem_versao_ativa.py /tmp/deploy-qa.json /tmp/pacote-args.txt > /tmp/pacote-args-novo.txt; then
    echo "Versão do agente já ativa na QA ($AGENTE_JA_ATIVO): reimplantando sem ela, com as versões novas da demanda."
    mapfile -t ARGS_NOVO < /tmp/pacote-args-novo.txt
    set +e
    sf project deploy start "${ARGS_NOVO[@]}" --target-org "$TARGET_ORG" --wait 30 --json > /tmp/deploy-qa.json
    RC=$?
    set -e
    if [ "$RC" -eq 0 ]; then
      SO_A_ATIVA=1
      ARGS=("${ARGS_NOVO[@]}")
      cp /tmp/pacote-args-novo.txt /tmp/pacote-args.txt
    elif ! jq -e --arg re "$ATIVO" '
          [(.result.details.componentFailures // []) | if type=="array" then .[] else . end]
          | length > 0 and all(.[]; (.problem // "") | test($re; "i"))' /tmp/deploy-qa.json >/dev/null 2>&1; then
      SO_A_ATIVA=1
    fi
  fi
  if [ -z "$SO_A_ATIVA" ]; then
  AGENTE_FORA=1
  echo "Versão do agente já ativa na QA ($AGENTE_JA_ATIVO): reimplantando o pacote sem os arquivos do agente."
  SEM_AGENTE=()
  i=0
  while [ "$i" -lt "${#ARGS[@]}" ]; do
    if [ "${ARGS[$i]}" = "--source-dir" ]; then
      case "${ARGS[$((i+1))]}" in
        */bots/*|*/genAiPlannerBundles/*) ;;
        *) SEM_AGENTE+=("--source-dir" "${ARGS[$((i+1))]}") ;;
      esac
      i=$((i+2))
    else
      SEM_AGENTE+=("${ARGS[$i]}")
      i=$((i+1))
    fi
  done
  printf '%s\n' "${SEM_AGENTE[@]}" > /tmp/pacote-args.txt
  if printf '%s\n' "${SEM_AGENTE[@]}" | grep -qx -- "--source-dir"; then
    ARGS=("${SEM_AGENTE[@]}")
    set +e
    sf project deploy start "${ARGS[@]}" --target-org "$TARGET_ORG" --wait 30 --json > /tmp/deploy-qa.json
    RC=$?
    set -e
  else
    echo "O pacote só tinha a versão do agente, que já está ativa na QA: nada a reimplantar."
    echo '{"result":{"id":"sem deploy","status":"versão do agente já ativa"}}' > /tmp/deploy-qa.json
    RC=0
  fi
  fi
fi
# Rodada nova de demanda com classe agendável ou batch (achado EPLAST-33,
# 2026-11-17): o trabalho que o QA armou na rodada anterior continua na QA, e a
# plataforma recusa atualizar classe com trabalho pendente; o deploy inteiro
# cai sem o build ter defeito. Se TODAS as falhas forem essa, cancela só os
# trabalhos que a própria plataforma citou (são os das classes do pacote),
# registra o que foi cancelado e reimplanta. Quem arma de novo é o QA, no teste,
# ou a ativação, que é passo separado.
JOBS_CANCELADOS=""
if [ "$RC" -ne 0 ] && python3 ../../scripts/jobs_pendentes.py /tmp/deploy-qa.json > /tmp/jobs-ids.txt; then
  mapfile -t JOBS < /tmp/jobs-ids.txt
  LISTA=$(printf "'%s'," "${JOBS[@]}")
  LISTA=${LISTA%,}
  echo "Deploy travado por trabalho Apex pendente na QA (${JOBS[*]}): cancelando e reimplantando."
  sf data query --query "SELECT Id, CronJobDetail.Name, CronExpression, State FROM CronTrigger WHERE Id IN ($LISTA)" \
    --target-org "$TARGET_ORG" --json > /tmp/jobs-antes.json 2>/dev/null || true
  DESCRITOS=$(jq -r '(.result.records // [])[] | "\(.Id[0:15]) \(.CronJobDetail.Name // "sem nome"), agenda \(.CronExpression // "?"), estado \(.State // "?")"' /tmp/jobs-antes.json 2>/dev/null || true)
  : > /tmp/abortar.apex
  for J in "${JOBS[@]}"; do
    echo "try { System.abortJob('$J'); } catch (Exception e) { System.debug(e.getMessage()); }" >> /tmp/abortar.apex
    if ! printf '%s\n' "$DESCRITOS" | grep -q "^${J:0:15} "; then
      DESCRITOS=$(printf '%s\n%s sem agenda registrada (trabalho assíncrono em andamento)' "$DESCRITOS" "${J:0:15}")
    fi
  done
  if sf apex run --file /tmp/abortar.apex --target-org "$TARGET_ORG" --json > /tmp/abortar.json; then
    JOBS_CANCELADOS=$(printf '%s\n' "$DESCRITOS" | sed '/^$/d')
    sleep 20
    set +e
    sf project deploy start "${ARGS[@]}" --target-org "$TARGET_ORG" --wait 30 --json > /tmp/deploy-qa.json
    RC=$?
    set -e
  else
    echo "::warning::Não consegui cancelar os trabalhos pendentes na QA; o deploy continua falho."
    jq -r '.message // empty' /tmp/abortar.json | head -5 || true
  fi
fi
ID=$(jq -r '.result.id // "sem id"' /tmp/deploy-qa.json)
ESTADO=$(jq -r '.result.status // .name // "desconhecido"' /tmp/deploy-qa.json)
if [ "$RC" -ne 0 ]; then
  echo "::error::Deploy na sandbox de QA falhou ($ESTADO, id $ID). O gate de build não foi aprovado; corrija e aprove de novo."
  jq -r '(.result.details.componentFailures // []) | if type=="array" then .[] else . end | "- \(.componentType) \(.fullName): \(.problem)"' /tmp/deploy-qa.json | head -40 || true
  # Falha de teste Apex não aparece em componentFailures (achado
  # SOMOSAGILITY-10, 2026-11-15: deploy Failed sem nenhum motivo no log).
  jq -r '(.result.details.runTestResult.failures // []) | if type=="array" then .[] else . end | "- teste \(.name).\(.methodName): \(.message)"' /tmp/deploy-qa.json | head -40 || true
  jq -r '(.result.details.runTestResult.codeCoverageWarnings // []) | if type=="array" then .[] else . end | "- cobertura \(.name // "geral"): \(.message)"' /tmp/deploy-qa.json | head -20 || true
  jq -r '.result.errorMessage // empty' /tmp/deploy-qa.json | head -5 || true
  jq -r '.message // empty' /tmp/deploy-qa.json | head -5
  exit 1
fi
# O que foi implantado fica registrado na pasta da demanda: é o que o
# QA confere antes de testar e o que quem homologa pode auditar.
{
  echo "# Deploy na sandbox de QA"
  echo
  echo "- **Org:** \`$TARGET_ORG\`"
  echo "- **Deploy:** \`$ID\` ($ESTADO)"
  echo "- **Quando:** $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "- **Commit:** \`$(git rev-parse --short HEAD)\`"
  if [ -n "$AGENTE_JA_ATIVO" ]; then
    echo "- **Agente:** já ativo na QA desde a rodada anterior, não reimplantado ($AGENTE_JA_ATIVO)"
  fi
  if [ -n "$AGENTE_FORA" ]; then
    echo "- **Atenção:** nenhum arquivo de agente foi implantado nesta rodada. Se a demanda criou versão nova do agente, ela **não está na QA**."
  fi
  if [ -n "$JOBS_CANCELADOS" ]; then
    echo
    echo "## Trabalhos agendados cancelados antes do deploy"
    echo
    echo "A plataforma recusa atualizar classe com trabalho pendente. Estes trabalhos das classes do pacote, deixados por rodada anterior, foram cancelados na sandbox de QA e **não foram rearmados**: o teste arma de novo o que precisar."
    echo
    printf '%s\n' "$JOBS_CANCELADOS" | sed 's/^/- /'
  fi
  echo
  echo "## Componentes"
  grep -v '^--' /tmp/pacote-args.txt | grep '^force-app/' | sed 's/^/- `/; s/$/`/'
} > "demandas/$DEMAND_ID/05-deploy-qa.md"
echo "Deploy $ID concluído ($ESTADO)."
