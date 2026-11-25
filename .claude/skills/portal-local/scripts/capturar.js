const { chromium } = require("playwright");
const out = process.argv[2];
const sess = (email) => "base64-" + Buffer.from(JSON.stringify({ access_token: "fake." + email, refresh_token: "r", token_type: "bearer", expires_in: 3600, expires_at: Math.floor(Date.now() / 1000) + 3600, user: { id: "00000000-0000-0000-0000-000000000001", email } })).toString("base64url");
const planos = JSON.parse(process.argv[3]);
(async () => {
  const b = await chromium.launch();
  for (const p of planos) {
    const ctx = await b.newContext({ viewport: p.mobile ? { width: 390, height: 844 } : { width: 1440, height: 900 }, deviceScaleFactor: 1 });
    await ctx.addCookies([{ name: "sb-localhost-auth-token", value: sess(p.email), domain: "localhost", path: "/" }]);
    const page = await ctx.newPage();
    const erros = [];
    page.on("console", (m) => m.type() === "error" && erros.push(m.text().slice(0, 200)));
    page.on("pageerror", (e) => erros.push("PAGEERROR " + e.message.slice(0, 200)));
    const r = await page.goto("http://localhost:3977" + p.url, { waitUntil: "networkidle", timeout: 30000 }).catch((e) => ({ status: () => "ERR " + e.message.slice(0, 80) }));
    if (p.click) for (const c of p.click) { await page.click(c, { timeout: 5000 }).catch((e) => erros.push("CLICK " + c + " " + e.message.slice(0, 80))); await page.waitForTimeout(600); }
    await page.screenshot({ path: `${out}/${p.nome}.png`, fullPage: !!p.full });
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    console.log(p.nome, r.status(), page.url().replace("http://localhost:3977", ""), "overflowX=" + overflow, erros.length ? JSON.stringify(erros.slice(0, 3)) : "");
    await ctx.close();
  }
  await b.close();
})();
