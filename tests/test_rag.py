"""Sanity checks que não exigem chamadas de rede/API."""

from salesforce_agents.rag import criar_rag_tools_server


def test_rag_tools_server_registrado():
    servidor = criar_rag_tools_server("acxya")
    assert servidor["type"] == "sdk"
    assert servidor["name"] == "rag"


def test_rag_tools_server_e_novo_por_cliente():
    # criar_rag_tools_server é uma factory, não um singleton de módulo (ao
    # contrário de salesforce_tools_server) — cada sessão do orchestrator
    # chama de novo, fechada sobre o cliente daquela sessão. Duas chamadas
    # não podem devolver o mesmo objeto, senão o fechamento sobre `client`
    # não estaria valendo nada.
    a = criar_rag_tools_server("acxya")
    b = criar_rag_tools_server("eplast")
    assert a is not b
