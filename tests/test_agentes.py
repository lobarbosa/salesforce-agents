"""Os agentes que o orquestrador manda acionar têm de existir, com modelo declarado.

Lê os arquivos em vez de importar `orchestrator` (que depende do SDK): o que se
quer travar é o nome escrito no prompt bater com um arquivo em `.claude/agents`.
"""

import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
AGENTES = RAIZ / ".claude" / "agents"


def _frontmatter(nome: str) -> dict:
    texto = (AGENTES / f"{nome}.md").read_text(encoding="utf-8")
    bloco = texto.split("---")[1]
    return dict(l.split(":", 1) for l in bloco.strip().splitlines() if ":" in l)


def _citados_no_orquestrador() -> set[str]:
    fonte = (RAIZ / "src" / "salesforce_agents" / "orchestrator.py").read_text(encoding="utf-8")
    mapa = fonte.split("SUBAGENTE_DA_ETAPA = {", 1)[1].split("\n}\n", 1)[0]
    return set(re.findall(r"`([a-z][a-z-]+)`", mapa)) - {"org-recon"}


def test_todo_subagente_citado_existe_e_declara_modelo():
    citados = _citados_no_orquestrador()
    assert {"ba-discovery", "recon", "arquiteto", "builder-declarativo", "dev-apex", "qa", "release", "doc"} <= citados
    for nome in citados:
        assert (AGENTES / f"{nome}.md").exists(), nome
        assert _frontmatter(nome).get("model", "").strip() in {"haiku", "sonnet", "opus"}, nome


def test_so_o_arquiteto_roda_no_modelo_mais_caro():
    caros = [p.stem for p in AGENTES.glob("*.md") if _frontmatter(p.stem).get("model", "").strip() == "opus"]
    assert caros == ["arquiteto"]


def test_recon_e_do_agente_recon_nao_do_arquiteto():
    assert _frontmatter("recon")["model"].strip() == "sonnet"
    arquiteto = (AGENTES / "arquiteto.md").read_text(encoding="utf-8")
    assert "Não refaça o recon" in arquiteto
