extends Control

const GOLD := Color("ffc629")
const WHITE := Color("f4f5f8")
const MUTED := Color("a7acb8")
const DARK := Color("080b12")
const RED := Color("e02943")
const SONGS := [
	{"title":"Beyond the Fire", "artist":"The Midnight Crew", "time":"3:42", "genre":"Rock alternativo", "year":"2023"},
	{"title":"Neon Skies", "artist":"Lunar Tide", "time":"4:18", "genre":"Hard rock", "year":"2021"},
	{"title":"Broken Roads", "artist":"Steel Orbit", "time":"3:55", "genre":"Rock clássico", "year":"2022"},
	{"title":"Fading Echoes", "artist":"Crystal Wave", "time":"4:06", "genre":"Rock alternativo", "year":"2020"},
	{"title":"Last Horizon", "artist":"The Anchor", "time":"5:12", "genre":"Metal", "year":"2024"}
]
const DIFFICULTIES := ["FÁCIL","MÉDIO","DIFÍCIL","EXPERTO"]
const COLORS := [Color("49f87e"), Color("ff4355"), Color("ffdb37"), Color("24bfff"), Color("ff9633")]

var library = preload("res://scripts/clone_hero_library.gd").new()
var audio = preload("res://scripts/audio_stems.gd").new()
var calibration_ms := 0.0
var game_audio_status := ""
var imported_songs: Array[Dictionary] = []
var active_song: Dictionary = {}
var song_error := ""
var page := "title"
var previous_settings_page := "menu"
var selected_song := 0
var selected_difficulty := 1
var settings_tab := 0
var elapsed := 0.0
var game = preload("res://scripts/gameplay_engine.gd").new()
var combo_value: Label
var accuracy_value: Label
var feedback_value: Label
var rock_meter_fill: Panel
var playing := false
var actions: Array[Button] = []
var active_index := 0
var bg: TextureRect
var layer: Control
var highway: Control
var score_value: Label
var key_flash := [0.0,0.0,0.0,0.0,0.0]

func _ready() -> void:
	library.load_saved()
	var config := ConfigFile.new()
	if config.load("user://audio_settings.cfg") == OK:
		calibration_ms = float(config.get_value("audio","offset_ms",0.0))
		audio.set_volume(float(config.get_value("audio","volume",0.8)))
	audio.offset_ms = calibration_ms
	imported_songs = library.songs
	_render("title")

func _process(delta: float) -> void:
	if playing and page == "gameplay":
		game.advance_to(audio.advance(delta),delta)
		elapsed = game.time
		if is_instance_valid(highway):
			highway.queue_redraw()
		if is_instance_valid(score_value):
			score_value.text = _format_score(game.score)
		if is_instance_valid(combo_value):
			combo_value.text = "x%d  •  %d COMBO" % [game.multiplier(), game.combo]
		if is_instance_valid(accuracy_value):
			accuracy_value.text = "PRECISÃO  %.1f%%" % game.accuracy()
		if is_instance_valid(rock_meter_fill):
			rock_meter_fill.size.y = 470.0 * game.rock_meter
			rock_meter_fill.position.y = 711.0 - rock_meter_fill.size.y
		if is_instance_valid(feedback_value):
			feedback_value.text = game.feedback if game.feedback_timer > 0.0 else ""
		if game.completed():
			playing = false
			audio.stop()
			_render("results")
	for i in range(5):
		key_flash[i] = maxf(0.0, key_flash[i] - delta * 3.0)

