# VaiViver — Roteiro de teste manual

Antes de considerar o MVP pronto, rode este roteiro no aparelho físico
(Xiaomi/Redmi/Poco, Android 13+):

## Calibração dos identificadores do Instagram

1. Instale o Instagram e o VaiViver no aparelho.
2. Abra o Instagram e, com o app "Accessibility Scanner" (ou o Layout Inspector
   do Android Studio conectado ao aparelho), inspecione a aba Reels e a aba Feed
   na barra inferior — anote o `resource-id` e/ou `content-description` reais.
3. Compare com as constantes em `ReelsTabRule.REELS_TAB_VIEW_ID_KEYWORDS` /
   `REELS_TAB_CONTENT_DESCRIPTIONS` e `FeedScrollLimitRule.FEED_TAB_VIEW_ID_KEYWORDS`
   (`android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/`).
   Ajuste as listas se os valores reais forem diferentes. **Importante:**
   confirme também que o atributo `selected`/`isSelected` (visível no
   Accessibility Scanner) aparece no **mesmo nó** que carrega esse
   `resource-id`/`content-description` — se o Instagram marcar `selected`
   num container pai ou num filho diferente, as regras nunca vão bater,
   mesmo com os identificadores certos.

## Onboarding

4. Instale o VaiViver do zero (ou limpe os dados do app) e abra-o — deve cair na
   tela de boas-vindas.
5. Complete o passo de Acessibilidade: o botão deve abrir a tela de
   Configurações de Acessibilidade do Android; ative o VaiViver lá e volte —
   o app deve reconhecer automaticamente que foi ativado.
6. Complete o passo de Otimização de Bateria: o botão deve abrir o diálogo do
   sistema; conceda a isenção.
7. Complete o passo de Autostart: siga as instruções na tela (Configurações >
   Apps > Gerenciar apps > VaiViver > Autostart, ou App Segurança > Permissões
   > Autostart no MIUI/HyperOS) e marque a caixinha.
8. Configure o limite de scroll (ex: 1 minuto, pra testar mais rápido) e conclua
   — deve cair na tela Home.

## Bloqueio de Reels

9. Abra o Instagram e toque na aba Reels — o VaiViver deve te levar
   imediatamente para a tela inicial do Android.
10. Desative o toggle "Bloquear aba Reels" nas Configurações do VaiViver, volte
    ao Instagram e toque em Reels de novo — agora não deve acontecer nada.

## Limite de scroll

11. Reative "Bloquear aba Reels" (ou deixe como está) e ative "Limite de scroll
    no Feed" com um valor baixo (1 minuto). Abra o Instagram, vá para o Feed e
    role continuamente — ao passar do tempo configurado, o VaiViver deve te
    levar para a tela inicial.
12. Saia do Instagram e volte a abrir — o contador deve ter reiniciado (você
    deve conseguir rolar pelo tempo configurado de novo).
13. Desative "Limite de scroll no Feed" e role o Feed por mais tempo que o
    limite configurado — não deve acontecer nada.

## Robustez

14. Reinicie o aparelho, abra o Instagram sem reabrir o VaiViver antes — no
    MIUI/HyperOS a Acessibilidade pode ter sido desativada automaticamente;
    confirme testando o bloqueio de Reels. Se não funcionar, abra o VaiViver:
    a tela Home deve mostrar "⚠️ Ação necessária".
15. Nas Configurações do Android, desative manualmente a permissão de
    Acessibilidade do VaiViver, volte para o app (sem fechá-lo) — a tela Home
    deve refletir isso na próxima vez que ela ganhar foco, sem precisar reabrir
    o app.
16. Confira as estatísticas do dia na tela Home depois dos testes acima —
    "Reels bloqueados hoje" e "Minutos de scroll evitados hoje" devem refletir
    o que aconteceu.

## Contagem de eventos

17. Teste a contagem de bloqueios de Reels: faça 3–5 toques rápidos e
    deliberados na aba Reels (toques simples, não mantidos nem repetidos) e
    confirme que o contador "Reels bloqueados hoje" na tela Home aumenta por
    volta de um por toque — não dois ou três por toque (o serviço já trava
    a contagem em um incremento por sessão; este passo é só a confirmação
    final no aparelho real).

## Reset de sessão por engano (risco conhecido, ver design.md §4.2)

18. Role o Feed continuamente e, no meio da rolagem, abra o teclado (toque
    na busca ou em comentar um post) ou aperte um botão de volume — depois
    volte a rolar até o tempo total configurado. Se o limite não disparar
    no tempo esperado (ou nunca disparar nessa sessão), é o risco já
    documentado: o teclado e os painéis do sistema (volume, notificações)
    podem resetar o contador de scroll por engano. Não é uma falha de
    segurança, só faz o limite demorar mais que o configurado — reportar
    se isso acontecer na prática, para priorizar o conserto.

## Visual e responsividade

19. Com o celular no tema claro, percorra onboarding (limpe os dados do app),
    Home, Configurações e Status das Permissões. Nenhum título pode ficar
    embaixo do relógio/câmera, e "Próximo"/"Concluir" ficam sempre acima da
    barra de navegação.
20. Com o app aberto, troque o celular para o tema escuro. O app deve
    acompanhar, com os textos legíveis sobre os cards de vidro.
21. Em Configurações do MIUI > Tela > Tamanho do texto, escolha o maior. Refaça o
    percurso do item 19: tudo deve ser alcançável rolando a tela, sem texto
    cortado nem sobreposto.
22. Se o launcher permitir, gire para paisagem (ou abra o VaiViver em tela
    dividida). O conteúdo deve rolar e o botão fixo do onboarding continuar
    visível.
