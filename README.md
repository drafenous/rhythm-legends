# Rhythm Legends — MVP 0.5: Áudio e Sincronização

Protótipo Godot 4.7.2 (GDScript), identidade Rock clássico, guitarra de cinco pistas.

## Teste local
1. Execute `git pull origin main` e importe `project.godot` no editor.
2. Execute F5 → **Biblioteca** → escolha sua pasta de músicas Clone Hero (subpastas com `song.ini` e `notes.mid` ou `notes.chart`).
3. Selecione a música e dificuldade. Aperte **A S J K L** ao chegar à linha de julgamento; Esc pausa.
4. Para arquivos `.opus` (por exemplo, *Before I Forget*), instale **FFmpeg** e configure o executável `ffmpeg` no PATH do sistema; reinicie o editor Godot após ajustar o PATH. Faça o teste com `ffmpeg -version` no terminal.
5. Em **Configurações → Áudio**, ajuste volume geral de música; em **Calibração**, ajuste atraso entre -250 e +250 ms. Preferências são gravadas em `user://audio_settings.cfg`.

## Nesta versão
- Carregamento externo de áudio OGG Vorbis, MP3 e WAV pelo Godot, sem copiar a biblioteca para `res://`.
- Para Opus: conversão por FFmpeg a Vorbis em `user://audio_cache`, reusando o cache com hash de caminho e mtime.
- Múltiplos stems: song, guitar, rhythm, bass, drums, drums_1 a drums_4, vocals, keys e crowd quando existirem. Cada stem usa um `AudioStreamPlayer`.
- Relógio das notas derivado da posição de reprodução, compensando mix e latência de saída; fallback sem áudio para teste visual.
- Pausa, retomada, replay e saída interrompem ou controlam os stems.
- Ajuste de latência e volume preservados entre sessões.
- Importador 0.4 de `song.ini`, `notes.mid`, `notes.chart` e quatro dificuldades preservado.

## Restrições e cuidados
- **FFmpeg é uma dependência externa opcional**, necessária para músicas somente em Opus. Não vem com o jogo.
- A conversão é feita de forma síncrona quando uma música é selecionada: primeira carga pode bloquear a UI, e várias faixas consomem espaço em disco. Futuramente fazer conversão em segundo plano.
- Os stems são disparados em sequência no mesmo frame, **não há garantia de alinhamento sample-accurate**; para sincronismo profissional precisamos aprimorar essa abordagem.
- Não há reprodução em streaming com gerenciamento de memória/decodificação assíncrona.
- A calibração aplica um deslocamento simples ao tempo das notas; não há assistente de calibração automática.
- Sustains, HOPO, tapping, frases de Star Power, input de palhetada e controles externos ainda não estão completos.
- Nem todos os casos de charts e song.ini foram testados.
- **Não houve teste no editor Godot neste ambiente.** Faça validação de parser e execução local antes de considerar a 0.5 estável.
- Importe apenas músicas com autorização adequada.

## Arquivos
- `scripts/main.gd`: interface, seleção, reprodução e menus.
- `scripts/audio_stems.gd`: áudio externo, conversão e relógio.
- `scripts/gameplay_engine.gd`: julgamento ancorado no relógio de áudio.
- `scripts/note_highway.gd`: pista.
- `scripts/clone_hero_library.gd`: biblioteca.
- `scripts/clone_hero_midi.gd`, `scripts/clone_hero_chart.gd`: parsers.

## Frets visuais (MVP 0.5.x)

- `assets/frets/fret_atlas.svg`: atlas 1280×1536 (5 colunas de cores × 6 linhas de estados; células 256×256).
- Cores, na ordem: verde, vermelho, amarelo, azul e laranja.
- Estados, na ordem: normal, pressed, hit, sustain, miss e disabled.
- `scripts/note_highway.gd` posiciona as texturas em perspectiva na linha de julgamento, com elipses achatadas e centros alinhados às cinco pistas.
- Normal, pressed, hit e miss estão conectados ao estado do gameplay; sustain e disabled permanecem reservados.
- O SVG é uma adaptação vetorial dos conceitos visuais, não uma exportação pixel a pixel dos renders anteriores.
- **Validação pendente no Godot**: confirmar importação do SVG, alinhamento, escala e acionamento dos estados.

## MVP 0.5.2 — Estabilização (em validação)

- Highway: coordenadas projetadas compartilhadas para centros de lanes, notas e fret buttons; linha de julgamento alinhada à mesma largura.
- Imagens: usa o atlas PNG existente em `assets/rhythm_legends_notes_atlas.png` (5 colunas × 3 linhas). Não adicione as capturas com fundo cinza como textura; use o PNG com transparência já preparado.
- Audio: relógio monotônico baseado em posição real de playback com fallback para tempo simulado; pausa preserva o timestamp.
- **Não verificado no runtime**: rodar o Godot 4.7.2 e testar a música Before I Forget no modo Médio, verificando posição das notas, acerto, pausa e áudio. A aplicação de offset e o alinhamento sample-accurate dos stems ainda exigem validação empírica.

## MVP 0.5.3 — Gameplay Refinement

- Julgamento das notas: Perfect (até 55 ms), Good (até 160 ms) e Miss (nota vencida).
- Precisão calculada sobre notas já julgadas, em vez do total futuro da música; a média de Good tem peso 0,5.
- Rock Meter inicia em 50%, ganha 1,2 ponto percentual por acerto e perde 3,5 pontos por nota perdida. É apenas indicador visual, sem game over ainda.
- Halo/partículas desenhadas na highway por cerca de 0,28 s após um acerto.
- Acordes funcionam com pressionamento simultâneo de teclas em pistas diferentes; ainda sem strum nem julgamento de acordes como grupo.
- Não há testes automatizados nem validação no editor Godot neste ambiente; verificar os novos scripts antes de considerar esta entrega estável.