func _input(event: InputEvent) -> void:
	if page != "gameplay" or not event is InputEventKey:
		return
	var key := event as InputEventKey
	var lane := [KEY_A, KEY_S, KEY_J, KEY_K, KEY_L].find(key.keycode)
	if lane == -1:
		return
	if key.pressed and not key.echo:
		key_flash[lane] = 1.0
		if playing:
			game.press_lane(lane)
	elif not key.pressed:
		game.release_lane(lane)
	get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if page == "title":
		_render("menu")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") and actions.size() > 0:
		active_index = (active_index+1)%actions.size()
		actions[active_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") and actions.size() > 0:
		active_index = posmod(active_index-1,actions.size())
		actions[active_index].grab_focus()
		get_viewport().set_input_as_handled()

func _format_score(value: int) -> String:
	var s := str(value)
	var result := ""
	while s.length() > 3:
		result = "," + s.substr(s.length()-3,3) + result
		s = s.substr(0,s.length()-3)
	return s+result

func _render(next: String) -> void:
	page = next
	actions.clear()
	active_index = 0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture = load("res://assets/%s.jpg" % ("title" if next=="title" else "darkstage" if next=="pause" or next=="difficulty" else "results" if next=="results" else "concert"))
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	layer=Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter=Control.MOUSE_FILTER_PASS
	add_child(layer)
	match next:
		"title": _screen_title()
		"menu": _screen_menu()
		"songs": _screen_songs()
		"difficulty": _screen_difficulty()
		"gameplay": _screen_gameplay()
		"pause": _screen_pause()
		"results": _screen_results()
		"profile": _screen_profile()
		"settings": _screen_settings()
		"library": _screen_library()
		"import_error": _screen_import_error()
	_footer()
	if not actions.is_empty():
		actions[0].grab_focus.call_deferred()

func _rect(x:float,y:float,w:float,h:float,color:Color,border:Color=Color.TRANSPARENT,radius:int=0) -> Panel:
	var p=Panel.new()
	p.position=Vector2(x,y)
	p.size=Vector2(w,h)
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1 if border.a>0 else 0)
	style.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel",style)
	layer.add_child(p)
	return p

func _label(s:String,x:float,y:float,w:float,h:float,fs:int=26,color:Color=WHITE,center:bool=false,bold:bool=false)->Label:
	var l=Label.new()
	l.text=s
	l.position=Vector2(x,y)
	l.size=Vector2(w,h)
	l.add_theme_font_size_override("font_size",fs)
	l.add_theme_color_override("font_color",color)
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if bold:
		l.add_theme_color_override("font_shadow_color",Color("000000cc"))
		l.add_theme_constant_override("shadow_offset_x",2)
		l.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(l)
	return l

func _button(text:String,x:float,y:float,w:float,h:float,callback:Callable,highlight:bool=false,fs:int=24)->Button:
	var b=Button.new()
	b.text=text
	b.position=Vector2(x,y)
	b.size=Vector2(w,h)
	b.focus_mode=Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size",fs)
	b.add_theme_color_override("font_color",Color("111317") if highlight else WHITE)
	b.add_theme_color_override("font_hover_color",Color("111317"))
	b.add_theme_color_override("font_focus_color",Color("111317"))
	b.add_theme_color_override("font_pressed_color",Color("111317"))
	var normal=StyleBoxFlat.new()
	normal.bg_color=GOLD if highlight else Color("090b10c8")
	normal.border_color=GOLD if highlight else Color("5a627588")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.content_margin_left=18
	var focused=normal.duplicate() as StyleBoxFlat
	focused.bg_color=GOLD
	focused.border_color=Color("fff4b2")
	focused.set_border_width_all(2)
	b.add_theme_stylebox_override("normal",normal)
	b.add_theme_stylebox_override("hover",focused)
	b.add_theme_stylebox_override("focus",focused)
	b.add_theme_stylebox_override("pressed",focused)
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(callback)
	layer.add_child(b)
	actions.append(b)
	return b

func _footer() -> void:
	_label("RHYTHM LEGENDS   ·   AUDIO SYNCHRONIZATION 0.5",30,854,700,28,15,Color("a6a9b5"))
	_label("ENTER  CONFIRMAR      ↑ ↓  NAVEGAR      ESC  VOLTAR",960,854,610,28,17,Color("d4d5da"),true)

func _screen_title() -> void:
	_rect(0,0,1600,900,Color("00000840"))
	_label("RHYTHM",340,162,920,160,128,WHITE,true,true)
	_label("LEGENDS",330,290,940,175,143,RED,true,true)
	_label("★    YOUR STAGE. YOUR LEGEND.    ★",400,492,800,48,26,GOLD,true)
	_label("PRESSIONE QUALQUER TECLA",430,708,740,66,31,WHITE,true)
	_button("COMEÇAR",672,784,256,54,func(): _render("menu"),true,23)

