import type { Metadata } from "next";
import { IBM_Plex_Mono, Poppins, PT_Sans } from "next/font/google";
import "./globals.css";

// Marca 2026 pede Futura Medium (display) + Trebuchet Regular (corpo).
// Nenhuma das duas é distribuível como webfont sem licença própria (Futura é
// comercial — Monotype/Bauer; Trebuchet MS é da Microsoft) — nenhuma licença
// foi confirmada nesta sessão. `--display`/`--sans` (em globals.css) citam o
// nome real primeiro (`futura`, `Trebuchet MS`), pra usar a fonte de verdade
// em qualquer máquina que já a tenha instalada/licenciada, com Poppins/PT
// Sans como aproximação visual carregada via Google Fonts pra todo o resto —
// documentado como aproximação, não como a fonte final. Trocar por
// self-hosted com licença real é troca só destes dois imports + do arquivo de
// fonte, nada mais no app depende disso.
const poppins = Poppins({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
});

const ptSans = PT_Sans({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "700"],
});

const plexMono = IBM_Plex_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["500", "600"],
});

export const metadata: Metadata = {
  title: "Squad OS",
  description:
    "Onde a demanda nasce e o briefing de cada cliente vive — o ponto de entrada do squad de agentes Salesforce.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="pt-BR"
      className={`${poppins.variable} ${ptSans.variable} ${plexMono.variable}`}
    >
      <body>{children}</body>
    </html>
  );
}
