import type { QuemAge } from "@/lib/demandas";

// Tipos e texto do estado da esteira por cliente — sem Prisma, para a sidebar
// (Client Component) importar sem arrastar o banco para o navegador. A conta
// mora em lib/esteira-sidebar.ts (servidor).

export type EstadoEsteira = "agente" | "cliente" | "time" | "fila" | "parado";

export interface ResumoEsteira {
  estado: EstadoEsteira;
  contagem: Partial<Record<QuemAge, number>>;
}

export function descreverEsteira(r: ResumoEsteira | undefined, visaoCliente: boolean): string {
  if (!r) return "";
  const c = r.contagem;
  const partes = [
    c.agente && `${c.agente} rodando agora`,
    c.cliente && `${c.cliente} esperando ${visaoCliente ? "você" : "o cliente"}`,
    c.time && `${c.time} esperando ${visaoCliente ? "a equipe" : "o time"}`,
    c.fila && `${c.fila} na fila`,
  ].filter(Boolean);
  return partes.length ? partes.join(" · ") : "nada em andamento";
}
