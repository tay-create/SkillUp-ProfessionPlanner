# Planejador de profissões para WoW Forever

## Propósito

Construir uma evolução do SkillUp Forever para planejar profissões com mais clareza e precisão, com escolha de objetivo, materiais, custo e assistência durante a fabricação. O desenvolvimento segue uma etapa por vez, com testes antes de avançar.

## Etapas

| Etapa | Entrega | Situação |
| --- | --- | --- |
| 1 | Ambiente, estudo da base, estrutura, testes e pacote de referência | Concluída: 10/10 testes no jogo aprovados em 14/11/2026 |
| 2 | Interface com próxima ação clicável, progresso e custos visíveis | Aprovada no WoW pelo jogador em 17/11/2026 |
| 3 | Planejador de rotas integradas de profissões complementares, com prioridades de custo, tempo e equilíbrio: Culinária + Pesca (Fishing) e Alfaiataria (Tailoring) + Encantamento (Enchanting) | Validada pelo jogador em 20/11/2026 |
| 4 | Aperfeiçoar a lista própria de compras, estoque, segurança da rota e Auctionator | Em andamento: estoque compartilhado, listas Auctionator e escolha de preços TSM |
| 5 | Assistente de fabricação e acompanhamento de receitas | Pendente |
| 6 | Navegação avançada até instrutores e vendedores, rotas recalculadas ao viajar, compatibilidade com Shortest Path Forever, TomTom, OpenMap e mapa nativo, rotas de coleta e personagens alternativos | Pendente |
| 7 | Compatibilidade final, documentação e publicação | Pendente |
| 8 | Nova interface do Profession Planner, simplificada e com identidade visual própria | Pendente |

O MVP será avaliado ao concluir a etapa 4. Cada etapa inclui seus próprios testes.

### Ideias confirmadas nos testes da Etapa 1

- **Etapa 2:** mostrar a próxima instrução no topo da rota, clicável, reutilizando a marcação de destino já implementada para instrutores e vendedores. A navegação completa permanece para a Etapa 6. O botão **Profession Planner** foi instalado e confirmado no jogo.
- **Etapa 3:** planejar o avanço conjunto de profissões complementares: Culinária com Pesca, usando peixes pescados nas receitas, e Alfaiataria com Encantamento, aproveitando itens produzidos pela Alfaiataria para obter materiais por desencantamento. Para Culinária + Pesca, identificar peixes usados nas receitas, exibir um ícone de anzol no reagente e permitir localizar o ponto de pesca mais próximo e criar um waypoint. Permitir avaliar rotas tradicionais e integradas, considerando disponibilidade de receitas, materiais e avanço em cada faixa de habilidade.
- **Etapa 4:** manter a lista de compras do próprio Profession Planner e aperfeiçoar sua integração com Auctionator. A integração com Profession Shopping List foi cancelada por decisão do jogador.
- **Etapa 8:** redesenhar a interface para distinguir o Profession Planner do SkillUp Forever, com navegação mais simples entre rota, próxima ação, materiais e fabricação. Mostrar primeiro as informações essenciais, reduzir elementos visuais desnecessários e manter as funções já aprovadas. Validar o novo visual e a usabilidade no jogo antes de concluir a etapa.

## Base técnica da Etapa 1

- Repositório de referência: `https://github.com/cjber/skillup-forever`, versão 1.10.1, commit `888f7b0`.
- Fonte do trabalho: `SkillUp-ProfessionPlanner`, branch `codex/etapa-1-fundacao`.
- Repositório público próprio: `https://github.com/tay-create/SkillUp-ProfessionPlanner` (fork, com histórico e autoria da base original preservados). A versão em desenvolvimento será publicada após a validação da Etapa 1.
- Remotes locais: `origin` aponta para o fork e `upstream` para `cjber/skillup-forever`.
- Dependência obrigatória: `ForeverCore`, tag `v1.12.1`, checkout irmão `../forever-core`.
- Cliente: WoW Forever, interface `16001`, Lua 5.1.
- `Core/Model.lua` concentra chances e custo por avanço. `Core/Plan.lua` produz a rota. `Core/Live.lua` obtém dados da janela de profissão. `Core/Changes.lua` controla atualizações e invalidação de caches.
- `Integrations/Prices.lua` calcula preços e intermediários. `UI/Route.lua`, `UI/Pages.lua` e `UI/PageParts.lua` exibem e navegam pelas rotas.
- A base original permanece no Git. O branch de desenvolvimento registra as mudanças em separado.
- `writ-profession` é outro projeto e fica fora deste trabalho.

