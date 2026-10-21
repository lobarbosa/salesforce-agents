# SOMOSAGILITY-6: Design da solução (arquiteto)

**Cliente:** Somos Agility. **Tipo:** sustentação, design enxuto.
**Org consultada:** `sbx-somos-agility-dev` (sandbox, confirmada por `sf org list`).
**Insumos:** `demanda.md`, `01-analise.md` (aprovada no gate `aguardando_gate_analise`),
`02-recon.md`, `comentarios-do-card.md`. Também conferi por conta própria, em 2026-10-21,
um retrieve somente-leitura de `ApprovalProcess:FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1`
num workspace temporário fora do repo, e consultei triggers e Flows do objeto (seção 4).
Nenhum username ou e-mail aparece aqui. Os usuários são citados pelo nome de exibição
("Sales Operation", "Grupo Operações") ou por "Kelly", como faz a própria demanda.

---

## 1. Decisão

**Configuração nativa (nível 1 da doutrina).** A mudança é só no metadata do Approval
Process: trocar o `assignedApprover` de uma etapa. Não precisa de Flow, Apex nem LWC.

| Item | Valor |
|---|---|
| Objeto | `FluxoVendaProdutos__c` |
| Approval Process | `FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1` (label "Validação de Pricing - v1.1", ativo, `processOrder` 2) |
| Etapa | `Diretor_a_Comercial_Validacao_Fiscal` (label "Diretor(a) Comercial - Validação de Pricing", 2ª etapa) |
| Antes | aprovador único = usuário **Kelly** (`type = user`) |
| Depois | aprovador único = usuário **"Sales Operation"** (`type = user`) |
| Fica igual | `entryCriteria` da etapa (`Tem_servico__c` = Verdadeiro), `rejectBehavior = RejectRequest`, `allowDelegate = false`, `whenMultipleApprovers = FirstResponse`, e o resto do processo (critérios de entrada, ações iniciais/finais, e-mail template, travamento de registro, submitters) |

**Por que não descer de nível.** Isto não tem lógica nova, cálculo ou integração. É troca de
destinatário numa aprovação padrão, que é justamente o caso do nível 1. Um Flow ou Apex só
para escolher aprovador colocaria uma segunda automação concorrendo com o Approval Process e
deixaria a manutenção mais cara, sem ganho nenhum. P-6 da análise fica confirmada.

### 1.1 Usuário "Sales Operation" ou grupo "Sales operations"?

**Decisão: usar o usuário "Sales Operation".** Segui a recomendação do recon, por três
motivos:

1. **Consistência.** Os dois processos ativos do objeto já usam esse **usuário** como
   aprovador: na 1ª etapa deste mesmo processo e em `ValidacaoCotacao`. Nenhum processo
   ativo usa grupo. Colocar o grupo só nesta etapa criaria um segundo padrão de atribuição
   dentro do mesmo processo.
2. **Escopo.** O grupo público "Sales operations" não é usado por nenhum processo ativo, e
   não levantei quem são os membros dele. Usar o grupo mudaria *quem* aprova, ou seja, todos
   os membros, e isso a demanda não pediu nem o negócio validou.
3. **Permissão já comprovada.** O usuário "Sales Operation" já aprova a 1ª etapa deste
   processo, nos mesmos registros. O acesso dele ao registro e ao item de aprovação já
   funciona hoje.

Se o negócio quiser redundância entre várias pessoas, é outra demanda: definir os membros
do grupo e trocar o padrão nos dois processos ativos de uma vez.

### 1.2 Processos inativos que ainda citam a Kelly: **fora do escopo**

`ValidacaoFiscal` (inativo, Kelly junto com "Grupo Operações" e "Sales Operation") e
`ValidacaoCotacao_v_1_1` (inativo, Kelly como aprovadora única da 2ª etapa) **não serão
alterados** nesta demanda. Motivos:

- Os critérios de aceite da análise falam de "nenhuma etapa **ativa**". Processo inativo
  não recebe submissão e não afeta nenhum FVP.
- Mexer neles aumenta o diff do PR e o risco de deploy (mais arquivos com username que
  precisa existir em cada sandbox, ver R-3), e não muda nada no comportamento.
- O destino certo de versão antiga inativa é ser depreciada ou apagada, não "corrigida".
  Essa decisão é de quem é dono do processo no cliente.

**Fica registrado como risco (R-4):** se alguém reativar `ValidacaoCotacao_v_1_1` ou
`ValidacaoFiscal` no futuro, a Kelly volta a ser aprovadora. Recomendo abrir uma demanda
própria de limpeza dos processos inativos.

## 2. Componentes

| Ação | Tipo | API name |
|---|---|---|
| **Alterar** | ApprovalProcess | `FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1` (só a etapa `Diretor_a_Comercial_Validacao_Fiscal`, nó `assignedApprover/approver/name`) |
| Criar | — | nada |
| Depreciar | — | nada (os inativos ficam como estão, ver 1.2) |

