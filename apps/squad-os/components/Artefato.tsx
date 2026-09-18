"use client";

import { useMemo } from "react";
import { blocos, type Bloco, type Trecho } from "@/lib/markdown";

// O documento que o gate põe na mesa, legível.
//
// Antes isto era um <pre> com o markdown cru: tabela virava fileira de barras
// e hífens, `**` e crase apareciam em toda linha, e o 03-design.md de uma
// demanda real tem 109 linhas de tabela e 700 linhas no total. Ninguém lê isso
// antes de clicar em aprovar — e o gate existe justamente pra ser lido.
//
// **A restrição de segurança não mudou**: o conteúdo é escrito por agente e
// nunca vira HTML. `lib/markdown.ts` devolve estrutura de dados e aqui ela
// vira elemento React, que escapa texto por construção. Não existe
// dangerouslySetInnerHTML neste caminho, nem biblioteca de markdown que
// devolva string de HTML pra sanitizar depois.

function Trechos({ trechos }: { trechos: Trecho[] }) {
  return (
    <>
      {trechos.map((t, i) => {
        if (t.tipo === "codigo") return <code key={i} className="md-codigo">{t.texto}</code>;
        if (t.tipo === "forte") return <strong key={i}><Trechos trechos={t.filhos} /></strong>;
        if (t.tipo === "enfase") return <em key={i}><Trechos trechos={t.filhos} /></em>;
        return <span key={i}>{t.texto}</span>;
      })}
    </>
  );
}

function BlocoMd({ bloco }: { bloco: Bloco }) {
  switch (bloco.tipo) {
    case "titulo": {
      const H = `h${bloco.nivel + 2}` as "h3" | "h4" | "h5";
      // Desloca dois níveis: o h1 do documento não pode competir com o título
      // do modal, que é o h2 da página.
      return <H className={`md-titulo md-t${bloco.nivel}`}><Trechos trechos={bloco.trechos} /></H>;
    }
    case "paragrafo":
      return <p className="md-paragrafo"><Trechos trechos={bloco.trechos} /></p>;
    case "regra":
      return <hr className="md-regra" />;
    case "codigo":
      return (
        <div className="md-codigo-bloco">
          <pre>{bloco.texto}</pre>
        </div>
      );
    case "lista": {
      const L = bloco.ordenada ? "ol" : "ul";
      return (
        <L className={`md-lista${bloco.itens.some((i) => i.marcado !== null) ? " md-lista-check" : ""}`}>
          {bloco.itens.map((item, i) => (
            <li key={i} className={item.marcado === true ? "md-feito" : undefined}>
              {/* Glifo, não <input>: marcar aqui não salvaria em lugar nenhum.
                  Quem responde pendência é o bloco de perguntas do gate, que
                  persiste e trava a aprovação. Um checkbox clicável aqui
                  prometeria uma ação que não existe. */}
              {item.marcado !== null && (
                <span className="md-check" aria-hidden="true">{item.marcado ? "☑" : "☐"}</span>
              )}
              {item.marcado !== null && (
                <span className="sr-only">{item.marcado ? "resolvido: " : "em aberto: "}</span>
              )}
              <Trechos trechos={item.trechos} />
            </li>
          ))}
        </L>
      );
    }
    case "tabela":
      return (
        // Rolagem horizontal só na tabela, não no documento: é a única coisa
        // aqui que legitimamente passa da largura da coluna de leitura.
        <div className="md-tabela-wrap">
          <table className="md-tabela">
            <thead>
              <tr>
                {bloco.cabecalho.map((celula, i) => (
                  <th key={i}><Trechos trechos={celula} /></th>
                ))}
              </tr>
            </thead>
            <tbody>
              {bloco.linhas.map((linha, i) => (
                <tr key={i}>
                  {linha.map((celula, j) => (
                    <td key={j}><Trechos trechos={celula} /></td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      );
  }
}

export function Artefato({ texto }: { texto: string }) {
  const doc = useMemo(() => blocos(texto), [texto]);
  return (
    <div className="md">
      {doc.map((b, i) => (
        <BlocoMd key={i} bloco={b} />
      ))}
    </div>
  );
}
