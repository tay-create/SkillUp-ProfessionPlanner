# Etapa 2 — Testes no WoW Forever

Esta etapa acrescenta o resumo da próxima ação e o progresso na aba **Rota** do Profession Planner. Os testes automáticos passaram. Preencha os resultados abaixo no jogo antes de avançarmos para a Etapa 3.

## Instalação

1. Feche o WoW. Faça uma cópia das pastas `ProfessionPlanner`, `ForeverCore` e `WTF` atuais.
2. Extraia `.release/ProfessionPlanner-etapa2.zip` na pasta `D:\World of Warcraft\_forever_\Interface\AddOns\`, substituindo os arquivos dos addons correspondentes. Confirme a existência de `ProfessionPlanner/ProfessionPlanner.toc` e `ForeverCore/ForeverCore.toc`.
3. Deixe a antiga pasta `SkillUpForever` fora de `AddOns` para evitar duplicação. No seletor de personagens, confira **Profession Planner**, **ForeverCore**, **!BugGrabber** e **BugSack**.
4. Execute `tools/iniciar_testes_wow.cmd` antes de abrir o jogo. Ao concluir os testes, digite `/reload` e execute `tools/finalizar_testes_wow.cmd` para gerar o relatório em `.release/ingame-diagnostics/relatorio.md`.

## Roteiro para preencher

Em cada item, substitua `[ ]` por `[x]` quando passar. Se falhar, anote profissão, habilidade atual, objetivo, receita e mensagem exibida.

1. **[x] Carregamento e `/pp`** — Entrar no personagem, abrir e fechar a interface. Conferir se a dependência carrega e não há erros Lua. Resultado:
2. **[x] Resumo e progresso** — Na aba **Rota**, conferir o texto **Próximo**, a habilidade atual, o alvo e o percentual. Exemplo esperado para habilidade 75 e objetivo 150, `Progresso: 75/150 (50%)`. Resultado:
3. **[ ] Treinamento de receita** — Encontrar um passo **Treinar [receita]**, por exemplo **Treinar Asa de Urubu grelhada**, e clicar tanto na instrução da lista quanto no resumo **Próximo** quando esse for o primeiro passo. Verificar se aponta um instrutor adequado. Resultado: to no meio do mapa onde n tem culinário trainer por perto por sinal clico em "treinar asa de urubu grelhado" e nada acontece. Se precisar procura um addon de mapa como OpenMap para usar o ping dele e fazer o caminho que siga trilha e se atualize caso precise para ficar bem organizado. Se estiver dando conflito com add-ons de mapa precisa ter um mecanismo que funcione com os add-ons de mapa mais famosos tanto quanto o mapa normal do wow forever.
4. **[x] Compra de receita** — Em uma rota que contenha **Comprar [receita]**, clicar no passo e no resumo **Próximo**. Conferir o vendedor indicado ou registrar por que o destino não foi encontrado. Se nenhuma rota oferecer compra, marcar **Não se aplica**. Resultado: Não se Aplica
5. **[x] Treinamento de categoria** — Aprovado pelo usuário no teste dentro do WoW. Resultado: aprovado.
6. **[ ] Fabricação** — Com **Fabricar [receita]** como próxima ação, clicar no resumo e confirmar que a receita aprendida abre na interface original. Fabricar normalmente, retornar à aba Rota e conferir a atualização da próxima ação e do progresso. Resultado:
7. **[x] Troca de profissão** — Alternar entre duas profissões na aba Rota. Conferir se a próxima ação e o progresso mudam junto com o objetivo. Resultado:
8. **[x] Layout** — Conferir se custo, próxima ação, progresso, títulos e listas aparecem separados, sem texto sobreposto. Se possível, testar a janela normal e uma janela ampliada. Resultado:
9. **[x] Persistência e combate** — Executar `/reload`, reabrir a rota e confirmar valores. Entrar e sair de combate e repetir um clique de navegação e uma fabricação normal quando permitido pelo jogo. Resultado:
10. **[x] Compras e Auctionator** — Conferir se a lista de compras própria continua funcionando e se a busca do Auctionator permanece acessível. Resultado:

Os marcadores dependem dos dados de locais disponíveis no cliente. `QuestieDB` fornece muitos instrutores e vendedores. Quando há coordenadas, a navegação usa `Shortest Path Forever`, `TomTom` ou o marcador nativo do mapa, conforme o que estiver disponível. Anote a mensagem do addon se ele só conseguir informar a localização em texto.

Depois de fechar o teste, envie os resultados junto com o relatório gerado. O caminho de evolução de Culinária apenas com peixes está programado para a **Etapa 3**.