func _screen_menu() -> void:
	_rect(0,0,615,900,Color("03050be8"))
	_label("RHYTHM",65,92,500,70,64,WHITE,false,true)
	_label("LEGENDS",65,155,500,74,74,RED,false,true)
	_rect(65,258,420,4,GOLD)
	var names=["TOCAR","BIBLIOTECA","PERFIL","CONFIGURAÇÕES","SAIR"]
	var targets=["songs","library","profile","settings","quit"]
	for i in range(names.size()):
		var destination: String=targets[i]
		_button(names[i],65,298+i*84,450,64,func():
			if destination=="quit": get_tree().quit()
			elif destination=="settings":
				previous_settings_page="menu"
				_render("settings")
			else: _render(destination)
		,i==0,29)
	_label("SEU PALCO. SEU SOM. SUA LENDA.",65,758,500,38,19,MUTED)

func _screen_songs() -> void:
	if not imported_songs.is_empty():
		_screen_imported_songs()
		return
	_rect(0,0,1030,900,Color("03050bf0"))
	_label("SELECIONAR MÚSICA",75,60,850,84,54,WHITE,false,true)
	_label("MODO SOLO  /  GUITARRA",80,138,700,38,20,GOLD)
	for i in range(SONGS.size()):
		var data:Dictionary=SONGS[i]
		var idx:=i
		var b=_button("%s     —     %s" % [data.title,data.artist],76,197+i*115,880,97,func():
			selected_song=idx
			_render("difficulty")
		,i==selected_song,29)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		_label(data.time,850,209+i*115,90,52,18,Color("37352b") if i==selected_song else MUTED,true)
	_rect(1090,90,417,417,Color("0b101c"),Color("545d70"),5)
	var cover=TextureRect.new()
	cover.texture=load("res://assets/cover.jpg")
	cover.position=Vector2(1097,97)
	cover.size=Vector2(403,403)
	cover.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(cover)
	_label(SONGS[selected_song].title.to_upper(),1080,520,455,92,38,WHITE,true,true)
	_label(SONGS[selected_song].artist,1080,608,455,42,24,MUTED,true)
	_label(SONGS[selected_song].genre,1080,662,455,40,21,WHITE,true)
	_label("%s   ·   %s" % [SONGS[selected_song].year,SONGS[selected_song].time],1080,709,455,42,21,MUTED,true)

func _screen_difficulty() -> void:
	if not active_song.is_empty():
		_screen_imported_difficulty()
		return
	_rect(0,0,1600,900,Color("00000099"))
	_label("ESCOLHER DIFICULDADE",180,112,1240,76,56,WHITE,true,true)
	_label("%s — %s" % [SONGS[selected_song].title,SONGS[selected_song].artist],260,186,1080,46,23,MUTED,true)
	for i in range(4):
		var idx:=i
		var clr:Color=[Color("66ff95"),GOLD,Color("ff5151"),Color("be62ff")][i]
		var x:=158+i*325
		_rect(x,299,300,355,Color("0b0e18ee"),clr,6)
		_label(DIFFICULTIES[i],x+12,325,276,58,29,WHITE,true,true)
		_label("♠",x+65,404,170,133,111,clr,true)
		_button("SELECIONAR",x+33,559,235,64,func():
			selected_difficulty=idx
			active_song = {}
			audio.stop()
			game.start(selected_difficulty)
			elapsed=0
			playing=true
			_render("gameplay")
		,i==selected_difficulty,21)
		for dot in range(4):
			_label("●" if dot<=i else "○",x+75+dot*39,654,45,40,25,clr,true)
	_label("ESCOLHA A DIFICULDADE E SUBA AO PALCO",210,735,1180,55,23,MUTED,true)

