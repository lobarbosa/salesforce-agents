"""Sanity checks que não exigem chamadas de rede/API."""

from salesforce_agents.agents import SPECIALISTS
from salesforce_agents.tools import salesforce_tools_server


def test_specialists_defined():
    expected = {"solution-architect", "declarative-builder", "apex-developer", "lwc-developer"}
    assert expected == set(SPECIALISTS.keys())
    for agent in SPECIALISTS.values():
        assert agent.description
        assert agent.prompt


def test_salesforce_tools_server_registered():
    assert salesforce_tools_server["type"] == "sdk"
    assert salesforce_tools_server["name"] == "salesforce-tools"
