// Autenticação de mentira para o portal local: aceita o token "fake.<email>" e devolve
// esse usuário. Só existe para ver telas com dados fictícios. Nunca aponte para o portal real.
const http = require("http");
http.createServer((req, res) => {
  const tok = (req.headers.authorization || "").replace("Bearer ", "");
  const email = tok.startsWith("fake.") ? tok.slice(5) : null;
  res.setHeader("content-type", "application/json");
  if (req.url.startsWith("/auth/v1/user") && email) {
    return res.end(JSON.stringify({ id: "00000000-0000-0000-0000-000000000001", aud: "authenticated", role: "authenticated", email, app_metadata: {}, user_metadata: {}, created_at: new Date().toISOString() }));
  }
  res.statusCode = 401; res.end(JSON.stringify({ message: "no" }));
}).listen(Number(process.argv[2] || 54399));
