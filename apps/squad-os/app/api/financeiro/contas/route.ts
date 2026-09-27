import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { lerReais } from "@/lib/contas";
import { lancarConta } from "@/lib/contas-data";
import { ehChaveDia } from "@/lib/horas";
import { removerArquivo, subirArquivo } from "@/lib/arquivo";
import { BUCKET_FINANCEIRO } from "@/lib/supabase/storage";

// Lançar conta a pagar (multipart: campos + documento fiscal opcional).
// Toda conta nasce "aguardando aprovação"; quem lança não aprova (lib/contas.ts).
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

  const arquivo = form.get("documento");
  let documento: { caminho: string; nome: string } | null = null;
  if (arquivo instanceof File && arquivo.size > 0) {
    const r = await subirArquivo(BUCKET_FINANCEIRO, "contas", arquivo);
    if ("erro" in r) return r.erro;
    documento = r;
  }

  try {
    const conta = await lancarConta(
      { fornecedor, descricao: texto("descricao", 500), categoria: texto("categoria", 80), valor, vencimento },
      documento,
      acesso.usuario.email
    );
    return NextResponse.json(conta, { status: 201 });
  } catch (e) {
    // Sem a linha no banco o arquivo ficaria órfão no bucket.
    if (documento) await removerArquivo(BUCKET_FINANCEIRO, documento.caminho);
    throw e;
  }
}
