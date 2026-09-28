# VaiViver — Roteiro de teste manual

Antes de considerar o MVP pronto, rode este roteiro no aparelho físico
(Xiaomi/Redmi/Poco, Android 13+):

## Calibração dos identificadores do Instagram

1. Instale o Instagram e o VaiViver no aparelho.
2. Abra o Instagram e, com o app "Accessibility Scanner" (ou o Layout Inspector
   do Android Studio conectado ao aparelho), inspecione a aba Reels e a aba Feed
   na barra inferior — anote o `resource-id` e/ou `content-description` reais.
3. Compare com as constantes em `ReelsTabRule.REELS_TAB_VIEW_ID_KEYWORDS` /
   `REELS_TAB_CONTENT_DESCRIPTIONS` e `HomeTabDetector.VIEW_ID_KEYWORDS` /
   `CONTENT_DESCRIPTIONS`
   (`android/app/src/main/kotlin/com/sorayaferreira/vaiviver/detection/`).
   Ajuste as listas se os valores reais forem diferentes. **Importante:** o
   Instagram marca `selected`/`isSelected` no **ícone filho** do botão da aba
   (`tab_icon`, sem descrição), e às vezes também no próprio botão. O
   `HomeTabDetector` aceita as duas formas (calibrado em 2026-09-28: botão
   `feed_tab`, descrição "Home"); a `ReelsTabRule` ainda exige o `selected` no
   mesmo nó que carrega o `resource-id`/`content-description`.

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
8. Configure o limite diário no Feed (ex: 1 minuto, pra testar mais rápido) e conclua
   — deve cair na tela Home.

## Bloqueio de Reels

9. Abra o Instagram e toque na aba Reels — o VaiViver deve te levar
   imediatamente para a tela inicial do Android.
10. Desative o toggle "Bloquear aba Reels" nas Configurações do VaiViver, volte
    ao Instagram e toque em Reels de novo — agora não deve acontecer nada.

## Limite diário no Feed

11. Com "Limite diário no Feed" em 1 minuto, abra o Instagram na Início e
    **não toque em nada** por 1 minuto — o VaiViver deve te levar para a tela
    inicial mesmo sem rolagem.
12. Reabra o Instagram — ele abre na Início; você tem ~5 s para tocar em
    Direct/Buscar/Perfil. Nessas abas nada acontece; voltar para a Início te
    expulsa na hora. No dia seguinte (ou apagando os dados do app), o limite
    volta a valer do zero.
13. Apague a tela com o Instagram na Início por 2 minutos e volte: o tempo de
    tela apagada não pode ter contado (confira "Tempo no Feed hoje" na Home).
    Desative o limite: o tempo continua aparecendo na Home, mas nada é
    bloqueado.

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
    "Tempo no Feed hoje", "Reels bloqueados hoje" e "Saídas forçadas do Feed
    hoje" devem refletir
    o que aconteceu.

16b. Feche o VaiViver deslizando-o para fora dos apps recentes e abra de novo
    logo em seguida: se o Android ainda não religou o serviço, a Acessibilidade
    aparece como "parada" (e a Home, "Ação necessária"); em alguns segundos,
    ao voltar para o app, deve voltar a "ativada".

## Contagem de eventos

17. Teste a contagem de bloqueios de Reels: faça 3–5 toques rápidos e
    deliberados na aba Reels (toques simples, não mantidos nem repetidos) e
    confirme que o contador "Reels bloqueados hoje" na tela Home aumenta por
    volta de um por toque — não dois ou três por toque (o serviço já trava
    a contagem em um incremento por sessão; este passo é só a confirmação
    final no aparelho real).

## Fim de sessão por engano (corrigido, ver design.md §4.2)

18. Na Início, abra o teclado (busca ou comentário), aperte o volume e puxe
    uma notificação — nada disso pode encerrar a sessão. Depois do limite,
    voltar do teclado/volume para a Início deve expulsar na hora (sem nova
    janela de 5 s).

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