## Decisões de compatibilidade

Esta primeira entrega usa o **motor funcional do SkillUp Forever** como ponto de partida. A identidade do addon agora é **Profession Planner**, com pasta `ProfessionPlanner`, arquivo `ProfessionPlanner.toc`, comando `/pp` e variáveis salvas em `ProfessionPlannerDB`. Para preservar preferências anteriores, o código pode importar `SkillUpForeverDB` quando o antigo arquivo de variáveis for copiado para `ProfessionPlanner.lua` antes de iniciar o jogo.

As alterações de interface devem respeitar as ações protegidas do jogo, inclusive em combate. A fabricação continuará usando os controles seguros existentes até haver um teste dentro do cliente. Novas opções de planejamento serão separadas da leitura de dados ao vivo e da renderização para facilitar testes.

O trabalho deriva do SkillUp Forever e permanece sujeito à licença **GPL-3.0-or-later**. Os arquivos `LICENSE`, `THIRD_PARTY.md` e os créditos existentes precisam acompanhar distribuições derivadas. O ForeverCore mantém seu código e seus avisos separados no pacote.

## Verificações automáticas

Executar na raiz do projeto, com ForeverCore ao lado. LuaJIT, Lua 5.1.5 (luac), Python e StyLua devem estar instalados. A regeneração de dados também usa o cache de fontes de `tools/.cache`.

```powershell
$lj = "$env:LOCALAPPDATA\Programs\LuaJIT\bin\luajit.exe"
Get-ChildItem tests/*_spec.lua | ForEach-Object { & $lj $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Erro em $($_.Name)" } }
& $lj tests/bench.lua
python tools/check_api_docs.py
python tools/check_localization.py
python tools/check_client_load.py
python tools/check_generated.py
python tools/package_local.py --stage 2
$env:PATH = "$env:LOCALAPPDATA\Programs\LuaJIT\bin;$env:PATH"
$env:FOREVER_CORE = (Resolve-Path ../forever-core).Path
$env:LUA51_LUAC = Join-Path $env:LOCALAPPDATA 'Programs\SkillUp-Lua51\luac5.1.exe'
python tools/check_package.py --release-dir "$env:TEMP/ProfessionPlanner-stage2"
```

O pacote local gerado para a Etapa 2 é `.release/ProfessionPlanner-etapa2.zip`. A montagem temporária fica em `%TEMP%/ProfessionPlanner-stage2` para evitar bloqueios de exclusão do OneDrive. O ZIP separa os diretórios `ProfessionPlanner` e `ForeverCore`, omite arquivos de desenvolvimento e preenche os marcadores de versão dos arquivos `.toc`.

## Resultado da Etapa 1 em 14/11/2026

- **Aprovado:** 64 arquivos de testes Lua, benchmark, checagem de carregamento do cliente, documentação da API, localizações, arte, editorconfig, estrutura da família de addons, StyLua 2.5.2, Ruff e dados gerados. `tools/check_generated.py` comprovou que os cinco arquivos de dados estão atualizados e são reproduzíveis byte a byte no Windows.
- **Aprovado:** ForeverCore `v1.12.1`, `tools/check_package.py` com o compilador Lua 5.1.5 e cenário do simulador. O ZIP foi testado, contém **133 arquivos** e passou na verificação de integridade.
- **Verificações adicionais aprovadas:** varredura de código morto, créditos, changelog, simulações e testes executados pelos verificadores do projeto.
- **Aprovado:** Gitleaks 8.30.1 analisou o histórico Git sem detectar vazamentos. O `tools/typecheck.sh` concluiu com Lua Language Server 3.19.1 sem diagnósticos, 48 arquivos de carregamento cobertos, 417 traduções verificadas e 93 testes Python aprovados.
- **Aprovado:** o gerador de screenshots foi ajustado para a codificação UTF-8 do Windows. As 14 imagens de referência foram renderizadas novamente, registradas e verificadas com sucesso.
- **Pendência de ferramenta auxiliar:** Luacheck 1.1.2 ainda precisa ser disponibilizado no Windows para repetir integralmente a etapa de lint do CI.
- **Validação manual concluída:** os 10 testes no WoW Forever passaram em 14/11/2026, incluindo comando `/pp`, rotas, lista de compras, Auctionator, fabricação, persistência e combate. Consulte `docs/TESTES_ETAPA1_WOW.md`.
- **Logs do jogo:** a coleta entre 17:48 e 18:03 registrou um erro novo de `ZygorGuidesViewerForever/Sync.lua:57` (`surname` nulo), sem erros novos atribuídos a Profession Planner ou ForeverCore.

