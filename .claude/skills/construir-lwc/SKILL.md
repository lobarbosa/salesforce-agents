---
name: construir-lwc
description: Checklist do desenvolvedor para Lightning Web Component — quando usar, acesso a dados, erro visível, segurança, acessibilidade e teste. Use na etapa de build quando o design aprovado pede componente de tela em código.
---

# Lightning Web Component

Componente de tela em código só existe quando o design justificou por que tela padrão,
Dynamic Forms, Screen Flow ou componente padrão não atendem. Se a justificativa não está
no design, pare e reporte: não é decisão do build.

## Dados

Use o nível mais simples que resolve, nesta ordem:

1. **Componentes base de formulário de registro** (`lightning-record-form` e os de
   visualização e edição): respeitam layout, permissão de campo e validação sem código.
2. **Lightning Data Service** por adaptadores (`getRecord`, `getRelatedListRecords` e as
   funções de criar e atualizar registro): cache compartilhado e permissão respeitada. Para
   várias consultas numa operação, o adaptador **GraphQL** (`lightning/graphql`) vem antes do
   Apex.
3. **Apex**, só para o que os dois acima não fazem (consulta que cruza objetos, regra no
   servidor).

Fonte: LWC Developer Guide, "Data Guidelines"
(https://developer.salesforce.com/docs/platform/lwc/guide/data-guidelines.html, lida em
2026-11-28). O LDS não consome chamada de API, mas **não atende Custom Metadata Type**; nos
formulários base, prefira listar os campos a usar o layout, que traz todos os campos dele.

Quando for Apex:

- Método só de leitura é `@AuraEnabled(cacheable=true)` e não grava nada; `@wire` exige
  `cacheable=true`. Não suponha tempo de cache. Depois de gravar por Apex imperativo, chame
  `refreshApex()` no dado do `@wire` e `notifyRecordUpdateAvailable(recordIds)` para o LDS:
  o LDS não enxerga o que o Apex imperativo gravou. Fonte: "Client-Side Caching of Apex
  Method Results"
  (https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html, lida
  em 2026-11-28).
- A classe declara `with sharing`, e a consulta respeita permissão de objeto e de campo
  (`WITH USER_MODE` explícito; na API 67.0 em diante é o padrão, skill `revisar-apex`).
- Nunca monte consulta concatenando texto vindo do componente.
- Devolva só os campos que a tela mostra. Não devolva o registro inteiro.
- O método valida a entrada: o que chega do navegador pode ser qualquer coisa.

## Estado da tela

Todo componente que busca dado tem quatro estados, todos tratados:

| Estado | O que a pessoa vê |
|---|---|
| Carregando | Indicador de carregamento, sem tela em branco |
| Com dado | O conteúdo |
| Vazio | Mensagem que diz que não há nada, e o que fazer |
| Erro | Mensagem em português, sem texto técnico cru, e sem engolir o erro |

Ação que grava: desabilite o botão enquanto roda, avise sucesso e falha, e atualize o que
a tela mostra depois de gravar.

## Segurança

- Nada de `innerHTML` com conteúdo vindo de dado. Use os componentes base e a marcação do
  modelo.
- Nenhum segredo, endereço de sistema externo ou Id fixo no JavaScript.
- Texto de tela em Custom Label quando a org é multilíngue ou o `CLAUDE.md` do cliente
  pedir; senão, em português, conferido.
- Navegação pelo serviço de navegação da plataforma, não por endereço montado à mão.

## Acessibilidade e aparência

- Componentes base e classes do design system da plataforma antes de CSS próprio.
- Todo campo tem rótulo; todo botão só com ícone tem texto alternativo.
- Tudo funciona pelo teclado, e o foco vai para a mensagem de erro quando ela aparece.
- Confira em largura estreita: o componente cabe em coluna lateral e em celular, se o
  design disser que será usado ali.

## Onde aparece

O arquivo de configuração do componente diz onde ele pode ser colocado (página de
registro, de aplicativo, de início) e para quais objetos. Exponha só o que o design pede.
Colocar o componente na página é metadata também (`FlexiPage`): se a demanda entrega a
página, ela está no pacote; se não, é passo manual listado.

## Teste

- Teste unitário de JavaScript (Jest) quando o projeto do cliente já tem a estrutura
  montada; se não tem, diga no plano que não há teste de componente e por quê. Não monte a
  estrutura por conta própria dentro de uma demanda.
- A classe Apex do componente tem a classe de teste dela, com a cobertura mínima da
  esteira, incluindo o usuário sem permissão.
- Teste de tela é do verificador e do QA: escreva no plano onde o componente aparece e o
  caminho para chegar até ele.

## Antes de escrever "concluído"

- [ ] A justificativa de código está no design.
- [ ] Os quatro estados da tela estão tratados.
- [ ] Depois de gravar, a tela mostra o dado novo (`refreshApex` / `notifyRecordUpdateAvailable`).
- [ ] Apex com `with sharing`, permissão respeitada e entrada validada.
- [ ] Deploy passou na dev e o componente abre na página, conferido.
- [ ] O plano diz em que página o componente fica e como chegar nele.
