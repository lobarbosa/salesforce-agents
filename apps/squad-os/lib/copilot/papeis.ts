// Quem recebe qual família de ferramenta do copiloto — puro, sem banco, para
// os testes de segurança poderem importar sem subir Prisma.

/** RAG interno (consultar_base_conhecimento): só o time. Cliente e financeiro, nunca. */
export function papelVeConhecimento(role: string): boolean {
  return role === "admin" || role === "consultor";
}
