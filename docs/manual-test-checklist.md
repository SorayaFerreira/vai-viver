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
   Ajuste as listas se os valores reais forem diferentes.

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
    volta de um por toque — não dois ou três por toque. Se o contador
    saltar 2+ por toque, há um problema de latência em `ReelsTabRule` ou
    `FeedScrollLimitRule` (sem "one-shot latch", as rajadas rápidas de eventos
    de acessibilidade antes de `GLOBAL_ACTION_HOME` podem contar múltiplas
    vezes). Nesse caso, a correção é adicionar um one-shot latch nas classes de
    regra — ver `docs/design.md` seção 4.2, último bullet de risco.
