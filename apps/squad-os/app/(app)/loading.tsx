// Mostrado na hora da navegação enquanto a página consulta o banco — as
// páginas de financeiro e operação levam alguns segundos e antes não davam
// sinal nenhum.
export default function Carregando() {
  return (
    <div className="empty-state" role="status" aria-live="polite">
      <p>Carregando…</p>
    </div>
  );
}
