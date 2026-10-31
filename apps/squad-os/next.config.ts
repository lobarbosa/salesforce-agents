import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // pdfkit lê as métricas das fontes padrão do disco em runtime
  // (lib/relatorio-pdf.ts): fica fora do bundle e vai como node_module.
  serverExternalPackages: ["pdfkit"],
};

export default nextConfig;
