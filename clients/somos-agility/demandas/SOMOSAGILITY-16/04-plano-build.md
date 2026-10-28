# Plano de Build — SOMOSAGILITY-16

## Não há build de metadata nesta demanda

**Nenhum componente é criado, alterado ou depreciado.** Ver `03-design.md`, seção 1
("Resumo da decisão") e seção 4 ("Componentes"): a tabela de componentes na org lista
"Nenhuma alteração na definição" para o relatório, e a única mudança é na(s)
assinatura(s)/agendamento(s) do relatório "Leads Semanais" — algo que não é metadata
(recon §2: não há `ReportSubscription` nem equivalente exposto por SOQL ou Metadata API)
e que só existe, de fato, em produção. Não existe nada a construir ou testar em
`force-app/`; nenhuma branch de metadata foi aberta e nenhum `sf project deploy` será
executado para esta demanda.

Este arquivo é, portanto, o **runbook de execução manual** que a seção 6 do design já
esboçou, formalizado como o artefato da etapa 4.

---

## Execução bloqueada até confirmação

**Ninguém deve executar este runbook em produção antes de D1, D2 e D3 aparecerem
respondidas no card.** `comentarios-do-card.md` até agora só registra a aprovação da
estimativa e dos gates de análise e design — nenhuma das três decisões abaixo foi
respondida. O design (`03-design.md`, §8) já era explícito: "o build não começa sem
D1 a D3 registradas no card". O runbook a seguir usa o **padrão proposto** de cada
decisão como ponto de partida — não como fato consumado. Se a resposta real divergir
do padrão, os passos marcados como condicionais mudam antes de qualquer execução.

