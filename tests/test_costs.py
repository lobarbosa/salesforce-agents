import csv
from types import SimpleNamespace

import pytest

from salesforce_agents import costs


@pytest.fixture(autouse=True)
def isolated_log_path(tmp_path, monkeypatch):
    monkeypatch.setattr(costs, "LOG_PATH", tmp_path / "logs" / "custos_agentes.csv")
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


def _read_rows():
    with costs.LOG_PATH.open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


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

    rows = _read_rows()
    assert len(rows) == 2
    models = {r["model"] for r in rows}
    assert models == {"claude-opus-5", "claude-haiku-4-5"}
    opus_row = next(r for r in rows if r["model"] == "claude-opus-5")
    assert opus_row["client"] == "acxya"
    assert opus_row["demand_id"] == "ACXYA-1"
    assert opus_row["etapa"] == "design"
    assert opus_row["input_tokens"] == "1000"
    assert opus_row["cost_usd"] == "0.0125"


def test_log_usage_falls_back_without_model_usage():
    result = _fake_result(
        usage={"input_tokens": 400, "output_tokens": 80},
        total_cost_usd=0.002,
    )

    costs.log_usage("acxya", "ACXYA-1", "analise", result)

    rows = _read_rows()
    assert len(rows) == 1
    assert rows[0]["model"] == "desconhecido"
    assert rows[0]["input_tokens"] == "400"
    assert rows[0]["cost_usd"] == "0.002"


def test_log_usage_appends_across_calls_with_single_header():
    result = _fake_result(usage={"input_tokens": 10, "output_tokens": 5}, total_cost_usd=0.001)

    costs.log_usage("acxya", "ACXYA-1", "analise", result)
    costs.log_usage("acxya", "ACXYA-1", "design", result)

    rows = _read_rows()
    assert len(rows) == 2
    assert [r["etapa"] for r in rows] == ["analise", "design"]
    header_lines = costs.LOG_PATH.read_text(encoding="utf-8").count(",".join(costs.FIELDS))
    assert header_lines == 1


def test_log_usage_never_persists_demand_content():
    result = _fake_result(usage={"input_tokens": 10, "output_tokens": 5}, total_cost_usd=0.001)

    costs.log_usage("acxya", "ACXYA-1", "analise", result)

    raw = costs.LOG_PATH.read_text(encoding="utf-8")
    assert "texto de resposta" not in raw
    assert "result" not in costs.FIELDS
