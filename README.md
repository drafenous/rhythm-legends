# Rhythm Legends — Protótipo Visual 0.2

Visual inspirado no concept board original de nove telas: espetáculo de rock clássico, botões dourados, palco, biblioteca em duas colunas, dificuldades em cartões, HUD de cinco notas, perfil e configurações.

## Abrir

1. Abra a pasta `rhythm-legends` no **Godot 4.7.2** (Importar `project.godot`).
2. Execute com **F5**.
3. Navegue com **mouse**, **setas**, **Enter** e **Esc**.
4. No gameplay, as teclas **A S J K L** iluminam as cinco casas (apenas demonstração visual).

## Escopo

- Os arquivos de fundo são derivados da própria imagem do concept board compartilhada na conversa.
- Biblioteca, música e score são demonstrativos. Não há reprodução do arquivo do Slipknot nem parser Clone Hero implementado nesta versão.
- A pista é uma visualização 2D desenhada com `_draw`, não é gameplay funcional.
- Tamanho lógico: 1600 × 900, com escala via canvas_items.

## Arquivos principais

- `scripts/main.gd`: navegação, telas, componentes UI e estado temporário.
- `scripts/note_highway.gd`: pista perspectiva e notas demonstrativas animadas.
- `assets/`: ilustrações/cenários baseados na referência visual.

## Próximas etapas

Extrair componentes UI reutilizáveis, importar uma biblioteca Clone Hero (`song.ini`, `notes.mid`/`notes.chart`, áudio OPUS/OGG) e implementar o motor de julgamento de notas.
