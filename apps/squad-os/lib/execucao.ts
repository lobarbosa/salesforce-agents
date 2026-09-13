// Quando uma execução disparada pelo app deixou de ser "demorando" e passou a
// ser "morreu sem avisar".
//
// Mora num arquivo sem import nenhum de propósito: quem precisa disto são os
// componentes de tela (browser) e as rotas (servidor). Junto do `prisma`, como
// estava antes, o build arrastava o adapter do Postgres pro bundle do browser e
// quebrava — sem chegar a rodar.

// Um run que passa disto sem reportar não está lento, está morto: o job inteiro
// (instalar CLI, autenticar JWT, rodar o agente, commitar, abrir PR) leva
// minutos. O limite não mata nada — só troca o girar infinito por uma frase
// honesta, que é o que faz a pessoa ir olhar o log em vez de esperar.
export const LIMITE_DE_EXECUCAO_MIN = 20;

export function execucaoTravada(iniciadoEm: Date | string | null | undefined): boolean {
  if (!iniciadoEm) return false;
  const minutos = (Date.now() - new Date(iniciadoEm).getTime()) / 60_000;
  return minutos > LIMITE_DE_EXECUCAO_MIN;
}