As cinco ferramentas `tools/gen_thresholds.py`, `tools/gen_vendor.py`, `tools/gen_recipes.py`, `tools/gen_trainer.py` e `tools/gen_sources.py` agora escrevem LF explicitamente, permitindo repetir a geração no Windows sem divergência artificial com os arquivos versionados.

## Resultado local da Etapa 2 em 17/11/2026

- **Interface:** o topo da aba Rota destaca a próxima ação, apresenta a habilidade atual em relação ao objetivo e reutiliza o clique existente para receita, instrutor, vendedor ou treinamento de categoria.
- **Testes:** 64/64 arquivos de especificações Lua passaram. `route_spec.lua` passou com 201 verificações e `route_layout_spec.lua` com 555. O benchmark e as verificações de API, localização, carregamento e dados gerados também passaram.
- **Pacote:** `.release/ProfessionPlanner-etapa2.zip`, com 133 arquivos, `ProfessionPlanner` e `ForeverCore`. A integridade ZIP e `tools/check_package.py` passaram, incluindo testes executados sobre os arquivos empacotados.
- **Validação no jogo:** o jogador confirmou que o botão **Profession Planner** foi instalado e funciona. Os testes `pages_spec` (54 verificações) e `profession_tabs_spec` (36 verificações) passaram.
- **Situação:** Etapa 2 aprovada. A Etapa 3 foi iniciada com Culinária + Pesca.

## Etapa 3 — Culinária + Pesca

O primeiro recorte da Etapa 3 conecta os reagentes de peixe a locais registrados de pesca para que o jogador consiga sair de uma receita e descobrir onde buscar o material. O rastreador fica disponível tanto na rota comum de Culinária quanto no contexto combinado de Culinária + Pesca. Também se aplica a peixes usados como reagentes em rotas de outras profissões.

- **Implementado:** peixes reconhecidos pelo catálogo de pesca recebem um ícone de anzol na lista de reagentes de qualquer rota de profissão, incluindo Culinária e outras profissões. Clicar no reagente aciona a busca por esse peixe; reagentes comuns permanecem sem o ícone.
- **Implementado:** foram incorporados 7.730 registros históricos de captura, cobrindo 16 dos 23 peixes cadastrados, obtidos de dados públicos do GatherLite referentes ao WoW Forever. Quando há coordenadas no mesmo continente/instância e posição válida do personagem, o anzol escolhe o ponto registrado mais próximo por distância no mundo e cria uma rota ou waypoint via Shortest Path Forever, TomTom ou mapa nativo. Cliques seguintes percorrem outros pontos e, após esgotá-los, reiniciam a seleção.
- **Comportamento esperado:** um ponto registrado pode estar sem cardume porque outro jogador pescou ali; isso não invalida o histórico de captura. Os pontos são referências de onde um peixe já foi obtido, sem garantia de cardume ativo naquele instante.
- **Navegação atualizada:** o anzol tenta primeiro a captura registrada mais próxima na instância atual. Se houver somente capturas de outra região, ainda tenta marcar um desses pontos históricos. Para os 7 peixes sem coordenadas de captura, tenta colocar uma rota ou waypoint no centro aproximado da zona atual ou da zona conhecida mais próxima. Usa Shortest Path Forever, TomTom ou o waypoint nativo, conforme disponível, e informa no chat se criou rota, waypoint ou não conseguiu marcar o destino. Nas zonas aproximadas, procurar água pescável perto do destino.
- **Escolha de rota:** na aba **Rota**, quando a profissão selecionada é Culinária, o botão alterna entre **Culinária normal** (planejamento por custo, padrão) e **Culinária + Pescaria** (prioridade para receitas com peixe com locais cadastrados). A escolha é salva por personagem e recalcula o plano. O anzol continua disponível nos reagentes de peixe de qualquer profissão, em ambos os modos.
- **Implementado:** o catálogo de associações peixe–zona é gerado a partir de `fishing_loot_template` e `reference_loot_template`, cruzando `AreaTable` e `UiMapAssignment`, com chance mínima de 10% nesta versão.
- **Verificação automatizada:** 64/64 arquivos da suíte Lua passaram em 18/11/2026 após normalizar a quebra de linha do modelo de traduções. `route_spec` (236 verificações), `waypoint_spec` (109), `pages_spec` (54), `profession_tabs_spec` (36) e `locale_spec` (9.164) passaram. A Etapa 2 e o botão **Profession Planner** foram preservados.
- **Validação em jogo (20/11/2026):** o jogador confirmou que o botão e o comando `/pp` voltaram a funcionar e que a seleção entre **Culinária normal** e **Culinária + Pescaria** está funcional. Também havia confirmado os destinos de pesca. Permanecem para conferência pontual a comparação de receitas entre modos, o anzol em ambos e a persistência da escolha após `/reload`.
- **Pacote de teste:** `.release/ProfessionPlanner-etapa3.zip` regenerado em 18/11/2026 com `python tools/package_local.py --stage 3`, incluindo `ProfessionPlanner`, `ForeverCore` e `Data/FishingPoints.lua`. O ZIP tem 135 arquivos, versão `1.10.1-etapa3` e integridade verificada. O verificador `tools/check_package.py` exige o empacotamento da publicação, o compilador Lua 5.1 fixado e a atualização do pin de ForeverCore; por isso ele não concluiu a verificação neste ambiente local.
- **Instalação local em 18/11/2026:** os arquivos de `ProfessionPlanner` foram copiados para `D:\World of Warcraft\_forever_\Interface\AddOns\ProfessionPlanner` e sete arquivos essenciais conferidos por SHA-256 (7/7). Backup anterior em `C:\Users\taay1\AppData\Local\Temp\ProfessionPlanner-backup-20261118-011449`. A cópia instalada de ForeverCore permaneceu em `v1.14.5` para preservar a versão mais nova já presente no cliente. Como o jogo estava aberto, é necessário `/reload` para carregar os novos arquivos.

