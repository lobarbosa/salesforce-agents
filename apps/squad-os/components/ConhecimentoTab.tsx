"use client";

import type { Client } from "@/lib/generated/prisma/client";
import { SaveField } from "@/components/SaveField";
import { AssessmentCard } from "@/components/AssessmentCard";

// Segmento e Contatos saíram daqui: em uso real, nenhum dos 5 clientes jamais
// preencheu nenhum dos dois, e não há como o assessment inferir nenhum a
// partir da org. Ambiente Salesforce e Integrações vêm primeiro de propósito
// — são os dois campos que o assessment pré-preenche sozinho (ver
// /api/sync/assessment), então chegam aqui com conteúdo com mais frequência
// que um campo 100% manual. Regras fica: tem conteúdo real de cliente (ex.:
// convenção de nomenclatura que sobrepõe o padrão), só não tem como vir do
// assessment.
const BRIEF_FIELDS = [
  { key: "ambienteSalesforce", label: "Ambiente Salesforce (clouds, orgs, convenções)", multiline: true, full: true },
  { key: "integracoes", label: "Integrações existentes", multiline: true },
  { key: "regras", label: "Regras específicas desta conta", multiline: true, full: true },
] as const;

export function ConhecimentoTab({ client, canManage }: { client: Client; canManage: boolean }) {
  async function save(key: string, value: string) {
    const res = await fetch(`/api/clients/${client.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ [key]: value }),
    });
    return res.ok;
  }

  return (
    <>
      <AssessmentCard client={client} canManage={canManage} />
      <div className="brief-grid">
      {BRIEF_FIELDS.map((f) => (
        <SaveField
          key={f.key}
          label={f.label}
          value={String(client[f.key as keyof Client] ?? "")}
          multiline={f.multiline}
          full={"full" in f && f.full}
          onSave={(value) => save(f.key, value)}
          readOnly={!canManage}
        />
        ))}
      </div>
    </>
  );
}
