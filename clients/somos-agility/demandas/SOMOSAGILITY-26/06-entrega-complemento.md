# SOMOSAGILITY-26 — Documentação da entrega (complemento do 06-entrega.md)

**Cliente:** somos-agility · **Data:** 2026-11-26 · **Org consultada:** `sbx-somos-agility-qa` (Sandbox, Connected; única org conectada, confirmada com `sf org list`). Produção não foi tocada.
**Complementa** `06-entrega.md`, gravado pelo release (deploy na QA). Aquele arquivo não foi alterado; o que está aqui é o que falta para os três leitores (cliente, subida em produção, manutenção).

## Situação

- Entregue na sandbox de QA. Homologação aprovada em `gates.md` (2026-11-26, commit `06ddf202`) sobre `05-testes.md` com veredito aprovado (rodada 3).
- Não entregue em produção. Subir em produção é ato humano (seção 5).
- **Há um pedido novo no card, de 26/11 11:56, ainda não tratado (pendência 1).**

## Pendências abertas

Cada item sem resposta vem com quem decide. Nenhuma foi resolvida por inferência.

1. **Pedido novo no card (26/11 11:56), fora do escopo entregue.** Pede a criação de `Cotacao__c`, `Proposta_Acabada__c`, `Informa_es_T_cnicas_Complementares__c` e as versões `_2` e `_3` de cada um, como Área de texto longo (32768). São 9 campos. O comentário não indica o objeto. Os três nomes coincidem com campos da conversão "Cenário 1" que o design (`03-design.md`, seção 9) excluiu desta demanda. **Não construído, não desenhado, não implantado.** Decisão do responsável: entra nesta demanda (volta ao gate de análise e ao de design) ou vira demanda nova.
2. **Versão do Flow ativa em produção: não registrada.** Precisa ser conferida e anotada antes da subida. Na dev o design previa "v1 ativa, única" e estava errado (a dev tinha v2 ativa). Responsável: consultor que sobe.
3. **Ativação da nova versão do Flow em produção:** passo humano, depois do deploy e da conferência dos layouts.
4. **FLS dos 9 campos nos perfis que o cliente usa em produção:** conferência humana. Perfis diferem entre orgs.
5. **Fórmula `FVP.PFP1UNCPath__c` = `'a'` na QA** (na dev é `PropostaSolucao__r.PFP_1__c`). Campo antigo, fora desta entrega. Cabe ao time confirmar se é rascunho de sandbox antes de produção.
6. **Premissas P1 a P5 e G5 do design** (relatórios, Conga/SDocs, SnapERP): não testáveis na sandbox. Seguem para validação com o cliente.
7. **Estado do Flow na dev divergente entre artefatos.** `04-plano-build.md` diz v2 Active e v3 Draft. `04-verificacao.md` observou v3 Active e v2 Obsolete. `06-entrega.md` repete o primeiro. A dev não está conectada nesta sessão; não foi possível conferir. Não afeta a QA, onde a consulta desta etapa mostrou só a v3 Active.
8. **Registro de C9 em `05-testes.md` inconsistente.** Diz "passou na dev (V7 de `04-verificacao.md`)", mas o V7 desse arquivo está "não executado". C9 não tem prova em dev nem em QA; só a análise da fórmula (item 5). Fica registrado; o veredito de QA não depende dele.
9. **PR da demanda: não localizado.** Os artefatos não trazem o número, e a `gh` não tem token nesta sessão. O card cita o PR #227 como correção da esteira (layouts com acento); não foi confirmado se é desta demanda.

## 1. O que foi entregue (para o cliente)

