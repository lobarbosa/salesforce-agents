# EPLAST-26 — Build não iniciado: bloqueios confirmados

**Sessão:** continuação do ciclo de delivery, acionada com `status: build` já definido em
`status.yaml` (gate de design aprovado por Carlos Sordi em 2026-11-11T21:58:43Z).
**Resultado desta sessão:** nenhum subagente de build (`builder-declarativo`/`dev-apex`) foi
acionado. Nenhuma branch, commit, metadata ou PR foi criado. `status.yaml` **não foi
alterado** — continua em `build`. O artefato `04-plano-build.md` foi escrito registrando o
mesmo bloqueio, para satisfazer o requisito de artefato do estágio sem inventar um plano de
construção que não existe.

## Por que parei antes de construir

O próprio `03-design.md` (aprovado no gate), seção 1 item 4 e seção "Bloqueios em aberto"
no fim do arquivo, diz explicitamente:

> O build não pode começar mesmo com este gate aprovado, enquanto três condições externas
> ao design estiverem abertas: Onda 3 não contratada (P12), alias dev/qa (P14) e aprovação
> da estimativa pelo cliente.

Reconferi as duas primeiras agora (2026-11-11), nesta sessão, contra a org e contra o
registro de contrato — nenhuma delas foi resolvida desde que o design foi escrito:

### P12 — Onda 3 (Comercial) ainda não contratada
- `demanda.md` desta própria demanda já afirma: *"Onda 3 · Comercial — ainda não contratada
  no projeto atual (Ondas 1–2)."*
- `clients/eplast/contrato.md` (materializado pelo Squad OS, fonte: Status Report semana 05,
  29/10/2026) confirma: *"Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e treinamento)
  ainda não contratadas."* Só as Ondas 1 e 2 (120h) estão no escopo contratado, e o projeto
  termina em 2026-11-30.
- EPLAST-26 ("Scoring de leads e oportunidades") é um entregável da Onda 3. Construir agora
  seria entregar trabalho fora do escopo pago — exatamente o que o design (R5, severidade
  Alta/comercial) registrou como "build bloqueado até contratação, independente deste gate".

### P14 — alias `sbx-eplast-dev` não distinto de qa
- Rodei `sf org list` nesta sessão. Resultado: **uma única org autenticada**, alias
  `sbx-eplast-dev` (sandbox, `IsSandbox` verdadeiro). O instance URL registrado tem sufixo
  `--qa` (mesmo padrão já flagueado no recon) e não existe nenhum alias `sbx-eplast-qa`
  autenticado neste runner. Não cito aqui o username da org nem o instance URL completo —
  são identificadores com formato de e-mail/host (guardrail #2); o alias já basta para
  rastrear a evidência em `02-recon.md`.
- Isso bate exatamente com o achado do recon (`02-recon.md`): *"Orgs autenticadas no runner:
  só uma... Não existe sbx-eplast-qa autenticada"* e *"o alias de dev continua apontando para
  uma sandbox com nome de qa... bloqueia o build (P14)."*
- Construir e já criar PR/deploy de validação apontando para esta sandbox, sem confirmar que
  QA roda em ambiente distinto, arrisca a demanda ser "homologada" no mesmo lugar onde foi
  construída — o que o design pede para confirmar antes do build, não depois.

### Terceiro bloqueio citado no design (aprovação de estimativa) — não se aplica
Pelo `CLAUDE.md` raiz (seção "Estimativa por demanda"), em contrato de **projeto** o gate de
design libera o build direto, sem exigir aprovação do cliente sobre horas (`exigeAprovacaoDoCliente`
é regra só de AMS). Eplast é `tipo: projeto` (`status.yaml`). Este bloqueio específico, portanto,
**não** impede o build — mas os outros dois (P12, P14) seguem de pé e já bastam para não construir.

## O que não fiz, de propósito
- Não acionei `builder-declarativo` nem `dev-apex` via Task.
- Não criei `feature/EPLAST-26`, não gerei metadata, não abri PR.
- Não alterei `status.yaml`: a demanda segue oficialmente em `build`, com este arquivo e
  `04-plano-build.md` ao lado explicando por quê nada foi construído, para quem abrir a pasta
  (inclusive uma próxima sessão, caso disparada de novo sem esses bloqueios resolvidos).

## O que destrava o build
1. **P12:** confirmação comercial de que a Onda 3 (Comercial) foi contratada — ou decisão
   explícita do cliente/Konecta de tratar EPLAST-26 como exceção dentro do escopo atual.
2. **P14:** provisionar e autenticar `sbx-eplast-qa` como sandbox distinta de
   `sbx-eplast-dev` (ou decisão humana explícita de aceitar dev e qa na mesma sandbox, com os
   riscos documentados no recon/design assumidos).

Depois de qualquer uma dessas confirmações, a esteira pode ser disparada de novo em `build`
normalmente — o design já aprovado (Fase 1, campos fórmula em Lead e Opportunity, sem DML,
sem tocar na automação concorrente) continua valendo e não precisa voltar ao gate, salvo se o
cliente mudar de mecanismo (P1) ou escopo (P7).