### Registro de manutenção e encaminhamento (20/11/2026)

- **Compatibilidade com ForeverCore 1.15.6:** o carregamento de `ForeverCore` foi ajustado para aguardar `PLAYER_LOGIN` e os callbacks de prontidão, por mudanças na inicialização do núcleo. O reparo foi instalado localmente com backup em `D:\World of Warcraft\_forever_\ProfessionPlanner-backups\20261120-144059-core-startup`.
- **Verificações automatizadas registradas:** 65/65 arquivos de testes Lua passaram, incluindo `tests/deferred_core_spec.lua` (5 verificações), e `git diff --check` passou. A interface previamente aprovada e os testes `pages_spec` (54) e `profession_tabs_spec` (36) foram preservados.
- **Confirmação manual do jogador:** botão, `/pp` e os dois modos de Culinária voltaram a funcionar. As coordenadas históricas de pesca e a navegação até pontos de peixe já haviam sido confirmadas.
- **Pendências de validação específica:** mudança efetiva na seleção de receitas entre modos em um caso com alternativas, anzol nas duas configurações e persistência após `/reload`. A confirmação geral do jogador não atesta individualmente esses cenários.

**Alfaiataria + Encantamento (etapa de rotas, 20/11/2026):** `Integrations/Disenchant.lua` sugere, no tooltip, equipamentos verdes conhecidos de Alfaiataria que podem fornecer materiais de Encantamento por desencantamento. A rota agora escolhe fabricar/desencantar quando o custo estimado é inferior ao de comprar os reagentes faltantes. Exibe etapas de fabricação dos componentes, fabricação do equipamento e desencantamento, com o rendimento esperado. A lista de compras e o custo total incluem os materiais da Alfaiataria, os reagentes presentes nas bolsas e banco, e as peças verdes já disponíveis. Peças existentes são alocadas uma vez por plano, e alterações nas bolsas atualizam as listas rastreadas quando ambas as profissões estão aprendidas.
- **Referência e limite dos números:** as faixas usam *nível de item* da tabela de WoW Forever em `https://legacyofwarcraft.com/db/forever/professions/disenchanting.html`; as probabilidades são aproximações dos dados Classic associados às mesmas faixas. A tabela de `https://www.wow-professions.com/forever/disenchanting-guide` usa *nível necessário para equipar*, portanto não serve diretamente para indexar o nível de item. O resultado do desencantamento é aleatório e os percentuais específicos do servidor ainda precisam de verificação. O tooltip comunica essa incerteza.
- **Validação automatizada da integração:** 66/66 arquivos de testes Lua passaram com o checkout ForeverCore `v1.15.2`. `disenchant_spec` cobriu 44 verificações, incluindo redução pelo estoque, preço, escolha, compra e alocação de equipamentos. A instalação live utiliza ForeverCore `v1.15.6` e necessita de validação manual específica.

