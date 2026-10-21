import { usuarioDaArea } from "@/lib/area";
import { listarEsteiraAoVivo } from "@/lib/esteira-ao-vivo";
import { EsteiraAoVivo } from "@/components/EsteiraAoVivo";

export default async function EsteiraPage() {
  const usuario = await usuarioDaArea("delivery");
  const runs = await listarEsteiraAoVivo({ comCusto: usuario.role === "admin" });
  return (
    <>
      <div className="overview-header">
        <h1>Esteira ao vivo</h1>
        <p>O que cada agente está fazendo agora, em cada demanda. Atualiza sozinho a cada poucos segundos.</p>
      </div>
      <EsteiraAoVivo inicial={runs} />
    </>
  );
}
