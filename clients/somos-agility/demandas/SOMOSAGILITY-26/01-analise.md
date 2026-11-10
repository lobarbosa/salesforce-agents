# SOMOSAGILITY-26 — Análise (ba-discovery)

**Cliente:** somos-agility · **Tipo:** sustentação (melhoria de campos) · **Fonte:** `demanda.md` (texto enviado pelo consultor, uma frase)
**Status desta análise:** rascunho para validação humana. Há perguntas bloqueantes (seção "O que a demanda não diz"). O arquiteto não deve ser acionado antes de respondê-las.

## Histórico do cliente (RAG)

Consultei `mcp__rag__rag_consultar` duas vezes (tema: campos de texto/tamanho, objeto "Cenário SF", PFP, Cotação, Proposta, Aceite). Não há demanda anterior deste cliente sobre tamanho de campo de texto nem sobre o objeto "Cenário SF". Os trechos retornados são de outros assuntos (ex.: `[demandas/SOMOSAGILITY-3/02-recon.md]` sobre Validation Rules em Opportunity; `[demandas/SOMOSAGILITY-2/01-analise.md]` sobre criação de usuários). Não usei nenhum deles como fonte para as conclusões abaixo.

## Saúde da org (assessment)

O `assessment.md` (saúde **vermelha**, 2026-09-30) não mede o objeto "Cenário SF" nem os cinco campos. Os riscos dele que podem tocar esta demanda, como suspeita a confirmar no recon:

- **Automações concorrentes (achado 1 e 2):** 31 automações ativas em Oportunidade, 24 no evento `RecordAfterSave`, e 59 Process Builders ativos na org. Se "Cenário SF" for relacionado a Oportunidade (ou se algum Flow/Process Builder ler ou escrever os cinco campos), mudar tamanho ou tipo pode afetar outra automação sem ninguém perceber. Não confirmado: depende de o recon listar as dependências dos campos.
- **Perfil por pessoa (achado 6):** 20 de 26 perfis em uso têm um único usuário. Se a solução criar campo novo, a permissão de campo (FLS) precisa ser ajustada em cada perfil e permission set afetado, o que multiplica a manutenção. Se a solução só alterar tamanho de campo existente, a FLS atual é preservada, mas vale checar.
- **Validation Rules (achado 8):** 387 ativas. Uma regra pode validar formato ou tamanho desses campos e ser a causa real da recusa, não só o tamanho. Não medido por objeto.
- **Cobertura de teste (achados 3 e 4):** 40% org-wide e 30 classes sem teste dedicado. Se a solução for só declarativa (metadata de campo), essa cobertura não bloqueia. Se o design envolver Apex (ex.: validação de URL em trigger), o deploy para produção exige 75% e a classe nova precisa de `<Classe>Test`. Hoje não há rede de teste nesse caminho.
- **Conga Composer e SDocs instalados (inventário):** se Cotação e Proposta são geradas em documento por template, o tamanho do campo pode também alimentar o documento. Não verificado.
- **SnapERP instalado (inventário):** se houver integração que lê ou escreve esses campos, a mudança de tipo pode quebrar a integração. Não verificado.

## Contexto de negócio

Na página do objeto "Cenário SF", cinco campos de preenchimento não aceitam links: **PFP 1 (UNC Path)**, **Cotação**, **Proposta acabada**, **Informações técnicas complementares** e **Aceite do cliente**. O consultor atribui a causa ao número baixo de caracteres da caixa. Não há informação sobre quem usa a tela, com que frequência, nem qual link é colado em cada campo.

Observação: "UNC Path" é um caminho de rede (`\\servidor\pasta\...`), não uma URL HTTP(S). O consultor fala em "links" de forma geral. Essa diferença muda a solução (ver perguntas 4 e 6).

## Objetivo

Permitir que o usuário registre, nos cinco campos, o link ou caminho de referência completo, sem que o valor seja recusado ou truncado por tamanho.

## Regra de negócio

A demanda não declara regra explícita. Regra implícita, a confirmar: **cada um dos cinco campos deve aceitar, de forma íntegra, um link ou caminho do tamanho máximo que o negócio usa, sem alterar o dado existente.** O tamanho máximo esperado não foi informado (premissa P3).

## Opções de solução (não escolhidas — dependem de resposta)

Esta escolha muda a arquitetura da mudança, por isso não escolho por conta própria.

- **A. Aumentar o comprimento do campo Text atual** (até o limite do tipo Text). Mantém o tipo e os dados existentes. Menor impacto, mas não atende se os links forem maiores que o limite do tipo Text.
- **B. Converter para Long Text Area.** Atende links longos e múltiplas linhas, mas muda o tipo do campo. Afeta fórmulas, Flows, relatórios, integrações e templates que leem o campo, e a reversão é restrita.
- **C. Converter para URL.** Valida formato e torna o link clicável, mas aceita um link só, limite menor, e não aceita caminho UNC. Muda o tipo do campo, com o mesmo impacto de B.

Se o tipo atual for Text e o maior link couber no limite do tipo Text, a opção A é a de menor risco. Esta é uma hipótese, não decisão. Confirmar no recon e com o cliente.

## Critérios de aceite (Gherkin)

Os valores entre `<...>` são pendentes e serão preenchidos após as respostas. Os critérios são testáveis com esses valores.

