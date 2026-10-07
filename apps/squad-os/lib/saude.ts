// A saúde é verde/amarelo/vermelho, ou seja, informação que nasce como cor. Cor
// sozinha não comunica — daí cada estado carregar também uma palavra e um
// símbolo. Quem não distingue as cores lê "Atenção"; quem lê rápido vê o tom.
// Único lugar que define isto: AssessmentCard (badge) e Sidebar (dot da lista
// de clientes) leem daqui — duplicar o mapa é como um dos dois ficava
// desatualizado silenciosamente se o vocabulário mudasse.
export const SAUDE: Record<string, { rotulo: string; simbolo: string; classe: string }> = {
  verde: { rotulo: "Saudável", simbolo: "●", classe: "ok" },
  amarelo: { rotulo: "Atenção", simbolo: "▲", classe: "alerta" },
  vermelho: { rotulo: "Crítica", simbolo: "■", classe: "critico" },
};
