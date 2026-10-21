"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { DemandaCompleta } from "@/lib/data";
import { DecisaoEstimativa } from "@/components/AprovacaoEstimativa";
import { Modal } from "@/components/Modal";
import { Artefato } from "@/components/Artefato";
import { DemandaPainel } from "@/components/DemandaPainel";
import {
  asPerguntas,
  asAprovacao,
  STAGE_LABEL,
  ESTADO_CLIENTE_LABEL,
  estadoDoCliente,
  podeAprovarGate,
  progressoDaDemanda,
  timeAgo,
  formatarMinutos,
  ESTAGIOS_PARAVEIS,
  gateLiberadoPor,
  estimativaAprovada,
} from "@/lib/demandas";

export function DemandModal({
  demanda,
  canManage,
  usuarioEmail,
  isAdmin,
  visaoCliente = false,
  onClose,
}: {
  demanda: DemandaCompleta;
  canManage: boolean;
  usuarioEmail: string;
  isAdmin: boolean;
  /** Sem jargão de esteira — ver ESTADOS_CLIENTE em lib/demandas.ts. */
  visaoCliente?: boolean;
  onClose: () => void;
}) {
  const router = useRouter();
  const perguntasIniciais = asPerguntas(demanda.perguntas);
  const aprovacao = asAprovacao(demanda.aprovacao);

  const [respostas, setRespostas] = useState(
    perguntasIniciais.map((p) => ({ ...p, resposta: p.resposta ?? "" }))
  );
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [aprovador, setAprovador] = useState("");
  const [observacao, setObservacao] = useState("");
  const [aprovando, setAprovando] = useState(false);
  const [aprovarMsg, setAprovarMsg] = useState("");
  const [aprovarErro, setAprovarErro] = useState("");
  const [materializando, setMaterializando] = useState(demanda.materializadoEm != null);
  const [materializeErro, setMaterializeErro] = useState("");
  const [confirmandoGate, setConfirmandoGate] = useState(false);
  const [aprovandoGate, setAprovandoGate] = useState(false);
  const [gateErro, setGateErro] = useState("");
  // Trava síncrona contra clique duplo: o `disabled` só vale depois do
  // próximo render, e dois cliques no mesmo tick disparavam dois POSTs (a
  // rota também recusa o segundo com 409, ver aprovar-gate/route.ts).
  const emVoo = useRef(false);

  const emGate = demanda.status.startsWith("aguardando_");
  // Mesma função que a API chama — ver podeAprovarGate em lib/demandas.ts.
  // Decide o botão de aprovar, o artefato que aparece e as perguntas que
  // podem ser respondidas: as três coisas são o mesmo gate.
  const podeAprovarEsteGate = podeAprovarGate(canManage, demanda.status);
  // Liberado = o clique já foi aceito e a próxima etapa está a caminho; o
  // status só muda quando a execução sincroniza. Sem isto, reabrir o card
  // nesse meio-tempo mostrava o botão de novo.
  const [liberadoAgora, setLiberadoAgora] = useState(false);
  const liberado = gateLiberadoPor(demanda) ?? (liberadoAgora ? { autor: "você", naFila: false } : null);

  const jaAprovada = !!aprovacao?.aprovado;
  const faltandoResposta = respostas.filter((p) => !p.resposta.trim()).length;
  // As perguntas saem do mesmo artefato do gate, então seguem a mesma regra:
  // pro cliente elas aparecem só no gate que é dele, junto do documento de
  // onde vieram. Antes ele via pergunta de gate interno sem o documento — e a
  // API deixava responder. Pra quem é do time, nada muda: continua podendo
  // responder mesmo fora de gate (adiantar resposta enquanto o agente roda).
  const mostrarPerguntas = respostas.length > 0 && (!visaoCliente || podeAprovarEsteGate);

  const [confirmarMaterializar, setConfirmarMaterializar] = useState(false);

  async function salvarResposta(id: string, valor: string) {
    const atualizadas = respostas.map((p) => (p.id === id ? { ...p, resposta: valor } : p));
    setRespostas(atualizadas);
    const res = await fetch(`/api/demandas/${demanda.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ perguntas: atualizadas }),
    }).catch(() => null);
    // Falha precisa aparecer: antes virava "" e a pessoa achava que a resposta ficou salva.
    setNotes((n) => ({ ...n, [id]: res?.ok ? "salvo" : "erro ao salvar — tente de novo" }));
    if (res?.ok) {
      setTimeout(() => setNotes((n) => ({ ...n, [id]: "" })), 1400);
      router.refresh();
    }
  }

  async function aprovarEAvancar() {
    if (faltandoResposta > 0) {
      setAprovarMsg(`Responda tudo antes (${faltandoResposta} falta${faltandoResposta > 1 ? "m" : ""})`);
      setTimeout(() => setAprovarMsg(""), 2000);
      return;
    }
    if (emVoo.current) return;
    if (!aprovador.trim()) {
      setAprovarErro("Informe seu nome para registrar a aprovação.");
      return;
    }
    emVoo.current = true;
    setAprovarErro("");
    setAprovando(true);
    const res = await fetch(`/api/demandas/${demanda.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        perguntas: respostas,
        aprovacao: {
          aprovado: true,
          por: aprovador.trim(),
          em: new Date().toISOString(),
          observacao: observacao.trim() || "",
        },
      }),
    }).catch(() => null);
    setAprovando(false);
    emVoo.current = false;
    if (res?.ok) {
      router.refresh();
      onClose();
    } else {
      setAprovarErro("Não consegui registrar a aprovação — tente de novo.");
    }
  }

  async function aprovarGate() {
    if (emVoo.current) return;
    emVoo.current = true;
    setGateErro("");
    setAprovandoGate(true);
    const res = await fetch(`/api/demandas/${demanda.id}/aprovar-gate`, { method: "POST" }).catch(() => null);
    if (!res || !res.ok) {
      const body = res ? await res.json().catch(() => ({})) : {};
      setGateErro(body.error || "não consegui liberar o gate");
      setAprovandoGate(false);
      emVoo.current = false;
      if (res?.status === 409) router.refresh();
      return;
    }
    // Sucesso: trava de vez — o card mostra "liberado" até a esteira devolver.
    setLiberadoAgora(true);
    setConfirmandoGate(false);
    router.refresh();
    onClose();
  }

  async function materializar() {
    if (emVoo.current) return;
    emVoo.current = true;
    setMaterializeErro("");
    setMaterializando(true);
    const res = await fetch(`/api/demandas/${demanda.id}/materialize`, { method: "POST" }).catch(() => null);
    if (!res || !res.ok) {
      const body = res ? await res.json().catch(() => ({})) : {};
      setMaterializeErro(body.error || "falha ao materializar");
      setMaterializando(false);
      emVoo.current = false;
      return;
    }
    router.refresh();
  }

  return (
    <Modal title={`${demanda.code} · ${demanda.titulo}`} onClose={onClose} wide>
      <div className="meta">
        <span className={`badge ${demanda.tipo === "projeto" ? "projeto" : "sustentacao"}`}>
          {demanda.tipo === "projeto" ? "projeto" : "sustentação"}
        </span>
        <span>{demanda.autor}</span>
        <span>{timeAgo(demanda.criadoEm)}</span>
      </div>

      <div className="demanda-texto">{demanda.texto || "(sem descrição)"}</div>

      {demanda.status === "standby" && (
        <div className="approval-banner pendente" role="status">
          <strong>Congelada</strong>
          {demanda.congeladaDe && !visaoCliente && <> — estava em {demanda.congeladaDe}</>}
          {demanda.motivoParada && <div>Motivo: {demanda.motivoParada}</div>}
        </div>
      )}
      {demanda.status === "cancelada" && (
        <div className="approval-banner" role="status">
          <strong>Cancelada</strong>
          {demanda.motivoParada && <div>Motivo: {demanda.motivoParada}</div>}
        </div>
      )}

      {canManage && demanda.status === "backlog" && (
        <div className="approval-banner pendente">
          {materializeErro && <div role="alert" style={{ marginBottom: "0.4rem" }}>{materializeErro}</div>}
          {demanda.materializadoEm
            ? "Na esteira. Os agentes estão fazendo a análise; o card avança sozinho até o primeiro gate."
            : "Pronta para a esteira? Os agentes começam pela análise e param no primeiro gate para você revisar."}
          {!demanda.materializadoEm && (
            <div style={{ marginTop: "0.5rem" }}>
              {/* Commita no repositório e dispara o CI: dois passos, como a aprovação do gate. */}
              {confirmarMaterializar ? (
                <span className="confirmar-inline" role="group" aria-label="Confirmar materialização">
                  <button type="button" className="btn-ghost" autoFocus onClick={() => setConfirmarMaterializar(false)} disabled={materializando}>
                    Ainda não
                  </button>
                  <button className="btn-secondary" type="button" onClick={materializar} disabled={materializando}>
                    {materializando ? "Enviando..." : "Confirmar envio"}
                  </button>
                </span>
              ) : (
                <button className="btn-secondary" type="button" onClick={() => setConfirmarMaterializar(true)}>
                  Enviar para a esteira
                </button>
              )}
            </div>
          )}
        </div>
      )}


      {!visaoCliente && <EstimativaDemanda demanda={demanda} isAdmin={isAdmin} />}
      <DecisaoEstimativa demanda={demanda} podeDecidir={visaoCliente || isAdmin} />

      {visaoCliente && demanda.estimativaCalibrada && (
        <div className="estimativa-demanda" aria-label="Estimativa de horas">
          <strong>
            Estimativa de horas: {faixaH(demanda.estimativaCalibrada.min, demanda.estimativaCalibrada.max)} h
          </strong>
          <span className="estimativa-nota">Feita após a análise, antes da construção; pode ser refinada no desenho da solução.</span>
        </div>
      )}

      {visaoCliente && !emGate && (
        <div className="estado-cliente">
          <span className={`badge ${estadoDoCliente(demanda.status) === "entregue" ? "aprovado" : "stage"}`}>
            {ESTADO_CLIENTE_LABEL[estadoDoCliente(demanda.status)]}
          </span>
          {progressoDaDemanda(demanda.status) && (
            <span className="gate-texto">{progressoDaDemanda(demanda.status)!.rotulo}</span>
          )}
        </div>
      )}

      {emGate && (
        <div className="gate-box">
          <div className="gate-titulo">
            {visaoCliente ? (
              <span className="badge gate">
                {ESTADO_CLIENTE_LABEL[estadoDoCliente(demanda.status)]}
              </span>
            ) : (
              <>
                <span className="badge gate">gate humano</span>
                {STAGE_LABEL[demanda.status] ?? demanda.status}
              </>
            )}
          </div>
          {podeAprovarEsteGate ? (
            <>
              <p className="gate-texto">
                {visaoCliente
                  ? "Revise o que foi entregue e aprove quando estiver de acordo. Seu nome e a data ficam registrados, junto com a versão exata do que você aprovou."
                  : "A esteira parou aqui esperando aprovação. Ao liberar, a próxima etapa dispara sozinha na sandbox correspondente — e o seu nome fica registrado como quem aprovou."}
              </p>
              {liberado ? (
                <p className="gate-liberado" role="status">
                  Liberado por {liberado.autor}.{" "}
                  {liberado.naFila && demanda.status === "aguardando_gate_design" && !estimativaAprovada(demanda)
                    ? "O build sai assim que o cliente aprovar a estimativa de horas."
                    : liberado.naFila
                    ? "Na fila da esteira: este cliente já tem uma execução rodando, e esta sai assim que ela terminar."
                    : "A próxima etapa está rodando — o card avança sozinho quando terminar."}
                </p>
              ) : !confirmandoGate ? (
                <button
                  className="btn-primary"
                  type="button"
                  onClick={() => setConfirmandoGate(true)}
                  disabled={!demanda.materializadoEm}
                >
                  {visaoCliente ? "Aprovar a entrega" : "Aprovar e liberar a próxima etapa"}
                </button>
              ) : (
                // Dois passos de propósito: isto aciona agente contra a org do
                // cliente e não tem desfazer. Um clique só num botão que fica
                // ao lado de "Fechar" é acidente esperando acontecer.
                <div className="gate-confirma" role="group" aria-label="Confirmar aprovação do gate">
                  <span>
                    {visaoCliente
                      ? "Confirma a aprovação? Não dá pra desfazer."
                      : "Confirma? Isso aciona os agentes agora."}
                  </span>
                  <button
                    className="btn-primary"
                    type="button"
                    onClick={aprovarGate}
                    disabled={aprovandoGate}
                  >
                    {aprovandoGate ? "Liberando..." : "Sim, liberar"}
                  </button>
                  <button
                    className="btn-ghost"
                    type="button"
                    onClick={() => setConfirmandoGate(false)}
                    disabled={aprovandoGate}
                  >
                    Cancelar
                  </button>
                </div>
              )}
              {!demanda.materializadoEm && (
                <p className="gate-texto">
                  Materialize a demanda primeiro — sem isso ela não existe no repositório pra
                  avançar.
                </p>
              )}
            </>
          ) : (
            <p className="gate-texto">
              Aguardando o time da Acxya liberar esta etapa.
            </p>
          )}
          {gateErro && (
            <div className="auth-note error" role="alert" style={{ marginTop: "0.5rem" }}>
              {gateErro}
            </div>
          )}
        </div>
      )}

      {/* O que está sendo julgado. Antes disto o gate chegava como um botão sem
          contexto: o artefato existia só no git, e aprovar sem ler era o
          caminho mais curto da tela.

          A condição é `podeAprovarEsteGate`, a mesma do botão, e não o papel:
          quem aprova vê o que aprova. Na prática isso dá ao cliente o
          `05-testes.md` no gate de homologação — que é a evidência da
          pergunta que ele responde ali ("aceito esta entrega?") — e mantém
          fechados os gates de análise, design e build, que são decisão
          interna de método e que ele não aprova de qualquer forma (a API
          restringe o papel `cliente` a `aguardando_homologacao`). O
          invariante que fica: não existe botão de aprovar sem a coisa
          aprovada do lado. */}
      {podeAprovarEsteGate && demanda.artefatoConteudo && (
        <details className="artefato" open>
          <summary>
            <span className="badge stage">{demanda.artefatoNome}</span>
            <span className="gate-texto">
              {visaoCliente ? "o que foi testado nesta entrega" : "o que este gate põe na mesa"}
            </span>
          </summary>
          {/* Renderizado, e ainda assim sem HTML: `lib/markdown.ts` devolve
              estrutura de dados e o Artefato monta elemento React, que escapa
              texto por construção. O que continua valendo é a restrição —
              conteúdo escrito por agente nunca passa por dangerouslySetInnerHTML
              nem por biblioteca que devolva string de HTML pra sanitizar. */}
          <div className="artefato-corpo">
            <Artefato texto={demanda.artefatoConteudo} />
          </div>
          {demanda.artefatoTruncado && (
            <p className="gate-texto">
              {visaoCliente ? (
                <>
                  Cortado por tamanho — peça o{" "}
                  <code className="mono">{demanda.artefatoNome}</code> completo ao time da Acxya.
                </>
              ) : (
                <>
                  Cortado por tamanho — o <code className="mono">{demanda.artefatoNome}</code>{" "}
                  completo está no PR desta demanda.
                </>
              )}
            </p>
          )}
        </details>
      )}

      {jaAprovada ? (
        <div className="approval-banner aprovado">
          ✓ Aprovado por {aprovacao!.por} em {(aprovacao!.em || "").slice(0, 10)}
          {aprovacao!.observacao ? ` — ${aprovacao!.observacao}` : ""}
        </div>
      ) : (
        mostrarPerguntas && (
          <div className="approval-banner pendente">
            Responda as perguntas abaixo — cada resposta salva sozinha. Depois aprove pra liberar a
            próxima etapa, sem precisar acionar ninguém.
          </div>
        )
      )}

      {mostrarPerguntas && (
        <div className="pergunta-list">
          {respostas.map((p, i) => (
            <div className="pergunta-item" key={p.id}>
              <div className="texto" id={`pergunta-${p.id}`}>
                {i + 1}. {p.texto}
              </div>
              <textarea
                aria-labelledby={`pergunta-${p.id}`}
                defaultValue={p.resposta}
                placeholder="sua resposta... (salva sozinho ao sair do campo)"
                onBlur={(e) => salvarResposta(p.id, e.target.value)}
              />
              <span className="save-note" role="status">
                {notes[p.id] ?? ""}
              </span>
            </div>
          ))}
        </div>
      )}

      {mostrarPerguntas && !jaAprovada && (
        <>
          <div className="field">
            <label htmlFor="aprovacao-nome">Seu nome (para registrar a aprovação)</label>
            <input
              id="aprovacao-nome"
              type="text"
              placeholder="quem está aprovando"
              value={aprovador}
              onChange={(e) => setAprovador(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="aprovacao-observacao">Observação (opcional)</label>
            <textarea
              id="aprovacao-observacao"
              placeholder="alguma ressalva ou contexto..."
              value={observacao}
              onChange={(e) => setObservacao(e.target.value)}
            />
          </div>
        </>
      )}

      <DemandaPainel
        demandaId={demanda.id}
        usuarioEmail={usuarioEmail}
        isAdmin={isAdmin}
        visaoCliente={visaoCliente}
        dados={{
          comentarios: demanda.comentarios,
          subtarefas: demanda.subtarefas,
          checklist: demanda.checklist,
          tempos: demanda.tempos,
          anexos: demanda.anexos,
        }}
      />

      {aprovarErro && (
        <p className="auth-note error" role="alert">
          {aprovarErro}
        </p>
      )}
      {canManage && <CicloDemanda demanda={demanda} onClose={onClose} />}
      <div className="modal-actions">
        <button className="btn-ghost" type="button" onClick={onClose}>
          Fechar
        </button>
        {mostrarPerguntas && !jaAprovada && (
          <button className="btn-primary" type="button" onClick={aprovarEAvancar} disabled={aprovando}>
            {aprovarMsg || (aprovando ? "Aprovando..." : "Aprovar e avançar")}
          </button>
        )}
      </div>
    </Modal>
  );
}

// Total da demanda = horas de consultor (estimadas pelo agente na análise →
// design) + horas de agente (tempo de sessão já rodado + projeção do que
// falta, da telemetria). Custo de agente em USD: só admin — a página já zerou
// o campo pros outros papéis, então isto é a segunda camada, não a única.
function EstimativaDemanda({ demanda, isAdmin }: { demanda: DemandaCompleta; isAdmin: boolean }) {
  const lancadoMin = demanda.tempos.reduce((soma, t) => soma + (t.fimEm ? (t.minutos ?? 0) : 0), 0);
  const temConsultor = demanda.estimativaHorasMin !== null && demanda.estimativaHorasMax !== null;
  const temAgente = demanda.agenteHorasGasto !== null && demanda.agenteHorasRestante !== null;
  const temCusto = isAdmin && demanda.custoAgenteRestanteUsd !== null;
  // Em triagem (backlog) não há o que estimar ainda: o agente sugere na
  // análise. Mostrar o campo vazio ali só empurrava a ação principal do
  // card (enviar para a esteira) para baixo de um formulário sem contexto.
  const emTriagem = ["backlog", "planejada", "recorrente", "standby"].includes(demanda.status);
  if (
    emTriagem &&
    demanda.estimativaConsultorHoras == null &&
    demanda.sugestaoConsultorHoras == null &&
    demanda.tempos.length === 0
  ) {
    return null;
  }

  const fmtH = (h: number) => h.toLocaleString("pt-BR", { maximumFractionDigits: 1 });
  const faixa = faixaH;
  const fmtUsd = (v: number) =>
    v.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 2 });
  const fonte = demanda.estimativaHorasFonte.startsWith("03") ? "design" : "análise";
  const agenteTotal = temAgente ? demanda.agenteHorasGasto! + demanda.agenteHorasRestante! : 0;
  const cal = demanda.estimativaCalibrada ?? null;

  return (
    <div className="estimativa-demanda" aria-label="Estimativa da demanda">
      <EstimativaConsultor demanda={demanda} />
      <div className="estimativa-linhas">
      {temConsultor && (
        <span title={`Esforço humano estimado pelo agente na ${fonte} (${demanda.estimativaHorasFonte}).`}>
          Sugestão do agente: {faixa(demanda.estimativaHorasMin!, demanda.estimativaHorasMax!)} h ({fonte}) · lançado{" "}
          {formatarMinutos(lancadoMin)}
        </span>
      )}
      {temAgente && (
        <span title="Tempo de sessão dos agentes: já rodado + projeção das etapas que faltam (mediana da telemetria).">
          Agente: {fmtH(demanda.agenteHorasGasto!)} h feitas + ~{fmtH(demanda.agenteHorasRestante!)} h
        </span>
      )}
      {(temConsultor || temAgente || demanda.estimativaConsultorHoras != null) && (
        <strong>
          Total estimado:{" "}
          {demanda.estimativaConsultorHoras != null
            ? `${fmtH(demanda.estimativaConsultorHoras + agenteTotal)}`
            : temConsultor
            ? faixa(demanda.estimativaHorasMin! + agenteTotal, demanda.estimativaHorasMax! + agenteTotal)
            : `${fmtH(agenteTotal)} (só agente — falta a estimativa do consultor)`}{" "}
          h
        </strong>
      )}
      {cal && demanda.estimativaConsultorHoras == null && cal.calibracao.escopo !== "nenhum" && (
        <strong
          title={`Consultor × ${cal.calibracao.fator.toLocaleString("pt-BR", { maximumFractionDigits: 2 })}: mediana de lançado÷estimado em ${cal.calibracao.amostras} demandas entregues (${cal.calibracao.escopo === "cliente" ? "deste cliente" : "todos os clientes"}). É o número que o cliente vê.`}
        >
          Calibrado pelo timesheet: {faixa(cal.min, cal.max)} h
        </strong>
      )}
      {cal && demanda.estimativaConsultorHoras == null && demanda.estimativaHorasMin !== null && cal.calibracao.escopo === "nenhum" && (
        <span title="Menos de 3 demandas entregues com estimativa e horas lançadas — o cliente vê o total sem calibração.">
          Sem histórico de timesheet para calibrar ainda
        </span>
      )}
      {temCusto && (
        <span
          title={
            demanda.custoAgenteAmostras > 0
              ? `Projeção pela mediana de ${demanda.custoAgenteAmostras} sessões já registradas por etapa.`
              : "Sem histórico suficiente: projeção pelo valor de partida de cada etapa."
          }
        >
          Custo agente (admin): gasto {fmtUsd(demanda.custoAgenteGastoUsd ?? 0)} · falta ~
          {fmtUsd(demanda.custoAgenteRestanteUsd!)}
          {demanda.custoAgenteAmostras === 0 && " (estimativa inicial)"}
        </span>
      )}
      </div>
    </div>
  );
}

