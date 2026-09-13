"use client";

import { useState } from "react";
import type { AmbienteOrg, TipoAmbiente } from "@/lib/generated/prisma/client";
import { SaveField } from "@/components/SaveField";

const CONEXAO_FIELDS = [
  { key: "orgAlias", label: "Alias do org", placeholder: "sbx-" },
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

// A esteira vai de dev até o deploy na sandbox de QA e para ali — os dois
// ambientes abaixo são exatamente esse percurso. Produção não aparece de
// propósito: o agente não toca prod (guardrail #1), e a credencial dela vive
// só no GitHub Environment com required reviewer.
const AMBIENTES: { tipo: TipoAmbiente; titulo: string; descricao: string }[] = [
  { tipo: "dev", titulo: "Sandbox de desenvolvimento", descricao: "onde os agentes constroem" },
  { tipo: "qa", titulo: "Sandbox de QA", descricao: "onde o deploy é validado — última parada do agente" },
];

export function ConexaoTab({
  clientId,
  clientSlug,
  ambientes,
}: {
  clientId: string;
  clientSlug: string;
  ambientes: AmbienteOrg[];
}) {
  return (
    <>
      <div className="conn-warning">
        <strong>Nunca cole aqui:</strong> chave privada (.key), Consumer Secret, senha ou qualquer
        token de acesso. Esses ficam só no GitHub Environment do ambiente — ver{" "}
        <code className="mono">docs/conexoes-e-setup.md</code>. Este card guarda só o que
        identifica a conexão, não o que autentica sozinho.
      </div>

      {AMBIENTES.map((a) => (
        <AmbienteCard
          key={a.tipo}
          clientId={clientId}
          clientSlug={clientSlug}
          tipo={a.tipo}
          titulo={a.titulo}
          descricao={a.descricao}
          inicial={ambientes.find((x) => x.tipo === a.tipo) ?? null}
        />
      ))}
    </>
  );
}

function AmbienteCard({
  clientId,
  clientSlug,
  tipo,
  titulo,
  descricao,
  inicial,
}: {
  clientId: string;
  clientSlug: string;
  tipo: TipoAmbiente;
  titulo: string;
  descricao: string;
  inicial: AmbienteOrg | null;
}) {
  const [ambiente, setAmbiente] = useState<AmbienteOrg | null>(inicial);
  const [requesting, setRequesting] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  const status = ambiente?.statusConexao ?? "nao_configurado";
  const base = `/api/clients/${clientId}/ambientes/${tipo}`;

  async function save(key: string, value: string) {
    const res = await fetch(base, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ [key]: value }),
    });
    if (!res.ok) return false;
    setAmbiente(await res.json());
    return true;
  }

  async function handleTestRequest() {
    setRequesting(true);
    setErro(null);
    const res = await fetch(`${base}/test-connection`, { method: "POST" });
    setRequesting(false);
    if (res.ok) {
      setAmbiente(await res.json());
      return;
    }
    const body = await res.json().catch(() => null);
    setErro(body?.error ?? `não consegui solicitar o teste (HTTP ${res.status})`);
  }

  return (
    <section className="ambiente-card">
      <header className="ambiente-head">
        <div>
          <h3>{titulo}</h3>
          <span className="sub">{descricao}</span>
        </div>
        <code className="mono ambiente-env">
          {clientSlug}-{tipo}
        </code>
      </header>

      <div className="conn-status">
        <span className={`dot2 ${status}`} />
        <div>
          <div className="label">{CONN_STATUS_LABEL[status] ?? status}</div>
          <div className="sub">
            {ambiente?.testeSolicitadoEm
              ? `solicitado por ${ambiente.testeSolicitadoPor ?? "?"} em ${new Date(
                  ambiente.testeSolicitadoEm
                )
                  .toISOString()
                  .slice(0, 16)
                  .replace("T", " ")}`
              : "nenhum teste solicitado ainda"}
          </div>
        </div>
        <button
          className="btn-secondary"
          type="button"
          onClick={handleTestRequest}
          disabled={requesting}
          style={{ marginLeft: "auto" }}
        >
          {requesting ? "Enviando..." : "Solicitar teste de conexão"}
        </button>
      </div>

      {erro && (
        <div className="auth-note error" role="alert">
          {erro}
        </div>
      )}

      <div className="brief-grid">
        {CONEXAO_FIELDS.map((f) => (
          <SaveField
            key={f.key}
            label={f.label}
            value={(ambiente?.[f.key] as string | null) ?? ""}
            placeholder={f.key === "orgAlias" ? `sbx-${clientSlug}-${tipo}` : f.placeholder}
            onSave={(value) => save(f.key, value)}
          />
        ))}
      </div>
    </section>
  );
}
