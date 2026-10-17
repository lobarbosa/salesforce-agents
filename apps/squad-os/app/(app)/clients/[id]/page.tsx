import { notFound } from "next/navigation";
import { getClientById, getDemandasByClient, demandasPorEntregavel, horasPorMes } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { ClientDetail } from "@/components/ClientDetail";
import { canAccessClient } from "@/lib/auth";
import { clienteParaCliente, demandaParaCliente, semCustoAgente } from "@/lib/visao-cliente";

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
  // proxy.ts já bloqueia role=cliente fora do próprio cliente e o financeiro
  // fora de clientes — a página confere de novo, pela mesma regra das APIs,
  // em vez de confiar só na navegação.
  if (!usuario || !canAccessClient(usuario.role, usuario.clientId, id)) notFound();

  const client = await getClientById(id);
  if (!client) notFound();

  const [demandas, horas, porEntregavel] = await Promise.all([
    getDemandasByClient(id),
    horasPorMes(id),
    demandasPorEntregavel(id),
  ]);

  // Tudo o que vai como prop pro ClientDetail (Client Component) chega ao
  // navegador. Pro cliente, o recorte é feito aqui — ver lib/visao-cliente.ts.
  const ehCliente = usuario.role === "cliente";

  return (
    <ClientDetail
      client={ehCliente ? clienteParaCliente(client) : client}
      demandas={
        ehCliente
          ? demandas.map(demandaParaCliente)
          : usuario.role === "admin"
            ? demandas
            : demandas.map(semCustoAgente)
      }
      usuario={usuario}
      horas={horas}
      demandasPorEntregavel={porEntregavel}
      initialTab={sp.tab as "conhecimento" | "contrato" | "conexao" | "demandas" | undefined}
      openDemandId={sp.demand}
    />
  );
}
