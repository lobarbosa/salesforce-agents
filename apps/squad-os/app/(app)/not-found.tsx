import Link from "next/link";

export default function NotFound() {
  return (
    <div className="empty-state">
      <h2>Cliente não encontrado</h2>
      <p>
        Pode ter sido removido, ou o link está errado.{" "}
        <Link href="/" style={{ color: "var(--accent)" }}>
          Voltar pra Visão Geral
        </Link>
        .
      </p>
    </div>
  );
}
