import { createServiceClient } from "@/lib/supabase/storage";

/** Define a senha de um e-mail no Supabase Auth, direto — sem convite.
 *
 * Cria a conta se ela ainda não existe; se já existe (convite anterior,
 * outra vez que a senha foi definida assim), troca a senha em vez de falhar
 * com "already registered". Usado tanto ao conceder acesso quanto ao gerar
 * uma nova senha pra quem já tem conta — mesma operação nos dois casos, o
 * que muda é só de onde ela é chamada.
 */
export async function definirSenha(email: string, senha: string): Promise<string | null> {
  const admin = createServiceClient().auth.admin;
  const { error: criarErro } = await admin.createUser({ email, password: senha, email_confirm: true });
  if (!criarErro) return null;

  if (!/already/i.test(criarErro.message)) {
    return `a senha não foi definida: ${criarErro.message}`;
  }

  const { data: lista, error: listaErro } = await admin.listUsers({ perPage: 1000 });
  const existente = listaErro ? undefined : lista.users.find((u) => u.email?.toLowerCase() === email);
  if (!existente) {
    return "não encontrei a conta existente pra definir a senha.";
  }
  const { error: atualizarErro } = await admin.updateUserById(existente.id, { password: senha });
  return atualizarErro ? `a senha não foi definida: ${atualizarErro.message}` : null;
}
