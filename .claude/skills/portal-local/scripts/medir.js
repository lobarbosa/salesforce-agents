const { chromium } = require("playwright");
const sess = (email) => "base64-" + Buffer.from(JSON.stringify({ access_token: "fake." + email, refresh_token: "r", token_type: "bearer", expires_in: 3600, expires_at: Math.floor(Date.now() / 1000) + 3600, user: { id: "00000000-0000-0000-0000-000000000001", email } })).toString("base64url");
const telas = [["admin","/"],["admin","/clients/c1?tab=demandas"],["admin","/clients/c1?tab=demandas&demand=d6"],["admin","/clients/c1?tab=contrato"],["admin","/clients/c1?tab=conexao"],["admin","/clients/c1?tab=conhecimento"],["admin","/esteira"],["admin","/falhas"],["admin","/horas"],["admin","/financeiro"],["admin","/financeiro/contas"],["admin","/financeiro/aprovacoes"],["admin","/financeiro/horas"],["admin","/financeiro/saude"],["admin","/financeiro/recorrentes"],["admin","/financeiro/contabilidade"],["admin","/financeiro/divergencias"],["admin","/operacao/agentes"],["admin","/operacao/execucoes"],["admin","/admin/usuarios"],["cliente","/clients/c1?tab=demandas"],["cliente","/clients/c1?tab=aprovacoes"],["cliente","/clients/c1?tab=contrato"],["cliente","/clients/c1?demand=d1"]];
(async () => {
  const b = await chromium.launch();
  for (const mobile of [true, false]) for (const [quem, url] of telas) {
    const ctx = await b.newContext({ viewport: mobile ? { width: 390, height: 844 } : { width: 1440, height: 900 } });
    await ctx.addCookies([{ name: "sb-localhost-auth-token", value: sess(quem + "@teste.local"), domain: "localhost", path: "/" }]);
    const page = await ctx.newPage();
    await page.goto("http://localhost:3977" + url, { waitUntil: "networkidle" });
    const r = await page.evaluate((mobile) => {
      const vis = (e) => { const s = getComputedStyle(e), r = e.getBoundingClientRect(); return s.display !== "none" && s.visibility !== "hidden" && r.width > 0 && r.height > 0; };
      const nome = (e) => e.tagName.toLowerCase() + (e.className && typeof e.className === "string" ? "." + e.className.trim().split(/\s+/).slice(0, 2).join(".") : "");
      const rolagem = [...document.querySelectorAll("main *, .modal *")].filter((e) => vis(e) && e.scrollWidth > e.clientWidth + 4 && ["auto", "scroll"].includes(getComputedStyle(e).overflowX)).map((e) => nome(e) + " " + e.scrollWidth + ">" + e.clientWidth);
      const cortado = [...document.querySelectorAll("main *, .modal *")].filter((e) => vis(e) && e.children.length === 0 && e.scrollWidth > e.clientWidth + 2 && getComputedStyle(e).textOverflow === "ellipsis").map((e) => nome(e) + ' "' + e.textContent.trim().slice(0, 30) + '"');
      const pequenos = mobile ? [...document.querySelectorAll("button, a[href], select, input:not([type=hidden]), summary")].filter((e) => vis(e) && !e.closest(".sr-only")).filter((e) => { const r = e.getBoundingClientRect(); return r.height < 32 || r.width < 24; }).map((e) => nome(e) + " " + Math.round(e.getBoundingClientRect().width) + "x" + Math.round(e.getBoundingClientRect().height)) : [];
      const miudo = [...document.querySelectorAll("main *, .modal *")].filter((e) => vis(e) && e.children.length === 0 && e.textContent.trim() && parseFloat(getComputedStyle(e).fontSize) < 11).map((e) => nome(e) + " " + getComputedStyle(e).fontSize);
      const conta = (a) => Object.entries(a.reduce((m, x) => (m[x] = (m[x] || 0) + 1, m), {})).map(([k, v]) => (v > 1 ? v + "× " : "") + k).slice(0, 6);
      return { rolagem: conta(rolagem), cortado: conta(cortado), pequenos: conta(pequenos.map((p) => p.replace(/ \d+x/, " ?x"))), miudo: conta(miudo) };
    }, mobile);
    const linhas = Object.entries(r).filter(([, v]) => v.length).map(([k, v]) => "   " + k + ": " + v.join(" | "));
    if (linhas.length) console.log((mobile ? "[cel] " : "[desk] ") + quem + " " + url + "\n" + linhas.join("\n"));
    await ctx.close();
  }
  await b.close();
})();
