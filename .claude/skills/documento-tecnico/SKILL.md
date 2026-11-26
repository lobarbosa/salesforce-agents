---
name: documento-tecnico
description: Layout padrão do documento técnico de construção que o arquiteto entrega em toda demanda (03-documento-tecnico.md) — o que vai ser construído, como, em que ordem, como testar, implantar e desfazer, escrito para os desenvolvedores Salesforce e, quando há integração, para o time do outro sistema. Use na etapa de design, depois de decidir a solução e antes de fechar o 03-design.md.
---

# Documento técnico de construção

Toda demanda sai do design com dois arquivos (decisão de 2026-11-26):

| Arquivo | Para quem | Responde |
|---|---|---|
| `03-design.md` | quem aprova o gate | o que foi decidido, por quê, e como cada critério será provado |
| `03-documento-tecnico.md` | quem constrói e quem integra | o que construir, como, em que ordem, como testar, implantar e desfazer |

O documento técnico não repete a justificativa do design: aponta para ela. Os dois não podem
se contradizer; se um muda, o outro muda junto. O builder e o verificador o leem antes de
construir, e ele vai para o time do outro sistema quando há integração.

Origem: documento de arquitetura da EPLAST-60, feito para os times Salesforce e Protheus.
O layout abaixo é o dele.

## Regras

- **Só metadata confirmada.** Objeto, campo, Flow ou classe que existe sai do `02-recon.md`
  ou de um `sf` específico. Componente novo leva "(novo)" e, se o nome não é definitivo,
  "(nome proposto)".
- **Nenhum dado real.** Exemplos de payload, chave ou registro são fictícios e dizem que são.
  Nada de Id de registro, nome, documento, e-mail ou valor de cliente.
- **Seção que não se aplica fica, com uma linha** dizendo por quê ("Não há integração nesta
  demanda."). Leitor que não acha a seção não sabe se foi esquecida.
- **Escreva para quem constrói**: tipo, tamanho, chave, gatilho, condição, ordem. Sem
  narrativa de negócio além do resumo.
- Tamanho: o que a demanda precisa. Uma correção pequena cabe em uma página.

## Layout padrão

Copie a estrutura e preencha. Títulos e ordem são fixos; o Squad OS e as pessoas procuram
as seções por nome.

```markdown
# Documento técnico – <DEMAND-ID>: <título da demanda>

**Cliente:** <cliente> · **Versão:** <AAAA-MM-DD> · **Design:** `03-design.md` · **Org de construção:** `sbx-<cliente>-dev`

## 1. Resumo
Problema e causa em até 3 frases. Solução em até 3 frases.

| Quem | O que faz |
| --- | --- |
| Dev Salesforce | ... |
| <Outro sistema>, se houver | ... |
| Consultor (produção) | ... |

## 2. Contexto na org
O que já existe e será tocado (do `02-recon.md`), com onde foi confirmado.

| Fato | Onde |
| --- | --- |

## 3. Arquitetura alvo
Diagrama do fluxo depois da mudança (mermaid `flowchart LR`), uma caixa por sistema ou
componente, setas com o que passa.

| Componente | Tipo | Novo, alterado ou nova versão | API name |
| --- | --- | --- | --- |

## 4. Modelo de dados e acesso
Cada campo ou objeto novo ou alterado: tipo, tamanho, obrigatório, chave externa, único,
valores. Quem lê e quem edita (perfil ou permission set).

## 5. Lógica e automações
Por componente: gatilho (objeto, evento, antes ou depois de salvar), condição de entrada, o
que faz, o que acontece no erro. Automações que já rodam no mesmo objeto e evento, e a
ordem entre elas. Flow ou classe que já existe: qual versão nova e quando ativa.

## 6. Integrações
Só quando a demanda chama ou é chamada por outro sistema; senão, uma linha.
- Hoje e depois (método, endpoint, chave).
- Formato das chaves.
- Exemplo de chamada com valores fictícios.
- Respostas e o que o outro sistema faz em cada uma.
- Plano B se o outro lado não puder mudar.

## 7. Dados: carga, migração e configuração
Registros que precisam existir no destino, carga inicial, correção de dados existentes,
desvios de trigger usados e por quê. Ou "Não há carga nem dado de configuração."

## 8. Plano de testes
| # | Cenário | Esperado | Critério |
| --- | --- | --- | --- |
Dado sintético criado pelo teste. Inclui o que não pode quebrar (regressão).

## 9. Implantação e rollback
Ordem de implantação na QA (esteira) e em produção (consultor), passos manuais com dono,
ativação.

| Passo | Como desfazer |
| --- | --- |

## 10. Responsabilidades, premissas e riscos
- Premissas, como `- [x]` com de onde vieram (regra das premissas assumidas do cliente).
- Riscos: risco, efeito, como tratar.
```

## Antes de fechar

- Cada componente da tabela da seção 3 aparece nas seções 4 a 7 e em pelo menos um cenário
  da seção 8.
- Nenhum nome de metadata existente que não esteja no `02-recon.md` ou confirmado por `sf`.
- Nada que pareça e-mail, CPF, CNPJ, telefone ou Id de registro real (o hook bloqueia o push
  e descarta a etapa).