```gherkin
Funcionalidade: Campos de preenchimento do Cenário SF aceitam links

  Cenário: Link HTTPS completo é salvo sem truncamento no campo Cotação
    Dado um usuário com permissão de edição no campo Cotação do registro Cenário SF
    Quando ele informa o link "https://<dominio>/<caminho com <N> caracteres>" e salva
    Então o registro é salvo sem mensagem de erro de tamanho
    E ao reabrir o registro, o valor lido é idêntico ao informado, caractere a caractere

  Esquema do Cenário: Cada um dos cinco campos aceita o tamanho alvo
    Dado um usuário com permissão de edição no campo <campo> do registro Cenário SF
    Quando ele informa um texto de <N> caracteres no campo <campo> e salva
    Então o registro é salvo sem erro
    E o valor lido de volta tem <N> caracteres

    Exemplos:
      | campo                                  |
      | PFP 1 (UNC Path)                       |
      | Cotação                                |
      | Proposta acabada                       |
      | Informações técnicas complementares    |
      | Aceite do cliente                      |

  Cenário: Valor acima do novo limite continua sendo recusado
    Dado o campo <campo> com o novo limite de <N> caracteres
    Quando o usuário informa um texto de <N+1> caracteres e salva
    Então o sistema recusa o salvamento com mensagem de tamanho
    E nenhum dado é gravado

  Cenário: Dados existentes permanecem íntegros após a mudança
    Dado um registro Cenário SF com valor preenchido antes da mudança em <campo>
    Quando a mudança é implantada no ambiente de dev e de qa
    Então o valor anterior é exatamente o mesmo após a implantação

  Cenário: Automações e validações existentes continuam funcionando
    Dado um registro Cenário SF com os cinco campos preenchidos
    Quando um registro é salvo ou atualizado em dev após a mudança
    Então nenhuma automação ou validation rule que depende dos campos apresenta erro
    E o resultado é o mesmo do registro antes da mudança, conforme o roteiro de regressão de QA

  Cenário: Permissões de campo atuais são mantidas
    Dado um perfil ou permission set que hoje lê e edita um dos cinco campos
    Quando a mudança é implantada em dev
    Então esse perfil ou permission set continua com o mesmo acesso ao campo
```

Se o cliente decidir pela opção C (URL) ou pelo caminho UNC, será preciso um critério adicional de formato, por exemplo "Dado um texto que não é URL válida, então o sistema recusa". Só entra depois da resposta.

## O que a demanda não diz (precisa de resposta antes do design)

Perguntas bloqueantes marcadas com **(bloqueia)**. As demais podem ser respondidas durante o recon.

1. **(bloqueia)** Qual é o objeto exato? "Cenário SF" é objeto customizado (`__c`) ou padrão? Qual o nome de API? Os cinco campos estão nele ou em Oportunidade?
2. **(bloqueia)** Qual é o tipo e o tamanho atual de cada um dos cinco campos? O consultor disse "provavelmente" caixa pequena. Isso só se confirma com `sf sobject describe` na sandbox de dev, que é recon.
3. **(bloqueia)** Qual é o tamanho máximo que o negócio precisa? Qual é o link mais longo que existe hoje, ou que se espera?
4. **(bloqueia)** No campo "PFP 1 (UNC Path)", o usuário quer colar caminho de rede (`\\servidor\...`), URL HTTP(S), ou os dois?
5. **(bloqueia)** O link é só armazenado como texto, ou precisa ser clicável? Essa resposta decide entre as opções A, B e C.
6. **(bloqueia)** A recusa é só por tamanho? Há validation rule, máscara, fórmula ou outra regra que recusa o valor? O consultor assumiu o tamanho como causa, sem confirmar.
7. **(bloqueia)** Os campos são lidos por algo além da tela? Templates de Cotação ou Proposta (Conga Composer, SDocs), relatórios, integrações (SnapERP) ou outros Flows? Se sim, a mudança de tipo precisa ser planejada com esses consumidores.
8. Escopo: são só os cinco campos listados, ou outros campos parecidos do mesmo objeto também precisam? (Não ampliar sem resposta.)
9. Há registros com valor já truncado ou recusado hoje? Isso precisa ser levantado por quem tem acesso à produção, em agregado, sem dado de cliente (guardrail #2). A sandbox de dev não tem dados (0 registros em Opportunity no assessment).
10. Quem usa a tela (perfis) e qual é o prazo desejado?

## Premissas a validar (pendentes, nenhuma foi confirmada)

- **P1 (pendente):** o objeto é customizado e os cinco campos são customizados (`__c`).
- **P2 (pendente):** o tipo atual dos cinco campos é Text com 80 caracteres. Vem do palpite do consultor, não de consulta à org.
- **P3 (pendente):** o tamanho alvo é de 255 caracteres. Este número é meu, não da demanda; não usar sem confirmação.
- **P4 (pendente):** nenhuma validation rule, Flow, Process Builder ou integração depende do tamanho ou do tipo desses campos. Só o recon confirma.
- **P5 (pendente):** o escopo é só os cinco campos listados.
- **P6 (pendente):** a regressão será feita com massa sintética em dev. Nenhum dado real de cliente entra na análise nem na sessão (guardrail #2).

## Complexidade

**P** — mudança de metadata de cinco campos, sem Apex, com solução declarativa provável. Vira **M** se a resposta à pergunta 5 ou 7 levar à mudança de tipo (B ou C) ou se houver consumidor do campo (template, integração ou Flow) que precise ser ajustado.

## Estimativa de esforço

**Estimativa de esforço:** 3–8 h

Premissas que mais pesam na faixa:
- Recon do objeto e dos consumidores dos campos (describe, dependências, validation rules): 1–2 h. Vai para a faixa alta se houver integração ou template dependente.
- Alteração de cinco campos e revisão de FLS: 0,5–1 h. Vai para a faixa alta se a opção for B ou C, pela mudança de tipo.
- Teste de regressão em dev com massa sintética, incluindo automações e validation rules: 1–3 h.
- Homologação em QA e PR com revisão: 1–2 h.

A faixa é larga porque as perguntas 1, 2, 5, 6 e 7 não estão respondidas. O arquiteto refina no design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
