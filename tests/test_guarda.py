"""A última camada antes de escrever numa org de cliente.

O que estes testes protegem é uma coisa só: que nenhum caminho de código
consiga escrever numa org que não se declarou sandbox. O hook `guard-prod.sh`
não cobre este caminho — as ferramentas `sf_*` chamam `sf` por subprocess, de
dentro do Python, e PreToolUse do Bash não dispara ali.
"""

from __future__ import annotations

import json

import pytest

from salesforce_agents import guarda


class FakeProc:
    def __init__(self, stdout: str = "", stderr: str = "", returncode: int = 0):
        self.stdout = stdout
        self.stderr = stderr
        self.returncode = returncode


def resposta(is_sandbox) -> FakeProc:
    return FakeProc(stdout=json.dumps({"result": {"records": [{"IsSandbox": is_sandbox}]}}))


@pytest.fixture(autouse=True)
def _cache_limpo():
    guarda._SANDBOX_CONFIRMADA.clear()
    yield
    guarda._SANDBOX_CONFIRMADA.clear()


def test_sandbox_confirmada_libera():
    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=lambda _a: resposta(True)) is None


def test_org_de_producao_com_nome_de_sandbox_e_recusada():
    """O achado que motivou este módulo: o alias tem a forma certa, a org não é
    sandbox. Nome não é destino."""
    recusa = guarda.recusa_de_escrita("sbx-acxya-dev", executor=lambda _a: resposta(False))
    assert recusa and "IsSandbox=false" in recusa


def test_alias_fora_da_esteira_nem_chega_a_perguntar_pra_org():
    def explode(_args):
        raise AssertionError("não deveria consultar a org com alias recusado")

    assert guarda.recusa_de_escrita("acxya-main", executor=explode)


def test_resposta_ilegivel_recusa_em_vez_de_assumir():
    """Falha de rede, org não autenticada, JSON truncado: na dúvida não escreve.
    O default seguro aqui é recusar, não seguir."""
    for proc in (
        FakeProc(stdout="", stderr="No authorization found for sbx-acxya-dev", returncode=1),
        FakeProc(stdout="não é json"),
        FakeProc(stdout=json.dumps({"result": {"records": []}})),
        FakeProc(stdout=json.dumps({"status": 1})),
    ):
        assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=lambda _a, p=proc: p)


def test_cli_ausente_recusa():
    def sem_cli(_args):
        raise guarda.CliAusenteError

    recusa = guarda.recusa_de_escrita("sbx-acxya-dev", executor=sem_cli)
    assert recusa and "não encontrada no PATH" in recusa


def test_so_o_positivo_e_cacheado():
    """Uma falha transitória não pode virar 'org liberada' pelo resto da sessão."""
    chamadas = []

    def falha(args):
        chamadas.append(args)
        return FakeProc(stdout="", stderr="timeout", returncode=1)

    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=falha)
    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=falha)
    assert len(chamadas) == 2, "recusa não pode ser cacheada"

    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=lambda _a: resposta(True)) is None
    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=falha) is None, "positivo é cacheado"


def test_consulta_e_so_metadata():
    """Guardrail #2: a pergunta que a guarda faz à org devolve um booleano, e
    nenhum campo de negócio pode entrar nela."""
    vistos = {}

    def capturar(args):
        vistos["args"] = args
        return resposta(True)

    guarda.recusa_de_escrita("sbx-acxya-dev", executor=capturar)
    soql = vistos["args"][vistos["args"].index("--query") + 1]
    assert soql == "SELECT IsSandbox FROM Organization"


def test_cache_e_por_alias():
    assert guarda.recusa_de_escrita("sbx-acxya-dev", executor=lambda _a: resposta(True)) is None
    recusa = guarda.recusa_de_escrita("sbx-acxya-qa", executor=lambda _a: resposta(False))
    assert recusa, "confirmar dev não pode liberar qa"
