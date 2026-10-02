import type { Role, StatusConta } from "@/lib/generated/prisma/client";

// Regras puras de contas a pagar — testadas em scripts/testa-contas.ts.
//
// Controles que o conselho exigiu para tirar o financeiro do ClickUp:
// - segregação de funções: quem lança a conta não aprova a própria conta;
// - alçada: admin aprova qualquer valor; o papel financeiro aprova só até
//   ALCADA_FINANCEIRO_ATE (em reais; vazio ou 0 = só admin aprova);
// - trilha imutável: toda ação vira um EventoConta (o banco recusa editar).

export type Acao = "aprovar" | "recusar" | "pagar" | "cancelar";

export interface ContaParaRegra {
  status: StatusConta;
  valor: number;
  lancadoPorEmail: string;
}

export interface QuemAge {
  role: Role;
  email: string;
}

export function alcadaFinanceiro(): number {
  const v = Number(process.env.ALCADA_FINANCEIRO_ATE ?? "0");
  return Number.isFinite(v) && v > 0 ? v : 0;
}

/** Motivo pelo qual a ação NÃO pode ser feita, ou null se pode. Texto pronto para a tela. */
export function bloqueio(acao: Acao, conta: ContaParaRegra, quem: QuemAge, alcada = alcadaFinanceiro()): string | null {
  const financeiro = quem.role === "admin" || quem.role === "financeiro";
  if (!financeiro) return "só o time financeiro age sobre contas a pagar";

  if (acao === "aprovar" || acao === "recusar") {
    if (conta.status !== "aguardando_aprovacao") return "esta conta não está aguardando aprovação";
    if (quem.email.toLowerCase() === conta.lancadoPorEmail.toLowerCase()) {
      return "quem lançou a conta não pode decidir sobre ela — outra pessoa precisa aprovar";
    }
    if (quem.role === "financeiro" && conta.valor > alcada) {
      return alcada
        ? `acima da sua alçada (até ${formatarReais(alcada)}) — precisa de um admin`
        : "a aprovação é do admin (sem alçada configurada para o financeiro)";
    }
    return null;
  }
  if (acao === "pagar") {
    return conta.status === "aprovada" ? null : "só conta aprovada pode ser marcada como paga";
  }
  if (acao === "cancelar") {
    if (conta.status !== "aguardando_aprovacao" && conta.status !== "aprovada") {
      return "conta paga, recusada ou cancelada não pode ser cancelada";
    }
    return null;
  }
  return "ação desconhecida";
}

export const PROXIMO_STATUS: Record<Acao, StatusConta> = {
  aprovar: "aprovada",
  recusar: "recusada",
  pagar: "paga",
  cancelar: "cancelada",
};

export const ROTULO_STATUS: Record<StatusConta, string> = {
  aguardando_aprovacao: "aguardando aprovação",
  aprovada: "aprovada, a pagar",
  recusada: "recusada",
  paga: "paga",
  cancelada: "cancelada",
};

/** Lê valor digitado em reais: "1.234,56", "1234,56", "1234.56", "R$ 1.234". null se inválido. */
export function lerReais(entrada: string): number | null {
  let s = entrada.replace(/r\$\s*/i, "").replace(/\s+/g, "");
  if (!s) return null;
  if (s.includes(",")) s = s.replace(/\./g, "").replace(",", ".");
  else if (/^\d{1,3}(\.\d{3})+$/.test(s)) s = s.replace(/\./g, "");
  if (!/^\d+(\.\d{1,2})?$/.test(s)) return null;
  const v = Number(s);
  return v > 0 ? Math.round(v * 100) / 100 : null;
}

export function formatarReais(v: number): string {
  return v.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

/** "R$ 12,3 mil" em vez de "R$ 12.345,67" — rótulo de gráfico, não extrato. */
export function formatarReaisCompacto(v: number): string {
  const sinal = v < 0 ? "-" : "";
  const abs = Math.abs(v);
  if (abs >= 1000) return `${sinal}R$ ${(abs / 1000).toLocaleString("pt-BR", { maximumFractionDigits: 1 })} mil`;
  return `${sinal}R$ ${abs.toLocaleString("pt-BR", { maximumFractionDigits: 0 })}`;
}

/** "vence hoje", "vence em 3 dias", "vencida há 2 dias" — situação por texto, não só cor. */
export function prazo(vencimento: string, hoje: string): { texto: string; vencida: boolean; urgente: boolean } {
  const dias = Math.round((Date.parse(`${vencimento}T00:00:00Z`) - Date.parse(`${hoje}T00:00:00Z`)) / 86_400_000);
  if (dias < 0) return { texto: `vencida há ${-dias} dia${dias === -1 ? "" : "s"}`, vencida: true, urgente: true };
  if (dias === 0) return { texto: "vence hoje", vencida: false, urgente: true };
  return { texto: `vence em ${dias} dia${dias === 1 ? "" : "s"}`, vencida: false, urgente: dias <= 3 };
}
