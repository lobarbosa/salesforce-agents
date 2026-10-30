import { existsSync } from "node:fs";
import { join } from "node:path";

// Onde o arquivo da marca deve ser colocado, em ordem de preferência. SVG
// primeiro: a sidebar renderiza a marca em ~140px de largura mas tela retina
// pede o dobro, e um SVG resolve isso sem gerar três PNGs.
const CANDIDATOS = ["marca.svg", "marca.png", "marca.webp"];

// Resolvido uma vez por processo, não a cada request: `public/` não muda em
// runtime na Vercel (o bundle é imutável), então checar de novo a cada
// navegação só gastaria syscall.
//
// Existe porque o arquivo da marca ainda não chegou ao repositório — imagem
// colada no chat não vira arquivo em disco. Enquanto não chegar, a interface
// mostra a marca escrita, que é um estado apresentável e não um buraco; no dia
// em que alguém colocar `public/marca.svg`, a troca acontece sozinha, sem
// tocar em componente nenhum.
let cache: string | null | undefined;

export function marcaUrl(): string | null {
  if (cache !== undefined) return cache;
  const dir = join(process.cwd(), "public");
  const achado = CANDIDATOS.find((nome) => existsSync(join(dir, nome)));
  cache = achado ? `/${achado}` : null;
  return cache;
}

// Versão para fundo escuro (2026-10-30): letras claras, servida pelo
// <picture> só quando o sistema está em tema escuro.
const CANDIDATOS_DARK = ["marca-dark.svg", "marca-dark.png", "marca-dark.webp"];
let cacheDark: string | null | undefined;

export function marcaDarkUrl(): string | null {
  if (cacheDark !== undefined) return cacheDark;
  const dir = join(process.cwd(), "public");
  const achado = CANDIDATOS_DARK.find((nome) => existsSync(join(dir, nome)));
  cacheDark = achado ? `/${achado}` : null;
  return cacheDark;
}
