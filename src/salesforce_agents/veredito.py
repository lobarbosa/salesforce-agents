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

_VEREDITO = re.compile(r"\*\*Veredito:\*\*\s*\**\s*(aprovado|reprovado)", re.I)
_ORG = re.compile(r"\*\*Org de teste:\*\*\s*`([^`]+)`", re.I)
_FALHA = re.compile(r"^#{2,4}\s*(FALHA\b[^\n]*)$", re.I | re.M)


@dataclass(frozen=True)
class Veredito:
    aprovado: bool
    motivo: str  # por que não passou; vazio quando aprovado
    falhas: tuple[str, ...] = ()


def ler(texto: str, org_de_qa: str) -> Veredito:
    falhas = tuple(m.group(1).replace("**", "").strip() for m in _FALHA.finditer(texto))
    explicito = _VEREDITO.search(texto)
    org = _ORG.search(texto)

    if not explicito:
        return Veredito(False, "o roteiro não declara `**Veredito:**` — sem veredito não há evidência de aprovação", falhas)
    if explicito.group(1).lower() == "reprovado":
        return Veredito(False, "QA reprovou", falhas)
    if not org or org.group(1).strip() != org_de_qa:
        achada = org.group(1) if org else "nenhuma"
        return Veredito(
            False,
            f"veredito aprovado sem evidência de que o teste rodou em `{org_de_qa}` (org declarada: {achada})",
            falhas,
        )
    return Veredito(True, "", falhas)
