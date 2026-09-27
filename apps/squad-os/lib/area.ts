import { NextResponse } from "next/server";
import { notFound } from "next/navigation";
import { getCurrentUsuario, type CurrentUsuario } from "@/lib/current-user";
import { podeVer, type Area } from "@/lib/permissoes";

// Gate de verdade das telas e APIs por área (o proxy só cuida da navegação).

/** Para Server Components: quem não pode ver a área recebe 404, sem revelar que ela existe. */
export async function usuarioDaArea(area: Area): Promise<CurrentUsuario> {
  const usuario = await getCurrentUsuario();
  if (!usuario || !podeVer(usuario.role, area)) notFound();
  return usuario;
}

/** Para Route Handlers: 403 em JSON, que o cliente sabe ler. */
export async function acessoDaArea(
  area: Area
): Promise<{ usuario: CurrentUsuario; erro?: never } | { erro: NextResponse; usuario?: never }> {
  const usuario = await getCurrentUsuario();
  if (!usuario || !podeVer(usuario.role, area)) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }
  return { usuario };
}
