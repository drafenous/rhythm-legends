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
