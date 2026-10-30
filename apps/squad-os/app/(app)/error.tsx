"use client";

import { useEffect } from "react";

// Antes disto, uma falha de banco numa página virava a tela branca do Next.
// Aqui a moldura (sidebar) continua de pé e a pessoa tenta de novo.
export default function Erro({ error, retry }: { error: Error & { digest?: string }; retry: () => void }) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="empty-state" role="alert">
      <h2>Não consegui carregar esta página</h2>
      <p>Pode ter sido uma falha passageira na conexão com o banco. Tente de novo; se repetir, avise o time.</p>
      {error.digest && (
        <p className="gate-texto">
          Código para o suporte: <code className="mono">{error.digest}</code>
        </p>
      )}
      <button type="button" className="btn-primary" onClick={() => retry()}>
        Tentar de novo
      </button>
    </div>
  );
}
