extends RefCounted
## External Clone Hero stems, with an optional FFmpeg-to-Vorbis cache for Opus.
const STEMS := ["song","guitar","rhythm","bass","drums","drums_1","drums_2","drums_3","drums_4","vocals","keys","crowd"]
const EXTENSIONS := [".ogg",".mp3",".wav",".opus"]
var players: Array[AudioStreamPlayer] = []
var clock_player: AudioStreamPlayer
var warning := ""
var audio_length := 0.0
var offset_ms := 0.0
var volume := 0.8
var initialized := false
var has_audio := false
var manual_time := 0.0
var paused := false
var offset_time := 0.0
var stable_time := 0.0
var playback_started := false

func prepare(song_folder: String, parent: Node) -> bool:
	stop()
	warning = ""
	has_audio = false
	initialized = false
	audio_length = 0.0
	var paths: Array[String] = []
	for stem in STEMS:
		for extension in EXTENSIONS:
			var candidate := song_folder.path_join(stem + extension)
			if FileAccess.file_exists(candidate):
				paths.append(candidate)
				break
	if paths.is_empty():
		warning = "Nenhuma faixa de audio encontrada."
		return false
	var streams: Array[AudioStream] = []
	for path in paths:
		var resolved := _resolve(path)
		if resolved.is_empty():
			continue
		var stream := _load_stream(resolved)
		if stream:
			streams.append(stream)
	if streams.is_empty():
		warning = "Nao foi possivel carregar audio; instale FFmpeg para arquivos .opus."
		return false
	for stream in streams:
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_linear = volume
		parent.add_child(player)
		players.append(player)
		audio_length = maxf(audio_length,stream.get_length())
	clock_player = players[0]
	has_audio = true
	initialized = true
	return true

func _resolve(path: String) -> String:
	if path.get_extension().to_lower() != "opus":
		return path
	var modified := FileAccess.get_modified_time(path)
	var cache_dir := "user://audio_cache"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_dir))
	var dest := ProjectSettings.globalize_path(cache_dir.path_join((path + str(modified)).md5_text() + ".ogg"))
	if FileAccess.file_exists(dest):
		return dest
	var output: Array = []
	var status := OS.execute("ffmpeg",PackedStringArray(["-nostdin","-v","error","-y","-i",path,"-vn","-c:a","libvorbis","-q:a","5",dest]),output,true)
	if status == 0 and FileAccess.file_exists(dest):
		return dest
	warning = "FFmpeg nao encontrado ou nao conseguiu converter uma faixa Opus."
	return ""

func _load_stream(path: String) -> AudioStream:
	match path.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"mp3": return AudioStreamMP3.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
	return null

func play() -> void:
	manual_time = 0.0
	stable_time = 0.0
	playback_started = false
	offset_time = 0.0
	paused = false
	if has_audio:
		for p in players:
			p.stream_paused = false
			p.play(0.0)
		playback_started = true

func pause() -> void:
	stable_time = current_time()
	paused = true
	for p in players:
		p.stream_paused = true

func resume() -> void:
	paused = false
	for p in players:
		p.stream_paused = false

func advance(delta: float) -> float:
	if paused:
		return current_time()
	manual_time += delta
	return current_time()

func current_time() -> float:
	if paused:
		return stable_time
	var observed := manual_time
	if has_audio and is_instance_valid(clock_player) and clock_player.playing:
		observed = clock_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	# Never reverse the chart clock due to audio mix jitter; calibration remains
	# independent of the transport so pausing resumes at an identical timestamp.
	stable_time = maxf(stable_time, maxf(0.0, observed - offset_ms / 1000.0))
	return stable_time

func stop() -> void:
	for p in players:
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
	players.clear()
	clock_player = null
	has_audio = false
	initialized = false
	paused = false
	playback_started = false
	stable_time = 0.0
	manual_time = 0.0

func set_volume(value: float) -> void:
	volume = clampf(value,0.0,1.0)
	for p in players:
		if is_instance_valid(p):
			p.volume_linear = volume
