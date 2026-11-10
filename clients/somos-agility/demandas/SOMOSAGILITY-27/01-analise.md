# Análise — SOMOSAGILITY-27

- **Cliente:** Somos Agility
- **Tipo:** sustentação (bug/acesso)
- **Org de dev confirmada:** `sbx-somos-agility-dev` (sandbox, `IsSandbox=true`, instância `agilitynetworks--sbxdev`)
- **Estado do card:** "Analisado e adicionado uma permissão para salvar relatórios. Aguardando testes" (equipe, 2026-11-10 00:03)
- **Status desta análise:** pendente de validação humana. Há uma pergunta que bloqueia o design (seção "O que a demanda NÃO diz", item 1).

## Confirmações feitas via `sf` (metadata e contagens, sem dado pessoal)

Não consultei o usuário da colaboradora nem o perfil dela. Buscar por nome traria dado pessoal para a sessão (guardrail #2), e a identificação dela é dado de negócio que o consultor deve informar. Nada abaixo afirma qual perfil ou permission set ela usa.

- Org: sandbox confirmada (`Organization.IsSandbox = true`), mesma org do assessment de 2026-09-30.
- Perfis: 77 no total. 54 têm `PermissionsCreateCustomizeReports = true` e 54 têm `PermissionsExportReport = true`. Não verifiquei se são os mesmos 54. Ou seja, as permissões de relatório já estão amplamente distribuídas por perfil na org.
- Permission sets não vinculados a perfil: 142 no total. 5 têm `PermissionsCreateCustomizeReports = true` e 3 têm `PermissionsExportReport = true`. (O assessment registrou 134 em 2026-09-30. A diferença sugere que a org mudou desde então, o que não investiguei.)
- `SetupAuditTrail` dos últimos 10 dias na sbx dev: nenhum registro de alteração de perfil ou permission set. As entradas são de conexão de deploy e de limites. Consequência: **não consigo confirmar na sbx dev que a permissão foi adicionada.** Ou a alteração foi feita em outro ambiente (qa ou produção), ou não foi feita na sbx dev, ou o registro não aparece nesta consulta. Isso precisa ser respondido pelo consultor.

Nomes de permissão usados aqui (`PermissionsCreateCustomizeReports`, `PermissionsExportReport`) foram confirmados como campos consultáveis da org. Que o rótulo de UI "salvar relatórios" corresponde a "Criar e personalizar relatórios" é hipótese minha, a validar na UI (ver premissas).

## Histórico do cliente (RAG)

Consultei `mcp__rag__rag_consultar` com "exportar dados relatório permissão perfil salvar relatório Report Builder modelo". Não há demanda anterior deste cliente sobre o assunto. Nenhuma fonte citada.

## Contexto de negócio

A colaboradora Luana Roberta relata que não consegue extrair dados nem criar um "modelo" no Salesforce. A equipe investigou, concluiu que é problema de permissão e adicionou uma permissão para salvar relatórios. A correção está aguardando teste de confirmação. Não há no card nenhuma confirmação de que o problema foi resolvido.

Pelo assessment (achado #6), a org segue o padrão "perfil por pessoa": 20 de 26 perfis em uso têm um único usuário ativo. Se a permissão foi adicionada no perfil individual da colaboradora, o problema foi resolvido no sintoma e o antipadrão foi mantido. Isso tende a se repetir para a próxima pessoa com a mesma necessidade.

## Objetivo

1. Restabelecer para a colaboradora a capacidade de extrair dados e criar o "modelo" que a função dela exige, com verificação em teste.
2. Fazer a correção pelo mecanismo que a org já deveria usar (permission set), e não por ajuste pontual de perfil individual, a não ser que o arquiteto decida o contrário com justificativa.

## Regra de negócio

Não está definida pelo negócio. A regra implícita é: quem tem a função de análise de dados deve conseguir extrair e salvar os relatórios que essa função exige, sem liberar mais acesso do que a função precisa. Quais objetos, pastas e tipos de relatório entram nessa função é pendente.

## Critérios de aceite (Gherkin)

Os critérios A1 a A3 são testáveis com o que já se sabe. Os critérios A4 e A5 dependem de respostas pendentes e estão marcados como bloqueados.

**A1 — Salvar relatório**
```gherkin
Dado um usuário de teste em sbx-somos-agility-qa com o mesmo perfil e os mesmos permission sets da colaboradora
E com acesso à pasta de relatórios usada pela função dela
Quando ele cria um relatório no Report Builder e clica em "Salvar"
Então o relatório é salvo sem erro de privilégio insuficiente
E o relatório aparece na pasta escolhida
```

**A2 — Extrair dados**
```gherkin
Dado o mesmo usuário de teste com acesso ao relatório salvo no A1
Quando ele exporta o relatório no formato que a função usa (formato a confirmar, ver pergunta 2)
Então o arquivo é gerado sem erro de privilégio insuficiente
E o número de linhas do arquivo bate com o número de linhas exibido na tela
```

**A3 — Sem ampliação de acesso além do necessário**
```gherkin
Dado o inventário de permissões de perfis e permission sets da sbx dev antes e depois da correção
Quando a correção é aplicada
Então a única diferença de permissão de relatório é a(s) permissão(ões) previstas no design
E nenhum usuário ativo além da colaboradora e da função dela ganha acesso novo
```

**A4 — Forma da correção (bloqueado pela decisão do arquiteto)**
```gherkin
Dado a correção aplicada em qa
Quando o arquiteto revisa onde a permissão foi concedida
Então a permissão está em permission set reutilizável por função
  ou a exceção ao perfil individual tem justificativa registrada no design
```

**A5 — "Criar modelo" (BLOQUEADO — não é critério ainda)**
```gherkin
# Não escrever critério até a pergunta 1 ser respondida.
# "Modelo" pode ser Report Type, objeto customizado, template de e-mail/documento,
# dashboard ou outro. Cada um tem um teste e uma mudança de arquitetura diferentes.
```

**A6 — Confirmação de uso pela colaboradora**
```gherkin
Dado o roteiro de teste de A1 a A3 executado pela colaboradora (ou pelo consultor com o perfil dela) em qa
Quando o roteiro é concluído
Então todos os passos estão marcados como OK, com evidência anexada se o anexo for liberado
```

## O que a demanda NÃO diz

Estas perguntas precisam de resposta antes do design (`03-design.md`). A 1 para o design por completo.

1. **"Criar um modelo Salesforce" — o que exatamente?** Report Type, objeto customizado, template de documento ou e-mail, dashboard? Muda a arquitetura da solução (metadata diferente, permissão diferente, risco diferente) e não dá para escolher por conta própria. **Parada de design.**
2. **"Extrair dado" — como?** Exportar um relatório (Export Reports), Data Export, Excel conectado, Data Loader/API, ou um relatório com dados de objeto específico?
3. **Qual permissão foi adicionada, em qual perfil ou permission set, e em qual ambiente?** O card diz "adicionado uma permissão" sem dizer onde. Na sbx dev não há registro dessa alteração (ver confirmações).
4. **O teste já foi feito?** O card diz "Aguardando testes". Não há resultado.
5. **Qual é o perfil e a licença da colaboradora?** Não consultei por ser dado pessoal. A licença importa: a org está com 29 de 30 licenças `Salesforce` em uso na sbx (assessment, achado #9). Mudança de licença não é opção barata.
6. **O problema também ocorre em qa?** A análise foi feita na sbx dev. Não investiguei a sbx qa.
7. **A pasta de relatórios e o compartilhamento** que a função usa: quais são, e quem mais precisa ver os relatórios? Salvar depende de acesso à pasta, não só de permissão.
8. **A mensagem de erro exata** que a colaboradora vê. Não há print nem texto no card. Anexo só entra se alguém de delivery liberar, declarando que não tem dado pessoal (guardrail #2).
9. **Desde quando o problema existe e se afeta outras pessoas.** Se afeta outras, a correção não é pontual.
10. **Prazo ou urgência** e quem valida a resolução do lado do cliente.

## Riscos do assessment que tocam este pedido

- **Achado #6 — perfil por pessoa em vez de permission set (média, segurança).** Diretamente relevante. Para o design decidir: (a) consertar via permission set reutilizável por função, ou (b) ajuste pontual no perfil da colaboradora. A opção (a) é a que não perpetua o antipadrão. A opção (b) é aceitável só se houver justificativa e registro. O arquiteto escolhe; eu não escolho aqui.
- **Achado #9 — licença `Salesforce` em 97% na sbx (média, limites).** Se o "modelo" ou a extração exigirem licença ou função que não existem, a solução pode ser de licença e não de permissão. Confirmar em produção está fora do escopo deste agente (guardrail #1).
- **Achado #1 — 24 automações no mesmo evento em Oportunidade (alta, automação).** Só entra se a pergunta 1 resultar em objeto, campo ou Flow em Oportunidade. Nesse caso, mapear automações antes de qualquer alteração.
- **Achado #3 — cobertura Apex de 40% (alta, código).** Não se aplica se a solução for só permissão. Se envolver Apex ou Flow, o design precisa dizer como lida com ele.

## Premissas a validar

Todas pendentes. Nenhuma foi tratada como fato.

- **P1 (pendente):** "extrair dado" significa exportar relatório. Validar com a pergunta 2.
- **P2 (pendente):** "salvar relatório" no Lightning corresponde a "Criar e personalizar relatórios" (`PermissionsCreateCustomizeReports`). Validar na UI com um usuário de teste em qa, ou pela descrição do perfil.
- **P3 (pendente):** a permissão adicionada pela equipe está em perfil individual da colaboradora. Não confirmado.
- **P4 (pendente):** a alteração foi feita na sbx dev. Não confirmado: não há registro no `SetupAuditTrail` da dev.
- **P5 (pendente):** a permissão de salvar sozinha resolve. Pode faltar acesso à pasta ou a um tipo de relatório.
- **P6 (pendente):** a solução é só de permissão e não envolve código, Flow nem alteração de metadata de objeto. Se a pergunta 1 mudar isso, o escopo e a complexidade mudam.

## Complexidade

**P** — se o problema for só permissão e a correção couber em um permission set de função. Sobe para **M** se "criar modelo" for objeto customizado, Report Type ou template, ou se a correção exigir decisão de licença ou de perfil-base.

## Estimativa de esforço

**Estimativa de esforço:** 2–8 h

Premissas que mais pesam na faixa:
- Teste e confirmação do problema reproduzido em qa com um usuário de teste (1 a 2 h, incluindo a ida e volta com o consultor).
- Se "criar modelo" for só permissão ou pasta, a faixa fica perto de 2 a 3 h. Se for objeto ou Report Type novo, passa de 8 h e precisa ser reavaliada no design.
- Decisão de permission set versus perfil individual: o design refina. Faixa larga porque a demanda é vaga e a pergunta 1 não foi respondida.

## Próximos passos

1. Consultor responde as perguntas 1 a 5 (prioridade: 1, 3 e 4).
2. Com a resposta da pergunta 1, esta análise é revisada. Se for "criar modelo", o critério A5 é escrito.
3. Só então o arquiteto desenha a solução, decidindo a forma da correção (A4).

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
