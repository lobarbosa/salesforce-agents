// `?next=` vem da URL — qualquer pessoa monta um link de login com o valor que
// quiser. Sem esta checagem, `next=javascript:...` virava XSS no
// `window.location.assign` da tela de login e `next=//outro.site` (ou
// `/\outro.site`, que o navegador normaliza pra `//`) virava open redirect
// depois do login, com a marca do Squad OS na frente. Só caminho interno
// absoluto passa: começa com uma barra, não com duas, e não tem barra
// invertida nem caractere de controle em lugar nenhum.
export function destinoSeguro(next: string | null | undefined): string {
  if (typeof next !== "string" || next.length === 0 || next.length > 2048) return "/";
  if (!/^\/(?!\/)/.test(next)) return "/";
  if (next.includes("\\")) return "/";
  if (/[\u0000-\u001f\u007f]/.test(next)) return "/";
  return next;
}