Não há campo, objeto, Flow, classe, layout ou e-mail template novo. **Não há mudança de
modelo de dados**, então não precisa escalar para arquitetura sênior por esse motivo.

**Pré-requisito de estrutura no repo:** `clients/somos-agility/` ainda não tem
`sfdx-project.json` nem `force-app/`. O build vai criar a estrutura mínima, no mesmo
formato de `clients/acxya/sfdx-project.json` (`packageDirectories: force-app`), contendo
**somente** o arquivo do approval process acima. É isso que faz o
`ci-salesforce-validate.yml` rodar o check-only no PR.

## 3. Permissões

**Nenhuma alteração em perfil ou permission set.** O usuário "Sales Operation" já é aprovador
da 1ª etapa do mesmo processo e já acessa os mesmos registros. A Kelly continua ativa
(P-7) e não perde nenhuma permissão: ela só deixa de receber itens novos desta etapa.

Ressalva: o recon não auditou perfil por perfil (`02-recon.md`, "Não pôde ser medido"). Por
isso a etapa de QA confirma na prática que "Sales Operation" enxerga o item de aprovação da
2ª etapa (cenário 3 da análise).

## 4. Conflito de automação e governador

- **Triggers no objeto:** 0 (`ApexTrigger` com `TableEnumOrId = 'FluxoVendaProdutos__c'`,
  Tooling API, consultado por mim).
- **Flows disparados por registro do objeto:** 0 (`FlowDefinitionView` filtrando o objeto
  "Fluxo de Venda de Produtos", consultado por mim).
- **Approval Processes ativos no objeto:** 2 (`ValidacaoCotacao` ordem 1 e
  `ValidacaoFiscal_v_1_1` ordem 2). A ordem e os critérios de entrada **não mudam**. Não
  surge conflito de ordem de execução novo.
- Nenhuma ação de aprovação ou rejeição do processo cita o aprovador (P-3, recon seção 4).
  Os field updates e alertas seguem iguais.
- **Governador e escala:** não se aplica. Não há SOQL, DML ou loop: é metadata declarativo,
  avaliado pela plataforma uma vez a cada submissão.

## 5. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R-1 | **Segregação de funções.** "Sales Operation" já aprova a 1ª etapa ("Grupo Operações - Validação de Pricing", FirstResponse com "Grupo Operações"). Com a troca, a **mesma conta pode aprovar as duas etapas** do mesmo FVP quando `Tem_servico__c` for verdadeiro. A dupla checagem (operações e depois diretoria) pode virar uma só. Além disso, "Sales Operation" é um usuário funcional/genérico: se a conta for compartilhada, a trilha de auditoria não mostra qual pessoa aprovou. | **Alta (controle de negócio)** | Não tem correção técnica dentro do escopo: aprovação padrão não impede o mesmo aprovador em etapas seguidas. **O humano precisa aceitar isso de forma explícita no gate.** Se não aceitar, a alternativa é outro aprovador para a 2ª etapa (por exemplo, um grupo com membros definidos), e aí é uma nova rodada de design. |
| R-2 | **Deploy em processo ativo.** Deploy de alteração em approval process ativo pode ser recusado pela Metadata API, que restringe mudança de etapas e ações em processo ativo. Trocar só o aprovador de uma etapa existente costuma ser aceito, mas eu não confirmei isso nesta org. | Média | O `sf project deploy validate` (check-only) do CI responde antes de qualquer deploy. Se recusar, o builder **para e volta ao arquiteto**. Não vale desativar, deployar e reativar por conta própria, porque isso mexe em processo ativo em uso. |
| R-3 | **Username por sandbox.** O XML referencia aprovadores e um submitter por **username**, e o arquivo vai inteiro no deploy: são 4 referências a usuário, incluindo as que não mudam. Na dev, esses usernames **não têm sufixo de sandbox**. Não sei como estão na qa nem em produção. Se algum não existir na org de destino, o deploy falha. | Média | Antes do deploy na qa, o builder/release confirma, por contagem e sem colar o username em artefato, que os 4 usuários existem e estão ativos lá. Se o username for diferente, ajusta o arquivo só no deploy daquele ambiente. O mesmo cuidado vale para quem fizer o deploy em produção (humano). |
| R-4 | Processos inativos (`ValidacaoFiscal`, `ValidacaoCotacao_v_1_1`) continuam com a Kelly. Se forem reativados, ela volta ao fluxo. | Baixa | Registrado. Demanda de limpeza separada (seção 1.2). |
| R-5 | **QA bloqueado por FLS.** O usuário de integração da esteira não enxerga `Status__c` (recon seção 6), e esse campo está nos critérios de entrada do processo. Sem ele não dá para montar e submeter um FVP de teste. | Média (para a etapa 5) | O QA usa um usuário de teste com leitura e edição em `Status__c` e `StatusAprovacoes__c`, ou roda o cenário com o consultor. **Não** se altera o perfil de integração dentro desta demanda. |
| R-6 | Itens já pendentes com a Kelly **não migram sozinhos**. Trocar o aprovador da etapa só vale para itens que entrarem nela depois do deploy. | Média (negócio) | Ver premissa P-5 (seção 6). |