func _screen_gameplay() -> void:
	_rect(0,0,1600,900,Color("01030a33"))
	_rect(1275,54,268,110,Color("030611dc"),Color("e7c765"),5)
	_label("PONTUAÇÃO",1300,66,223,28,18,MUTED,true)
	score_value=_label(_format_score(game.score),1300,98,223,50,38,WHITE,true,true)
	_label("☆☆☆☆☆",1260,170,300,55,39,GOLD,true)
	_rect(78,230,35,490,Color("08110edc"),Color("70c991"),10)
	rock_meter_fill = _rect(85,711.0-470.0*game.rock_meter,21,470.0*game.rock_meter,Color("2aea73"))
	_label("ROCK METER",44,172,185,48,19,WHITE)
	combo_value=_label("x1  •  0 COMBO",1195,385,325,108,34,GOLD,true,true)
	accuracy_value=_label("PRECISÃO  0.0%",1210,475,315,52,22,WHITE,true)
	feedback_value=_label("",560,385,480,80,46,GOLD,true,true)
	_label("%s   •   %s" % [str(active_song.get("title",SONGS[selected_song].title)),DIFFICULTIES[selected_difficulty]],390,24,840,55,26,WHITE,true)
	highway=Control.new()
	highway.position=Vector2(280,125)
	highway.size=Vector2(930,700)
	highway.set_script(load("res://scripts/note_highway.gd"))
	layer.add_child(highway)
	highway.set("main",self)
	_label("A   S   J   K   L    =    BOTÕES DE GUITARRA",1040,786,510,40,18,WHITE,true)
	_button("Ⅱ  PAUSAR",1290,705,230,58,func(): playing=false; audio.pause(); _render("pause"),false,22)
	_label(game_audio_status if not game_audio_status.is_empty() else "A/S/J/K/L • AUDIO SINCRONIZADO",1110,771,450,57,16,MUTED,true)

func _screen_pause() -> void:
	_rect(0,0,1600,900,Color("000000a0"))
	_label("PAUSA",105,160,700,100,71,WHITE,false,true)
	var opts=["CONTINUAR","REINICIAR MÚSICA","OPÇÕES DA MÚSICA","CONFIGURAÇÕES","VOLTAR AO MENU"]
	for i in range(opts.size()):
		var idx:=i
		_button(opts[i],105,290+i*84,575,68,func():
			match idx:
				0: playing=true;audio.resume();_render("gameplay")
				1: _restart_gameplay()
				2,3: previous_settings_page="pause";_render("settings")
				4: playing=false;audio.stop();_render("menu")
		,i==0,27)

func _screen_results() -> void:
	_rect(0,0,1600,900,Color("01040bc0"))
	_label("MÚSICA CONCLUÍDA!",230,83,1140,93,64,WHITE,true,true)
	_label("★★★★☆",350,175,900,110,85,GOLD,true)
	_label(_format_score(game.score),340,294,920,108,83,WHITE,true,true)
	_rect(200,436,590,243,Color("060910e8"),Color("647080"),6)
	var stats=["PRECISÃO                %.1f%%" % game.accuracy(), "NOTAS ACERTADAS         %d" % game.hits, "NOTAS PERDIDAS          %d" % game.misses, "MAIOR COMBO             %d" % game.max_combo]
	for i in range(stats.size()): _label(stats[i],239,451+i*53,510,48,25,WHITE)
	_label("A",972,443,250,230,147,GOLD,true,true)
	_label("PERFECT: %d    GOOD: %d" % [game.perfects,game.goods],911,661,370,37,18,MUTED,true)
	_button("TOCAR NOVAMENTE",393,731,365,67,func(): _restart_gameplay(),true)
	_button("OUTRAS MÚSICAS",790,731,365,67,func(): _render("songs"))

func _screen_profile() -> void:
	_rect(0,0,1600,900,Color("010307dc"))
	_label("PERFIL / PROGRESSO",81,70,1100,83,58,WHITE,false,true)
	_rect(84,198,175,177,Color("161c2a"),Color("bfc3c8"),7)
	_label("♠",95,199,155,169,106,RED,true)
	_label("Player",300,199,620,61,42,WHITE)
	_label("Nível 1   ·   Novato",301,264,650,35,25,MUTED)
	_rect(301,321,580,19,Color("29303a"),Color("616876"),4)
	_rect(302,322,145,17,GOLD)
	_label("250 / 1.000 XP",899,307,250,44,22,MUTED)
	_rect(80,428,685,324,Color("070b15df"),Color("4c5869"),5)
	_rect(795,428,725,324,Color("070b15df"),Color("4c5869"),5)
	_label("ESTATÍSTICAS",110,441,580,60,33,GOLD)
	_label("Músicas tocadas                        0\n\nMédia de precisão                      —\n\nMaior pontuação                         —\n\nMaior combo                               —",125,510,620,238,22,WHITE)
	_label("GÊNEROS FAVORITOS",826,441,610,60,32,GOLD)
	_label("Rock\n\nAlternativo\n\nMetal\n\nPop",835,515,610,220,23,WHITE)

