# Delivery Salesforce com Agentes — doutrina detalhada

> Este é o texto completo que morava no `CLAUDE.md` da raiz até 2026-11-14. Saiu de lá
> porque o `CLAUDE.md` é relido a cada turno de toda sessão de agente (93% dos tokens da
> esteira eram releitura de contexto) e a maior parte disto só interessa a quem altera a
> esteira ou o Squad OS. O `CLAUDE.md` ficou com as regras; aqui ficam o porquê, os
> achados e o funcionamento. **Mudou uma regra? Atualize os dois.**

Squad de agentes que constrói soluções Salesforce a partir de **demandas** registradas por
consultores — o papel que uma estória de Jira teria em outros contextos, aqui é um registro
de demanda dentro deste repositório (veja `sfagents demanda --help`). Modelo: **humano +
agente em co-construção**. Agente nunca entrega sozinho.

## Regra de ouro
Toda demanda passa por **gates humanos bloqueantes**. O agente para e espera aprovação
explícita. Não existe "vou seguindo e depois você revisa".

## Fluxo canônico

| # | Etapa | Agente | Gate |
|---|-------|--------|------|
| 1 | Ler a demanda, refinar critérios de aceite | `ba-discovery` | Humano aprova o refinamento |
| 2 | Recon da org (o que já existe) | `recon` (skill `org-recon`) | — |
| 3 | Desenho da solução (declarativo vs código) | `arquiteto` | **BLOQUEANTE** — arquiteto humano aprova |
| 4 | Build em branch + sandbox de dev, e verificação | `builder-declarativo` / `dev-apex`, depois `verificador` | PR obrigatório |
| 5 | Testes na sandbox de QA | `qa` | Cliente homologa |
| 6 | Empacotamento e registro da entrega na sandbox de QA | `release` | **Prod: proibido ao agente** |
| 7 | Documentação de entrega | `doc` | Spot check |

Antes da etapa 1 de todo cliente novo vem o **assessment da org** (`org-assessment`,
`run-assessment.yml`): diagnóstico read-only da saúde da org, que vira `assessment.md` +
`assessment.json` em `clients/<cliente>/` e o bloco "Saúde da org" no perfil do cliente no
Squad OS. Dispara sozinho quando a org de dev conecta pela primeira vez. Não é demanda —
não tem `status.yaml` nem gate; é o que evita desenhar solução numa org desconhecida. Desde 2026-11-01 o assessment
também é **contexto de toda etapa de demanda**: `assessment.nota_para_o_prompt` põe saúde,
resumo e recomendações no prompt da sessão, e os agentes de análise, design, build e QA
leem `assessment.md` — a análise registra os riscos que tocam o pedido e o design diz como
lida com eles. Antes disso ele só aparecia no perfil do cliente.

Num cliente de **contrato de projeto**, as demandas não precisam ser digitadas uma a uma:
o agente `planejador` (`run-planejamento.yml`) lê os entregáveis contratados e propõe as
demandas que eles viram, que entram no quadro em `backlog`. Ele não toca em org nenhuma,
não decide declarativo vs. código e não materializa nada — quem decide o que vira esteira
continua sendo o humano.

O orquestrador (sessão principal) roteia entre agentes. Nunca pula etapa.
Cada subagente é acionado uma única vez, em primeiro plano: a execução em background fica
desligada na sessão (`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`). Achado da EPLAST-47 (2026-11-14):
o orquestrador acionou o `builder-declarativo` em background e de novo em seguida; os dois
escreveram na mesma pasta e na mesma sandbox e a etapa terminou sem build.

## Como a conta é vendida muda o que o time acompanha

O `Contrato` de cada cliente é **AMS** ou **projeto**, e a aba Contrato do Squad OS mostra
coisas diferentes porque as perguntas são diferentes:

- **AMS** — horas contratadas por ciclo, SLA por severidade, e o consumo mês a mês contra
  o contratado. A pergunta é "quanto do balde já foi?".
- **Projeto** — cadastro, entregáveis com peso e progresso ponderado. A pergunta é "quanto
  do escopo já saiu?". O peso existe porque "migrar 12 Flows" e "ajustar um layout"
  contariam igual numa média simples, e o progresso mentiria perto do fim.
  O progresso é calculado das demandas, não marcado à mão (decisão de 2026-11-16): cada
  demanda de projeto não cancelada avança conforme a etapa (`AVANCO_POR_STATUS` em
  `lib/contrato.ts`; homologação pendente vale 85%, só `entregue` vale 100%). Entregável
  com demanda segue a média delas; entregável sem demanda (feito fora da esteira) segue a
  marcação manual; demanda de projeto sem entregável conta como peso 1.

As horas vêm dos `RegistroTempo` das demandas do cliente, agrupadas pelo mês em que o
trabalho aconteceu (`inicioEm`), não pelo mês do lançamento. Cronômetro ainda rodando não
entra: hora que não fechou não é hora gasta.

## O ciclo anda sozinho — e onde ele para

Ninguém abre o GitHub Actions pra mover uma demanda. `src/salesforce_agents/fluxo.py`
roda a etapa atual, avança até o próximo gate e devolve o controle; o sync de volta
(`/api/sync/demanda`) faz o quadro do Squad OS mostrar o gate esperando; quando alguém
aprova no card, a próxima etapa dispara sozinha. Detalhes em `docs/ativacao.md`.

Toda rota `/api/sync/*` autentica por bearer token (`lib/sync-auth.ts`), comparado em tempo
constante — e, desde o achado do council de 2026-10-01, por **cliente**: um token único e
global (`SQUAD_OS_SYNC_TOKEN`) comprometia os 6 clientes ao mesmo tempo se vazasse (igual
aprovar qualquer gate de qualquer cliente remotamente, sem passar por nenhum dos guardrails
de produção, que pressupõem aprovação humana legítima antes de chegar neles). Um cliente
migrado pra `SQUAD_OS_SYNC_TOKEN_<CLIENTE>` deixa de aceitar o token global pra ele —
migração real, não mais uma chave que também abre a porta (passo a passo em
`docs/conexoes-e-setup.md`). `run-planejamento.yml` ainda fica de fora dessa segmentação —
é o único workflow de propósito sem GitHub Environment (não toca em org), e Environment é
o mecanismo que torna o token por cliente possível do lado do Actions.

Isso **não afrouxa a regra de ouro**: toda etapa de agente continua sendo seguida por um
gate humano bloqueante — essa invariante tem teste (`tests/test_fluxo.py`). O que ficou
automático é a borda: agente→humano (o gate aparece pra quem precisa ver) e humano→agente
(aprovar aciona). O que era manual antes era o transporte, não a decisão.

**Fila de disparo por cliente** (2026-10-21): o Squad OS nunca dispara `run-demand.yml`
direto — aprovação de gate e envio para a esteira entram em `DisparoEsteira`
(`lib/fila-esteira.ts`) e saem um por vez, só com o cliente livre no Actions. Motivo: o
concurrency group `demanda-<cliente>` guarda **um** pendente só, e o seguinte cancela o
anterior em silêncio. Achado real: 7 gates da Somos aprovados em 6 minutos, 5 cancelados
sem ninguém saber, e o card ainda dizia "liberado". Quem esvazia a fila: a própria
aprovação (cliente livre), o sync de fim de execução e a varredura de hora em hora
(`/api/sync/fila`), que também devolve à fila o que o Actions cancelou antes de rodar.