| # | Decisão | Quem decide | Padrão proposto (usado neste runbook enquanto não houver resposta) |
|---|---|---|---|
| **D1** | Escopo: remover só Fabio Soto **ou** desativar o agendamento do relatório inteiro? | Consultora (Juliana Mendes) com o cliente | Remover só Fabio Soto (passo 5a) |
| **D2** | Ambiente: o link da demanda é mesmo da org de produção? E **quem** (papel) vai executar lá? | Consultora | Produção; executor = administrador do sistema do cliente, a nomear |
| **D3** | Destino do mapeamento nominal de destinatários: fica só com a consultora, ou vai para o card do Squad OS? (No repositório, só contagem e perfil — inegociável, RN4/guardrail #2) | Consultora | Mapeamento nominal fica só com a consultora, fora do repositório |

Uma quarta pergunta (D4, prazo de execução) está no design mas não bloqueia: na
ausência de prazo declarado, o padrão é executar assim que D1–D3 estiverem
respondidas.

---

## O que a esteira de agentes pode e não pode fazer aqui

Resumo da seção 3 do design — vale durante toda a execução deste runbook:

| Ação | Quem faz |
|---|---|
| Ler definição do relatório | Já feito pelo agente, só na sandbox dev (recon) |
| Ler a lista real de destinatários em produção | **Humano**, nunca o agente (guardrail #1; a assinatura não é consultável por `sf`) |
| Usar a sandbox como substituto do mapeamento de produção | **Ninguém** — não serve; assinaturas em geral não são copiadas num refresh de sandbox |
| Remover Fabio Soto do agendamento em produção | **Humano**, nunca o agente |
| "Ensaiar" a mudança na sandbox dev | **Ninguém** — não há o que validar; a cópia não reflete o estado real |
| Registrar evidência sem dado pessoal | Humano, no `05-testes.md`/`06-entrega.md` |

Nenhum nome, e-mail, telefone ou outro dado pessoal de destinatário, do usuário
removido ou do executor entra neste repositório em nenhum momento — inclusive nos
artefatos futuros (`05-testes.md`, `06-entrega.md`). Cite o executor pelo papel
("administrador do sistema do cliente"), nunca pelo nome.

---

## Quem executa

Um **humano com acesso de edição à pasta pública "Leads"** e permissão de gerenciar
assinaturas de terceiros no relatório — na prática, um administrador do sistema do
cliente (recon §4: o `OwnerId` do relatório é a pasta "Leads", não um usuário
individual). O design não confirmou nomes de permissão específicos em produção; isso
faz parte do que o executor confere antes de agir. Se o papel nomeado em D2 não tiver
esse acesso hoje, conceder acesso novo está fora do escopo desta demanda (design §7).

Nunca o agente. Não há execução pela esteira nesta etapa.

---

## Passo a passo (runbook de execução na UI, em produção)

Os caminhos de menu abaixo seguem a documentação pública da Salesforce para
assinaturas/agendamento de relatório no Lightning e **não foram confirmados na org de
produção** — o agente não tem acesso a ela (guardrail #1). O executor confere o
caminho real na tela antes de agir, em vez de assumir que bate com o descrito aqui.

1. **Confirmar o alvo e o ambiente (depende de D2).** Abrir o link da demanda; conferir
   que é de fato a org de produção do cliente (não a sandbox), que o nome do relatório é
   "Leads Semanais", Id `00O4z0000057ssKEAQ`, pasta "Leads" — valores já confirmados
   **na sandbox dev** pelo recon, a conferir agora contra o estado real de produção.
2. **Confirmar o usuário.** Em Setup → Usuários, confirmar que existe exatamente um
   usuário ativo "Fabio Soto" em produção (na sandbox dev há só um, sem homônimo — não
   verificado em produção).
3. **Enumerar as assinaturas do relatório.** Pode haver mais de uma: no Lightning, cada
   usuário pode ter a própria assinatura do mesmo relatório, com seus próprios
   destinatários. Pontos de entrada possíveis: botão "Assinar"/"Editar assinatura" no
   relatório, e Setup → Jobs agendados (tipo de job de execução de relatório).
4. **Mapear o "antes".** Para cada assinatura encontrada: quem é o dono (papel, não
   nome) e quais destinatários (usuários, grupos, papéis). Registrar no `05-testes.md`,
   na etapa seguinte, **só a contagem total e a distribuição por perfil/papel** (ex.:
   "Vendas — 3 destinatários"). A lista nominal completa fica com a consultora,
   fora do repositório (D3 — ou no card, se a resposta de D3 for essa).
5. **Aplicar a mudança, conforme D1:**
   - **5a (padrão — remover só Fabio Soto):** remover Fabio Soto da lista de
     destinatários da(s) assinatura(s) em que ele aparece **individualmente**. Se a
     assinatura for dele mesmo (ele é o dono/inscrito), excluir aquela assinatura —
     não afeta mais ninguém.
   - **5b (só se D1 vier como "desativar tudo"):** excluir/desativar todas as
     assinaturas do relatório, **após** comunicar os demais destinatários — esse
     runbook, como está, não cobre a comunicação; ela entraria no escopo só se D1
     confirmar esta opção.
   - **Parar e escalar** (não prosseguir) se Fabio Soto recebe o relatório **via grupo
     público ou papel**, não individualmente: removê-lo dali exigiria tirar o
     grupo/papel inteiro (afeta outros destinatários) ou mudar a participação dele no
     grupo (efeito colateral fora deste relatório). Nenhuma das duas está aprovada
     neste design — volta para o arquiteto/consultora antes de agir.
6. **Mapear o "depois"** e conferir: lista depois = lista antes − Fabio Soto (se 5a);
   relatório continua existindo com o mesmo Id; agendamento continua ativo para os
   demais destinatários.
7. **Registrar evidência** no `05-testes.md`: contagens antes/depois, distribuição por
   perfil/papel, data/hora da alteração, papel de quem executou. Nenhum screenshot com
   nome, e-mail de destinatário ou dado de lead (guardrail #2).

---

## Rollback

Reinscrever Fabio Soto como destinatário na mesma assinatura (se 5a foi aplicado) ou
recriar a(s) assinatura(s) com a lista do "antes" (se 5b foi aplicado). Por isso a
lista nominal do "antes" (passo 4) precisa continuar guardada com a consultora até o
aceite final da demanda — sem ela, o rollback de 5b não tem como ser exato.

---

## O que NÃO será feito nesta demanda

Conforme a seção 10 do design:

- Nenhuma alteração na definição do relatório (filtros, colunas, tipo, pasta).
- Nenhuma exclusão do relatório.
- Nenhuma alteração de compartilhamento da pasta "Leads", de grupos públicos, papéis,
  perfis ou permission sets.
- Nenhuma desativação ou alteração do usuário Fabio Soto.
- Nenhuma automação (Flow, Apex, chamada à Analytics REST API) para gerenciar
  assinaturas.
- Nenhuma escrita em produção pelo agente; nenhum "ensaio" na sandbox dev.
- Nenhum mapeamento nominal de destinatários no repositório — só contagem e
  perfil/papel (RN4/guardrail #2).
- Nenhuma revisão de outros relatórios agendados que Fabio Soto possa receber — só
  "Leads Semanais".
