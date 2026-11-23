# Design SOMOSAGILITY-28: acesso ao objeto "Solicitação de Treinamento" (sustentação, design enxuto)

**Org consultada:** `sbx-somos-agility-dev` (sandbox, conectada em `sf org list`). Só leitura nesta etapa.
**Entradas:** `01-analise.md` (aprovada em `gates.md`, gate `aguardando_gate_analise`), `02-recon.md` (com complemento do arquiteto desta sessão), `00-preflight.md` (sem bloqueios, sem demanda concorrente), `comentarios-do-card.md`.

> **Duas incertezas atravessam todo o design e não estão resolvidas:**
> 1. **O objeto não está confirmado pelo solicitante.** O candidato é `JOB_de_Solicitacao_de_Treinamentos__c` (label "JOB de Solicitação de Treinamentos"), escolhido por semelhança de nome. Nenhum objeto da org se chama exatamente "Solicitação de Treinamento". Há outros 4 objetos com "Treinamento" no label (ver 02-recon).
> 2. **O colaborador não está identificado.** Perfil, permission sets, licença e estado ativo dele são desconhecidos, e a causa do bloqueio não foi provada.
>
> O desenho abaixo vale **para o objeto candidato**. Se o solicitante indicar outro objeto, a estrutura da solução continua a mesma, mas o build precisa de nova confirmação de automação e permissões naquele objeto.

## 1. Decisão

**Configuração pura: um permission set novo, de menor privilégio, dedicado ao objeto, atribuído ao usuário-alvo. Sem Flow, sem Apex, sem alterar perfil.**

| Nível | Usado? | Por quê |
|---|---|---|
| Configuração (permission set) | **Sim** | O problema é de acesso. Permissão de objeto, FLS, aba e record type são todos configuráveis num permission set. |
| Declarativo (Flow) | Não | Não há regra de negócio a automatizar. Uma atribuição automática por Flow seria sobre-engenharia para um usuário. |
| Código (Apex/LWC) | Não | Nada exige código. Também não mexe em código existente, por isso o achado de cobertura Apex não pesa. |

**Por que um permission set novo e não um existente** (confirmado nesta sessão, ver complemento do 02-recon):
- `jobsAprovacao` dá R/C/E/D + **ViewAll** no JOB de Treinamentos **e** em `JOB_de_Solicita_o_de_Investimento__c`. Atribuí-lo daria acesso a outro objeto e a todos os registros.
- `Gastos_treinamento` dá só Read no JOB, sem nenhum FLS no objeto, e acesso total (com ViewAll) a `Previsao_de_Gastos_do_Treinamento__c` e `Previsao_Gastos_Treinamento_Realizado__c`.
- Nenhum dos dois atende ao critério de aceite 3 ("nenhum outro acesso além do necessário").

**Por que não editar o perfil:** o comentário do card diz que o acesso foi "realizado para o perfil do usuário". Esse é o padrão do achado #6 do assessment (perfil por pessoa), e a análise aprovada pede correção reproduzível sem editar um perfil individual (critério de aceite 2). Se o gate escolher manter só o ajuste de perfil (Opção A da análise), não há build e este design se reduz à documentação.

## 2. Componentes

### A criar (em `feature/SOMOSAGILITY-28`, implantado na dev)

| Tipo | API name proposto | Conteúdo |
|---|---|---|
| PermissionSet | `PS_Treinamento_SolicitacaoJob` (convenção `PS_<Area>_<Funcao>` da skill `padrao-entrega`; o `CLAUDE.md` do cliente não define outra; nome livre na org, confirmado) | Licença: a mesma do usuário-alvo (**pendente P5**; os PS existentes no objeto usam licença Salesforce). Ver detalhamento abaixo. |

Conteúdo do permission set, **condicionado ao nível de acesso P2** (pendente):

