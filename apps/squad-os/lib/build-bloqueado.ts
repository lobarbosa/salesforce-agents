// Build que não construiu nada não pode ser aprovado no gate de build
// (2026-11-12).
//
// Achado real (Somos Agility): cinco demandas chegaram à homologação sem nada
// construído. O agente declarou "BUILD BLOQUEADO" no 04-plano-build.md por
// falta de resposta do cliente, e o gate de build foi aprovado mesmo assim —
// o botão não distinguia PR para revisar de aviso de bloqueio.
//
// A esteira já devolve build bloqueado ao gate de design
// (src/salesforce_agents/bloqueio.py — mesma regra, mude as duas juntas). Esta
// é a segunda camada, para o card que já está no gate de build.

const EXPLICITO = /\*\*Resultado do build:\*\*\s*\**\s*(conclu[ií]do|bloqueado)/i;
const LEGADO =
  /build[^\n]{0,25}bloquead|bloquead[oa][^\n]{0,25}build|build n[ãa]o (foi )?executado|execu[çc][ãa]o bloqueada|nenhum (metadata|componente) foi (criado|escrito)/i;
const NEGADO = /n[ãa]o (est[áa] |foi |h[áa] )?bloque/i;

export function buildBloqueado(texto: string): boolean {
  const explicito = texto.match(EXPLICITO)?.[1]?.toLowerCase();
  if (explicito) return explicito === "bloqueado";
  // Só título, citação ou destaque no começo: "bloqueado" no meio de um
  // parágrafo de risco não é declaração de build bloqueado.
  return texto
    .split("\n")
    .slice(0, 40)
    .map((l) => l.trim())
    .some((l) => /^(#|\*\*|>)/.test(l) && LEGADO.test(l) && !NEGADO.test(l));
}

/** O card está no gate de build com um plano que só registra o bloqueio. */
export function gateDeBuildBloqueado(d: { status: string; artefatoNome: string; artefatoConteudo: string }): boolean {
  return (
    d.status === "aguardando_gate_build" &&
    d.artefatoNome === "04-plano-build.md" &&
    !!d.artefatoConteudo &&
    buildBloqueado(d.artefatoConteudo)
  );
}
