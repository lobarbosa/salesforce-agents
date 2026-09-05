"""Sanity checks que não exigem chamadas de rede/API."""

from salesforce_agents.tools import salesforce_tools_server


def test_salesforce_tools_server_registered():
    assert salesforce_tools_server["type"] == "sdk"
    assert salesforce_tools_server["name"] == "salesforce-tools"
