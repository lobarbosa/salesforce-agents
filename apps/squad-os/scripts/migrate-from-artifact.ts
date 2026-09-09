/**
 * Migra os dados do Squad OS antigo (Artifact db) pro Postgres.
 *
 * Como gerar o export de entrada: no Claude Code, com o artifact publicado
 * aberto, rode a ação `read_db` (list) pras coleções `clients` e `demandas`
 * com `out_dir` apontando pra uma pasta local — isso salva um .json por
 * documento em `<out_dir>/clients/<id>.json` e `<out_dir>/demandas/<id>.json`.
 *
 * Uso:
 *   DATABASE_URL=... npx tsx scripts/migrate-from-artifact.ts <out_dir>
 *
 * Idempotente o suficiente pra reexecutar em cima de um export atualizado:
 * cliente existente é identificado pelo slug derivado do nome (não recria),
 * demanda existente é identificada por (clientId, code) — mas não faz merge
 * de edições feitas nos dois lados ao mesmo tempo; rode uma vez, valide, e
 * trate o Artifact como somente-leitura a partir daí.
 */
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { prisma } from "../lib/prisma";
import { generateUniqueSlug, generateDemandCode } from "../lib/slug";
import { Prisma, type TipoDemanda, type StatusDemanda } from "../lib/generated/prisma/client";

interface OldClient {
  id: string;
  nome: string;
  segmento?: string;
  criadoEm?: string;
  contatos?: string;
  ambienteSalesforce?: string;
  integracoes?: string;
  regras?: string;
  orgAlias?: string;
  loginUrl?: string;
  username?: string;
  consumerKey?: string;
  statusConexao?: string;
  testeSolicitadoPor?: string;
  testeSolicitadoEm?: string;
}

interface OldDemanda {
  id: string;
  clientId: string;
  titulo: string;
  tipo?: string;
  texto?: string;
  autor?: string;
  status?: string;
  criadoEm?: string;
  perguntas?: unknown;
  aprovacao?: unknown;
  historico?: unknown;
}

function loadCollection<T>(outDir: string, collection: string): T[] {
  const dir = join(outDir, collection);
  if (!existsSync(dir)) {
    console.warn(`(aviso) ${dir} não existe — pulando ${collection}`);
    return [];
  }
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => JSON.parse(readFileSync(join(dir, f), "utf-8")) as T);
}

async function main() {
  const outDir = process.argv[2];
  if (!outDir) {
    console.error("uso: npx tsx scripts/migrate-from-artifact.ts <out_dir>");
    process.exit(1);
  }

  const oldClients = loadCollection<OldClient>(outDir, "clients");
  const oldDemandas = loadCollection<OldDemanda>(outDir, "demandas");
  console.log(`${oldClients.length} clientes, ${oldDemandas.length} demandas no export.`);

  const clientIdMap = new Map<string, { id: string; slug: string }>();

  for (const oc of oldClients) {
    const slug = await generateUniqueSlug(oc.nome);
    const existing = await prisma.client.findUnique({ where: { slug } });
    const statusConexao = ["nao_configurado", "aguardando_teste", "conectado", "erro"].includes(
      oc.statusConexao ?? ""
    )
      ? (oc.statusConexao as "nao_configurado" | "aguardando_teste" | "conectado" | "erro")
      : "nao_configurado";

    const data = {
      nome: oc.nome,
      segmento: oc.segmento ?? "",
      contatos: oc.contatos ?? "",
      ambienteSalesforce: oc.ambienteSalesforce ?? "",
      integracoes: oc.integracoes ?? "",
      regras: oc.regras ?? "",
      orgAlias: oc.orgAlias || null,
      loginUrl: oc.loginUrl || null,
      username: oc.username || null,
      consumerKey: oc.consumerKey || null,
      statusConexao,
      testeSolicitadoPor: oc.testeSolicitadoPor || null,
      testeSolicitadoEm: oc.testeSolicitadoEm ? new Date(oc.testeSolicitadoEm) : null,
    };

    const client = existing
      ? await prisma.client.update({ where: { id: existing.id }, data })
      : await prisma.client.create({
          data: { ...data, slug, criadoEm: oc.criadoEm ? new Date(oc.criadoEm) : new Date() },
        });

    clientIdMap.set(oc.id, { id: client.id, slug: client.slug });
    console.log(`cliente: ${oc.nome} -> slug=${client.slug} id=${client.id}`);
  }

  for (const od of oldDemandas) {
    const mapped = clientIdMap.get(od.clientId);
    if (!mapped) {
      console.warn(`(aviso) demanda "${od.titulo}" referencia clientId ${od.clientId} não migrado — pulando`);
      continue;
    }

    const existing = await prisma.demanda.findMany({ where: { clientId: mapped.id } });
    // Reaproveita o code se já existe uma demanda migrada com o mesmo título +
    // criadoEm (heurística simples pra não duplicar em reexecução); senão gera novo.
    const dup = existing.find(
      (d) => d.titulo === od.titulo && d.criadoEm.toISOString() === new Date(od.criadoEm ?? 0).toISOString()
    );
    const code = dup ? dup.code : await generateDemandCode(mapped.id, mapped.slug);

    const tipo: TipoDemanda = od.tipo === "projeto" ? "projeto" : "sustentacao";
    const status = (od.status ?? "backlog") as StatusDemanda;

    const data = {
      clientId: mapped.id,
      code,
      titulo: od.titulo,
      tipo,
      texto: od.texto ?? "",
      autor: od.autor ?? "",
      status,
      perguntas: (od.perguntas ?? []) as Prisma.InputJsonValue,
      aprovacao: od.aprovacao ? (od.aprovacao as Prisma.InputJsonValue) : Prisma.JsonNull,
      historico: (od.historico ?? []) as Prisma.InputJsonValue,
    };

    if (dup) {
      await prisma.demanda.update({ where: { id: dup.id }, data });
    } else {
      await prisma.demanda.create({
        data: { ...data, criadoEm: od.criadoEm ? new Date(od.criadoEm) : new Date() },
      });
    }
    console.log(`demanda: ${od.titulo} -> code=${code} cliente=${mapped.slug}`);
  }

  console.log("Migração concluída.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
