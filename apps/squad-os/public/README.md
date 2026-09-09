# public/

## Marca

Coloque o logotipo aqui como **`marca.svg`** (ou `marca.png` / `marca.webp`, nessa
ordem de preferência) e ele aparece sozinho no topo da sidebar e na tela de login —
`lib/marca.ts` procura o arquivo, nenhum componente precisa ser editado.

Enquanto o arquivo não existir, a interface mostra a marca escrita ("Squad OS" com o
gradiente institucional), que é o estado atual. Não é um placeholder quebrado; é a
alternativa deliberada.

Requisitos:

- **SVG de preferência.** A marca é exibida em ~140px de largura, e tela retina pede o
  dobro de resolução — um SVG resolve sem gerar três PNGs.
- **Fundo transparente.** A sidebar tem fundo claro no tema claro e escuro no escuro; um
  logotipo com fundo branco chapado vira um retângulo esquisito no tema escuro.
- **Legível em cima de fundo escuro também.** Se a versão colorida some no escuro,
  coloque a versão monocromática clara como `marca-dark.svg` e me avise — hoje
  `lib/marca.ts` só procura um arquivo, e passar a alternar por tema é uma linha a mais.