**Esteira ao vivo** (`/esteira` no Squad OS, 2026-10-21): durante a sessão,
`src/salesforce_agents/ao_vivo.py` manda eventos para `/api/sync/evento` — começou,
qual subagente entrou, que ferramenta chamou (nome do arquivo sem caminho, as três
primeiras palavras de um comando), custo do turno, terminou. **Só metadata**
(guardrail #2): nunca texto do modelo, conteúdo de arquivo, padrão de busca ou
argumento de SOQL. Best-effort: sem URL/token vira no-op e falha de rede nunca derruba
a sessão. Eventos ficam 7 dias; o histórico durável é `ExecucaoAgente` (/falhas).

**Build bloqueado volta ao gate de design** (2026-11-12): quando o agente de build não
constrói nada por falta de resposta, ele escreve `**Resultado do build:** bloqueado` no
topo do `04-plano-build.md`, e `fluxo.py` devolve a demanda a `aguardando_gate_design` em
vez de seguir para o gate de build (`bloqueio.py`); o plano bloqueado é apagado antes de o
build rodar de novo. O portal recusa aprovar um gate de build com plano bloqueado
(`lib/build-bloqueado.ts`). Achado real: cinco demandas da Somos chegaram à homologação
sem nada construído, com os gates de build aprovados sobre um aviso de bloqueio.

**Reaprovar o design sem resposta não refaz o build** (2026-11-23): no bloqueio, a esteira
guarda em `04-bloqueio-insumos.txt` uma impressão do que o construtor leu (`03-design.md` e
os comentários de gente no card, sem as linhas automáticas "Aprovou o gate" e "Aprovou a
estimativa"). Uma nova aprovação do gate de design com a mesma impressão é recusada
(`fluxo.aprovar_gate`, `GateSemMudancaError`): o job termina verde, a demanda fica no gate e
nada é registrado em `gates.md`. O card do gate de design mostra no topo o começo do plano
bloqueado, com a pergunta (`revisao.artefato_em_revisao`). Achado real: SOMOSAGILITY-30 teve
o gate de design aprovado sete vezes num dia sem a resposta, e cada aprovação rodou o
construtor para ele bloquear igual.

**QA é a porta para o cliente** (2026-11-14): depois da etapa `qa`, a demanda só chega à
homologação com evidência de aprovação — `**Veredito:** aprovado` e `**Org de teste:**`
igual à sandbox de QA do cliente (`veredito.py`). Reprovado, sem veredito ou org errada: o
roteiro vira `05-testes-rodada-<n>.md`, a demanda volta para `build` e o Squad OS põe o
build refeito na fila sozinho (motivo `refazer` no sync). O build corrigido passa de novo
pelo gate de PR antes de voltar ao QA — cada volta tem um humano no meio. Depois de duas
reprovações seguidas a demanda para no gate de design, para o arquiteto decidir. Achado
real: dez demandas (Eplast e Somos) estavam em homologação com o QA reprovado, porque o
fluxo só conferia se o `05-testes.md` existia.

**O QA reprovado vai para quem resolve** (2026-11-25): cada `### FALHA` do roteiro traz
`**Origem:** construção | ambiente | não exercitado` (skill `provar-criterio`), e
`veredito.py` lê a linha. Se há alguma falha de construção (ou sem a linha, que conta como
construção), nada muda: a demanda volta para `build`. Se **nenhuma** falha é de construção,
refazer o build não muda o resultado, então a demanda para em `aguardando_gate_build`, com
uma pessoa: o card abre com "O QA não conseguiu provar" e a lista do que falta
(`revisao.py`); ela resolve o ambiente e aprova, e a aprovação leva ao deploy em QA e ao
QA, sem passar pelo construtor. Essa rodada não conta para o teto de duas voltas, que mede
tentativas de construção. O portal não lê a origem: só o motor decide por ela. Achado
real: medição em 36 demandas, 71 falhas de QA, das quais cerca de 27 eram "não consegui
executar" e 14 de ambiente; SOMOSAGILITY-22, SOMOSAGILITY-27 e EPLAST-40 voltaram ao
builder e repetiram a mesma falha na rodada seguinte, gastando um build e uma verificação
cada.

Nova versão antes de implementar (2026-11-15): o deploy da EPLAST-27 na QA foi recusado
porque alterava a versão ativa do agente `SFAgent2`, e a validação da EPLAST-33 foi recusada
porque reimplantava classes Apex com job agendado. Decisão do responsável: Flow, agente e
classe que já existem ganham uma versão nova, implantada sem substituir a que está em uso,
e a ativação é passo separado, registrado no plano ("Versões e ativação"). Regra completa na
skill `salesforce-doutrina`.

Verificação do build (2026-11-15): o gate de build chegava ao revisor sem ninguém ter
exercitado a construção; o builder só provava que a metadata era aceita, e o primeiro teste
de comportamento era o QA, depois do gate. Decisão do responsável: precisa existir uma etapa
em que o agente testa, evidencia e confirma que funciona, e só depois o humano é chamado.
Ficou dentro da etapa de build, sem status novo: depois do construtor, o `verificador` testa
na sandbox de dev contra os critérios de aceite, com dado sintético que ele cria e apaga, e
grava `04-verificacao.md` (`verificacao.py`). Aprovada segue para o gate, e o card mostra a
evidência logo abaixo do plano. Reprovada vira `04-verificacao-rodada-<n>.md` e a construção
roda de novo, disparada pelo Squad OS como no QA reprovado; depois de
`MAX_VOLTAS_DA_VERIFICACAO` (2) quem decide é o arquiteto, no gate de design. Inconclusiva
(não há como disparar na dev, depende de sistema externo) vai ao gate mesmo assim, porque
refazer não resolve, e diz o que ficou sem prova. O QA na sandbox de QA continua existindo:
é outro teste, em outra org, antes do cliente.

Teste com sistema externo na cadeia (2026-11-15): na EPLAST-47 a primeira verificação saiu
inconclusiva porque criar oportunidade ganha dispara pedido, cotação, CPQ e a integração
Protheus, e a linha de base mostra a sandbox apontando para o endereço cadastrado como
produção do ERP. O responsável pela conta decidiu testar mesmo assim. Regra que ficou: o
`verificador` e o `qa` criam os próprios dados e executam; quando a cadeia chama sistema
externo que não dá para isolar, só disparam com autorização escrita do responsável no card
(`comentarios-do-card.md`), usam o mínimo de registros e listam o que pode ter saído da org.

Autorização para toda a esteira (2026-11-15, decisão do responsável): pedir autorização card
a card deixou seis de nove verificações da Eplast inconclusivas (26, 28, 29, 30, 36, 39) sem
defeito nenhum, só por falta do comentário. Desde então criar dados de teste, deixar a
automação da solução rodar (inclusive agendada, em duas fases) e ativar na QA a versão nova
de um agente para testar valem para toda demanda de todo cliente, sem comentário no card.
Em 2026-11-20 (achado SOMOSAGILITY-26) o responsável estendeu explicitamente a Flow e a
modelo de prompt, também quando a QA não tem versão ativa anterior: o QA da Somos Agility
leu o aviso do preflight ("versão ativa não é alterada no lugar") como proibição de ativar e
reprovou sem exercitar o centro da demanda. O aviso passou a dizer que fala do conteúdo. O
que continua: só sintético, `TESTE <DEMAND-ID>` no nome, o mínimo que prova o critério,
nunca tocar em registro que o agente não criou, e a seção "O que pode ter saído da org". O
`CLAUDE.md` do cliente ou um comentário no card podem proibir, e aí vale a proibição. Para
rodar de novo só a verificação de um build parado no gate de build, sem reconstruir, há
`run-demand.yml` com `reverificar` (`sfagents demanda rodar --reverificar`).

Fila por sandbox e QA agendado curto (2026-11-15, decisão do responsável): a fila de
disparo segurava o cliente inteiro, e a dev ficava parada enquanto a QA testava; o guardrail
#6 é por sandbox. A fila (`lib/fila-esteira.ts`) passou a deixar um disparo em voo por
cliente e ambiente, e o concurrency group do `run-demand.yml` virou cliente + ambiente.
Run do cliente que a fila não conhece continua segurando tudo. No QA em duas fases, o
agente arma para no máximo 1 hora à frente (16/11: encurtado para 5–10 minutos, com conferência 10 minutos depois do disparo; a EPLAST-33 segurou a QA por 50 minutos com um job de 20) (parâmetro da solução, job agendado para daqui a
15–30 min, ou Flow agendado com o horário trocado só na QA, sem commit), e o sync
reenfileira a segunda sessão com `liberar_em` = `Conferir depois de` + 5 min; a varredura
roda de 15 em 15 minutos e a dispara.

Conferência sobre o arme (2026-11-16, achado EPLAST-28): o passo de deploy em QA reimplantava o
build antes da sessão de conferência; recriar o Flow agendado trocou o `CronTrigger` do arme
por um novo, sem `PreviousFireTime`, e o QA reprovou sem como provar que o alerta rodou.
Agora, quando `05-testes.md` está em `aguardando execução` e já passou do `Conferir depois
de`, o deploy é pulado antes da sessão e feito depois dela (passo "Reimplantar o build
original na QA", `scripts/implantar-build-qa.sh`). Antes do horário continua como era:
reimplanta antes, e o QA arma de novo.

Usuário de execução na dev (2026-11-15, decisão do responsável): na reverificação da EPLAST-36
a Oportunidade de teste não pôde ser criada porque a validation rule exige "ID Usuário
Protheus" no proprietário, e o proprietário é o usuário com que o job autentica, que o agente
não criou. Não há licença livre para usuário de teste. Ficou permitido ao `verificador`
preencher, só na sandbox de dev, campo que validação exige no próprio usuário de execução,
com valor sintético, registrando antes e depois e devolvendo o valor de antes ao final.

QA em duas fases (2026-11-15): o `ScheduledFlowOpportunity` da EPLAST-47 só roda às 15:47
UTC, não dispara à mão, e a sessão de QA acaba em minutos; o QA reprovava sem defeito
nenhum. Com autorização do responsável no card, a primeira sessão registra o estado de
antes por contagens, muda o parâmetro de execução da própria solução na sandbox de QA e
grava `**Veredito:** aguardando execução` com `**Conferir depois de:**`. O fluxo devolve
`motivo=aguardar` e a demanda fica em `qa`, sem voltar ao build e sem chamar o cliente
(`veredito.Veredito.pendente`). A segunda sessão é disparada por gente depois do horário
(`run-demand.yml` sem aprovação de gate); o passo de deploy em QA reimplanta a configuração
original, e o QA confere antes e depois e dá o veredito final. Não há disparo automático
da segunda sessão: o Squad OS só reenfileira em `refazer`.

Deploy em QA (2026-11-15): o build só toca a sandbox de dev e o QA só testa, e até aqui
ninguém levava o pacote de uma para a outra antes do teste; o `release` faz isso só depois
da homologação. Na EPLAST-47 o QA reprovou em um minuto ("o build não está na QA"), o
builder respondeu que não podia corrigir, e a demanda rodava em círculo. O `run-demand.yml`
ganhou um passo fixo, antes da sessão de QA: implanta em `sbx-<cliente>-qa` só o que a
branch mudou no `force-app` (`scripts/pacote_da_demanda.py`; sem Apex, sem teste; com Apex,
só os `<Classe>Test` da demanda) e grava `05-deploy-qa.md`. Se o deploy falha, o job falha
antes de o gate de build ser aprovado. Arquivo removido na demanda não é apagado da org.
No mesmo achado: o agente de QA gravou uma cópia do roteiro como `05-testes-rodada-1.md`;
a esteira passou a apagar qualquer arquivo de rodada criado pela sessão.

Trabalho pendente trava o deploy em QA (2026-11-17, achado EPLAST-33): a demanda tem classe
agendável e batch, o QA em duas fases deixou o trabalho armado na sandbox de QA e, no
redesenho, o deploy do mesmo pacote caiu inteiro ("essa classe programável tem trabalhos
pendentes ou em andamento"), com o gate de build já aprovado e sem defeito no build. Quando
TODAS as falhas do deploy são essa (`scripts/jobs_pendentes.py`), o `implantar-build-qa.sh`
cancela só os trabalhos que a plataforma citou, que são os das classes do pacote, e
reimplanta. O que foi cancelado fica em `05-deploy-qa.md`; a esteira não rearma, porque quem
arma é o QA no teste ou a ativação. Havendo outra falha junto, nada é cancelado. A opção da
org de permitir deploy com trabalho pendente não foi usada: é configuração da sandbox do
cliente e não chega à produção.

Versão nova do agente ficava fora da QA (2026-11-17, achado EPLAST-29): quando a versão ativa
do agente derrubava o deploy, o passo reimplantava sem nenhum arquivo de agente. A demanda
tinha criado a v17 para corrigir as falhas que o QA achou na v16; a v16 ativa derrubou o
deploy, a v17 saiu junto, e a rodada seguinte de QA reprovou porque a correção não estava na
sandbox. Agora sai do pacote só a versão que a plataforma recusou
(`scripts/pacote_sem_versao_ativa.py`) e o resto do agente vai. Se esse deploy cair por outro
motivo, é essa a falha que aparece. Só se a plataforma continuar recusando por versão ativa o
passo volta a tirar o agente inteiro, e aí o `05-deploy-qa.md` avisa que nenhuma versão nova
chegou à QA.

Agente ativo não aceita versão nova na QA (2026-11-17, achado EPLAST-29, rodada 3 de QA): o
deploy sem a versão ativa também foi recusado, a v17 continuou fora da sandbox e a demanda
voltou ao gate de design por limite de rodadas, sem defeito no build. Decisão do responsável
no mesmo dia: quando a recusa por agente ativo persiste, o `implantar-build-qa.sh` desativa
o agente na sandbox de QA (`sf agent deactivate`), implanta a versão nova inativa e registra
em `05-deploy-qa.md` que o agente ficou desativado. Quem ativa é o `qa`, que já ativa a
versão da demanda antes de testar. Até lá o assistente não responde na QA, e isso afeta quem
estiver homologando outra demanda do mesmo agente. Se o deploy cair mesmo com o agente
desativado, o passo reativa o agente e segue como antes; se a reativação falhar, o job
acusa em erro. As respostas da plataforma em cada tentativa vão para o log e, quando o
agente fica fora do pacote, para o `05-deploy-qa.md`. Só vale para `sbx-<cliente>-qa`.

Arquivo com acento ficava fora do pacote de QA (2026-11-20, achado SOMOSAGILITY-26): o git
cita caminho com acento (`"...Solicita\303\247\303\243o..."`) quando `core.quotepath` está
ligado, que é o padrão. A linha não começava com `clients/`, e o `pacote_da_demanda.py` a
descartava sem aviso: 9 dos 16 layouts da demanda, todos com acento no nome, não chegaram à
QA, e o QA reprovou. Os `git diff --name-only` da esteira e do CI passaram a usar
`-c core.quotepath=false`, e o script desfaz a citação se ela vier mesmo assim.

Perfil e permission set inteiros derrubavam o deploy em QA (2026-11-20, achado
SOMOSAGILITY-26): o pacote levava o arquivo inteiro, e o permission set `DiretorComercial`
citava um app que só existe na dev. O builder, devolvido para corrigir, enxugou os 66 perfis
e os 2 permission sets na própria branch, o que passa na QA mas apagaria o resto do conteúdo
desses arquivos no merge para a `main`. Agora o `implantar-build-qa.sh` reduz, só na cópia de
trabalho do job e só para o deploy, cada perfil e permission set ao que a demanda acrescentou
em relação à base (`scripts/permissoes_so_o_diff.py`), mantendo os campos que o deploy exige,
e devolve os arquivos ao conteúdo commitado ao sair. O builder faz edição aditiva e não
enxuga arquivo-fonte (`.claude/agents/builder-declarativo.md`). Arquivo novo na demanda vai
inteiro.

Roteiro do cliente (2026-11-14): o `05-testes.md` é evidência para quem aprova gate, e era
ele que aparecia para o cliente na homologação. Quando aprova, o `qa` grava também
`05-roteiro-cliente.md`, o passo a passo em linguagem de usuário. A sessão não encerra sem
ele (`roteiro.py`), o sync o leva ao Squad OS, e o card o mostra ao cliente da homologação
em diante, com botão para baixar em PDF (mesmo desenho do espelho de horas,
`lib/roteiro-pdf.ts`).
Desde 2026-11-15 o roteiro sai em toda rodada de QA, não só na aprovada: na EPLAST-47 a
sandbox de QA tem dado real e parte do teste fica para gente, que precisa do passo a passo
mesmo com o QA automático reprovado. A esteira apaga o roteiro antes de cada rodada, para
a sessão escrever o novo; o cliente continua vendo só da homologação em diante.
No mesmo dia o roteiro deixou de ter seção própria no card: o sync gera o PDF e o publica
como um anexo só, na seção de anexos (`lib/roteiro-anexo.ts`), substituído a cada rodada.
O cliente não vê esse anexo nem consegue baixá-lo antes da homologação.

**Entregue só com evidência** (2026-11-14): `demands.transition` recusa `entregue` sem
`05-testes.md` aprovado na sandbox de QA e sem `06-entrega.md` (`EntregaSemEvidenciaError`),
no fluxo e em correção manual. Achado real: quatro demandas da Somos foram marcadas
"entregue" por correção manual tendo só o texto do pedido.

**Entrega manual** (2026-11-25): alguns cards são concluídos pelo consultor fora da esteira
(tarefa manual na org, ajuste feito em reunião, trabalho que não é metadata), e a regra
acima não deixava encerrá-los. A regra continua; muda quem produz a evidência. No card, o
consultor ou o admin usa "Entregar manualmente" (`components/EntregaManual.tsx`,
`/api/demandas/[id]/entrega-manual`): descreve o que foi feito (30 caracteres no mínimo) e
anexa uma evidência, as duas obrigatórias. O Squad OS grava `06-entrega-manual.md` na pasta
da demanda, com `**Entrega manual:**`, `**Por:**`, `**Em:**` e `**Evidência:**`, e leva o
card a `aguardando_homologacao`. O cliente vê o registro e a evidência e homologa; só então
o card vira `entregue`, sem disparar agente (`/aprovar-gate`). Quem homologa é o cliente ou
um admin em nome dele, nunca quem registrou a entrega. `demands.transition` aceita o
registro completo no lugar de `05-testes.md` + `06-entrega.md` (`entrega_manual_registrada`);
arquivo vazio ou sem evidência nomeada não vale. Não entra com execução da esteira em
andamento ou na fila, nem em card congelado ou encerrado. Horas aprovadas pelo cliente e
ainda não debitadas entram no contrato no registro. Decisões do dono: descrição mais anexo
obrigatórios, cliente homologa, admin e consultor podem registrar.

**Skills alcançáveis e skills de operação** (2026-11-25): a sessão da esteira não libera a
ferramenta de skill (`ALLOWED_TOOLS` em `orchestrator.py`), e seis agentes citavam skills só
pelo nome; só o `recon` dava o caminho. Agora todo agente cita o arquivo
(`.claude/skills/<nome>/SKILL.md`) e o `CLAUDE.md` manda abri-lo com Read. Do `qa.md` saíram
os dois procedimentos que nem toda demanda usa (teste pela tela e QA em duas fases), para a
skill `teste-em-sandbox`; no agente ficou o resumo, a regra que não pode ser esquecida e a
ordem de ler o guia. O que vale em toda demanda continua no prompt do agente. Entraram
também skills para quem opera e entrega, não para os agentes de etapa: `status-da-esteira`,
`operar-esteira`, `homologacao-assistida`, `subir-producao`, `promover-qa-dev` e
`portal-local` (com os scripts do ambiente local do portal). `revisar-custos` passou a ler o
custo no banco e os CSV nas branches de demanda, onde eles de fato ficam.

**Skills por papel técnico** (2026-11-25): medição nas branches de 36 demandas que chegaram
ao QA: 45 roteiros reprovados e 31 aprovados; 54 verificações, das quais 22 inconclusivas e
14 reprovadas; 6 builds bloqueados em 46. Das 71 falhas registradas pelo QA, cerca de 27
eram "não consegui exercitar", 14 eram de ambiente ou ativação e cerca de 30 eram defeito de
construção, nove delas de comportamento de agente Agentforce. Reprovar por não ter
exercitado devolve a demanda ao builder, que não tem o que corrigir (três demandas repetiram
a mesma falha em rodadas seguidas). Daí cinco skills, uma por papel, cada uma citada com
caminho no agente: `design-testavel` (arquiteto: plano de prova por critério e
pré-requisitos de ambiente), `construir-flow` (builder declarativo), `construir-apex`
(desenvolvedor), `agentforce` (os três, mais o QA) e `provar-criterio` (verificador e QA: o
que tentar antes de "não executado", e a linha `**Origem:**` abaixo de cada falha). Desde o
mesmo dia a esteira roteia a reprovação pela origem (ver "O QA reprovado vai para quem
resolve").

**Skills por papel, para projeto e sustentação** (2026-11-25): as cinco skills acima
cobriam arquiteto, builders, verificador e QA; os agentes de análise, recon, release,
documentação, planejamento, assessment e pipeline não tinham nenhuma, e nada tratava
sustentação como diferente de projeto. Dezessete skills novas, cada uma citada com caminho
no agente que a usa e lida só quando a demanda pede (economia de contexto):
`criterio-testavel`, `triagem-sustentacao` e `estimar-esforco` (BA; a última também o
arquiteto); `impacto-cruzado` (recon); `modelo-de-dados-e-acesso` (arquiteto); `integracao`
(design, build e teste); `relatorios-e-paineis` e `carga-e-migracao` (builder declarativo);
`construir-lwc` e `revisar-apex` (desenvolvedor); `dados-de-teste` e `teste-de-regressao`
(verificador e QA); `pacote-e-rollback` (release); `documentar-entrega` (doc);
`quebrar-entregavel` (planejador); `divida-tecnica` (assessment); `triagem-de-deploy`
(devops, release e QA). Só três têm achado medido por trás: `criterio-testavel` (seis
builds bloqueados por pergunta de negócio), `dados-de-teste` (falta de dado, a causa mais
comum de caso não executado) e `impacto-cruzado` (diferença entre dev e QA, automação do
objeto pai). As demais registram prática de plataforma e ainda não foram exercitadas por
demanda real: quando uma delas contradisser o que a org mostrar, vale a org, e a skill é
corrigida com o achado.

**Limpeza de 2026-11-25**: revisão do repositório atrás do que sobrou de arquiteturas
anteriores. O que saiu, e a evidência:
- Ferramentas `sf_deploy`, `sf_retrieve`, `sf_query` e `sf_org_list` (`tools.py`): nenhum
  subagente as declarava em `tools:`, e em 66 execuções registradas no banco nenhuma foi
  chamada; os agentes usam o `sf` pelo Bash. Com elas saiu o corte de 12 mil caracteres da
  saída do `sf`, que só existia nesses wrappers e portanto nunca valeu. Se o tamanho da
  saída do `sf` voltar a pesar no custo, o lugar de cortar é o Bash (hook), não uma
  ferramenta paralela.
- O comentário de `assessment.py` e de `run-assessment.yml` que dizia que o assessment era
  read-only "por construção" porque a lista de ferramentas não tinha `sf_deploy`: o agente
  tem Bash. A proteção mecânica real é o `guard-prod.sh` e o alias restrito às sandboxes;
  o texto agora diz isso.
- `spec_read` continua, e passou a constar em `tools:` de `ba-discovery` e `arquiteto`: a
  nota de anexos mandava ler documento com ela, mas nenhum subagente podia chamá-la.
- No portal: o script `migrate-from-artifact.ts` (migração única do Artifact antigo) e três
  exportações sem uso.
- Texto que descrevia arquitetura que não existe mais: os dois READMEs (Artifact como fonte
  de verdade, ponte manual, "ainda sem deploy"), `conexoes-e-setup.md` (Squad OS como
  artifact, branch `develop`), a tabela do fluxo desta doutrina, e o agente `devops`, cujo
  modelo de branches (`develop`, `release/*`, INT, UAT, `main` = produção) contradizia o
  guardrail de produção.
O que foi olhado e ficou: a duplicação de regra entre Python e TypeScript (`veredito.py` e
`qa-veredito.ts`, `bloqueio.py` e `build-bloqueado.ts`), que é o preço de ter dois
runtimes e está marcada nos dois lados; os padrões "legados" de build bloqueado, que ainda
leem planos antigos nas branches de demanda; e o leitor do CSV de custo antigo, que a skill
`revisar-custos` usa.

**Contexto enxuto** (2026-11-14): o `CLAUDE.md` da raiz caiu de 30 KB para as regras; o
prompt do orquestrador diz qual subagente roda a etapa e manda não reler artefatos; os
agentes consultam o assessment por trecho. (O corte de 12 mil caracteres na saída do `sf`
nunca valeu na prática: estava nos wrappers `sf_*`, que nenhum agente chamava; os agentes
usam o `sf` pelo Bash, sem corte. Ver "Limpeza de 2026-11-25".) Medir de novo o custo por etapa depois de duas semanas de uso.

O fluxo falha alto em vez de contornar quando o agente não produz o artefato da etapa
(`ArtifactAusenteError`) e quando a etapa cai em org diferente da que o job autenticou.

Antes de falhar, porém, ele **cobra**. Uma sessão de agente aqui é um tiro só: roda num job
de CI e termina quando o modelo para de responder — não há turno seguinte nem ninguém
lendo o chat. O modelo não sabe disso por padrão, e conversa admite "já volto". Achado real
(Konecta, 2026-09-13): o primeiro assessment de uma org de verdade encerrou com o agente
dizendo que seguia "rodando em background" e que avisaria quando terminasse. Não avisou —
a sessão morreu na frase, `assessment.json` nunca existiu, e a tela seguiu mostrando "ainda
não avaliada", igual a nunca ter tentado. `src/salesforce_agents/sessao.py` fecha isso:
confere o disco com a sessão ainda aberta, recobra o agente dizendo que não existe depois
(e que "não consegui medir X" é resposta válida, mas inventar não é), e só então desiste.
Vale para o assessment e para as 7 etapas de demanda.

## Guardrails inegociáveis

1. **Produção é proibida.** Nenhum agente executa deploy, DML ou anonymous Apex em org
   de produção. A esteira tem dois ambientes e só dois: **dev** (`sbx-<cliente>-dev`) e
   **qa** (`sbx-<cliente>-qa`). Build e tudo antes acontece em dev; a partir da etapa `qa`
   a demanda já vive na sandbox de QA, onde o roteiro roda, o humano homologa e o release
   entrega — e o agente para ali. Quem sabe dessa regra é
   `src/salesforce_agents/ambientes.py`, que recusa qualquer ambiente fora de
   `("dev", "qa")` antes de montar comando `sf` nenhum; os workflows perguntam pra ele
   (`sfagents demanda ambiente`) em vez de repetirem a condição em YAML.

   A checagem acontece em **três camadas, e as três respondem perguntas diferentes**:

   - `ambientes.alias_permitido` — **allowlist** de formato: só `sbx-<cliente>-dev|qa`.
   - `.claude/hooks/guard-prod.sh` — PreToolUse do Bash, mesma allowlist, para o `sf`
     que o agente digita no terminal.
   - `src/salesforce_agents/guarda.py` — pergunta à própria org (`Organization.IsSandbox`)
     antes de qualquer escrita, e recusa se ela não se declarar sandbox.

   As duas primeiras conferem o **nome**; a terceira confere o **destino**. Achado do
   council de 2026-09-11: até ali o guardrail era um denylist (`prod|prd|production` no
   texto do comando) registrado só no hook do Bash — e as ferramentas `sf_*` chamam `sf`
   por subprocess de dentro do Python, onde PreToolUse do Bash nunca dispara. Uma org de
   produção autenticada como `sbx-acxya-dev` passava limpo pelas duas pontas. Não
   substitua nenhuma das três pelas outras: um denylist responde "esse nome parece
   produção?", e a pergunta certa sempre foi "essa org é sandbox?".

   O agente `qa` testa a UI Lightning de verdade com um navegador (`qa_browser_*` em
   `tools.py`), não com o servidor MCP oficial do Playwright. Motivo: `--allowed-origins`
   daquele servidor é documentado como "não é um limite de segurança e não afeta
   redirect" — não segurava o guardrail #1 sozinho. `qa_browser_open` é o único ponto
   que decide pra onde o navegador vai, e só chega lá depois de `guarda.url_de_login`
   fazer as mesmas perguntas 1 e 2 de cima; as ferramentas seguintes (click/fill/
   screenshot) operam dentro da sessão já aberta e não aceitam URL. Vale o guardrail #2
   aqui também: nunca screenshotar um registro real de cliente.
2. **Dados reais não entram no contexto.** Nunca rodar SOQL que retorne dados de cliente
   (CPF, e-mail, telefone, valores). Só metadata e contagens agregadas. LGPD.

   O copiloto (`apps/squad-os/app/api/copilot/chat`, `lib/copilot/`) segue este guardrail por
   construção, não por instrução: ele não tem nenhuma ferramenta que fale com Salesforce —
   só lê do mesmo Postgres que a tela já expõe (demandas no vocabulário `ESTADOS_CLIENTE`,
   contrato somente leitura, financeiro só leitura), nas mesmas funções de
   `lib/data.ts`/`lib/contrato.ts`/`lib/contas-data.ts`/`lib/ops.ts` que a UI usa.
   `consultar_saude_da_org` (2026-11-01) devolve o mesmo bloco "Saúde da org" que o perfil
   do cliente já mostra a quem enxerga o cliente — saúde, resumo e recomendações do banco,
   nunca o `assessment.md` longo. `criar_demanda` é a única ferramenta de escrita de todas (cliente, consultor e admin), e
   chama a mesma `criarDemanda()` que a API — sempre em `backlog`, nunca aprova gate nem
   materializa; as financeiras (`consultar_painel_financeiro`, `consultar_contas_a_pagar`,
   `consultar_divergencias`, `consultar_horas_por_cliente`) não escrevem nada. Existe pra
   todo papel, mas o conjunto de ferramentas muda por quem está perguntando e por onde
   (`app/api/copilot/chat/route.ts` monta o conjunto a cada request, nunca o modelo): cliente
   só vê o próprio cliente; consultor só vê o cliente cuja página está aberta (sem
   ferramenta nenhuma fora de uma página de cliente); admin soma isso com o financeiro,
   sempre; financeiro só vê o financeiro, nunca demanda ou cliente. O `clientId` em escopo
   nunca é um argumento que o modelo escolhe — pro cliente vem sempre da sessão; pra
   consultor/admin vem da página de cliente aberta no navegador (`ClientDetail.tsx` passa o
   id pro componente, que manda no corpo da requisição) e a rota ainda confere
   `canAccessClient` antes de aceitar. Mesmo que a pessoa injete instrução via conversa, não
   existe caminho pra pedir dado de outro cliente — a pergunta nunca chega a existir pra ele.
   Aprovação de gate, pagamento de conta e decisão de divergência continuam exigindo o fluxo
   de confirmação na tela; o copiloto explicitamente recusa qualquer uma das três pelo chat,
   pra qualquer papel.

   Melhorias do assessment propostas ao cliente (2026-11-21, decisão do responsável): o
   time pede ao copiloto, na página do cliente, o que do assessment ainda não virou
   demanda (`listar_melhorias_do_assessment`) e, depois de confirmar a lista exata na
   conversa, ele abre as demandas (`propor_melhorias_ao_cliente`, até 10 por vez e 20 por
   hora por cliente, só admin/consultor, mesmo recorte do RAG). Elas nascem em `backlog`
   pela mesma `criarDemanda()`, marcadas com a recomendação de origem
   (`origemAssessmentId`, id estável derivado de área + título em
   `lib/assessment-propostas.ts`, para a mesma melhoria não virar dois cards) e com
   `propostaClienteEm`. Enquanto o cliente não decide, a demanda não vai para a esteira
   (materialize e o arrastar recusam). **Só o papel cliente decide**, no card ou na aba
   Aprovações (`/api/demandas/[id]/proposta`, dois passos): aprovada, continua no backlog e
   o time decide quando manda para a esteira, porque a fila é uma por cliente e as horas
   do AMS só correm depois da análise e da estimativa; recusada, vai para `cancelada` com o
   motivo, e a recomendação não é oferecida de novo. O copiloto do cliente mostra e explica
   as propostas, mas não aprova nem recusa pelo chat.

   RAG interno por cliente (`src/salesforce_agents/rag.py`, `apps/squad-os/lib/rag.ts`,
   `/api/sync/rag*`) — decisão de 2026-09-29, revista em 2026-11-01: o pipeline de agentes
   Python consulta (`rag_consultar`, liberada nos subagentes de análise, design, build e
   doc), e o **copiloto só para o time** — `consultar_base_conhecimento`, para admin e
   consultor, sempre no cliente da página aberta (`lib/copilot/papeis.ts`, com teste em
   `testa-seguranca.ts`). **Nunca o papel cliente**: o corpus é material interno de
   delivery (designs, `gates.md`, briefing de conta), impróprio para o próprio cliente. O corpus é todo `.md` de
   `clients/<cliente>/` (CLAUDE.md de conta, demanda.md, os artefatos das 7 etapas,
   gates.md, assessment.md) — dado interno de delivery, já sujeito ao guardrail #2 desde
   que foi escrito (nenhum desses arquivos deveria ter CPF/e-mail/telefone/valor de
   cliente; a ingestão não filtra isso de novo, herda a disciplina de quem escreveu). O que
   é novo aqui: os trechos saem daqui pra um provedor de embeddings de terceiro (AI
   Gateway) antes de voltar pro Postgres — um processador a mais que não existia antes
   desta feature, vale saber que existe. `rag_consultar` é fechada por closure sobre o
   `client` que o orchestrator já resolveu pra sessão (nunca um argumento que o agente
   escolhe, mesmo padrão do copiloto) — não tem como pedir dado de outro cliente
   (guardrail #7). A tabela `rag_chunks` tem RLS ligado sem policy, como toda tabela nova
   deste banco (achado de 2026-09-09: sem isso o Supabase publica a linha inteira —
   `conteudo` incluído — via PostgREST pra qualquer um com a anon key).

   Anexos de card (print, PDF, planilha) **não** entram na sessão por padrão — só os que
   alguém de delivery **libera** no card, declarando que o arquivo não tem dado pessoal
   (rota `PATCH /api/demandas/<id>/anexos/<anexoId>`, recusa sem a declaração; o papel
   cliente anexa mas não libera). `run-demand.yml` baixa os liberados via
   `/api/sync/anexos` para `demandas/<ID>/anexos/` só no runner: a pasta está no
   `.gitignore`, então anexo nunca vira commit, PR ou RAG. `anexos.py` lista os arquivos no
   prompt (imagem com Read, documento com `spec_read`) e manda descrever sem transcrever
   dado pessoal se ainda assim aparecer. Achado que motivou (SOMOSAGILITY-14, 2026-10-16):
   "segue anexo o print do erro" e o agente só via o texto. A liberação humana é a única
   camada para imagem — `ci-pii-scan` lê texto, não pixel.

   **Comentários do card** também chegam à sessão (`/api/sync/comentarios` →
   `demandas/<ID>/comentarios-do-card.md`, só no runner, `.gitignore`): é onde cliente e
   consultor respondem as dúvidas da análise. Vai só o lado (cliente/equipe), a data e o
   texto — nunca nome ou e-mail de quem escreveu — e `comentarios.py` troca CPF/e-mail/
   telefone por marcador com os mesmos padrões do scanner de PII antes de gravar.

   Curadoria desse corpus por Obsidian (local, opcional, pra gente — nunca pro pipeline
   de agentes) é `.mcp.json` + `docs/obsidian.md`.
3. **Não invente metadata.** Antes de referenciar qualquer objeto, campo, Flow ou classe,
   confirme via `sf` CLI contra a org. Se não confirmou, declare a incerteza.
4. **Git é obrigatório.** Todo build acontece em branch `feature/<DEMAND-ID>`. Nada é
   commitado direto na main. Todo merge passa por PR com revisor humano — `main` é
   protegida (push direto bloqueado) e exige os checks de CI abaixo passando. Vale pra
   sessão de agente inteira, não só pro build declarativo/Apex: `run-demand.yml` cria/
   reusa `feature/<DEMAND-ID>` (sem o sufixo de descrição — quem cria manualmente pode
   adicionar) e abre PR automaticamente na primeira etapa; `baseline-retrieve.yml` usa
   `baseline/<cliente>` do mesmo jeito. Achado real (ACXYA-1, 2026-09-07): antes dessa
   correção, `run-demand.yml` empurrava direto pra branch que disparou o workflow —
   funcionava só por acaso enquanto isso era uma branch não protegida; quebrou na
   primeira vez que rodou em `main`. `run-demand.yml` roda em dois jobs (`decidir` sem
   environment, `rodar` no `<cliente>-<ambiente>` que o primeiro apontou) porque um job
   do Actions declara um `environment:` só e a esteira atravessa dois.

   **`feature/<DEMAND-ID>` acumula commit a cada etapa — `assessment/<cliente>`,
   `plano/<cliente>` e `baseline/<cliente>` fazem o oposto: são substituídas inteiras a
   cada rodada.** As duas semânticas usam o mesmo "cria a branch se não existir, reusa se
   existir", e é fácil confundir uma com a outra na hora de reusar. Achado real
   (2026-10-02): as três branches de "substituir" reusavam resetando pro **tip remoto
   antigo da própria branch** (`git checkout -B $BRANCH origin/$BRANCH`) em vez de pro
   `main` que acabara de ser clonado no mesmo job — então uma rodada nova partia da foto
   de quando a branch nasceu, não da atual. `assessment/mais-polimeros` herdou assim um
   `main` de antes de `SOMOSAGILITY-2` existir e o PR resultante **deletava** a demanda
   de outro cliente — guardrail #7 quebrado sem ninguém escrever uma linha ruim, só
   porque "reusar" apontou pro lugar errado. Corrigido nos três workflows: a branch
   sempre reparte do checkout fresco (`git checkout -B $BRANCH`, sem start-point) e o
   push vira `--force-with-lease` — seguro aqui porque só o próprio job escreve nessas
   branches, nunca um commit humano por cima pra perder. `feature/<DEMAND-ID>` continua
   como estava: ali reusar o tip remoto é o comportamento certo, é isso que faz a
   demanda acumular etapa sobre etapa.

   - `ci-python.yml` — testes do orquestrador (`src/salesforce_agents/`)
   - `ci-squad-os.yml` — lint + build do Squad OS (`apps/squad-os/`)
   - `ci-salesforce-validate.yml` — deploy check-only (dry-run, nunca deploy de verdade)
     contra a sandbox do cliente cujo `force-app` mudou no PR. Roda só os testes da
     própria demanda (`<Classe>Test` do Apex alterado; sem Apex, nenhum), não a suíte da
     org: 70 de 79 testes legados da `sbx-eplast-dev` falham e reprovavam PR sem Apex
     (achado EPLAST-47, 2026-11-14). Em PR de demanda quem dispara é o `run-demand.yml`
     ao fim do build, porque o evento de PR de commit do robô nasce aguardando aprovação;
     o resultado aparece na PR como status do commit
5. **Estado em disco.** Cada demanda gera `clients/<cliente>/demandas/<DEMAND-ID>/` com os
   artefatos numerados. Se a sessão cair, o próximo agente lê a pasta e retoma de onde parou.
   `sfagents demanda avancar` **recusa avançar** um estágio de execução pra frente se o
   artefato que aquele estágio deveria ter produzido não existir em disco (`demands.py`,
   `ArtifactAusenteError`) — status.yaml não pode mais declarar um estágio que não aconteceu.
   Corrigir manualmente pra trás (reverter um status errado) sempre é permitido, sem exigir
   o artefato do estágio abandonado.
6. **Uma demanda por vez, por cliente.** Não paralelize builds na mesma sandbox sem alinhar
   com o humano.
7. **Nunca misture clientes.** Cada cliente vive isolado em `clients/<cliente>/`, com seu
   próprio org, seu próprio `CLAUDE.md` de briefing e seu próprio histórico de demandas.

## Convenções

- Branch: `feature/<DEMAND-ID>-descricao-curta`
- Commit: `<DEMAND-ID>: verbo no imperativo`
- Cobertura mínima de teste Apex: 85% por classe
- Toda classe tem classe de teste dedicada `<Classe>Test`
- Nomenclatura de campo/Flow/classe: ver skill `padrao-entrega` (convenção específica de
  cada cliente pode sobrepor a convenção padrão — confira o `CLAUDE.md` do cliente primeiro)

## Seleção de modelo por agente

Cada agente em `.claude/agents/*.md` declara `model:` no frontmatter — não roda mais tudo
no mesmo modelo default por acidente. Heurística aplicada (council de 2026-09-07, ver
`gates.md`/histórico de sessão — não repita a análise, ela já foi feita):

- **haiku** — `ba-discovery`, `doc` e, desde 2026-11-14, o **orquestrador** (só roteia: o
  prompt diz qual subagente roda a etapa): extração, formatação e roteamento, sem decisão
  de risco.
- **sonnet** — `recon` (desde 2026-11-14: o levantamento da org saiu do `arquiteto`, que o
  fazia em Opus, e virou agente próprio; o arquiteto lê o `02-recon.md` pronto),
  `builder-declarativo`, `dev-apex`, `devops`, `qa`, `release`, `planejador`,
  `org-assessment`: trabalho
  estruturado com julgamento, mas revisado por PR ou gate antes de valer. Cavalo de batalha.
- **opus** — só `arquiteto`, e só pela decisão declarativo-vs-código em si: é o único gate
  humano bloqueante da doutrina, erro ali compõe nos 6 clientes, e já paga a latência de
  revisão humana de qualquer forma.

**Isso é hipótese reversível, não doutrina validada.** Ninguém tem sinal empírico de
custo/latência/taxa-de-retrabalho por agente ainda — nenhuma demanda completou o ciclo
inteiro. Antes de tratar esta tabela como padrão para os outros 5 clientes, rode pelo menos
um ciclo completo real (ACXYA-1) e confira se algum agente errou por estar num modelo
barato demais ou custou caro demais num modelo caro demais para o que fez. Ajuste com dado,
não com a heurística sozinha.

### Telemetria de custo

Segundo council de otimização de custo (2026-09-07): a variável que domina o custo deste
pipeline não é qual modelo cada agente usa — é o reprocessamento de `CLAUDE.md`/skills sem
cache em 7 etapas × 6 clientes × ciclo indefinido. Antes de mexer em cache, model routing ou
Batch API, é preciso medir. `src/salesforce_agents/orchestrator.py` agora loga cada sessão
de agente (`src/salesforce_agents/costs.py`) em `logs/custos_agentes/` — modelo, tokens
de input/output/cache, custo em USD, etapa, cliente, demanda. Só metadata e contagens, nunca
conteúdo da demanda (guardrail #2). Esse log é o pré-requisito pra qualquer decisão futura de
caching ou de revisão da tabela de modelo acima — sem ele, qualquer ajuste continua sendo
achismo.

`logs/custos_agentes/` **é versionado** (commitado pelo workflow `run-demand.yml`, mesmo
passo que commita os artefatos da demanda) — precisa sobreviver entre execuções de CI, que
rodam em runner efêmero. Achado real (ACXYA-1, 2026-09-07): a primeira sessão real de agente
gerou o log dentro do runner, mas como o arquivo estava no `.gitignore` e o commit só incluía
`clients/$CLIENT`, o dado se perdeu — corrigido depois desse incidente.

**Um arquivo por sessão, não um CSV único crescendo** (mudou em 2026-10-02, achado do
council daquele dia): o formato original era `logs/custos_agentes.csv`, um arquivo só que
toda sessão appendava. Cada demanda vive na própria branch `feature/<DEMAND-ID>` (guardrail
#4) — duas demandas de clientes diferentes, cada uma appendando no fim do mesmo arquivo,
geram PRs que conflitam entre si quando os dois tentam mesclar na mesma região do arquivo.
Aconteceu de verdade (somos-agility × eplast). `logs/custos_agentes.csv` (singular) continua
existindo só como arquivo **legado**, com o que foi gravado antes da mudança — nunca mais
escrito, só lido. Quem precisa do agregado usa
`salesforce_agents.costs.ler_todas_as_linhas()`, que junta os dois (ver skill
`revisar-custos`).

### Estimativa por demanda

Cada card mostra horas de consultor, horas de agente, o total das duas, e custo de agente — de fontes diferentes de propósito
(`src/salesforce_agents/estimativa.py`, espelhadas pelo sync):

- **Horas de esforço humano** — julgamento do agente: `ba-discovery` escreve
  `**Estimativa de esforço:** <min>–<max> h` na análise e o `arquiteto` refina no design
  (a do design vence). Sem a linha, não aparece — não se inventa número. A faixa crua é de
  delivery; o cliente vê a calibrada (abaixo).
- **Horas de agente** — conta: tempo de sessão já rodado (`duration_ms` da telemetria) mais
  a mediana por etapa do que falta. O card soma com as de consultor e mostra o **total
  estimado** da demanda (consultor + agente). Delivery vê; cliente não.
- **Calibração pelo timesheet** — a faixa de consultor é multiplicada pela mediana de
  "horas lançadas ÷ ponto médio estimado" das demandas já **entregues** que tinham
  estimativa (`apps/squad-os/lib/estimativa.ts`): fator do próprio cliente com ≥3
  amostras, senão o geral, senão 1; preso entre 0,5 e 3. O **cliente vê só a faixa total
  calibrada** (consultor calibrado + agente), e só a partir do gate da análise — é quando
  ele decide se segue, antes da construção. Delivery vê bruta e calibrada lado a lado.
- **Estimativa oficial do consultor** — lançada no card (`PATCH /api/demandas/<id>/estimativa`,
  só delivery), **pré-preenchida com a sugestão do agente já calibrada** (ponto médio,
  meia hora). Sem ela o apontamento de horas é recusado — card, cronômetro e grade de
  Minhas horas (reduzir/zerar continua livre). Quando existe, é o número oficial: o
  cliente vê ela + horas de agente, sem recalibrar. A calibração continua medindo a
  sugestão do agente contra o lançado — é a sugestão que ela corrige.
- **Aprovação do cliente e débito no contrato** (2026-10-21) — o cliente aprova ou
  **segura** a estimativa oficial na aba Aprovações (ou no card), depois da análise e antes
  do build. O gate de design **não libera o build** sem aprovação válida (a do número que
  está no card agora — se o consultor muda a estimativa, o cliente aprova de novo); uma
  aprovação de gate já na fila espera por ela. Segurar congela a demanda com o motivo do
  cliente; aprovar depois descongela. Quando a demanda entra em build, a estimativa aprovada
  **vira o consumo do contrato** naquele mês (`horasPorMes`), uma vez só; o timesheet dela
  deixa de debitar e passa a medir o desvio (excedente aparece no card, não debita).
  Demandas sem aprovação (anteriores à regra) seguem debitando pelo timesheet.
  **Só em AMS** (2026-11-11): em contrato de projeto o escopo já foi vendido fechado e não
  há balde de horas, então o cliente não aprova horas e o gate de design libera o build
  direto (`exigeAprovacaoDoCliente` em `lib/demandas.ts`). A estimativa do consultor
  continua existindo ali, para o apontamento e a calibração.
- **Custo de agente (USD)** — conta, não opinião: o gasto da demanda pela telemetria
  acima, mais a mediana por etapa do que ainda falta (valor de partida declarado enquanto
  não há 3 amostras). **Só admin vê**: a página recorta para os demais papéis
  (`lib/visao-cliente.ts`) antes de virar prop.

## Estrutura de artefatos por demanda

```
clients/<cliente>/demandas/<DEMAND-ID>/
  demanda.md         # a história enviada pelo consultor — entrada, não editar
  status.yaml        # estágio atual e histórico de transições (mantido pela CLI sfagents)
  01-analise.md      # BA: contexto, critérios de aceite, dúvidas
  02-recon.md        # o que já existe na org e será impactado
  03-design.md       # decisão declarativo vs código + justificativa
  04-plano-build.md  # passo a passo do que será criado/alterado
  05-testes.md       # roteiro + resultado
  05-roteiro-cliente.md  # passo a passo do cliente (só com QA aprovado)
  06-entrega.md      # documentação final
  gates.md           # log de aprovações humanas — escrito por sfagents, não pelo agente
```

`gates.md` é **mecânico**: `src/salesforce_agents/gates.py` escreve o bloco no
momento em que o humano aprova, com o sha256 de cada artefato que estava na mesa.
Nenhum agente escreve nele — era instrução no prompt até 2026-09-11, e instrução
é a camada mais fraca que existe pro único rastro do gate bloqueante da doutrina.

O hash é o que transforma "fulano aprovou o design" em "fulano aprovou **este**
design": `sfagents demanda conferir-gates --client <cliente> <DEMAND-ID>` responde
se o que está em disco hoje ainda é o que foi aprovado, e sai diferente de zero
quando não é. Divergir não é erro — corrigir depois do gate às vezes é o certo.
O que não pode é ninguém conseguir saber.

## Escopo duplo: projeto e sustentação

- **Projeto (greenfield):** fluxo completo, etapas 1→7.
- **Sustentação (bug/melhoria):** etapas 1, 2, 3 (design enxuto), 4, 5, 7. Bug crítico
  ainda passa pelo gate do arquiteto — reduzido, mas existe.

## Antes de qualquer coisa

1. Confirme com `sf org list` qual org está conectada e **diga ao humano qual é** antes de
   tocar em qualquer coisa. Org errada é o erro mais caro dessa operação.
2. Confirme qual cliente e qual demanda está sendo tratada. O `CLAUDE.md` deste cliente
   (na raiz do workspace atual) é o briefing de conta — leia-o antes de desenhar qualquer
   solução, ele é fonte de verdade sobre quem é o cliente e como trabalhar por ele.

## Nota sobre permissões em execução headless

O orquestrador roda sessões sem humano para responder prompt de permissão, então
concede ferramentas inteiras (`Bash` incluído) via `allowed_tools` no próprio SDK —
isso torna a lista `allow` de `.claude/settings.json` redundante nesse modo, e o aviso
de "workspace não confiável" do Claude Code é sobre exatamente essa lista, nada além.
A rede de segurança real não depende dela: a lista `deny` (`git merge*`, `git push
--force*`, `sf org delete*`) e o hook `guard-prod.sh` continuam bloqueando
normalmente independente de o workspace estar marcado como confiável — verificado
empiricamente. O que o hook **não** cobre são as ferramentas `sf_*` do MCP, que não
passam pela ferramenta Bash: quem guarda aquele caminho é `guarda.py` (guardrail #1).
Não "resolva" esse aviso afrouxando permissão; ele não protege nada
que já não esteja protegido por hook ou pela lista `deny`.

Evidências de teste no card (2026-11-16, decisão do responsável): a evidência do QA ficava só
no git (`05-testes.md`), e a captura de tela era mostrada ao agente e descartada. Agora
`qa_browser_screenshot` guarda a captura (JPEG, com legenda) em
`demandas/<ID>/evidencias/`, o sync manda o roteiro executado e as capturas
(`evidencias.py`, teto de 12 imagens e 2,5 MB), e o Squad OS publica o anexo "Evidências de
teste" em PDF (`lib/evidencias-anexo.ts`), no desenho do roteiro do cliente e com a mesma
regra de quem vê. A pasta é esvaziada a cada rodada de QA, menos na conferência do QA em duas
fases. `demandas.evidencias_hash` evita regerar o PDF quando nada mudou.