- **Três campos novos de texto longo, "PFP 1", "PFP 2" e "PFP 3",** em três lugares: Blueprint (BluePrint), Proposta de Solução e Fluxo de Venda de Produtos. Cada um aceita até 32.768 caracteres.
- **Onde aparecem:** logo abaixo dos campos "PFP 1/2/3 (UNC Path)" já existentes, nas telas (layouts) que hoje mostram os antigos. São 16 telas no total: 1 do Blueprint, 10 da Proposta de Solução e 5 do Fluxo de Venda de Produtos.
- **O que passa a acontecer sozinho:** ao criar ou atualizar uma Proposta de Solução numa oportunidade que tenha Blueprint, o texto de "PFP 1/2/3" do Blueprint é copiado para a Proposta. Os campos "PFP 1/2/3 (UNC Path)" continuam sendo preenchidos como antes. Um valor já digitado na Proposta não é sobrescrito, nos dois tipos de campo.
- **Quem é afetado:** quem trabalha com Blueprint, Proposta de Solução e Fluxo de Venda de Produtos. Os perfis e conjuntos de permissão que já liam ou editavam os campos "PFP (UNC Path)" receberam acesso aos novos, com o mesmo nível. Não houve atribuição de usuário nem perfil novo.
- **O que não mudou:** os campos "PFP 1/2/3 (UNC Path)" continuam com o mesmo tipo e tamanho e seguem nas telas. Nenhum dado existente foi alterado. Nenhum campo foi apagado.
- **Limitações (o que a entrega não faz):**
  - Não copia para os campos novos o que já estava nos antigos. Só o que for escrito no Blueprint a partir de agora é copiado. Histórico (322 Blueprints e 1.475 Propostas na QA) fica como está.
  - No Fluxo de Venda de Produtos, os campos novos são digitados à mão. Nada os preenche sozinho.
  - Não valida formato. Aceita qualquer texto, e o caminho ou link não vira clicável.
  - Relatórios, documentos gerados (Conga, SDocs) e integração SnapERP não foram verificados. Só a homologação com o cliente confirma se algum deles lê os campos antigos.
- **O que a pessoa precisa saber na tela:** existem dois campos com nome parecido ("PFP 1" e "PFP 1 (UNC Path)"). O novo é o texto. O "(UNC Path)" é o caminho de rede que já existia.

## 2. O que mudou em relação ao pedido e ao desenho

- **Pedido original** (`01-analise.md`, aprovado em 10/11): cinco campos de "Cenário SF", com a dúvida entre aumentar o tamanho, converter para Long Text ou para URL.
- **Especificação do card** (17/11): nove campos novos "PFP 1/2/3" em área de texto longo nos três objetos, e ajuste do Flow sem mudar a lógica. Essa virou o escopo. A análise não foi reescrita; o desenho registra a troca.
- **Desenho aceito** (`03-design.md`, 20/11): os nove campos, mais o Flow em nova versão, com a opção G1-b (a nova versão copia para os campos novos e continua copiando o antigo para o antigo, para não quebrar as fórmulas do Fluxo).
- **Versão do Flow:** o desenho previa a "v2". A dev já tinha uma v2 ativa, então a versão nova ficou como **v3**. O conteúdo corresponde ao que foi desenhado.
- **Estimativa:** aprovada pelo cliente em 3 h. O desenho deu 5,5 a 7,5 h, e o responsável decidiu seguir. O card registra que o alinhamento das horas com o cliente ficaria com o Leonardo; não há registro no artefato de que isso foi feito.
- **Desvios do desenho e do build:**
  - No layout de Blueprint, o campo antigo é obrigatório e o novo não é.
  - No Fluxo de Venda de Produtos, o antigo é fórmula (só leitura) e o novo é editável (premissa P2).
  - Os campos antigos não foram convertidos nem removidos (decisão do desenho, seção 9).
- **Fora desta entrega:** a conversão dos campos "Cenário 1" e a migração de dados antigos para os novos. O pedido de 26/11 (pendência 1) toca isso.

## 3. Componentes (API name)

| Tipo | Nome | Papel |
|---|---|---|
| CustomField (9) | `PFP_1_Texto__c`, `PFP_2_Texto__c`, `PFP_3_Texto__c` em `BluePrint__c`, `Propostas_de_Solucao__c` e `FluxoVendaProdutos__c` | Texto longo de 32.768, rótulo "PFP 1/2/3", descrição preenchida |
| Layout (16) | 1 de `BluePrint__c`, 10 de `Propostas_de_Solucao__c`, 5 de `FluxoVendaProdutos__c` | Mostram os campos novos logo abaixo dos antigos. Lista completa em `05-deploy-qa.md` |
| Flow (1) | `Atualiza_os_Campos_PFP_X_UNC_Path_se_PSL_Criada_ou_Atualizada` | Copia o Blueprint para a Proposta. Na QA: v3 Active, única versão (consulta de hoje) |
| Profile (66) e PermissionSet (2: `DiretorComercial`, `Acesso_completo_Esteira_de_vendas_e_renovacoes`) | Só as `fieldPermissions` dos 9 campos (573 linhas) | Permissão de leitura e edição nos campos novos |

Os perfis e permission sets no repositório são **parciais**. Contêm só os blocos desta demanda. Não servem de backup do perfil nem devem ser reimplantados inteiros.

## 4. Como funciona (manutenção)

**Disparo:** a Proposta de Solução (`Propostas_de_Solucao__c`) é criada ou atualizada. O Flow é after-save, em criação e atualização, e só entra quando `Oportunidade__c` está preenchido.