| Item | Proposta padrão (se P2 = "criar e acompanhar as próprias solicitações") | Variações |
|---|---|---|
| Objeto `JOB_de_Solicitacao_de_Treinamentos__c` | Read, Create, Edit. **Sem** Delete, ViewAll e ModifyAll. | Só Read (consulta); ViewAll só se P2 exigir ver registros de outros (ver R4). |
| Aba `JOB_de_Solicitacao_de_Treinamentos__c` | Visível (`Visible` no PS). | — |
| Record type `Mestre` | Visível. | — |
| FLS | Read/Edit nos campos que o solicitante precisa preencher; Read nos de valor (`Valor_Total_*`) e nos lookups de aluno (`Nome_do_Aluno_1..4__c`). A lista exata de campos sai do layout em uso. **Não confirmada nesta etapa**: o builder lista os campos via describe e o solicitante valida o que é editável. | Em Read-only, todos os campos só leitura. |
| Objetos referenciados pelos lookups de aluno | **Não incluídos.** Se o usuário não tiver Read no objeto alvo do lookup, ele vê o campo, mas não abre o registro relacionado. O objeto alvo não foi conferido nesta etapa. O builder confirma isso via describe e registra no plano. | — |

### A alterar
- Nenhum. Nenhum perfil, permission set existente, regra de compartilhamento, processo de aprovação ou layout.

### A depreciar
- Nenhum nesta demanda. Se o "acesso realizado" no perfil existir no ambiente de destino, a reversão dele é **decisão do humano** (pendência G3), feita fora da esteira se for produção.

### Atribuição
- Atribuir o permission set a usuário real **não é feito pelo agente** em nenhum ambiente. Na dev e na QA, o teste usa um usuário de teste do agente. Em produção, a atribuição ao colaborador é passo manual do humano, depois da homologação.

### Versionamento
- Não há Flow, agente Agentforce nem classe Apex existente sendo alterado. Por isso, a regra "nova versão primeiro, ativação depois" não se aplica. O permission set é novo e não tem estado ativo a preservar.

## 3. Impacto em permissões

- **Perfis:** nenhum alterado (critério 2). O build entrega a comparação do metadata do perfil do usuário de teste antes e depois.
- **Permission sets:** +1 (`PS_Treinamento_SolicitacaoJob`). Os existentes ficam intactos.
- **Compartilhamento:** OWD continua Private/Private. As 3 regras de compartilhamento (`Coordenador_de_DC`, `Coordenador_de_EA`, `Coordenador_de_SEG`, todas Read) continuam como estão. Sem ViewAll, o usuário vê os registros que criou, os que recebeu por propriedade e os que alguma regra compartilhar com ele.
- **Critério 3 (nenhum outro usuário ganha acesso):** é atendido por construção, porque o PS só tem uma atribuição. O QA registra a contagem de `PermissionSetAssignment` do PS antes e depois.

## 4. Conflito de automação e ordem de execução

Fonte: 02-recon, seção 3. No objeto candidato não há trigger, Flow, Process Builder, workflow rule nem validation rule. A solução não cria automação. **Não há risco de ordem de execução.**

Ponto de atenção: existem **2 processos de aprovação ativos** (`Aprovacao_do_JOB_de_Treinamentos_v7` e `JobSTGeral_v2`). Eles não são alterados aqui, mas, se o colaborador precisar submeter a solicitação para aprovação, os critérios de entrada podem barrá-lo mesmo com o acesso concedido. O histórico do cliente mostra esse padrão: em SOMOSAGILITY-22, `05-testes.md` registra um processo de aprovação de JOB com entrada restrita a cerca de 17 usuários nomeados em `CreatedBy`. Os critérios destes dois processos não foram lidos (02-recon, item 7). Ver R3.

## 5. Limites de governador e escala

Não se aplica de forma relevante. A mudança é metadata de permissão, sem DML em lote, sem SOQL e sem transação nova. O volume do objeto na dev é 0 registro. O cenário "registro pai com muitos filhos" (achado SOMOSAGILITY-10) não existe aqui, porque nenhuma automação dispara na gravação do objeto.

## 6. Riscos do assessment que tocam a demanda

