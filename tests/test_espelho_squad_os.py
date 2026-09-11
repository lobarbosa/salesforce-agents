"""O Squad OS repete a lista de estágios em TypeScript. Aqui é onde isso é conferido.

`apps/squad-os/lib/demandas.ts` declara TRIAGE e EXEC_STAGES à mão porque o app
é outro runtime — não dá pra importar `demands.py` de dentro do Next. A cópia é
consciente, mas cópia sem conferência sai de sincronia na primeira mudança, e
sai **em silêncio**: um estágio novo em Python vira cartão que não aparece em
coluna nenhuma do quadro. A demanda existe, o quadro não a mostra.

Mora do lado Python (e não num teste do app) porque é aqui que a fonte de
verdade está, e porque `ci-python.yml` roda em todo PR.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from salesforce_agents import demands

TS = Path("apps/squad-os/lib/demandas.ts")


def _lista(nome: str) -> tuple[str, ...]:
    texto = TS.read_text(encoding="utf-8")
    m = re.search(rf"export const {nome} = \[(.*?)\] as const;", texto, re.S)
    assert m, f"{nome} não encontrada em {TS} — o formato do arquivo mudou"
    return tuple(re.findall(r'"([^"]+)"', m.group(1)))


@pytest.fixture(autouse=True)
def _tem_o_app():
    if not TS.exists():
        pytest.skip(f"{TS} não existe neste checkout")


def test_triagem_bate_com_o_python():
    assert _lista("TRIAGE") == demands.STAGES_TRIAGEM


def test_execucao_bate_com_o_python():
    # `entregue` fica de fora no app de propósito: é a coluna "Entregue" do
    # quadro, não uma etapa da esteira em execução.
    assert _lista("EXEC_STAGES") == tuple(e for e in demands.STAGES_EXECUCAO if e != "entregue")


def test_todo_estagio_aparece_em_alguma_coluna_do_quadro():
    """O que este teste impede: demanda existindo e sumindo do quadro."""
    no_quadro = set(_lista("TRIAGE")) | set(_lista("EXEC_STAGES")) | {"entregue"}
    assert set(demands.STAGES) - no_quadro == set()


def test_o_gate_do_cliente_e_o_mesmo_dos_dois_lados():
    """`aguardando_homologacao` é o único gate que o papel `cliente` aprova. Se
    o nome mudasse só de um lado, o cliente veria "precisa da sua aprovação"
    num gate que a API devolve 403 — ou, pior, não veria no que é dele."""
    texto = TS.read_text(encoding="utf-8")
    m = re.search(r'const GATE_DO_CLIENTE = "([^"]+)";', texto)
    assert m, "GATE_DO_CLIENTE não encontrado em lib/demandas.ts"
    assert m.group(1) in demands.STAGES_EXECUCAO
    assert m.group(1) == "aguardando_homologacao"
