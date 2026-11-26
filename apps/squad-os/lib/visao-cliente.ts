import type { ResumoEsteira } from "@/lib/esteira-resumo";
import type { AmbienteOrg, Client, Contrato, Entregavel } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import { GATE_DO_CLIENTE } from "@/lib/demandas";
import { clienteVeEstimativa } from "@/lib/estimativa";

// O que desce pra um Client Component vai inteiro no payload RSC — esconder
// na tela não é esconder do navegador (basta abrir o DevTools). Para o papel
// `cliente` o recorte é feito aqui, no servidor, antes de virar prop. A forma
// do objeto não muda (os componentes continuam tipados igual); muda o
// conteúdo: o que é interno de delivery sai vazio.

type ClienteComRelacoes = Client & {
  ambientes: AmbienteOrg[];
  contrato: (Contrato & { entregaveis: Entregavel[] }) | null;
};

/** Cliente visto pelo próprio cliente: sem log/erro de job e sem identificador de credencial. */
export function clienteParaCliente<T extends ClienteComRelacoes>(client: T): T {
  return {
    ...client,
    assessmentErro: "",
    assessmentRunUrl: "",
    ambientes: client.ambientes.map((a) => ({
      ...a,
      // Consumer Key e usuário de integração identificam a credencial da
      // Connected App — são do time, não de quem acompanha o projeto.
      consumerKey: null,
      username: null,
      testeSolicitadoPor: null,
    })),
  };
}

/** Custo de agente é só pra admin (decisão de 2026-10-17): zera pros demais papéis. */
const SEM_CUSTO_AGENTE = {
  custoAgenteGastoUsd: null,
  custoAgenteRestanteUsd: null,
  custoAgenteAmostras: 0,
} as const;

export function semCustoAgente<T extends DemandaCompleta>(d: T): T {
  return { ...d, ...SEM_CUSTO_AGENTE };
}

/** Etapas em que o cliente vê o roteiro de teste: a homologação e o que vem depois dela. */
const CLIENTE_VE_ROTEIRO = new Set<string>([GATE_DO_CLIENTE, "release", "entregue"]);

export function clienteVeRoteiro(status: string): boolean {
  return CLIENTE_VE_ROTEIRO.has(status);
}

// O roteiro chega ao card como um anexo em PDF (lib/roteiro-anexo.ts), sempre
// neste caminho. Upload de gente nunca cai aqui: a chave dele leva um UUID.
export const caminhoDoRoteiro = (demandaId: string) => `${demandaId}/roteiro-de-teste.pdf`;

export function ehAnexoDoRoteiro(anexo: { caminho: string; demandaId: string }): boolean {
  return anexo.caminho === caminhoDoRoteiro(anexo.demandaId);
}

// Evidências de teste (lib/evidencias-anexo.ts, 2026-11-16): o roteiro que o QA
// executou e as capturas de tela, no mesmo desenho e com a mesma regra de
// quem vê — o time sempre, o cliente da homologação em diante.
export const caminhoDasEvidencias = (demandaId: string) => `${demandaId}/evidencias-de-teste.pdf`;

export function ehAnexoDasEvidencias(anexo: { caminho: string; demandaId: string }): boolean {
  return anexo.caminho === caminhoDasEvidencias(anexo.demandaId);
}

/** Anexo publicado pela esteira de QA (roteiro ou evidências), e não por gente. */
export function ehAnexoDoQa(anexo: { caminho: string; demandaId: string }): boolean {
  return ehAnexoDoRoteiro(anexo) || ehAnexoDasEvidencias(anexo);
}

/**
 * Demanda vista pelo cliente: artefato e perguntas só no gate que é dele
 * (a mesma regra de podeAprovarGate), sem histórico de esteira, sem link de
 * run, sem subtarefa/checklist (instrumento interno, ver demanda-access.ts) e
 * com as horas reduzidas ao total — que é o que a aba Tempo mostra pra ele.
 */
export function demandaParaCliente(d: DemandaCompleta): DemandaCompleta {
  const noGateDele = d.status === GATE_DO_CLIENTE;
  const minutos = d.tempos.reduce((soma, t) => soma + (t.fimEm ? (t.minutos ?? 0) : 0), 0);
  const primeiro = d.tempos[0];
  return {
    ...d,
    artefatoNome: noGateDele ? d.artefatoNome : "",
    artefatoConteudo: noGateDele ? d.artefatoConteudo : "",
    artefatoTruncado: noGateDele ? d.artefatoTruncado : false,
    perguntas: noGateDele ? d.perguntas : [],
    // O roteiro de teste foi escrito para ele, mas só faz sentido do gate dele
    // em diante: antes disso o anexo fica só com o time.
    // O texto do roteiro é insumo do PDF, não tela: o cliente recebe o anexo.
    roteiroCliente: "",
    // `?.`: nem toda consulta que passa por aqui carrega os anexos.
    anexos: clienteVeRoteiro(d.status) ? d.anexos : d.anexos?.filter((a) => !ehAnexoDoQa(a)),
    historico: [],
    // O cliente vê quem responde pela demanda, pelo nome; e-mail e quem
    // trocou ficam com o time.
    dono: d.dono ? { id: "", nome: d.dono.nome.trim() || "Time Acxya", email: "" } : null,
    donoId: null,
    donoDefinidoPor: "",
    ultimoRunUrl: "",
    ultimoResultado: "",
    // O cliente vê só a faixa total calibrada, e só depois da análise (é
    // quando ele decide se segue, antes da construção). Os insumos — faixa
    // crua do agente, horas de agente, custo — ficam em delivery.
    estimativaCalibrada:
      clienteVeEstimativa(d.status) && d.estimativaCalibrada
        ? { min: d.estimativaCalibrada.min, max: d.estimativaCalibrada.max, calibracao: { fator: 1, amostras: 0, escopo: "nenhum" } }
        : null,
    estimativaHorasMin: null,
    estimativaHorasMax: null,
    estimativaHorasFonte: "",
    // O número oficial é o que o cliente aprova (e o que debita do contrato
    // quando a construção começa) — ver components/AprovacaoEstimativa.tsx.
    estimativaConsultorHoras: clienteVeEstimativa(d.status) || d.status === "standby" ? d.estimativaConsultorHoras : null,
    estimativaConsultorPor: "",
    sugestaoConsultorHoras: null,
    agenteHorasGasto: null,
    agenteHorasRestante: null,
    ...SEM_CUSTO_AGENTE,
    subtarefas: [],
    checklist: [],
    tempos: primeiro
      ? [
          {
            ...primeiro,
            id: `total-${d.id}`,
            autor: "",
            autorEmail: "",
            descricao: "",
            origem: "",
            fimEm: primeiro.fimEm ?? primeiro.inicioEm,
            minutos,
          },
        ]
      : [],
  };
}

/** O que a sidebar precisa de cada cliente — nada além disto vai pro navegador. */
export function clienteDaSidebar(
  c: Pick<Client, "id" | "nome" | "assessmentSaude">,
  esteira?: ResumoEsteira
) {
  return {
    id: c.id,
    nome: c.nome,
    assessmentSaude: c.assessmentSaude,
    esteira: esteira ?? { estado: "parado" as const, contagem: {} },
  };
}
export type ClienteDaSidebar = ReturnType<typeof clienteDaSidebar>;
