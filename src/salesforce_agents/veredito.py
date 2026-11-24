"""Veredito do QA: só o que foi provado na sandbox de QA chega ao cliente.

Achado real (2026-11-12/13): sete demandas da Eplast e três da Somos estavam em
"aguardando homologação" com o QA reprovado — o veredito existia no
`05-testes.md`, mas o fluxo avançava igual, porque só conferia se o arquivo
existia. O cliente era chamado a homologar o que o próprio QA tinha recusado.

Regra (decisão do responsável, 2026-11-14): depois do QA, a demanda só segue
para a homologação com **evidência de aprovação** — `**Veredito:** aprovado`
e `**Org de teste:**` apontando a sandbox de QA do cliente. Qualquer outra
coisa (reprovado, sem veredito, org errada) volta para a construção.

A leitura espelha `apps/squad-os/lib/qa-veredito.ts` — mude as duas juntas.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

_VEREDITO = re.compile(
    r"\*\*Veredito:\*\*\s*\**\s*(aprovado|reprovado|aguardando execu[çc][ãa]o)", re.I
)
# A org vem com ou sem crase, e às vezes seguida de comentário entre parênteses:
# "`sbx-x-dev`", "sbx-x-dev" e "`sbx-x-dev` (Org ID ...)" são a mesma declaração.
# Achado EPLAST-28 (2026-11-15): sem crase, a verificação inconclusiva foi lida
# como reprovada e a construção rodou de novo à toa.
_ORG = re.compile(r"\*\*Org de teste:\*\*\s*`?([A-Za-z0-9_.\-]+)`?", re.I)
_FALHA = re.compile(r"^#{2,4}\s*(FALHA\b[^\n]*)$", re.I | re.M)


@dataclass(frozen=True)
class Veredito:
    aprovado: bool
    motivo: str  # por que não passou; vazio quando aprovado
    falhas: tuple[str, ...] = ()
    # QA em duas fases (2026-11-15): automação que só roda por agendamento não
    # se prova numa sessão. Na primeira, o QA arma o teste e declara
    # `aguardando execução`; não é aprovação nem reprovação, e a demanda
    # espera em `qa` até a sessão seguinte conferir e dar o veredito final.
    pendente: bool = False


def ler(texto: str, org_de_qa: str) -> Veredito:
    falhas = tuple(m.group(1).replace("**", "").strip() for m in _FALHA.finditer(texto))
    explicito = _VEREDITO.search(texto)
    org = _ORG.search(texto)

    if not explicito:
        return Veredito(False, "o roteiro não declara `**Veredito:**` — sem veredito não há evidência de aprovação", falhas)
    if explicito.group(1).lower() == "reprovado":
        return Veredito(False, "QA reprovou", falhas)
    if explicito.group(1).lower().startswith("aguardando"):
        if not org or org.group(1).strip() != org_de_qa:
            return Veredito(False, f"teste armado fora de `{org_de_qa}`", falhas)
        return Veredito(False, "aguardando a execução agendada para conferir", falhas, pendente=True)
    if not org or org.group(1).strip() != org_de_qa:
        achada = org.group(1) if org else "nenhuma"
        return Veredito(
            False,
            f"veredito aprovado sem evidência de que o teste rodou em `{org_de_qa}` (org declarada: {achada})",
            falhas,
        )
    return Veredito(True, "", falhas)


# Quando o QA em duas fases quer ser conferido (2026-11-15). Vai no sync para o
# Squad OS reenfileirar a segunda sessão sozinho, em vez de alguém lembrar de
# disparar. Formato pedido em qa.md: data e hora em UTC, ISO 8601.
_CONFERIR = re.compile(r"\*\*Conferir depois de:\*\*\s*`?(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?Z?)`?", re.I)


def conferir_depois_de(texto: str) -> str:
    """O instante ISO (UTC) de `**Conferir depois de:**`, ou vazio."""
    m = _CONFERIR.search(texto)
    if not m:
        return ""
    v = m.group(1).replace(" ", "T")
    return v if v.endswith("Z") else v + "Z"
