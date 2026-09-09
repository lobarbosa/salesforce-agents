"use client";

import { useState } from "react";
import type { Client } from "@/lib/generated/prisma/client";
import { SaveField } from "@/components/SaveField";

const CONEXAO_FIELDS = [
  { key: "orgAlias", label: "Alias do org (sandbox)", placeholder: "sbx-" },
  { key: "loginUrl", label: "Login URL", placeholder: "https://test.salesforce.com" },
  { key: "username", label: "Username do usuário de integração", placeholder: "integracao@cliente.com.sandbox" },
  { key: "consumerKey", label: "Consumer Key (Client ID)", placeholder: "3MVG9..." },
] as const;

const CONN_STATUS_LABEL: Record<string, string> = {
  nao_configurado: "Não configurado",
  aguardando_teste: "Teste de conexão solicitado",
  conectado: "Conectado",
  erro: "Erro na última tentativa",
};

export function ConexaoTab({ client }: { client: Client }) {
  const [status, setStatus] = useState(client.statusConexao);
  const [testeSolicitadoPor, setTesteSolicitadoPor] = useState(client.testeSolicitadoPor);
  const [testeSolicitadoEm, setTesteSolicitadoEm] = useState(client.testeSolicitadoEm);
  const [requesting, setRequesting] = useState(false);

  async function save(key: string, value: string) {
    const res = await fetch(`/api/clients/${client.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ [key]: value }),
    });
    return res.ok;
  }

  async function handleTestRequest() {
    setRequesting(true);
    const res = await fetch(`/api/clients/${client.id}/test-connection`, {
      method: "POST",
    });
    setRequesting(false);
    if (res.ok) {
      const updated = await res.json();
      setStatus(updated.statusConexao);
      setTesteSolicitadoPor(updated.testeSolicitadoPor);
      setTesteSolicitadoEm(updated.testeSolicitadoEm);
    }
  }

  return (
    <>
      <div className="conn-warning">
        <strong>Nunca cole aqui:</strong> chave privada (.key), Consumer Secret, senha ou qualquer
        token de acesso. Esses ficam só no GitHub Environment do cliente — ver{" "}
        <code className="mono">docs/conexoes-e-setup.md</code>. Este card guarda só o que
        identifica a conexão, não o que autentica sozinho.
      </div>

      <div className="conn-status">
        <span className={`dot2 ${status}`} />
        <div>
          <div className="label">{CONN_STATUS_LABEL[status] ?? status}</div>
          <div className="sub">
            {testeSolicitadoEm
              ? `solicitado por ${testeSolicitadoPor ?? "?"} em ${new Date(testeSolicitadoEm)
                  .toISOString()
                  .slice(0, 16)
                  .replace("T", " ")}`
              : "nenhum teste solicitado ainda"}
          </div>
        </div>
        <div style={{ marginLeft: "auto", display: "flex", gap: "0.4rem", alignItems: "center" }}>
          <button className="btn-secondary" type="button" onClick={handleTestRequest} disabled={requesting}>
            {requesting ? "Enviando..." : "Solicitar teste de conexão"}
          </button>
        </div>
      </div>

      <div className="brief-grid">
        {CONEXAO_FIELDS.map((f) => (
          <SaveField
            key={f.key}
            label={f.label}
            value={client[f.key as keyof Client] as string | null ?? ""}
            placeholder={f.placeholder}
            onSave={(value) => save(f.key, value)}
          />
        ))}
      </div>
    </>
  );
}