| Achado do assessment | Toca? | Como o design lida |
|---|---|---|
| #1: 31 automações ativas em Oportunidade (24 em RecordAfterSave create/update) | **Não** | A demanda não toca Oportunidade. O recon confirmou 0 Flow referenciando o objeto candidato em 335 arquivos de Flow. |
| 59 Process Builders ativos | **Não** | Nenhum referencia o objeto candidato (mesma evidência). Nenhum PB é criado ou alterado. |
| #3/#4: cobertura Apex 40% e classes sem teste | **Não** | Não há código. Ressalva: as 96 classes não foram varridas para referências ao objeto (02-recon, item 6). Classe `with sharing` que leia o objeto passa a respeitar o novo acesso, o que é o comportamento desejado. O risco é baixo. |
| #6: 20 de 26 perfis com 1 usuário (perfil por pessoa) | **Sim, é o centro da demanda** | O acesso vem de permission set, não de perfil. A migração dos 20 perfis fica **fora** desta demanda e é recomendada como demanda própria. |
| #9: 29 de 30 licenças usadas (foto da dev) | **Talvez** | O permission set precisa ser compatível com a licença do usuário-alvo, que é desconhecida (P5). Se for incompatível, a atribuição falha. Nesse caso, o processo para e escala, sem contornar. Nenhuma licença nova é consumida por esta solução. |

O assessment é de 2026-09-30, medido na dev. Os números acima não foram reconferidos nesta sessão porque não tocam o objeto (02-recon, item 9).

