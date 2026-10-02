import csv
from types import SimpleNamespace

import pytest

from salesforce_agents import costs


@pytest.fixture(autouse=True)
def isolated_log_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(costs, "LOG_DIR", tmp_path / "logs" / "custos_agentes")
    monkeypatch.setattr(costs, "LOG_PATH_LEGADO", tmp_path / "logs" / "custos_agentes.csv")
    yield


def _fake_result(**overrides):
    defaults = dict(
        session_id="sess-1",
        duration_ms=1234,
        num_turns=3,
        is_error=False,
        model_usage=None,
        usage=None,
        total_cost_usd=None,
        result="texto de resposta que nunca deve ir pro log",
    )
    defaults.update(overrides)
    return SimpleNamespace(**defaults)


def _read_all_rows():
    return list(costs.ler_todas_as_linhas())


def _session_files():
    return sorted(costs.LOG_DIR.glob("*.csv")) if costs.LOG_DIR.exists() else []


def test_log_usage_writes_one_row_per_model():
    result = _fake_result(
        model_usage={
            "claude-opus-5": {
                "inputTokens": 1000,
                "outputTokens": 200,
                "cacheReadInputTokens": 0,
                "cacheCreationInputTokens": 500,
                "costUSD": 0.0125,
            },
            "claude-haiku-4-5": {
                "inputTokens": 300,
                "outputTokens": 50,
                "cacheReadInputTokens": 100,
                "cacheCreationInputTokens": 0,
                "costUSD": 0.0006,
            },
        }
    )

    costs.log_usage("acxya", "ACXYA-1", "design", result)

    rows = _read_all_rows()
    assert len(rows) == 2
    models = {r["model"] for r in rows}
    assert models == {"claude-opus-5", "claude-haiku-4-5"}
    opus_row = next(r for r in rows if r["model"] == "claude-opus-5")
    assert opus_row["client"] == "acxya"
    assert opus_row["demand_id"] == "ACXYA-1"
    assert opus_row["etapa"] == "design"
    assert opus_row["input_tokens"] == "1000"
    assert opus_row["cost_usd"] == "0.0125"
    # As duas linhas (dois modelos) vieram da mesma sessão — um arquivo só.
    assert len(_session_files()) == 1


def test_log_usage_falls_back_without_model_usage():
    result = _fake_result(
        usage={"input_tokens": 400, "output_tokens": 80},
        total_cost_usd=0.002,
    )

    costs.log_usage("acxya", "ACXYA-1", "analise", result)

    rows = _read_all_rows()
    assert len(rows) == 1
    assert rows[0]["model"] == "desconhecido"
    assert rows[0]["input_tokens"] == "400"
    assert rows[0]["cost_usd"] == "0.002"


def test_log_usage_different_sessions_write_different_files():
    """O ponto inteiro da mudança: duas sessões nunca tocam o mesmo arquivo."""
    r1 = _fake_result(session_id="sess-1", usage={"input_tokens": 10, "output_tokens": 5}, total_cost_usd=0.001)
    r2 = _fake_result(session_id="sess-2", usage={"input_tokens": 20, "output_tokens": 8}, total_cost_usd=0.002)

    costs.log_usage("acxya", "ACXYA-1", "analise", r1)
    costs.log_usage("eplast", "EPLAST-1", "design", r2)

    arquivos = _session_files()
    assert len(arquivos) == 2
    nomes = {a.name for a in arquivos}
    assert any("acxya" in n and "sess-1" in n for n in nomes)
    assert any("eplast" in n and "sess-2" in n for n in nomes)

    rows = _read_all_rows()
    assert len(rows) == 2
    assert {r["client"] for r in rows} == {"acxya", "eplast"}


def test_ler_todas_as_linhas_inclui_arquivo_legado(tmp_path):
    costs.LOG_PATH_LEGADO.parent.mkdir(parents=True, exist_ok=True)
    with costs.LOG_PATH_LEGADO.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=costs.FIELDS)
        writer.writeheader()
        writer.writerow({campo: "" for campo in costs.FIELDS} | {"client": "acxya", "model": "legado"})

    r = _fake_result(usage={"input_tokens": 1, "output_tokens": 1}, total_cost_usd=0.0001)
    costs.log_usage("acxya", "ACXYA-1", "analise", r)

    rows = _read_all_rows()
    assert len(rows) == 2
    assert {r["model"] for r in rows} == {"legado", "desconhecido"}


def test_log_usage_never_persists_demand_content():
    result = _fake_result(usage={"input_tokens": 10, "output_tokens": 5}, total_cost_usd=0.001)

    costs.log_usage("acxya", "ACXYA-1", "analise", result)

    arquivo = _session_files()[0]
    raw = arquivo.read_text(encoding="utf-8")
    assert "texto de resposta" not in raw
    assert "result" not in costs.FIELDS
