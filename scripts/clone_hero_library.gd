extends RefCounted
const Midi = preload("res://scripts/clone_hero_midi.gd")
const Chart = preload("res://scripts/clone_hero_chart.gd")
const CONFIG_FILE := "user://clone_hero_library.txt"
var songs: Array[Dictionary] = []
var root := ""
func load_saved() -> void:
	if FileAccess.file_exists(CONFIG_FILE):
		root = FileAccess.get_file_as_string(CONFIG_FILE).strip_edges()
		scan(root)
func scan(path: String) -> void:
	songs.clear()
	root = path
	if not DirAccess.dir_exists_absolute(path):
		return
	var directories: Array[String] = [path]
	while not directories.is_empty():
		var current: String = directories.pop_back()
		var dir := DirAccess.open(current)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var entry := dir.get_next()
			if entry.is_empty():
				break
			if dir.current_is_dir() and not entry.begins_with("."):
				directories.append(current.path_join(entry))
		dir.list_dir_end()
		if FileAccess.file_exists(current.path_join("song.ini")):
			var ini := _read_song_ini(current.path_join("song.ini"))
			var chart_path := current.path_join("notes.mid") if FileAccess.file_exists(current.path_join("notes.mid")) else current.path_join("notes.chart")
			if not FileAccess.file_exists(chart_path):
				continue
			songs.append({
				"title":str(ini.get("name",current.get_file())),
				"artist":str(ini.get("artist","Desconhecido")),
				"genre":str(ini.get("genre","")),
				"year":str(ini.get("year","")),
				"time":"--:--",
				"path":current,
				"chart_path":chart_path
			})
	songs.sort_custom(func(a: Dictionary,b: Dictionary):return str(a["title"]).naturalnocasecmp_to(str(b["title"]))<0)
	var saved := FileAccess.open(CONFIG_FILE,FileAccess.WRITE)
	if saved:
		saved.store_string(path)
func get_chart(song: Dictionary) -> Dictionary:
	var path := str(song.get("chart_path",""))
	if path.ends_with(".mid"):
		return Midi.new().read(path)
	return Chart.new().read(path)

## Clone Hero INI contains plain, unquoted strings (not Godot Variant syntax).
func _read_song_ini(path: String) -> Dictionary:
	var values := {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return values
	var in_song := false
	while not file.eof_reached():
		var line := file.get_line().strip_edges().trim_prefix("\ufeff")
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			in_song = line.substr(1,line.length()-2).to_lower() == "song"
			continue
		if not in_song:
			continue
		var separator := line.find("=")
		if separator < 1:
			continue
		var key := line.substr(0,separator).strip_edges().to_lower()
		var value := line.substr(separator+1).strip_edges()
		if value.begins_with("\"") and value.ends_with("\"") and value.length()>=2:
			value = value.substr(1,value.length()-2)
		values[key] = value
	return values