function faixaH(lo: number, hi: number): string {
  const f = (h: number) => h.toLocaleString("pt-BR", { maximumFractionDigits: 1 });
  return Math.abs(hi - lo) < 0.05 ? f(lo) : `${f(lo)}–${f(hi)}`;
}

// O consultor lança a estimativa oficial aqui, antes de apontar qualquer hora
// (a API recusa o apontamento sem ela). O campo vem pré-preenchido com a
// sugestão do agente já calibrada pelo timesheet — é ponto de partida, não
// resposta: quem vai fazer é quem assina o número.
function EstimativaConsultor({ demanda }: { demanda: DemandaCompleta }) {
  const router = useRouter();
  const atual = demanda.estimativaConsultorHoras;
  const [valor, setValor] = useState(String(atual ?? demanda.sugestaoConsultorHoras ?? ""));
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  async function salvar() {
    setSalvando(true);
    setErro(null);
    try {
      const res = await fetch(`/api/demandas/${demanda.id}/estimativa`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ horas: Number(valor.replace(",", ".")) }),
      });
      if (!res.ok) {
        const corpo = await res.json().catch(() => null);
        setErro(corpo?.error ?? `não consegui salvar (HTTP ${res.status})`);
        return;
      }
      router.refresh();
    } catch {
      setErro("sem conexão com o servidor — tente de novo");
    } finally {
      setSalvando(false);
    }
  }

  return (
    <div className="estimativa-campo">
      <label htmlFor={`estimativa-${demanda.id}`}>
        {atual == null ? "Estimativa de horas — obrigatória antes de apontar tempo" : "Estimativa de horas do consultor"}
      </label>
      <div className="estimativa-entrada">
        <input
          id={`estimativa-${demanda.id}`}
          inputMode="decimal"
          value={valor}
          onChange={(e) => setValor(e.target.value)}
          aria-describedby={`estimativa-ajuda-${demanda.id}`}
        />
        <span className="estimativa-unidade">h</span>
        <button type="button" className="btn-secondary" onClick={salvar} disabled={salvando || !valor.trim()}>
          {atual == null ? "Lançar estimativa" : "Atualizar"}
        </button>
      </div>
      <p id={`estimativa-ajuda-${demanda.id}`} className="estimativa-nota">
        {atual != null
          ? `Lançada por ${demanda.estimativaConsultorPor || "—"}${demanda.estimativaConsultorEm ? " " + timeAgo(demanda.estimativaConsultorEm) : ""}.`
          : demanda.sugestaoConsultorHoras != null
            ? `Pré-preenchida com a sugestão do agente (calibrada pelo timesheet). Ajuste se precisar.`
            : "O agente ainda não sugeriu — informe a sua estimativa."}
      </p>
      {erro && (
        <p className="auth-note error" role="alert">
          {erro}
        </p>
      )}
    </div>
  );
}

