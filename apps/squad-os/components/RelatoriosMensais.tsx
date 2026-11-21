"use client";

import { useEffect, useState } from "react";
import { nomeDoMes } from "@/lib/relatorio-mensal";

// Relatórios mensais publicados (2026-11-21): o mesmo PDF de resumo do mês
// (demandas concluídas, contrato e horas) que foi enviado por e-mail ao
// cliente. Aparece na aba Contrato, para o cliente e para o time.

interface Envio {
  mes: string;
  enviadoEm: string;
}

export function RelatoriosMensais({ clientId }: { clientId: string }) {
  const [envios, setEnvios] = useState<Envio[] | null>(null);
  const [erro, setErro] = useState(false);

  useEffect(() => {
    let vivo = true;
    fetch(`/api/clients/${clientId}/relatorios`)
      .then((r) => (r.ok ? r.json() : Promise.reject()))
      .then((b: { relatorios: Envio[] }) => vivo && setEnvios(b.relatorios))
      .catch(() => vivo && setErro(true));
    return () => {
      vivo = false;
    };
  }, [clientId]);

  return (
    <section className="painel-bloco">
      <div className="bloco-head">
        <h3>Relatórios mensais</h3>
        <span className="save-note">o resumo de cada mês fechado, igual ao enviado por e-mail</span>
      </div>
      {erro ? (
        <p className="auth-note error" role="alert">
          Não consegui carregar os relatórios — recarregue a página.
        </p>
      ) : envios === null ? (
        <p className="save-note">Carregando...</p>
      ) : envios.length === 0 ? (
        <p className="save-note">Nenhum relatório enviado ainda. O primeiro chega no fechamento do mês.</p>
      ) : (
        <ul className="aprovacoes-lista">
          {envios.map((e) => (
            <li key={e.mes} className="aprovacoes-item">
              <a href={`/api/clients/${clientId}/relatorios/${e.mes}`} target="_blank" rel="noopener noreferrer">
                {nomeDoMes(e.mes)}
              </a>{" "}
              <span className="save-note">
                enviado em {new Date(e.enviadoEm).toLocaleDateString("pt-BR", { timeZone: "America/Sao_Paulo" })}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