**Validação da Etapa 3:** o jogador confirmou o funcionamento da integração e autorizou o avanço em 20/11/2026. As probabilidades de desencantamento do servidor continuam como estimativas até que haja dados oficiais.

**Etapa 4 — estoque compartilhado (20/11/2026):** a lista geral de compras reserva cada reagente uma vez entre as profissões rastreadas (ordem alfabética), evitando subestimar a quantidade total a comprar. O campo `have` na visão conjunta representa o estoque alocado àquela rota. Ao consultar uma profissão isoladamente, a API mantém o estoque integral do personagem. As listas individuais do Auctionator usam o mesmo saldo compartilhado, recalculado quando as bolsas mudam. Os testes automatizados passaram em 66/66 arquivos, incluindo cenários com duas profissões disputando o mesmo tecido. Instalados `UI/Shopping.lua` e `Core/API.lua` em `D:/World of Warcraft/_forever_/Interface/AddOns/ProfessionPlanner`, com SHA-256 conferido (2/2) e backup em `D:/World of Warcraft/_forever_/ProfessionPlanner-backups/20261120-165226-stage4-shared-stock`. A validação manual no cliente ainda depende de `/reload` e de testar duas profissões acompanhadas com o mesmo reagente.

**Etapa 4 — fonte de preços Auctionator/TSM (20/11/2026):** em *Configurações > Preços*, o jogador pode selecionar **Automática (Auctionator primeiro)**, **Somente Auctionator** ou **Somente TradeSkillMaster**. O modo automático usa o preço do Auctionator e recorre ao TSM se faltar um valor. Cada modo exclusivo consulta apenas sua fonte de preços de leilão. Preços de vendedores continuam sendo considerados. A orientação de reagente sem preço respeita a fonte escolhida. As listas de compra continuam integradas ao Auctionator; a API pública do TSM disponível nesta instalação permite consultar valores, mas não ofereceu uma operação de lista de compras. Testes automatizados: 66/66 arquivos, incluindo 27 verificações do TSM, mais checagem de formatação dos arquivos envolvidos. Instalados cinco arquivos no cliente `_forever_`, com hashes SHA-256 conferidos (5/5), backup em `D:/World of Warcraft/_forever_/ProfessionPlanner-backups/20261120-171158-stage4-tsm-prices`. Ainda é necessário `/reload` e conferir as três opções com dados reais de leilão no WoW. O recálculo de rotas continua sob responsabilidade do engenheiro-chefe.

O comando `python tools/package_local.py --stage 1` continua gerando o pacote da Etapa 1 quando necessário. As etapas 1, 2 e 3 usam diretórios temporários e nomes de ZIP distintos.

## Instalação e validação no jogo

O roteiro de testes atual e a coleta de erros estão em `docs/TESTES_ETAPA2_WOW.md`. Os resultados anteriores estão registrados em `docs/TESTES_ETAPA1_WOW.md`.

1. Fechar o WoW e fazer backup de `Interface/AddOns/SkillUpForever`, `Interface/AddOns/ProfessionPlanner`, `Interface/AddOns/ForeverCore` (quando existirem) e `WTF`. Remover a pasta antiga `SkillUpForever` de `Interface/AddOns` para evitar carregamento duplicado.
2. Para migrar as preferências, copiar `WTF/Account/<conta>/SavedVariables/SkillUpForever.lua` para `ProfessionPlanner.lua` no mesmo diretório, sem substituir um arquivo que já exista. Extrair o ZIP em `Interface/AddOns/` da instalação WoW Forever. O ZIP contém as pastas `ProfessionPlanner` e `ForeverCore`. Na instalação live o diretório costuma ser `_forever_`, e na beta `_classic_beta_`.
3. Abrir a lista de addons, confirmar que **ForeverCore** e **Profession Planner** carregaram e acessar uma janela de profissão.
4. Testar `/pp`, abrir a aba de rotas, conferir a próxima fabricação e a lista de materiais. Usar `/reload` e verificar se não houve erros Lua.
5. Verificar ações protegidas em combate e confirmar se uma fabricação normal funciona após sair do combate.

A Etapa 1 foi validada dentro do jogo em 14/11/2026. A Etapa 2 adiciona um resumo clicável da próxima ação e o progresso até o objetivo acima das listas. A Etapa 2 foi aprovada pelo jogador em 17/11/2026. O desenvolvimento segue agora para Culinária + Pesca na Etapa 3.
