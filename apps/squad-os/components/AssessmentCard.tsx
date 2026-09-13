"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import { execucaoTravada, LIMITE_DE_EXECUCAO_MIN } from "@/lib/execucao";
import { useAutoRefresh } from "@/lib/auto-refresh";

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

function horaCurta(valor: Date | string): string {
  return new Date(valor).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" });
}

export function AssessmentCard({ client, canManage }: { client: Client; canManage: boolean }) {
  const router = useRouter();
  const [rodando, setRodando] = useState(false);
  const [erro, setErro] = useState("");

  const recomendacoes = asRecomendacoes(client.assessmentRecomendacoes);
  const saude = SAUDE[client.assessmentSaude] ?? null;

  // O run em voo é outra pergunta que o resultado: dá pra ter assessment de
  // ontem (verde, com recomendações) e um run de agora que falhou. As duas
  // informações convivem no card em vez de uma apagar a outra.
  const travado = execucaoTravada(client.assessmentIniciadoEm);
  const emExecucao = client.assessmentStatus === "rodando" && !travado;

  // Enquanto há run vivo, a tela se atualiza sozinha. Travado não: se o job
  // morreu sem reportar, nada novo vai chegar e ficar batendo no banco só
  // gasta conexão.
  useAutoRefresh(emExecucao);

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

      {emExecucao && (
        <p className="assessment-execucao" role="status">
          <span className="pulso" aria-hidden="true" />
          Rodando desde {horaCurta(client.assessmentIniciadoEm!)} — o agente está auditando a
          org. Esta tela se atualiza sozinha quando terminar; pode fechar e voltar depois.
        </p>
      )}

      {client.assessmentStatus === "rodando" && travado && (
        <div className="auth-note error" role="alert">
          Começou às {horaCurta(client.assessmentIniciadoEm!)} e não reportou nada desde então
          (mais de {LIMITE_DE_EXECUCAO_MIN} min). O job leva minutos, não isso — o mais provável
          é que ele tenha morrido sem conseguir avisar. Rode de novo; se repetir, o log do run
          diz em que passo parou.
        </div>
      )}

      {client.assessmentStatus === "erro" && (
        <div className="auth-note error" role="alert">
          <strong>O último assessment falhou.</strong>{" "}
          {client.assessmentErro || "o job não disse o motivo."}{" "}
          {client.assessmentRunUrl && (
            <a href={client.assessmentRunUrl} target="_blank" rel="noopener noreferrer">
              Ver o log do run
            </a>
          )}
          {client.assessmentEm && (
            <>
              {" "}O resultado abaixo é o da rodada anterior, que deu certo — não o desta.
            </>
          )}
        </div>
      )}

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
        client.assessmentStatus === "nunca" && (
          <p className="assessment-nota">
            O assessment roda sozinho quando a org de dev conecta pela primeira vez — é a
            primeira atividade de um cliente novo. Se a conexão já foi testada e nada apareceu
            aqui, dá pra rodar na mão.
          </p>
        )
      )}

      {canManage && (
        <div>
          {/* Sem aviso próprio de "disparado": o refresh logo abaixo traz o
              estado real do servidor, e duas mensagens dizendo a mesma coisa
              (uma otimista, uma verdadeira) é como a tela começa a mentir. */}
          <button
            className="btn-secondary"
            type="button"
            onClick={rodar}
            disabled={rodando || emExecucao}
          >
            {rodando
              ? "Disparando..."
              : emExecucao
                ? "Rodando..."
                : client.assessmentEm
                  ? "Refazer assessment"
                  : "Rodar assessment agora"}
          </button>
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
