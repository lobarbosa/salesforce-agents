"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";

interface Recomendacao {
  titulo: string;
  severidade: string;
  area: string;
}

// A saúde é verde/amarelo/vermelho, ou seja, informação que nasce como cor. Cor
// sozinha não comunica — daí cada estado carregar também uma palavra e um
// símbolo. Quem não distingue as cores lê "Atenção"; quem lê rápido vê o tom.
const SAUDE: Record<string, { rotulo: string; simbolo: string; classe: string }> = {
  verde: { rotulo: "Saudável", simbolo: "●", classe: "ok" },
  amarelo: { rotulo: "Atenção", simbolo: "▲", classe: "alerta" },
  vermelho: { rotulo: "Crítica", simbolo: "■", classe: "critico" },
};

const SEVERIDADE_ORDEM: Record<string, number> = { alta: 0, media: 1, baixa: 2 };
const SEVERIDADE_ROTULO: Record<string, string> = {
  alta: "alta",
  media: "média",
  baixa: "baixa",
};

function asRecomendacoes(valor: unknown): Recomendacao[] {
  if (!Array.isArray(valor)) return [];
  return (valor as Recomendacao[])
    .filter((r) => r && typeof r.titulo === "string" && r.titulo.trim())
    .sort(
      (a, b) =>
        (SEVERIDADE_ORDEM[a.severidade] ?? 9) - (SEVERIDADE_ORDEM[b.severidade] ?? 9)
    );
}

export function AssessmentCard({ client, canManage }: { client: Client; canManage: boolean }) {
  const router = useRouter();
  const [rodando, setRodando] = useState(false);
  const [erro, setErro] = useState("");
  const [pedido, setPedido] = useState(false);

  const recomendacoes = asRecomendacoes(client.assessmentRecomendacoes);
  const saude = SAUDE[client.assessmentSaude] ?? null;

  async function rodar() {
    setErro("");
    setRodando(true);
    const res = await fetch(`/api/clients/${client.id}/assessment`, { method: "POST" });
    setRodando(false);
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setErro(body.error || "não consegui disparar o assessment");
      return;
    }
    setPedido(true);
    router.refresh();
  }

  return (
    <section className="assessment" aria-labelledby="assessment-titulo">
      <div className="assessment-head">
        <h3 id="assessment-titulo">Saúde da org</h3>
        {saude ? (
          <span className={`saude ${saude.classe}`}>
            <span aria-hidden="true">{saude.simbolo}</span> {saude.rotulo}
          </span>
        ) : (
          <span className="saude pendente">ainda não avaliada</span>
        )}
      </div>

      {client.assessmentEm ? (
        <>
          <p className="assessment-resumo">{client.assessmentResumo}</p>
          {recomendacoes.length > 0 && (
            <ol className="assessment-recs">
              {recomendacoes.map((r, i) => (
                <li key={`${r.titulo}-${i}`}>
                  <span className={`sev sev-${r.severidade}`}>
                    {SEVERIDADE_ROTULO[r.severidade] ?? r.severidade}
                  </span>
                  <span className="rec-titulo">{r.titulo}</span>
                  {r.area && <span className="rec-area mono">{r.area}</span>}
                </li>
              ))}
            </ol>
          )}
          <p className="assessment-nota">
            Avaliado em {new Date(client.assessmentEm).toLocaleDateString("pt-BR")}. O relatório
            completo, com evidência de cada achado, está em{" "}
            <code className="mono">clients/{client.slug}/assessment.md</code>.
          </p>
        </>
      ) : (
        <p className="assessment-nota">
          O assessment roda sozinho quando a org de dev conecta pela primeira vez — é a
          primeira atividade de um cliente novo. Se a conexão já foi testada e nada apareceu
          aqui, dá pra rodar na mão.
        </p>
      )}

      {canManage && (
        <div>
          <button className="btn-secondary" type="button" onClick={rodar} disabled={rodando}>
            {rodando
              ? "Disparando..."
              : client.assessmentEm
                ? "Refazer assessment"
                : "Rodar assessment agora"}
          </button>
          {pedido && (
            <p className="assessment-nota" role="status">
              Disparado. Leva alguns minutos — o resultado aparece aqui quando o agente termina.
            </p>
          )}
        </div>
      )}

      {erro && (
        <div className="auth-note error" role="alert">
          {erro}
        </div>
      )}
    </section>
  );
}