**Passos, para cada um dos três campos (N = 1, 2, 3):**
1. Verifica se `PFP_N_Texto__c` da Proposta está vazio.
2. Se estiver, copia `Oportunidade__r.BluePrint__r.PFP_N_Texto__c` para `PFP_N_Texto__c` da Proposta.
3. Faz a cópia do antigo: `PFP_N__c` recebe o `PFP_N_UNC_Path__c` do Blueprint, só se estiver vazio. É a fórmula `IF(ISBLANK(PFP_N__c), BluePrint.PFP_N_UNC_Path__c, PFP_N__c)`.
4. Cada cópia é uma gravação separada no mesmo registro. Com os três campos, são até 6 gravações por salvamento da Proposta (conta do design, G1-b).

**Limitação da lógica (herdada, aceita):** o passo 1 testa só o campo novo. Se a Proposta tiver o campo novo preenchido e o antigo vazio, o antigo não é copiado.

**Onde mexer:**
- Tamanho: 32.768 nos três objetos. Os três precisam ser iguais (destino igual ou maior que a origem). Se mudar em um, mudar nos três.
- Texto do Flow (critério, cópias): nova versão do Flow, nunca editar a versão ativa.
- Permissão: espelhada por campo, em cada perfil e permission set. Mudança de acesso exige editar cada um.
- Não há Custom Metadata nem valor de picklist nesta entrega.

**Decisões não óbvias:**
- Campo novo, e não conversão do antigo. Fórmula não lê nem devolve Long Text Area, e os antigos alimentam fórmulas (`FluxoVendaProdutos__c.PFPNUNCPath__c` e `Propostas_de_Solucao__c.PFP_N_UNC_Path__c`).
- O antigo continua sendo copiado (G1-b). A alternativa descartada era parar de copiar, o que quebraria as telas do Fluxo.
- Referência direta no lugar de fórmula de texto para copiar o campo novo. Motivo: não foi confirmado como fórmula de Flow trata texto acima de 255 (incerteza I3 do desenho).
- Campos do Fluxo de Venda de Produtos sem automação (premissa P2). Alimentar esses campos exige desenho novo (opção G1-c).
- Sem Apex. Nenhum critério da doutrina para Apex se aplicava.

**O que mais roda e pode interferir:**
- Proposta de Solução: 5 Flows after-save (incluindo o desta demanda, sem `triggerOrder`) e o trigger `TrgPropostasSolucao`. A ordem entre eles não é definida.
- Blueprint: `Atualiza_Campo_Blueprint_da_Oportunidade` (after-save).
- Fluxo de Venda de Produtos: 4 Flows (`Definir_BOM`, `SolicitacaoPrecos`, `Replica_o_status_da_FVP_para_PSL` e `EmailOrcamentista`).
- Oportunidade: 31 automações ativas no assessment. Esta entrega não as altera.
- Validation rules: as 15 ativas nos três objetos não citam os campos novos.

**Como testar de novo:**
- Dados: sintéticos, com nome `TESTE SOMOSAGILITY-26`. A cadeia exige Oportunidade com Orçamentista, Autor e telefone preenchidos, para passar nas validation rules. Blueprint ligado à Oportunidade; Proposta ligada à Oportunidade; Fluxo de Venda de Produtos ligado à Proposta.
- Casos: C1 a C13 de `05-testes.md`. Roteiro em linguagem de usuário: `05-roteiro-cliente.md` (7 testes).
- Limpeza: os registros de teste da rodada 3 foram apagados (`05-testes.md`, seção "O que pode ter saído da org").

## 5. Subida em produção (consultor)

Dono de cada passo: consultor responsável pela demanda (nome a registrar na subida; não consta nos artefatos).

Sequência, conforme `06-entrega.md` (passos manuais 1 a 6). Pontos específicos desta demanda:
1. Antes de tudo: registrar a versão ativa do Flow em produção. Sem isso não há rollback do Flow.
2. Deploy do pacote: campos, depois layouts, FLS e Flow (que entra em Draft).
3. Ativar a nova versão do Flow só depois de conferir os campos nos layouts.
4. Conferir o FLS dos 9 campos nos perfis que o cliente usa.
5. Não subir o perfil ou permission set do repositório inteiro. Usar só o bloco desta demanda.

**Conferir logo depois de subir:** os 9 campos aparecem nos layouts; uma Proposta nova recebe o texto do Blueprint; o campo "PFP x (UNC Path)" continua recebendo o caminho; não há erro ao salvar Proposta.

**Sinal de que é preciso voltar:** Proposta salva sem o texto do Blueprint; erro no Flow nas primeiras Propostas (observar na primeira hora e no primeiro dia útil); usuário perder acesso a campo antigo.

