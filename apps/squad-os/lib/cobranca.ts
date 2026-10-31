import type { Parada } from "@/lib/esteira-parada";

// Cobrança diária (2026-10-31): quem precisa agir recebe um e-mail com o que
// espera por ele — sem tela nova. Achado que motivou: 16 estimativas
// esperando o cliente e gates do time parados há 10 dias, e a única forma de
// saber era abrir o portal (ou perguntar a um agente).
//
// Este módulo é puro (monta o texto); quem consulta o banco e envia é
// app/api/cron/cobranca/route.ts. O e-mail carrega só código, título e o que
// falta — o mesmo que o card já mostra a quem o recebe (guardrail #2).

export interface ParadaComCliente extends Parada {
  clientId: string;
}

export interface Email {
  para: string;
  assunto: string;
  texto: string;
}

const DIAS_PARA_COBRAR_TIME = 2;

function dias(n: number): string {
  const d = Math.floor(n);
  return d <= 0 ? "hoje" : d === 1 ? "há 1 dia" : `há ${d} dias`;
}

const FALA_DO_CLIENTE: Record<string, string> = {
  "aprovar horas": "aprovar a estimativa de horas",
  homologar: "conferir e aprovar a entrega",
};

/** E-mail do cliente: só o que é dele fazer, nas palavras dele. */
export function emailDoCliente(
  usuario: { email: string; nome: string },
  clienteNome: string,
  paradas: ParadaComCliente[],
  urlCliente: string
): Email | null {
  const itens = paradas.flatMap((p) =>
    p.acoes.filter((a) => a.quem === "cliente").map((a) => `- ${p.code} — ${p.titulo}: ${FALA_DO_CLIENTE[a.oque] ?? a.oque} (${dias(p.diasNaEtapa)})`)
  );
  if (itens.length === 0) return null;
  const ola = usuario.nome.trim() ? `Olá, ${usuario.nome.trim().split(" ")[0]}.` : "Olá.";
  return {
    para: usuario.email,
    assunto: itens.length === 1 ? `${clienteNome}: 1 demanda esperando você` : `${clienteNome}: ${itens.length} itens esperando você`,
    texto: [
      ola,
      "",
      "Estas demandas só seguem depois da sua decisão:",
      "",
      ...itens,
      "",
      `Para decidir: ${urlCliente} (aba Aprovações, ou o próprio card).`,
      "",
      "— Squad OS",
    ].join("\n"),
  };
}

/** E-mail do time: tudo que espera gente há mais de 2 dias, do mais antigo. */
export function emailDoTime(usuario: { email: string }, paradas: ParadaComCliente[], url: string): Email | null {
  const velhas = paradas.filter(
    (p) => p.diasNaEtapa >= DIAS_PARA_COBRAR_TIME && p.acoes.some((a) => a.quem === "time" || a.quem === "cliente")
  );
  if (velhas.length === 0) return null;
  const linha = (p: ParadaComCliente) =>
    `- ${p.cliente} · ${p.code} — ${p.titulo}: ${p.acoes.map((a) => `${a.quem} ${a.oque}`).join(", ")} (${dias(p.diasNaEtapa)})${
      p.qaReprovado ? " — QA reprovou" : ""
    }`;
  const doTime = velhas.filter((p) => p.acoes.some((a) => a.quem === "time"));
  const doCliente = velhas.filter((p) => !p.acoes.some((a) => a.quem === "time"));
  return {
    para: usuario.email,
    assunto: `Esteira: ${doTime.length} com o time, ${doCliente.length} com clientes há mais de ${DIAS_PARA_COBRAR_TIME} dias`,
    texto: [
      `Esperando o time (${doTime.length}):`,
      ...(doTime.length ? doTime.map(linha) : ["- nada"]),
      "",
      `Esperando o cliente (${doCliente.length}):`,
      ...(doCliente.length ? doCliente.map(linha) : ["- nada"]),
      "",
      url,
      "",
      "— Squad OS",
    ].join("\n"),
  };
}
