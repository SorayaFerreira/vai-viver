# VaiViver — Requisitos

> Complementa `docs/design.md` (que explica arquitetura e decisões técnicas).
> Este documento lista o que o sistema deve fazer, de forma objetiva e rastreável.

## Requisitos Funcionais (RF)

| ID | Descrição |
|----|-----------|
| RF01 | O sistema deve detectar quando a aba "Reels" do Instagram é aberta. |
| RF02 | Ao detectar a aba Reels, o sistema deve acionar a ação Home do Android (`GLOBAL_ACTION_HOME`), retirando a usuária do Instagram. |
| RF03 | O sistema deve medir o tempo acumulado de rolagem ativa (gestos de scroll) na aba Feed do Instagram. |
| RF04 | O sistema deve permitir configurar o limite de tempo de rolagem ativa (padrão: 2 minutos). |
| RF05 | Ao atingir o limite de rolagem configurado, o sistema deve acionar `GLOBAL_ACTION_HOME`. |
| RF06 | O contador de rolagem ativa deve reiniciar a cada nova sessão do Instagram. |
| RF07 | O sistema deve permitir habilitar/desabilitar independentemente o bloqueio de Reels e o limite de scroll. |
| RF08 | O sistema deve exibir estatísticas diárias: quantidade de bloqueios de Reels e minutos de scroll evitados no dia corrente. |
| RF09 | O sistema deve guiar a usuária através de um fluxo de concessão de permissões (Acessibilidade, Otimização de Bateria, Autostart no MIUI). |
| RF10 | O sistema deve permitir verificar e corrigir o status de cada permissão a qualquer momento, fora do fluxo inicial de onboarding. |
| RF11 | O sistema deve restringir a leitura de conteúdo de tela exclusivamente ao pacote do Instagram (`com.instagram.android`). |

## Requisitos Não-Funcionais (RNF)

| ID | Descrição |
|----|-----------|
| RNF01 | Plataforma-alvo: Android 13+ (dispositivo de referência: Xiaomi/Redmi/Poco, MIUI/HyperOS). |
| RNF02 | Distribuição via sideload (instalação direta de APK), sem publicação em loja de apps. |
| RNF03 | Arquitetura MVVM no lado Flutter, usando Riverpod como solução de state management/DI. |
| RNF04 | Uso do Repository Pattern para abstrair a origem dos dados (configurações e estatísticas) das ViewModels, garantindo testabilidade via fakes/mocks. |
| RNF05 | Uso do Strategy Pattern no lado nativo (Kotlin) para as regras de detecção — cada regra de bloqueio como uma classe independente. |
| RNF06 | Persistência local apenas (sem backend, sem sincronização em nuvem). |
| RNF07 | O app não deve reter nem transmitir a nenhum servidor externo qualquer conteúdo lido da tela do Instagram — processamento 100% local/on-device. |
| RNF08 | A interface do usuário deve ser em português (pt-BR). |

## Restrições e Limitações Conhecidas (RL)

| ID | Descrição |
|----|-----------|
| RL01 | Não é possível forçar o encerramento real do processo do Instagram sem root/Device Owner — a ação usada é sempre `GLOBAL_ACTION_HOME`. |
| RL02 | A detecção de telas do Instagram depende de identificadores internos não documentados, que podem mudar em atualizações do Instagram e quebrar a detecção sem aviso. |
| RL03 | Em dispositivos MIUI/HyperOS, a permissão de Acessibilidade pode ser desativada automaticamente após reinicialização do aparelho, exigindo reativação manual. |
| RL04 | O reset "por sessão" do contador de scroll é contornável simplesmente saindo e reabrindo o Instagram — escolha consciente de simplicidade sobre rigor. |

## Fora de Escopo (nesta versão)

- Bloqueio de Reels exibidos dentro do scroll do Feed (fora da aba dedicada).
- Bloqueio de qualquer outro app além do Instagram.
- Histórico de estatísticas além do dia corrente.
- Sincronização em nuvem / múltiplos dispositivos.
- Publicação na Play Store.

## Rastreabilidade

Decisões de produto por trás destes requisitos, e o detalhamento técnico de como
cada um será implementado, estão em `docs/design.md`.