// Congelar / descongelar / cancelar / excluir (2026-10-21). Só delivery.
// Parar só vale fora de etapa rodando (triagem ou gate) — a API confere de
// novo; aqui é só pra não oferecer o botão que vai ser recusado.

function CicloDemanda({ demanda, onClose }: { demanda: DemandaCompleta; onClose: () => void }) {
  const router = useRouter();
  const [acao, setAcao] = useState<"" | "congelar" | "cancelar" | "excluir">("");
  const [motivo, setMotivo] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");

  const congelada = demanda.status === "standby";
  const podeParar = ESTAGIOS_PARAVEIS.includes(demanda.status);
  const podeExcluir = !demanda.materializadoEm;
  if (!podeParar && !congelada) return null;

  async function enviar(qual: "congelar" | "descongelar" | "cancelar" | "excluir") {
    setEnviando(true);
    setErro("");
    const res =
      qual === "excluir"
        ? await fetch(`/api/demandas/${demanda.id}`, { method: "DELETE" }).catch(() => null)
        : await fetch(`/api/demandas/${demanda.id}/ciclo`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ acao: qual, motivo }),
          }).catch(() => null);
    setEnviando(false);
    if (!res?.ok) {
      const body = await res?.json().catch(() => ({}));
      setErro(body?.error || "não deu certo — tente de novo");
      return;
    }
    router.refresh();
    onClose();
  }

  const exigeMotivo = acao === "congelar" || acao === "cancelar";
  return (
    <div className="ciclo-demanda">
      {!acao && (
        <div className="ciclo-botoes">
          {congelada ? (
            <button type="button" className="btn-secondary" onClick={() => enviar("descongelar")} disabled={enviando}>
              {enviando ? "Descongelando..." : "Descongelar"}
            </button>
          ) : (
            <button type="button" className="btn-ghost" onClick={() => setAcao("congelar")}>
              Congelar
            </button>
          )}
          <button type="button" className="btn-ghost" onClick={() => setAcao("cancelar")}>
            Cancelar demanda
          </button>
          {podeExcluir && (
            <button type="button" className="btn-ghost perigo" onClick={() => setAcao("excluir")}>
              Excluir
            </button>
          )}
        </div>
      )}
      {acao && (
        <div className="approval-banner pendente" role="group" aria-label="Confirmar">
          <div>
            {acao === "congelar" && "Congelar pausa a demanda onde está; descongelar volta para a mesma etapa."}
            {acao === "cancelar" && "Cancelar encerra a demanda sem entregar. Não tem volta pela tela."}
            {acao === "excluir" && "Excluir apaga a demanda, com subtarefas, comentários e horas. Não tem volta."}
          </div>
          {exigeMotivo && (
            <label className="field">
              Motivo
              <textarea value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={2} autoFocus />
            </label>
          )}
          {erro && <p className="auth-note error" role="alert">{erro}</p>}
          <span className="confirmar-inline">
            <button type="button" className="btn-ghost" onClick={() => { setAcao(""); setErro(""); }} disabled={enviando}>
              Voltar
            </button>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => enviar(acao)}
              disabled={enviando || (exigeMotivo && !motivo.trim())}
            >
              {enviando ? "Enviando..." : `Confirmar: ${acao === "cancelar" ? "cancelar demanda" : acao}`}
            </button>
          </span>
        </div>
      )}
      {!acao && erro && <p className="auth-note error" role="alert">{erro}</p>}
    </div>
  );
}
