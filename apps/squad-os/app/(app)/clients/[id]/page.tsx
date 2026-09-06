import { notFound } from "next/navigation";
import { getClientById, getDemandasByClient } from "@/lib/data";
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
  const client = await getClientById(id);
  if (!client) notFound();

  const demandas = await getDemandasByClient(id);

  return (
    <ClientDetail
      client={client}
      demandas={demandas}
      initialTab={sp.tab as "conhecimento" | "conexao" | "demandas" | undefined}
      openDemandId={sp.demand}
    />
  );
}
