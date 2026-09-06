import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getClients } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { UsuariosAdmin } from "@/components/UsuariosAdmin";

export default async function UsuariosPage() {
  const usuario = await getCurrentUsuario();
  // proxy.ts já bloqueia /admin pra quem não é admin — defesa em profundidade.
  if (!usuario || usuario.role !== "admin") notFound();

  const [usuarios, clients] = await Promise.all([
    prisma.usuario.findMany({ orderBy: { criadoEm: "asc" } }),
    getClients(),
  ]);

  return (
    <>
      <div className="overview-header">
        <h1>Administração — acessos</h1>
        <p>
          Quem entra no Squad OS e com que papel. Login continua sendo link mágico por e-mail —
          conceder acesso aqui não envia nada, a pessoa só entra normalmente em <code className="mono">/login</code>.
        </p>
      </div>
      <UsuariosAdmin usuarios={usuarios} clients={clients} currentUsuarioId={usuario.id} />
    </>
  );
}
