import type { UIMessage, InferUITools } from "ai";
import type { criarFerramentasCliente } from "@/lib/copilot/ferramentas";
import type { criarFerramentasFinanceiro } from "@/lib/copilot/ferramentas-financeiro";

// Import só de tipo — nunca puxa os módulos de ferramentas (que falam com o
// Postgres) pro bundle do client component. É o que dá tipagem de ponta a
// ponta pro useChat (ver componentes/Copiloto.tsx) sem duplicar o formato das
// ferramentas à mão.
//
// União das duas famílias de ferramenta: uma mesma conversa (mesmo
// componente, mesmo useChat) pode receber só as de cliente, só as
// financeiras, as duas juntas (admin numa página de cliente) ou nenhuma
// (consultor numa tela sem cliente aberto) — a rota decide por requisição
// (ver app/api/copilot/chat/route.ts); o tipo aqui só precisa cobrir todo
// resultado possível pra renderizar sem `any`.
type CopilotTools = ReturnType<typeof criarFerramentasCliente> & ReturnType<typeof criarFerramentasFinanceiro>;
export type CopilotUIMessage = UIMessage<unknown, never, InferUITools<CopilotTools>>;
