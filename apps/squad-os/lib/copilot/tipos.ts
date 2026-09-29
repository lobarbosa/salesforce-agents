import type { UIMessage, InferUITools } from "ai";
import type { criarFerramentasCopiloto } from "@/lib/copilot/ferramentas";

// Import só de tipo — nunca puxa `ferramentas.ts` (que fala com o Postgres)
// pro bundle do client component. É o que dá tipagem de ponta a ponta pro
// useChat (ver componentes/Copiloto.tsx) sem duplicar o formato das
// ferramentas à mão.
type CopilotTools = ReturnType<typeof criarFerramentasCopiloto>;
export type CopilotUIMessage = UIMessage<unknown, never, InferUITools<CopilotTools>>;
