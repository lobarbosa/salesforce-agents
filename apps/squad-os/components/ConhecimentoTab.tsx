"use client";

import type { Client } from "@/lib/generated/prisma/client";
import { SaveField } from "@/components/SaveField";
import { AssessmentCard } from "@/components/AssessmentCard";

const BRIEF_FIELDS = [
  { key: "segmento", label: "Segmento / indústria", multiline: false },
  { key: "contatos", label: "Contatos principais", multiline: true },
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
        />
        ))}
      </div>
    </>
  );
}
