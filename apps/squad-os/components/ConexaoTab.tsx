"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { AmbienteOrg, TipoAmbiente } from "@/lib/generated/prisma/client";
import { SaveField } from "@/components/SaveField";
import { execucaoTravada, LIMITE_DE_EXECUCAO_MIN } from "@/lib/execucao";
import { useAutoRefresh } from "@/lib/auto-refresh";

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
  const router = useRouter();
  const [requesting, setRequesting] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  // Sem espelho local do ambiente: o servidor é a fonte, e toda mutação daqui
  // termina em `router.refresh()`. Guardar uma cópia em `useState` parecia
  // inofensivo até existir auto-refresh — aí a cópia congelada do primeiro
  // render passa a esconder justamente o estado novo que se foi buscar.
  // `SaveField` já mantém o rascunho do que está sendo digitado, então nada se
  // perde no caminho.
  const ambiente = inicial;
  const status = ambiente?.statusConexao ?? "nao_configurado";
  const base = `/api/clients/${clientId}/ambientes/${tipo}`;

  // "Aguardando teste" é um estado que só sai daqui por fora: quem muda é o
  // workflow, reportando em /api/sync/conexao. Sem auto-refresh, a aba aberta
  // mostra "aguardando" para sempre mesmo depois de o banco já dizer
  // "conectado" — aconteceu na Konecta em 2026-09-13, e o susto foi achar que
  // a conexão tinha falhado quando ela tinha dado certo.
  const travado = execucaoTravada(ambiente?.testeSolicitadoEm);
  const esperandoResultado = status === "aguardando_teste" && !travado;
  useAutoRefresh(esperandoResultado);

  async function save(key: string, value: string) {
    const res = await fetch(base, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ [key]: value }),
    });
    if (!res.ok) return false;
    router.refresh();
    return true;
  }

  async function handleTestRequest() {
    setRequesting(true);
    setErro(null);
    const res = await fetch(`${base}/test-connection`, { method: "POST" });
    setRequesting(false);
    if (res.ok) {
      router.refresh();
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

      {esperandoResultado && (
        <p className="assessment-execucao" role="status">
          <span className="pulso" aria-hidden="true" />
          Teste em andamento — o workflow autentica na org e reporta de volta. Esta tela se
          atualiza sozinha; não precisa recarregar.
        </p>
      )}

      {status === "aguardando_teste" && travado && (
        <div className="auth-note error" role="alert">
          O teste foi solicitado há mais de {LIMITE_DE_EXECUCAO_MIN} minutos e não reportou
          resultado. Ele leva cerca de um minuto — o mais provável é que o job tenha falhado
          antes de conseguir responder (credencial faltando no GitHub Environment é a causa
          mais comum). Solicite de novo; se repetir, o log do run diz o passo exato.
        </div>
      )}

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
