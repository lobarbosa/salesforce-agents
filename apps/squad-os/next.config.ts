import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // pdfkit lê as métricas das fontes padrão do disco em runtime
  // (lib/relatorio-pdf.ts): fica fora do bundle e vai como node_module.
  serverExternalPackages: ["pdfkit"],
  poweredByHeader: false,
  // Cabeçalhos de segurança em toda resposta (2026-11-24). O portal não é
  // embutido em nenhum outro site: negar frame fecha clickjacking nas telas
  // de aprovação de gate e de pagamento. Sem CSP de script por enquanto — o
  // Next injeta script inline e uma política errada tira o app do ar.
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Content-Security-Policy", value: "frame-ancestors 'none'" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
        ],
      },
    ];
  },
};

export default nextConfig;