## 6. Premissas para o humano validar

- **P-5 (itens pendentes com a Kelly em produção). O agente não decide isto.** Não dá para
  medir na esteira (0 registros na dev, produção fora do alcance, guardrail #1).
  **Premissa adotada pelo design:** o build não faz nada sobre itens pendentes. Antes do
  deploy em produção, o cliente escolhe uma destas opções:
  (a) a Kelly conclui os itens que já estão com ela;
  (b) um admin do cliente reatribui esses itens para "Sales Operation" pela ação
  "Reatribuir" da aprovação, em produção;
  (c) o solicitante faz o recall (`allowRecall = true`) e submete de novo.
  Isso fica no checklist do release como passo do humano. O critério de aceite 6 da análise
  só fecha com essa decisão registrada.
- **"Todos os FVPs ou só os novos":** do jeito que a plataforma funciona, a troca vale para
  toda entrada na etapa **depois** do deploy. Se o cliente esperava outra coisa, é uma
  expectativa a alinhar com ele, não escopo técnico.
- **P-7:** a Kelly continua ativa. Desativar o usuário dela não faz parte desta demanda.

## 7. Passos do build (etapa 4, `builder-declarativo`)

1. Na branch `feature/SOMOSAGILITY-6`, confirmar com `sf org list` que o alvo é
   `sbx-somos-agility-dev`.
2. Criar `clients/somos-agility/sfdx-project.json` (mesmo formato do acxya, com o
   `sourceApiVersion` suportado pela org) e `force-app/`.
3. `sf project retrieve start --metadata "ApprovalProcess:FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1"`
   para trazer o arquivo atual da dev para o repo. Fazer um commit só com o retrieve, sem
   alterar nada, para servir de baseline no diff.
4. Editar **somente** o nó `assignedApprover/approver/name` da etapa
   `Diretor_a_Comercial_Validacao_Fiscal`, trocando o username da Kelly pelo do usuário
   "Sales Operation". Usar o mesmo username que já aparece na etapa
   `GrupoOperacoesValidacaoFiscal` do mesmo arquivo, que é a fonte confirmada. Manter
   `type = user`. O diff do segundo commit tem que ser de **uma linha**.
5. Rodar `sf project deploy validate` (check-only) na dev. Se der erro do tipo de R-2,
   **parar e escalar**, sem contornar.
6. Deploy na dev, depois um retrieve de novo para conferir que a etapa 2 tem um único
   aprovador e que ele é "Sales Operation".
7. Abrir o PR com o diff de uma linha e citar R-1 e R-3 na descrição. **Não colar username
   na descrição do PR** (guardrail #2): descrever como "Kelly → Sales Operation".
8. Para a qa (etapa de QA/release), conferir R-3 antes do deploy.

## 8. O que NÃO será feito

- Alterar os processos inativos `ValidacaoFiscal` e `ValidacaoCotacao_v_1_1`.
- Trocar o padrão de atribuição para o grupo público "Sales operations" ou mexer nos
  membros dele.
- Mudar critérios de entrada, ordem das etapas, `rejectBehavior`, ações de aprovação ou
  rejeição, e-mail templates ou alertas.
- Reatribuir itens pendentes em qualquer org (P-5 é decisão e execução humana em produção).
- Desativar a usuária Kelly ou mexer nas permissões dela.
- Corrigir a FLS de `Status__c` no perfil de integração (achado à parte, se for o caso vira
  demanda própria).
- Qualquer deploy em produção (guardrail #1).

## 9. Estimativa

**Estimativa de esforço:** 3–5 h

**O que mudou em relação à análise (3–6 h):** o recon confirmou o cenário P. A Kelly
aparece em uma única etapa ativa, por atribuição direta, sem Flow, Apex ou regra de
atribuição envolvida. O cenário que levaria a M (vários processos ou regras) foi
descartado, por isso o teto caiu de 6 para 5 h. O piso ficou em 3 h porque entraram custos
que a análise não tinha como prever: montar a estrutura SFDX do cliente no repo (que ainda
não existe), conferir os usernames na qa (R-3) e preparar um usuário de teste com FLS em
`Status__c` para o QA (R-5). Divisão aproximada: build, validate e PR, 1 h; deploy na qa
com conferência de R-3, 0,5–1 h; teste em sandbox com submissão real nas duas etapas,
1–2 h; homologação e documentação, 0,5–1 h. A estimativa oficial já aprovada pelo cliente
(4,5 h) fica dentro da faixa.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o
build. Pontos que pedem decisão explícita no aceite: **R-1 (a mesma conta pode aprovar as
duas etapas)** e **P-5 (destino dos itens pendentes com a Kelly em produção)**.
