import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getClients, getClientesEncerrados } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { UsuariosAdmin } from "@/components/UsuariosAdmin";

export default async function UsuariosPage() {
  const usuario = await getCurrentUsuario();
  // proxy.ts já bloqueia /admin pra quem não é admin — defesa em profundidade.
  if (!usuario || usuario.role !== "admin") notFound();

  const [usuarios, clients, encerrados] = await Promise.all([
    prisma.usuario.findMany({ orderBy: { criadoEm: "asc" } }),
    getClients(),
    getClientesEncerrados(),
  ]);

  return (
    <>
      <div className="overview-header">
        <h1>Administração — acessos</h1>
        <p>
          Quem entra no Squad OS e com que papel. Com a senha em branco, a pessoa recebe um convite por e-mail;
          com senha definida, nada é enviado e você repassa a senha por fora. Ela entra em{" "}
          <code className="mono">/login</code>.
        </p>
      </div>
      <UsuariosAdmin usuarios={usuarios} clients={clients} encerrados={encerrados} currentUsuarioId={usuario.id} />
    </>
  );
}