func _screen_library() -> void:
	if not imported_songs.is_empty() or not library.root.is_empty():
		_screen_clone_library()
		return
	_rect(0,0,1600,900,Color("010307cf"))
	_label("BIBLIOTECA",92,88,1020,93,70,WHITE,false,true)
	_label("MÚSICAS DISPONÍVEIS",96,229,840,45,28,GOLD)
	_label("%d músicas demonstrativas" % SONGS.size(),96,299,960,51,35,WHITE)
	_label("A leitura de pastas Clone Hero, song.ini, notes.chart e notes.mid\nserá integrada em uma próxima etapa.",97,377,1020,101,24,MUTED)
	_button("IMPORTAR PASTA CLONE HERO",98,544,540,69,func(): _choose_library(),true)
	_button("VER MÚSICAS",98,620,395,69,func(): _render("songs"))
	_button("VOLTAR",98,637,395,69,func(): _render("menu"))

func _screen_settings() -> void:
	_rect(0,0,1600,900,Color("020308e0"))
	_label("CONFIGURAÇÕES",78,70,980,96,64,WHITE,false,true)
	var tabs=["ÁUDIO","VÍDEO","CONTROLES","CALIBRAÇÃO","INTERFACE","ACESSIBILIDADE"]
	for i in range(tabs.size()):
		var idx:=i
		_button(tabs[i],80,216+i*86,360,64,func(): settings_tab=idx;_render("settings"),i==settings_tab,24)
	_rect(480,211,1020,532,Color("0d1119ec"),Color("485363"),5)
	_label(tabs[settings_tab],523,243,898,66,39,GOLD)
	if settings_tab==0:
		var names=["Volume da Música","Volume dos Efeitos","Volume da Interface"]
		for i in range(3):
			_label(names[i],527,340+i*106,370,50,25,WHITE)
			var slide=HSlider.new()
			slide.position=Vector2(937,345+i*106)
			slide.size=Vector2(410,48)
			slide.min_value=0;slide.max_value=100;slide.value=audio.volume*100.0 if i==0 else 80 if i==1 else 70
			layer.add_child(slide)
			_label("%d%%" % int(slide.value),1350,339+i*106,115,52,22,WHITE,true)
			var val_label:Label=layer.get_child(layer.get_child_count()-1)
			var slot := i
			slide.value_changed.connect(func(v:float):
				val_label.text="%d%%" % int(v)
				if slot==0:
					audio.set_volume(v/100.0)
					_save_audio_settings()
			)
	elif settings_tab==3:
		_label("ATRASO DE AUDIO / VIDEO",533,333,870,65,30,WHITE)
		_label("Ajuste em milissegundos (-250 a +250)",533,407,870,55,23,MUTED)
		var tune := HSlider.new()
		tune.position=Vector2(538,491)
		tune.size=Vector2(690,55)
		tune.min_value=-250.0
		tune.max_value=250.0
		tune.step=5.0
		tune.value=calibration_ms
		layer.add_child(tune)
		var value_label := _label("%+.0f ms" % calibration_ms,1250,480,200,75,27,GOLD,true)
		tune.value_changed.connect(func(v:float):
			calibration_ms=v
			audio.offset_ms=v
			value_label.text="%+.0f ms" % v
			_save_audio_settings()
		)
	else:
		_label("OPÇÕES DE %s" % tabs[settings_tab],533,350,870,66,31,WHITE)
		_label("Esta seção será configurada nas próximas versões do protótipo.",533,440,850,114,23,MUTED)
	_button("VOLTAR",80,761,360,64,func(): _render(previous_settings_page),false,24)


func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio","offset_ms",calibration_ms)
	config.set_value("audio","volume",audio.volume)
	config.save("user://audio_settings.cfg")

func _start_song_audio() -> void:
	audio.offset_ms = calibration_ms
	game_audio_status = ""
	if active_song.is_empty():
		audio.stop()
		return
	if not audio.prepare(str(active_song["path"]),get_tree().root):
		game_audio_status = "SEM AUDIO: " + audio.warning
	audio.play()

