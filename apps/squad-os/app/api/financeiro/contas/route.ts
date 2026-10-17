import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { lerReais } from "@/lib/contas";
import { lancarConta } from "@/lib/contas-data";
import { ehChaveDia } from "@/lib/horas";
import { removerArquivo, subirArquivo } from "@/lib/arquivo";
import { BUCKET_FINANCEIRO } from "@/lib/supabase/storage";
import { prisma } from "@/lib/prisma";
import { NATUREZAS, PERIODICIDADES } from "@/lib/recorrencias";
import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";

// Lançar conta a pagar (multipart: campos + documento fiscal opcional).
// Toda conta nasce "aguardando aprovação"; quem lança não aprova (lib/contas.ts).
// Campos de recorrência: natureza (direto|fixo), clientId (opcional) e
// repetir=<periodicidade> (cria o modelo recorrente a partir desta conta).
export async function POST(request: NextRequest) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;

  const form = await request.formData();
  const texto = (k: string, max = 200) => String(form.get(k) ?? "").trim().slice(0, max);
  const fornecedor = texto("fornecedor");
  const valor = lerReais(texto("valor", 30));
  const vencimento = texto("vencimento", 10);

  if (!fornecedor) return NextResponse.json({ error: "informe o fornecedor" }, { status: 400 });
  if (valor === null) return NextResponse.json({ error: "valor inválido — use 1.234,56" }, { status: 400 });
  if (!ehChaveDia(vencimento)) return NextResponse.json({ error: "informe o vencimento" }, { status: 400 });

  const naturezaTxt = texto("natureza", 10);
  if (naturezaTxt && !NATUREZAS.includes(naturezaTxt as NaturezaCusto)) {
    return NextResponse.json({ error: "natureza inválida" }, { status: 400 });
  }
  const natureza = (naturezaTxt || null) as NaturezaCusto | null;
  const clientId = texto("clientId", 60) || null;
  if (clientId && !(await prisma.client.findUnique({ where: { id: clientId }, select: { id: true } }))) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 400 });
  }
  const repetirTxt = texto("repetir", 12);
  if (repetirTxt && !PERIODICIDADES.includes(repetirTxt as Periodicidade)) {
    return NextResponse.json({ error: "periodicidade inválida" }, { status: 400 });
  }
  if (repetirTxt && !natureza) {
    return NextResponse.json({ error: "para repetir, escolha a natureza (custo direto ou despesa fixa)" }, { status: 400 });
  }
  const repetir = repetirTxt
    ? { periodicidade: repetirTxt as Periodicidade, valorVariavel: form.get("valorVariavel") === "on" }
    : null;

  const arquivo = form.get("documento");
  let documento: { caminho: string; nome: string } | null = null;
  if (arquivo instanceof File && arquivo.size > 0) {
    const r = await subirArquivo(BUCKET_FINANCEIRO, "contas", arquivo, "conta");
    if ("erro" in r) return r.erro;
    documento = r;
  }

  try {
    const conta = await lancarConta(
      { fornecedor, descricao: texto("descricao", 500), categoria: texto("categoria", 80), valor, vencimento, natureza, clientId },
      documento,
      acesso.usuario.email,
      repetir
    );
    return NextResponse.json(conta, { status: 201 });
  } catch (e) {
    // Sem a linha no banco o arquivo ficaria órfão no bucket.
    if (documento) await removerArquivo(BUCKET_FINANCEIRO, documento.caminho);
    throw e;
  }
}
