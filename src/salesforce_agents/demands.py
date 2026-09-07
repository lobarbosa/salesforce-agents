"""Modelo de demanda: substitui o Jira como fonte de "história" para os agentes,
mantendo o mesmo fluxo de gates descrito em CLAUDE.md.

Cada demanda vive em clients/<cliente>/demandas/<DEMAND-ID>/, com a história do
consultor em demanda.md e o estágio atual em status.yaml.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import yaml

CLIENTS_ROOT = Path("clients")

# Triagem: onde a demanda espera antes de entrar no fluxo de execução.
STAGES_TRIAGEM = ("backlog", "planejada", "recorrente", "standby")

# Execução: espelha o fluxo canônico do CLAUDE.md (etapas 1-7).
STAGES_EXECUCAO = (
    "analise",
    "aguardando_gate_analise",
    "design",
    "aguardando_gate_design",
    "build",
    "aguardando_gate_build",
    "qa",
    "aguardando_homologacao",
    "release",
    "entregue",
)

STAGES = STAGES_TRIAGEM + STAGES_EXECUCAO


class DemandNotFoundError(Exception):
    pass


class InvalidStatusError(Exception):
    pass


class ArtifactAusenteError(InvalidStatusError):
    """Bloqueia a transição quando o estágio que está sendo deixado não produziu
    o(s) artefato(s) numerado(s) que ele deveria ter gerado — sem isso, status.yaml
    pode declarar um estágio que nunca aconteceu de fato (achado do council de
    2026-09-07: o gate humano só vale algo se o estado que ele lê for verdadeiro)."""

    pass


# Ordem de progresso do fluxo de execução — usada só para saber se uma transição
# está avançando (exige o artefato do estágio anterior) ou corrigindo/recuando
# (sempre permitido, é assim que um estado incorreto é reparado).
_STAGE_ORDER = {stage: i for i, stage in enumerate(STAGES_EXECUCAO)}

# Artefato(s) que devem existir em disco antes de avançar PARA ALÉM do estágio
# indicado — reflete a "Estrutura de artefatos por demanda" do CLAUDE.md raiz.
REQUIRED_ARTIFACTS = {
    "analise": ("01-analise.md",),
    "design": ("02-recon.md", "03-design.md"),
    "build": ("04-plano-build.md",),
    "qa": ("05-testes.md",),
    "release": ("06-entrega.md",),
}


@dataclass
class Demand:
    id: str
    client: str
    titulo: str
    tipo: str  # "projeto" | "sustentacao"
    status: str
    criado_em: str
    historico: list[dict] = field(default_factory=list)

    @property
    def path(self) -> Path:
        return CLIENTS_ROOT / self.client / "demandas" / self.id

    def status_path(self) -> Path:
        return self.path / "status.yaml"

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "client": self.client,
            "titulo": self.titulo,
            "tipo": self.tipo,
            "status": self.status,
            "criado_em": self.criado_em,
            "historico": self.historico,
        }

    def save(self) -> None:
        self.path.mkdir(parents=True, exist_ok=True)
        self.status_path().write_text(
            yaml.safe_dump(self.to_dict(), allow_unicode=True, sort_keys=False),
            encoding="utf-8",
        )

    @classmethod
    def load(cls, client: str, demand_id: str) -> "Demand":
        status_file = CLIENTS_ROOT / client / "demandas" / demand_id / "status.yaml"
        if not status_file.exists():
            raise DemandNotFoundError(f"{client}/{demand_id} não encontrada")
        data = yaml.safe_load(status_file.read_text(encoding="utf-8"))
        return cls(**data)


def _next_id(client: str) -> str:
    base = CLIENTS_ROOT / client / "demandas"
    base.mkdir(parents=True, exist_ok=True)
    code = re.sub(r"[^A-Z0-9]", "", client.upper()) or "CLI"
    existing = [p.name for p in base.iterdir() if p.is_dir() and p.name.startswith(f"{code}-")]
    nums = [int(n.rsplit("-", 1)[-1]) for n in existing if n.rsplit("-", 1)[-1].isdigit()]
    return f"{code}-{max(nums, default=0) + 1}"


def create(client: str, titulo: str, texto: str, tipo: str = "sustentacao") -> Demand:
    if tipo not in ("projeto", "sustentacao"):
        raise InvalidStatusError(f"tipo inválido: {tipo}")
    demand_id = _next_id(client)
    demand = Demand(
        id=demand_id,
        client=client,
        titulo=titulo,
        tipo=tipo,
        status="backlog",
        criado_em=datetime.now(timezone.utc).isoformat(),
    )
    demand.path.mkdir(parents=True, exist_ok=True)
    (demand.path / "demanda.md").write_text(f"# {titulo}\n\n{texto}\n", encoding="utf-8")
    demand.save()
    return demand


def transition(client: str, demand_id: str, novo_status: str, autor: str) -> Demand:
    if novo_status not in STAGES:
        raise InvalidStatusError(f"status desconhecido: {novo_status}")
    demand = Demand.load(client, demand_id)

    is_avanco = (
        demand.status in _STAGE_ORDER
        and novo_status in _STAGE_ORDER
        and _STAGE_ORDER[novo_status] > _STAGE_ORDER[demand.status]
    )
    if is_avanco and demand.status in REQUIRED_ARTIFACTS:
        faltando = [
            nome for nome in REQUIRED_ARTIFACTS[demand.status]
            if not (demand.path / nome).exists()
        ]
        if faltando:
            raise ArtifactAusenteError(
                f"{client}/{demand_id}: não é possível avançar de '{demand.status}' para "
                f"'{novo_status}' — falta(m) {', '.join(faltando)} em {demand.path}/. "
                f"O estágio '{demand.status}' não produziu o que deveria; gere o artefato "
                f"antes de avançar, ou corrija o status manualmente se ele já estava errado."
            )

    demand.historico.append(
        {
            "de": demand.status,
            "para": novo_status,
            "autor": autor,
            "em": datetime.now(timezone.utc).isoformat(),
        }
    )
    demand.status = novo_status
    demand.save()
    return demand


def list_demands(client: str | None = None) -> list[Demand]:
    if not CLIENTS_ROOT.exists():
        return []
    clients = (
        [client]
        if client
        else sorted(p.name for p in CLIENTS_ROOT.iterdir() if p.is_dir())
    )
    out: list[Demand] = []
    for c in clients:
        demandas_dir = CLIENTS_ROOT / c / "demandas"
        if not demandas_dir.exists():
            continue
        for d in sorted(demandas_dir.iterdir()):
            if (d / "status.yaml").exists():
                out.append(Demand.load(c, d.name))
    return out
