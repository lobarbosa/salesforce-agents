# SOMOSAGILITY-16 — Design (arquiteto) — sustentação, design enxuto

**Cliente:** Somos Agility
**Demanda:** "Desabilitar relatório - Leads Semanais" (sustentação)
**Insumos:** `demanda.md`, `01-analise.md` (aprovada em `gates.md`, gate `aguardando_gate_analise`),
`comentarios-do-card.md`, `02-recon.md` (coletado em 2026-10-27 contra `sbx-somos-agility-dev`)
**Org consultada pelo agente:** só `sbx-somos-agility-dev` (sandbox, `IsSandbox = true`
confirmado no recon). Produção não foi e não será tocada (guardrail #1).

---

## 1. Resumo da decisão

**Configuração pura, executada por um humano em produção, a partir de um runbook produzido
pela esteira.** A esteira não executa a mudança nem lê a lista de destinatários real:
ela entrega o passo a passo, a planilha de verificação antes/depois (sem dado pessoal) e o
registro da evidência que o humano preencher.

Este design **não resolve** as duas ambiguidades em aberto (escopo e ambiente). Ele define
um caminho padrão para aprovação e lista, na seção 8, as decisões humanas que **precisam**
estar registradas no card antes de o build começar.

## 2. Nível de solução: por que configuração, e por que não desce

| Nível | Serve? | Motivo |
|---|---|---|
| **Configuração (UI do relatório)** | **Sim — escolhido** | Remover um destinatário de uma assinatura/agendamento de relatório é uma ação de UI no próprio relatório ("Assinar"/"Editar assinatura") ou no agendamento. Não há metadata a criar nem alterar. |
| Declarativo (Flow) | Não | Flow não administra assinatura de relatório. Nenhum evento de registro está envolvido. |
| Código (Apex/LWC, Analytics REST API) | Não | A Analytics REST API (`/analytics/reports/{id}/subscriptions`, ver recon §2) seria o único caminho programático, mas: (a) é uma mudança pontual, de uma vez, num registro — automatizar custa mais do que fazer; (b) teria de rodar contra produção, o que nenhum agente pode fazer; (c) essa API não está entre as ferramentas da esteira. Não há justificativa para descer. |

**Conflito de automação:** nenhum. Não há Flow, Trigger, Validation Rule ou classe Apex
envolvidos — a demanda não toca em objeto, campo nem evento de registro.

**Limites de governador / escala:** não se aplica. Uma alteração manual, num relatório.

**Modelo de dados:** sem mudança. Nada a escalar como decisão de arquitetura sênior.

## 3. O que a esteira de agentes pode e não pode fazer nesta demanda

| Ação | Agente pode? | Por quê |
|---|---|---|
| Ler definição do relatório na sandbox dev | Sim (já feito no recon) | Metadata, sandbox. |
| Ler a lista de destinatários **em produção** | **Não** | Guardrail #1 (produção) e limitação de ferramenta (recon §2: assinatura não é SOQL nem Metadata API). |
| Ler a lista de destinatários **na sandbox** como substituto | **Não serve** | Mesmo se fosse acessível, não representa produção: assinaturas não são, em geral, copiadas no refresh (documentação pública da plataforma, não confirmada nesta org — recon §2). Usar a cópia como "mapeamento" seria entregar dado que parece certo e não é. |
| Remover Fabio Soto do agendamento em produção | **Não** | Guardrail #1. Escrita em produção é humana. |
| "Ensaiar" a remoção na sandbox dev | **Não será feito** | Não há o que validar: não há metadata nem deploy, e a assinatura da sandbox não reflete a de produção. Ensaio não reduziria nenhum risco real. |
| Produzir runbook, checklist de verificação e registrar evidência sem dado pessoal | **Sim** | É a entrega da esteira nesta demanda. |
| Gravar nomes/e-mails dos destinatários no repositório | **Não** | Guardrail #2 / RN4: o artefato guarda só contagem e perfil/papel. |

## 4. Componentes

### 4.1 Na org (executados pelo humano, em produção)

| Item | Ação | Identificador |
|---|---|---|
| Relatório "Leads Semanais" | **Nenhuma alteração na definição** | `00O4z0000057ssKEAQ` / `Leads_Semanais_fu2`, pasta `Leads` — confirmado **na sandbox dev**; em produção, o executor confere que o Id do link é o mesmo relatório antes de agir |
| Assinatura(s)/agendamento(s) do relatório | **Alterar**: remover o destinatário Fabio Soto (caminho padrão, ver §5) | Não tem API name — não é metadata (recon §2) |

Nenhum componente a **criar** ou **depreciar**. Nada entra em `force-app/` e, portanto, o
`ci-salesforce-validate.yml` não tem o que validar nesta demanda.

### 4.2 No repositório (produzidos pela esteira)

| Artefato | Etapa | Conteúdo |
|---|---|---|
| `04-plano-build.md` | build | Runbook de execução humana em produção (esqueleto na §6), com a escolha de escopo da §8 já aplicada. |
| `05-testes.md` | qa | Checklist de verificação antes/depois, **preenchido pelo humano que executou**: contagem de destinatários antes, contagem depois, distribuição por perfil/papel, confirmação de que Fabio Soto não consta mais. Sem nomes de terceiros, e-mails ou Ids de usuário. |
| `06-entrega.md` | doc | Registro do que foi feito, por quem (papel, não nome pessoal novo), quando, e como reverter. |

## 5. Escopo padrão proposto para aprovação

Proponho como **padrão** a leitura do corpo da demanda (RN1 da análise):

- **Remover somente Fabio Soto** dos destinatários do relatório "Leads Semanais".
- O relatório continua existindo com o mesmo Id; o agendamento continua ativo para os
  demais destinatários.
- **Mapear** os destinatários atuais (antes da mudança) e registrar no artefato só a
  contagem total e a distribuição por perfil/papel. A lista nominal fica com a consultora,
  fora do repositório (ou no próprio card, se o time decidir — ver D3).

Motivo para este ser o padrão: o corpo é o texto mais específico da demanda e o único que
descreve uma ação concreta; o título usa "desabilitar" mas pede, no corpo, a remoção de um
usuário. Desabilitar o agendamento inteiro afeta todos os destinatários e é irreversível
na prática para quem não sabe que estava inscrito — então é a leitura que **exige**
confirmação explícita, não a padrão.

**Isto é proposta, não resposta.** Se a consultora confirmar a outra leitura (desativar o
agendamento inteiro), o runbook muda (§6, passo 5b) e a comunicação aos demais
destinatários entra no escopo.

## 6. Esqueleto do runbook (vira `04-plano-build.md` depois do gate)

Os caminhos de menu abaixo seguem a documentação pública da Salesforce para assinaturas
de relatório no Lightning e **não foram confirmados na org de produção** (o agente não tem
acesso a ela). O executor confere o caminho real na tela antes de agir.

**Quem executa:** usuário de produção com acesso de edição à pasta pública "Leads" e
permissão de gerenciar assinaturas de terceiros — na prática, um administrador do sistema
do cliente. (Nomes de permissão como "Subscribe to Reports: Add Recipients" vêm da
documentação pública; não confirmados nesta org.)

1. **Confirmar o alvo.** Abrir o link da demanda em produção; conferir nome "Leads
   Semanais", pasta "Leads", e que a URL de domínio é a da org de produção do cliente.
2. **Confirmar o usuário.** Em Setup → Usuários, confirmar que existe exatamente um
   usuário "Fabio Soto" ativo (na sandbox há um só; em produção não foi verificado).
3. **Enumerar as assinaturas do relatório.** Pode haver mais de uma: no Lightning cada
   usuário pode ter a própria assinatura do mesmo relatório, com seus destinatários.
   Pontos de entrada: botão "Assinar"/"Editar assinatura" no relatório, e Setup → Jobs
   agendados (tipo de job de execução de relatório), que lista quem enviou cada
   agendamento.
4. **Mapear o "antes".** Para cada assinatura: quem é o dono (papel), quais destinatários
   (usuários, grupos, papéis). Registrar **no `05-testes.md` só a contagem e o
   perfil/papel**; a lista nominal fica com a consultora (ver D3).
5. **Aplicar a mudança.**
   - **5a (padrão):** remover Fabio Soto da lista de destinatários da(s) assinatura(s) em
     que ele aparece **individualmente**. Se a assinatura for dele mesmo (ele é o dono),
     excluir aquela assinatura — não afeta mais ninguém.
   - **5b (só se D1 = desativar tudo):** excluir/desativar todas as assinaturas do
     relatório, após comunicar os demais destinatários.
   - **Parar e escalar** se Fabio Soto recebe **via grupo público ou papel** (não
     individualmente): removê-lo exigiria tirar o grupo/papel inteiro (afeta outros) ou
     mudar a participação dele no grupo (efeito colateral fora deste relatório). Nenhuma
     das duas está aprovada neste design.
6. **Mapear o "depois"** e conferir: lista depois = lista antes − Fabio Soto (cenário 2 da
   análise); relatório com o mesmo Id; agendamento ativo para os demais (cenário 3).
7. **Registrar evidência** no `05-testes.md` (contagens e perfis, data/hora da
   alteração). Nenhum screenshot com nome, e-mail ou dado de lead (guardrail #2).

**Rollback:** reinscrever Fabio Soto como destinatário na mesma assinatura (5a) ou
recriar a(s) assinatura(s) com a lista do "antes" (5b) — por isso a lista nominal do
"antes" precisa ficar guardada com a consultora até o aceite final.

## 7. Impacto em permissões

Nenhum perfil ou permission set é criado ou alterado. O pré-requisito é que **o executor
em produção já tenha** o acesso descrito na §6; se não tiver, conceder acesso é outra
decisão, fora desta demanda.

## 8. Decisões humanas pendentes — bloqueiam o build

Nenhuma delas foi respondida no card até agora (`comentarios-do-card.md` só registra a
aprovação da estimativa e do gate de análise). O build **não começa** sem D1 a D3 registradas
no card.

| # | Decisão | Quem | Padrão proposto se aprovado assim |
|---|---|---|---|
| **D1** | Escopo: remover só Fabio Soto **ou** desativar o agendamento do relatório inteiro? | Consultora (Juliana Mendes) com o cliente | Remover só Fabio Soto (§5) |
| **D2** | Ambiente: o link é mesmo da org de produção? E **quem** vai executar lá (nome do papel: admin do cliente ou consultor com acesso de admin)? | Consultora | Produção; executor a nomear |
| **D3** | Destino do mapeamento nominal: fica só com a consultora, ou vai para o card do Squad OS? (No repositório, só contagem e perfil — inegociável, RN4.) | Consultora | Só com a consultora |
| D4 | Prazo: a próxima execução semanal já deve sair sem Fabio Soto? | Consultora | Sem prazo declarado — executar assim que D1–D3 estiverem respondidas |

Perguntas 4 (motivo), 5, 8 da análise não bloqueiam a execução e ficam como informação
desejável.

## 9. Riscos técnicos

| Risco | Severidade | Mitigação |
|---|---|---|
| **Escopo errado (desativar tudo quando era só remover um, ou o contrário)** | **Alta** | D1 bloqueia o build. Padrão é o menos destrutivo. |
| **Usar a sandbox como fonte do mapeamento** e entregar lista que não é a de produção | **Alta** | Proibido neste design (§3). Mapeamento só em produção, pelo humano. |
| **Fabio Soto recebe via grupo/papel**, não individualmente | Média | Runbook para e escala (§6, passo 5). |
| Mais de uma assinatura no mesmo relatório (uma por usuário) e só uma ser ajustada | Média | Passo 3 enumera todas antes de mexer. |
| Homônimo ou usuário duplicado em produção (não verificável pelo agente) | Baixa | Passo 2 confere em produção. |
| Executor sem permissão de editar assinatura de terceiros | Baixa | Pré-requisito explícito na §6/§7; se faltar, vira nova decisão. |
| Vazamento de dado pessoal na evidência (print com nomes, e-mails ou leads) | Média | Evidência só em contagem/perfil; sem screenshot de lista nominal ou de dados do relatório. |

## 10. O que NÃO será feito nesta demanda

- Nenhuma alteração na definição do relatório (filtros, colunas, tipo, pasta).
- Nenhuma exclusão do relatório.
- Nenhuma alteração de compartilhamento da pasta "Leads", de grupos públicos, papéis,
  perfis ou permission sets.
- Nenhuma desativação ou alteração do usuário Fabio Soto.
- Nenhuma automação (Flow, Apex, chamada à Analytics REST API) para gerenciar assinaturas.
- Nenhuma escrita em produção por agente; nenhum "ensaio" na sandbox dev.
- Nenhum mapeamento nominal de destinatários no repositório.
- Revisão de outros relatórios agendados que Fabio Soto possa receber — só "Leads Semanais".

## 11. Estimativa de esforço refinada

**Estimativa de esforço:** 1–2 h

Mudou em relação à análise: **a faixa não mudou, a composição mudou.** A análise contava
com parte do trabalho (identificar usuário e mecanismo, gerar o mapeamento) sendo feita
pela esteira na org. O recon mostrou que nada disso é viável pelo agente: a assinatura não
é exposta por SOQL nem Metadata API, e o estado real só existe em produção. Então a hora
humana deixa de ser "conferir o que o agente fez" e passa a ser execução direta:
responder D1–D3 (~0,25 h), executar o runbook em produção com mapeamento antes/depois
(~0,5–1 h, mais perto do teto se houver várias assinaturas ou recebimento via grupo),
registrar evidência e homologar (~0,25–0,5 h). Em compensação, não há build, deploy nem
teste em sandbox a revisar. Se D1 vier como "desativar tudo", soma-se a comunicação aos
demais destinatários e a faixa pode chegar a 2,5 h.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o
build. Para liberar, além do aceite deste design, D1, D2 e D3 (§8) precisam estar
respondidas no card.
