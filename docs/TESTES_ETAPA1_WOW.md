# Validação da Etapa 1 — WoW Forever

Use este roteiro com o personagem que tem uma profissão aprendida. Marque cada teste como **OK**, **Falhou** ou **Não se aplica**. Quando algo falhar, anote o passo, o que aconteceu e, se possível, a receita envolvida.

## Preparação

1. **Feche o WoW completamente** antes de instalar o pacote.
2. Guarde uma cópia da pasta `D:\World of Warcraft\_forever_\WTF` e das pastas `SkillUpForever`, `ProfessionPlanner` e `ForeverCore`, se existirem, em `Interface\AddOns`. Remova `SkillUpForever` da pasta ativa de addons para evitar duas cópias carregadas.
3. Para migrar preferências antigas, localize `WTF\Account\<conta>\SavedVariables\SkillUpForever.lua` e copie esse arquivo para `ProfessionPlanner.lua` na mesma pasta **antes de abrir o WoW**. Preserve o original e não substitua `ProfessionPlanner.lua` caso já exista.
4. Extraia `.release\ProfessionPlanner-etapa1.zip` dentro de `D:\World of Warcraft\_forever_\Interface\AddOns`. Ao final, devem existir `Interface\AddOns\ProfessionPlanner\ProfessionPlanner.toc` e `Interface\AddOns\ForeverCore\ForeverCore.toc`.
5. Dê dois cliques em `tools\iniciar_testes_wow.cmd` na pasta do projeto **antes de iniciar o jogo**. Isso marca o início dos logs. Se já tiver sido executado para esta sessão, não precisa repetir.
6. Abra o WoW Forever. Na lista de addons da seleção de personagem, confirme que `ForeverCore`, `Profession Planner`, `!BugGrabber` e `BugSack` estão habilitados.

## Testes dentro do jogo

1. **[ x ] Carregamento** — Entre no personagem. Confira se não há mensagem de dependência ausente, addon desativado ou erro Lua. Resultado: Não tem mensagem, esta funcionando.
2. **[ x ] Comando** — Digite `/pp` e veja se a interface abre ou se o comando responde conforme esperado. Feche e reabra a janela. Resultado: Funcionando.
3. **[ x ] Profissão** — Abra uma profissão com receitas disponíveis. Confira se o Profession Planner acrescenta informações às receitas sem atrapalhar a janela original. Resultado: Sim perfeito.
4. **[ x ] Dados das receitas** — Compare duas receitas de cores ou dificuldades diferentes. Confira requisito de habilidade, cor/limiar e chance de ganhar ponto, quando disponíveis. Resultado: esta ok, quero que na culinária eu possa escolher o caminho tradicional ou o caminho com fishing que é upar apenas com peixe
5. **[ x ] Planejamento** — Abra a rota de evolução. Confira profissão, faixa ou objetivo de habilidade, receitas sugeridas e ordem dos passos. Registre qualquer receita estranha ou impossível. Resultado: tudo ok, queria acrescentar uma forma que ao clicar por na instrução de "Treinar Asa de Urubu grelhada" por exemplo, assim que eu clicar já fazer um rastreador para onde treinar, se for no treiner de culinária marcar o treiner mais próximo, se for algo que precisa comprar recipe marcar onde compra recipe, entendeu?
6. **[ x ] Lista de compras** — Abra a lista de materiais da rota. Compare pelo menos uma receita, a quantidade planejada e os reagentes necessários. Confira o desconto de itens já presentes na bolsa, quando aplicável. Resultado: funcionando bem
7. **[ x ] Auctionator** — Se estiver instalado, abra o leilão e experimente a pesquisa ou lista de compras criada pelo Profession Planner. Verifique nomes e quantidades. Se não houver Auctionator, marque Não se aplica. Resultado: OK
8. **[ x ] Fabricação e atualização** — Fabrique um item de uma receita que aparece na rota. Observe se a profissão, o progresso e a lista de materiais se atualizam após a fabricação. Resultado: OK
9. **[ x ] Persistência** — Faça `/reload`. Reabra a profissão e o Profession Planner. Confira se configurações e rota permanecem coerentes. Resultado: OK
10. **[ x ] Combate e compatibilidade** — Entre e saia de combate com o addon carregado, depois abra a profissão e fabrique normalmente. Verifique se o `Profession Shopping List` continua abrindo e funcionando. A transferência direta da rota para esse outro addon está prevista para a Etapa 4. Resultado: ok, não vamos usar o profession shopping list já que temos lista de compra propria

## Encerramento e coleta de logs

1. Ao concluir, digite `/reload` **ou saia do personagem** para o WoW salvar os erros capturados pelo `!BugGrabber`.
2. Dê dois cliques em `tools\finalizar_testes_wow.cmd` na pasta do projeto.
3. O coletor criará `.release\ingame-diagnostics\relatorio.md` e `.release\ingame-diagnostics\errors.json`, com os erros registrados depois da linha de base. O relatório pode incluir informações do personagem e caminhos locais, então revise antes de compartilhar fora deste computador.
4. Diga no chat **"Terminei os testes do Profession Planner. Analise os logs."**. Pela conexão local posso ler o relatório e verificar as falhas junto com as respostas dos itens acima.

O `!BugGrabber` grava os erros quando o jogo salva suas variáveis. Se o relatório avisar que o arquivo não foi atualizado, faça `/reload` e execute novamente `finalizar_testes_wow.cmd`.

**Critério para encerrar a Etapa 1:** addon e dependência carregam, os fluxos principais de profissão, rota, compras e fabricação funcionam, e não aparecem erros Lua novos atribuíveis a `ProfessionPlanner` ou `ForeverCore`. Os resultados manuais acima são obrigatórios antes de iniciar a Etapa 2.