func _restart_gameplay() -> void:
	if active_song.is_empty():
		audio.stop()
		game.start(selected_difficulty)
	else:
		var parsed: Dictionary = library.get_chart(active_song)
		if parsed.has("error"):
			song_error = str(parsed["error"])
			playing=false
			audio.stop()
			_render("import_error")
			return
		var chart_notes: Array = parsed["notes"][selected_difficulty]
		game.start_chart(chart_notes)
		_start_song_audio()
	elapsed = 0.0
	playing = true
	_render("gameplay")

func _choose_library() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.title = "Selecionar pasta Clone Hero"
	dialog.size = Vector2i(900,600)
	add_child(dialog)
	dialog.dir_selected.connect(func(path: String):
		library.scan(path)
		imported_songs = library.songs
		active_song = {}
		dialog.queue_free()
		_render("library")
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _screen_clone_library() -> void:
	_rect(0,0,1600,900,Color("010307cf"))
	_label("BIBLIOTECA CLONE HERO",92,85,1280,96,62,WHITE,false,true)
	_label("%d músicas encontradas" % imported_songs.size(),96,218,900,65,36,GOLD)
	_label("Pasta: %s" % library.root,96,310,1360,95,19,MUTED)
	_label("Audio: OGG/MP3/WAV; Opus via FFmpeg local com cache.",96,430,1340,55,23,WHITE)
	_button("ESCOLHER OUTRA PASTA",98,545,540,70,func(): _choose_library(),true)
	_button("SELECIONAR MÚSICA",98,630,540,70,func(): _render("songs"))
	_button("VOLTAR",98,715,320,62,func(): _render("menu"))

func _screen_imported_songs() -> void:
	_rect(0,0,1600,900,Color("03050bea"))
	_label("MÚSICAS IMPORTADAS",72,55,1200,80,55,WHITE,false,true)
	_label("%d músicas  •  guitarra de cinco botões" % imported_songs.size(),78,135,1110,44,22,GOLD)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(76,207)
	scroll.size = Vector2(1410,568)
	layer.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 1370
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	for song in imported_songs:
		var data: Dictionary = song
		var button := Button.new()
		button.text = "%s   —   %s" % [data["title"],data["artist"]]
		button.custom_minimum_size = Vector2(1300,68)
		button.add_theme_font_size_override("font_size",25)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func():
			active_song = data
			_render("difficulty")
		)
		list.add_child(button)
		actions.append(button)
	_button("VOLTAR",80,794,320,53,func(): _render("menu"))

func _screen_imported_difficulty() -> void:
	_rect(0,0,1600,900,Color("03050be8"))
	_label("ESCOLHER DIFICULDADE",135,96,1320,80,60,WHITE,true,true)
	_label("%s — %s" % [active_song["title"],active_song["artist"]],120,191,1360,65,28,GOLD,true)
	for i in range(4):
		var difficulty := i
		var x := 140+i*333
		_button(DIFFICULTIES[i],x,355,305,96,func():
			var parsed: Dictionary = library.get_chart(active_song)
			if parsed.has("error"):
				song_error = str(parsed["error"])
				_render("import_error")
				return
			var notes_for_difficulty: Array = parsed["notes"][difficulty]
			if notes_for_difficulty.is_empty():
				song_error = "Esta música não possui notas nessa dificuldade."
				_render("import_error")
				return
			selected_difficulty = difficulty
			game.start_chart(notes_for_difficulty)
			_start_song_audio()
			elapsed = 0
			playing = true
			_render("gameplay")
		,i==selected_difficulty,26)
	_label("Versão 0.5: reprodução de áudio, stems, relógio musical e calibração.",175,625,1250,75,22,MUTED,true)

func _screen_import_error() -> void:
	_rect(0,0,1600,900,Color("03050bed"))
	_label("ERRO AO IMPORTAR",120,180,1310,90,61,RED,true,true)
	_label(song_error,200,340,1200,150,30,WHITE,true)
	_button("VOLTAR",600,610,400,75,func(): _render("difficulty"),true)

func _back() -> void:
	match page:
		"title": _render("menu")
		"menu": _render("title")
		"songs","library","profile": _render("menu")
		"difficulty": _render("songs")
		"gameplay": playing=false;audio.pause();_render("pause")
		"pause": playing=true;audio.resume();_render("gameplay")
		"results": _render("songs")
		"import_error": _render("difficulty")
		"settings": _render(previous_settings_page)
