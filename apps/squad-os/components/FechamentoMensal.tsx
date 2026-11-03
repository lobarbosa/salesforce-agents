"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

// Fechamento do mês (2026-11-03): no primeiro dia útil, quem fecha o mês
// confere o PDF de cada cliente (demandas concluídas, contrato e horas da
// equipe) e envia. Dois passos de propósito: o e-mail vai para o cliente e
// não tem desfazer.

export interface LinhaFechamento {
  clientId: string;
  clienteNome: string;
  destinatarios: number;
  enviado: { por: string; em: string; para: number } | null;
}

export function FechamentoMensal({ mes, rotuloMes, linhas, emailAtivo }: { mes: string; rotuloMes: string; linhas: LinhaFechamento[]; emailAtivo: boolean }) {
  const router = useRouter();
  const [confirmando, setConfirmando] = useState<string | null>(null);
  const [enviando, setEnviando] = useState<string | null>(null);
  const [aviso, setAviso] = useState<{ erro: boolean; texto: string } | null>(null);

  async function enviar(l: LinhaFechamento) {
    setEnviando(l.clientId);
    setAviso(null);
    const res = await fetch(`/api/relatorio-mensal/${l.clientId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mes, reenviar: !!l.enviado }),
    }).catch(() => null);
    const corpo = res ? await res.json().catch(() => ({})) : {};
    setEnviando(null);
    setConfirmando(null);
    if (!res?.ok) {
      setAviso({ erro: true, texto: `${l.clienteNome}: ${corpo.error ?? "não consegui enviar — verifique a conexão"}` });
      return;
    }
    setAviso({ erro: false, texto: `${l.clienteNome}: relatório de ${rotuloMes} enviado para ${corpo.enviados} ${corpo.enviados === 1 ? "pessoa" : "pessoas"}.` });
    router.refresh();
  }

  const pendentes = linhas.filter((l) => !l.enviado).length;

  return (
    <section className="overview-section fechamento" aria-labelledby="fechamento-titulo">
      <h2 id="fechamento-titulo">Fechamento de {rotuloMes} para os clientes</h2>
      <p className="save-note">
        Confira o PDF de cada cliente — demandas concluídas, contrato e as horas que cada consultor lançou no mês — e
        envie. O cliente recebe um e-mail com os principais números e o PDF anexo; você recebe uma cópia.
        {pendentes > 0 ? ` ${pendentes} ${pendentes === 1 ? "pendente" : "pendentes"}.` : " Todos enviados."}
      </p>
      {!emailAtivo && (
        <p className="auth-note error">
          O envio de e-mail ainda não está configurado (Microsoft 365 ou Resend). Dá para conferir os PDFs, mas não enviar.
        </p>
      )}
      {aviso && (
        <p className={`auth-note${aviso.erro ? " error" : ""}`} role={aviso.erro ? "alert" : "status"}>
          {aviso.texto}
        </p>
      )}
      <div className="tabela-wrap">
        <table className="tabela">
          <thead>
            <tr>
              <th scope="col">Cliente</th>
              <th scope="col">Situação</th>
              <th scope="col">Ações</th>
            </tr>
          </thead>
          <tbody>
            {linhas.map((l) => (
              <tr key={l.clientId}>
                <th scope="row">{l.clienteNome}</th>
                <td>
                  {l.enviado
                    ? `Enviado por ${l.enviado.por} em ${l.enviado.em} (${l.enviado.para} ${l.enviado.para === 1 ? "pessoa" : "pessoas"})`
                    : l.destinatarios
                      ? `Pendente · vai para ${l.destinatarios} ${l.destinatarios === 1 ? "pessoa" : "pessoas"}`
                      : "Sem usuário do cliente no portal para receber"}
                </td>
                <td className="fechamento-acoes">
                  <a className="btn-ghost" href={`/api/relatorio-mensal/${l.clientId}?mes=${mes}`} target="_blank" rel="noopener">
                    Ver PDF
                  </a>
                  {confirmando === l.clientId ? (
                    <>
                      <button className="btn-primary" type="button" onClick={() => void enviar(l)} disabled={enviando === l.clientId}>
                        {enviando === l.clientId ? "Enviando…" : "Confirmar envio"}
                      </button>
                      <button className="btn-ghost" type="button" onClick={() => setConfirmando(null)} disabled={enviando === l.clientId}>
                        Cancelar
                      </button>
                    </>
                  ) : (
                    <button
                      className={l.enviado ? "btn-secondary" : "btn-primary"}
                      type="button"
                      onClick={() => setConfirmando(l.clientId)}
                      disabled={!emailAtivo || !l.destinatarios || enviando !== null}
                    >
                      {l.enviado ? "Reenviar" : "Enviar ao cliente"}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
