import { notFound } from "next/navigation";
import { getClientById, getDemandasByClient } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { ClientDetail } from "@/components/ClientDetail";

export default async function ClientPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string; demand?: string }>;
}) {
  const { id } = await params;
  const sp = await searchParams;
  const usuario = await getCurrentUsuario();
  // proxy.ts já bloqueia role=cliente fora do próprio cliente — checagem
  // redundante aqui é só defesa em profundidade, não o gate principal.
  if (!usuario || (usuario.role === "cliente" && usuario.clientId !== id)) notFound();

  const client = await getClientById(id);
  if (!client) notFound();

  const demandas = await getDemandasByClient(id);

  return (
    <ClientDetail
      client={client}
      demandas={demandas}
      usuario={usuario}
      initialTab={sp.tab as "conhecimento" | "conexao" | "demandas" | undefined}
      openDemandId={sp.demand}
    />
  );
}
