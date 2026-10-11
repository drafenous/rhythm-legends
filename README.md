# Rhythm Legends — MVP 0.4 (Clone Hero Importer)

Protótipo de jogo de ritmo em **Godot 4.7.2 / GDScript**, com visual Rock clássico e guitarra de cinco pistas.

## Executar
1. Importe `project.godot` no Godot 4.7.2 e execute com **F5**.
2. Abra **BIBLIOTECA → ESCOLHER PASTA CLONE HERO**.
3. Escolha uma pasta que contenha subpastas de músicas, cada uma com `song.ini` e `notes.mid` ou `notes.chart`.
4. Acesse **SELECIONAR MÚSICA**, escolha a faixa e a dificuldade.
5. Pressione **A S J K L** ao chegar à linha de acerto. **Esc** pausa.

A pasta é lembrada em `user://clone_hero_library.txt`. Nenhuma música é copiada para o projeto. Sem pasta configurada, o menu **TOCAR** preserva as músicas de demonstração.

## Importador 0.4
- Varredura recursiva de diretórios de músicas.
- `song.ini`: título, artista, gênero e ano.
- `notes.mid`: Standard MIDI File com eventos de tempo, alterações de BPM, canal MIDI e `PART GUITAR`; mapeamento de notas de 5 trastes (Easy 60–64, Medium 72–76, Hard 84–88, Expert 96–100).
- `notes.chart`: `[SyncTrack]`, BPM e `EasySingle/MediumSingle/HardSingle/ExpertSingle`.
- Conversão de ticks para segundos, inclusive alterações de tempo.
- HUD, combos, pontos, misses e resultado usando as notas importadas.

## Limitações conhecidas
- **Áudio ainda não toca**, incluindo arquivos `.opus`. O gameplay funciona como visualizador/julgador de chart sem referência musical.
- Sustains são lidos como duração, mas ainda não têm julgamento de sustentação.
- Ainda não há HOPO, tapping, open notes, frases de Star Power nem suporte completo a acordes e à palhetada real.
- Nem todos os formatos/variantes de `song.ini` foram verificados.
- No MIDI, o parser básico cobre `PART GUITAR`, mas não implementa SysEx, fraseamento, instrumentos adicionais ou regras completas de chart.
- No MIDI, o leitor associa notas por altura e ainda não cobre sobreposições de mesma altura.
- O algoritmo atual de input aceita apertar a tecla diretamente (sem strum).
- Projeto **ainda não testado no runtime do editor** por indisponibilidade do Godot no ambiente de execução.
- Arquivos de músicas comerciais pertencem aos titulares de direitos; importe somente conteúdo que você tenha autorização para usar.

## Scripts
- `scripts/main.gd` — menus, seleção e fluxo de jogo.
- `scripts/gameplay_engine.gd` — estado, julgamento e pontuação.
- `scripts/note_highway.gd` — desenho da pista 2D.
- `scripts/clone_hero_library.gd` — varredura, indexação e pasta persistida.
- `scripts/clone_hero_midi.gd` — leitura de Standard MIDI Files.
- `scripts/clone_hero_chart.gd` — leitura de arquivos de chart em texto.

## Próxima fase (0.5)
Implementar reprodução confiável de áudio e stems, relógio musical e calibração de latência antes de aumentar a complexidade de HOPO/sustains.
