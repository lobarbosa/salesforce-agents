// Veredito do QA lido do 05-testes.md (2026-10-30).
//
// Achado real (SOMOSAGILITY-10): o QA na sandbox de QA reprovou por estouro de
// CPU, e a demanda chegou à homologação com cara de pronta — a falha só
// aparecia lendo o artefato inteiro. Isto extrai o que importa para o topo:
// passou ou não, as falhas pelo título, e em qual org o teste rodou.
//
// O agente qa escreve `**Veredito:** aprovado|reprovado` (ver
// .claude/agents/qa.md); para os artefatos anteriores a essa regra, cai na
// leitura dos títulos "### FALHA ...".

export type Veredito = "aprovado" | "reprovado" | "indefinido";

export interface VereditoQa {
  veredito: Veredito;
  falhas: { titulo: string; critica: boolean }[];
  org: string | null;
}

export function lerVereditoQa(texto: string): VereditoQa {
  const falhas = [...texto.matchAll(/^#{2,4}\s*(FALHA\b[^\n]*)$/gim)].map((m) => {
    const titulo = m[1].replace(/\*\*/g, "").trim();
    return { titulo, critica: /cr[ií]tic/i.test(titulo) };
  });
  const org = texto.match(/\*\*Org de teste:\*\*\s*`([^`]+)`/i)?.[1] ?? null;

  const explicito = texto.match(/\*\*Veredito:\*\*\s*\**\s*(aprovado|reprovado)/i)?.[1]?.toLowerCase();
  const veredito: Veredito =
    explicito === "aprovado" || explicito === "reprovado"
      ? explicito
      : falhas.length > 0
        ? "reprovado"
        : "indefinido";
  return { veredito, falhas, org };
}

/** Org de QA esperada pela convenção sbx-<cliente>-qa (guardrail #1). */
export function orgEhDeQa(org: string | null): boolean {
  return org != null && /^sbx-.+-qa$/.test(org);
}
