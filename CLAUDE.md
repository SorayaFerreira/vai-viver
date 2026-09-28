# VaiViver

App Android (Flutter/Dart) de uso pessoal para reduzir tempo de tela no
Instagram: bloqueia a aba Reels e impõe um limite de tempo de rolagem ativa
no Feed. Detalhes de arquitetura e decisões de produto em `docs/design.md`;
requisitos rastreáveis em `docs/requirements.md`.

## Regras de trabalho

- **Nunca faça `git commit` neste projeto.** Deixe as mudanças no working tree
  e peça para a autora revisar e commitar ela mesma. Isso vale mesmo que a
  tarefa pareça concluída e pronta para commit. Sem exceções, nem se um plano
  ou skill tiver uma etapa de commit.

## Setup

- Antes do primeiro `flutter test`/`build` num clone novo, rode
  `tool/fetch_fonts.sh`. As fontes (Satoshi, JetBrains Mono) ficam fora do git
  por causa da licença da Satoshi, e este repositório é público.
- Flutter via FVM: `.fvm/flutter_sdk/bin/flutter`.