## 7. Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **Objeto errado.** O solicitante pode estar falando de `Treinamento_Interno_SUATC__c`, `Treinamento_Publico_SUATC__c` ou de um dos dois de Previsão de Gastos. | **alta** | Pendência G1, que bloqueia o build. Com outro objeto, o builder refaz a checagem de automação e de ObjectPermissions naquele objeto antes de criar o PS. |
| R2 | **A causa não é permissão de objeto.** O usuário pode já ter acesso pelo perfil (35 entradas de permissão no objeto), e a causa pode ser aba oculta, compartilhamento (OWD Private), licença ou usuário inativo. Nesse caso, o PS não resolve, ou resolve só em parte. | **alta** | O PS cobre objeto, aba, record type e FLS, ou seja, 4 das causas candidatas. Compartilhamento e licença não são cobertos. O QA primeiro reproduz o bloqueio com um usuário de teste **no mesmo perfil do colaborador e sem o PS**, depois repete com o PS. Se não reproduzir, a causa é outra e o processo volta ao design. Isso depende de G2 (perfil do colaborador). |
| R3 | O usuário passa a acessar, mas não consegue submeter para aprovação por causa dos critérios de entrada dos 2 processos ativos. | média | Fora do escopo, salvo se P2 incluir "submeter". O QA registra o resultado da submissão como observação, sem alterar o processo. |
| R4 | P2 exigir ver registros de outros usuários. A saída mais simples seria ViewAll, que conflita com a menor privilégio. | média | Não conceder ViewAll por padrão. Se for necessário, o humano decide entre ViewAll no PS e regra de compartilhamento nova. Uma regra nova altera o modelo de compartilhamento do objeto e **é decisão de arquitetura sênior: escalar, não decidir aqui**. |
| R5 | O ajuste manual já feito no perfil (em ambiente desconhecido, P1/P6) deixa o acesso duplicado (perfil + PS) e mascara o teste. | média | Pendência G3. Na QA, o teste usa usuário de teste, não o perfil ajustado. |
| R6 | A licença do usuário-alvo é incompatível com o PS (licença Salesforce). | média | A falha aparece na atribuição. Nesse caso, parar e escalar (achado #9). |
| R7 | Lookups de aluno apontam para um objeto sem Read para o usuário, e o link fica inacessível. | baixa | O builder confirma o objeto alvo via describe e registra. Não amplia o acesso sem aprovação. |
| R8 | Massa de teste: a dev tem 0 registro e o objeto tem campos de valor e lookups de pessoa. | baixa | O teste cria registro sintético, sem dado pessoal (guardrail #2). Não há screenshot de registro real. |

## 8. O que NÃO será feito

- Nenhuma alteração de perfil, inclusive o do colaborador.
- Nenhuma alteração em `jobsAprovacao`, `Gastos_treinamento`, nas regras de compartilhamento, nos processos de aprovação, em layouts ou no OWD.
- Nenhuma regra de compartilhamento nova (se necessária, é escalonamento, R4).
- Migração dos 20 perfis de usuário único (achado #6 completo): fica como demanda própria.
- Nenhuma atribuição a usuário real pelo agente, e nada em produção. A reversão do ajuste manual de perfil, se o humano decidir fazê-la, é feita por ele.
- Nenhum acesso aos outros 4 objetos de "Treinamento".
- Nenhuma mudança de modelo de dados (não há campo nem objeto novo).

## 9. Pendências para o gate (perguntas de negócio sem resposta)

Os comentários do card não respondem nenhuma das premissas da análise. O único conteúdo novo é a aprovação do gate e da estimativa de 2 h. **G1 e G2 bloqueiam o build.** Sem elas, o builder deve sair com `**Resultado do build:** bloqueado`.

| # | Pergunta | Origem | Bloqueia? |
|---|---|---|---|
| G1 | O objeto é `JOB_de_Solicitacao_de_Treinamentos__c` ("JOB de Solicitação de Treinamentos")? Se não, qual dos outros 4? | P4 | **Sim** |
| G2 | Nível de acesso (ler / criar / editar / excluir; só os próprios ou de todos) e sintoma exato (mensagem em texto, sem dado de registro). | P2, P3 | **Sim** |
| G3 | Em qual org foi feito o "acesso para o perfil do usuário", o que mudou, se o colaborador confirmou, e se esse ajuste deve ser revertido depois do PS. | P1, P6 | Não para o build; sim para encerrar |
| G4 | Perfil e licença do colaborador (só o nome do perfil e o tipo de licença, sem identificar a pessoa no card). Sem isso, R2 e R6 não são testáveis. | P5 | Não para criar o PS; sim para o QA reproduzir |
| G5 | O problema é isolado ou recorrente (outros colaboradores)? | P8 | Não; se for recorrente, muda o escopo |
| G6 | Quem autoriza a concessão de acesso no cliente? | P11 | Não para o build; sim para a atribuição em produção |
| G7 | Escolha entre Opção A (só documentar o ajuste já feito) e Opção B (este design, com permission set). | P10 | **Sim**: com A, não há build |
| G8 | O `CLAUDE.md` do cliente ainda tem placeholders de URL e versão de API das sandboxes. | P14 | Não bloqueia; recomendável preencher |

## 10. Estimativa refinada

**Estimativa de esforço:** 2–4 h

O que mudou em relação à análise (1–5 h) e por quê:
- **Sai o piso de 1 h:** a Opção A (só validar) não resolve o critério 2. Com a Opção B recomendada, há build e teste em dev e QA.
- **O teto cai de 5 h para 4 h:** o recon mostrou zero automação no objeto, nenhum código e nenhuma mudança de compartilhamento. A investigação de licença e compartilhamento, que pesava no teto, se reduz a reproduzir o bloqueio com um usuário de teste.
- **Composição:** cerca de 0,5 h para o humano responder G1, G2 e G4; 1 a 1,5 h para revisar o PS e a FLS com o solicitante e revisar o PR; 0,5 a 1 h para homologar; 0,5 a 1 h para a atribuição em produção e o encerramento pelo humano.
- **Atenção:** o cliente aprovou **2 h** no card. Isso cabe no piso desta faixa. Se G1 apontar outro objeto ou se R2 ou R4 se materializarem, a faixa passa de 2 h e a estimativa precisa ser reapresentada ao cliente.
- Esta faixa não inclui o tempo do agente nem a migração de perfis (achado #6).

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