**Rollback:** ordem inversa do deploy, como em `06-entrega.md`. Atenção: rollback de metadata não desfaz dado. Textos gravados nos campos novos e valores copiados para os antigos enquanto a nova versão do Flow esteve ativa ficam. Na QA, há 1.475 Propostas sujeitas a isso.

## 6. Dívida e limitações

**Limitações aceitas**, com quem aceitou (gate de design, 20/11, Leonardo Barbosa):
- Campos antigos ficam no layout até decisão de migração (G4).
- Premissas de consumidores externos (G5) como risco a validar.
- Estimativa acima das 3 h aprovadas.

**Dívida técnica (uma linha cada, para virar card):**
- FLS espelhada em 66 perfis e 2 permission sets por campo. Efeito do perfil por pessoa (20 de 26 perfis com um usuário).
- Perfis e permission sets do repositório são parciais. Risco de reimplantar o arquivo inteiro e apagar permissões.
- Flow faz até 6 gravações por salvamento da Proposta, sem ordem definida entre os Flows after-save. Risco de recursão e interferência.
- Flow só testa o campo novo vazio para copiar o antigo.
- Dados históricos não migrados (322 Blueprints e 1.475 Propostas na QA).
- Dois campos "PFP 1" na mesma tela, com nomes parecidos.
- Fórmula `FVP.PFP1UNCPath__c` = `'a'` na QA, diferente da dev. Confirmar antes de produção.
- Premissas P1 a P5 e G5 não testadas.
- Estado da versão do Flow na dev divergente entre artefatos (pendência 7).
- Registro de C9 em `05-testes.md` sem prova (pendência 8).
- Sem validação de formato nem link clicável (decisão do desenho, seção 9).
- Esteira: 9 de 16 layouts com acento ficaram fora do pacote da QA na rodada 2; o card aponta correção no PR #227. Dívida da esteira, não desta demanda.

**Falha branda do QA que não impediu a aprovação:** C12, a tela da PSL de teste mostra só o topo da aba Detalhes; a prova dos 16 layouts é o retrieve. A conferência visual fica no roteiro do cliente.

**Sugestões para demanda futura (uma linha cada):**
- Migrar os valores dos campos antigos para os novos e aposentar os antigos (design, seção 9).
- Trocar as permissões por perfil por um permission set único (exige decisão de modelo de acesso).
- Alimentar os campos do Fluxo de Venda de Produtos a partir da Proposta (G1-c, com novo desenho).
- Validar formato de caminho ou link.
- Conversão dos campos "Cenário 1" (ver pendência 1).

## 7. Rastreabilidade

- **Demanda:** SOMOSAGILITY-26 · **Cliente:** somos-agility · **Tipo:** sustentação (design enxuto).
- **Branch:** `feature/SOMOSAGILITY-26` · **Commit do release:** `06ddf202` · **PR:** não localizado (pendência 9).
- **Deploys na QA** (`sbx-somos-agility-qa`):
  - Real, 2026-11-26T12:00Z: `0AfHa00000EPER7KAP` (Succeeded, 94/94).
  - Dry-run: `0AfHa00000EPEPVKA5` (Succeeded).
  - Anterior da esteira, 2026-11-20T23:36Z, commit `d36dd65f`: `0AfHa00000EM4PtKAL` (Succeeded).
  - Falhas anteriores: `0AfHa00000EM3aHKAT` (permission set com app que só existe na dev) e `0AfHa00000EM4CzKAL` (16 layouts incompletos).
- **Dev:** `sbx-somos-agility-dev` (build e verificação). Não conectada nesta sessão.
- **Produção:** não tocada. Nenhum deploy, DML ou anonymous Apex fora da sandbox.
- **Gates** (`gates.md`):
  - Análise: 2026-11-10, commit `3fba5e20`.
  - Design: 2026-11-20, commit `79eceff3`.
  - Build: 2026-11-20, commits `dcf3e040`, `6b798860` e `d36dd65f`.
  - Homologação: 2026-11-26, commit `06ddf202`.
- **Relacionadas:** o desenho cita SOMOSAGILITY-10 (cenário de pai com muitos filhos, que a opção G1-c reabriria) e SOMOSAGILITY-23 (diagnóstico, cujo PR motivou a regra de não copiar retrieve para o PR). Nenhuma delas é corrigida ou estendida por esta demanda.
- **Histórico (RAG):** consulta feita; nenhuma demanda anterior do cliente sobre estes campos foi encontrada.
- **Data desta documentação:** 2026-11-26.
