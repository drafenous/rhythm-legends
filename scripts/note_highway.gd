extends Control

var main: Control
const COLORS := [Color("4cfb7d"), Color("fe4a58"), Color("ffe43f"), Color("33c7ff"), Color("ff9c36")]
const ATLAS_PATH := "res://assets/rhythm_legends_notes_atlas.png"
const ATLAS_CELL := Vector2(280.0, 220.0)
const ROW_NORMAL := 0
const ROW_HIT := 1
const ROW_FRET := 2
const TARGET_Y := 650.0
const TOP_Y := 42.0
const BOTTOM_Y := 690.0
const TOP_LEFT := 300.0
const TOP_RIGHT := 610.0
const BOTTOM_LEFT := 75.0
const BOTTOM_RIGHT := 845.0
const TRAVEL_SECONDS := 2.0
var atlas: Texture2D

func _ready() -> void:
	var location := ProjectSettings.globalize_path(ATLAS_PATH)
	if FileAccess.file_exists(location):
		var picture := Image.load_from_file(location)
		if picture != null and not picture.is_empty():
			atlas = ImageTexture.create_from_image(picture)
	if atlas == null:
		push_warning("Fret atlas PNG ausente: " + ATLAS_PATH)

func _draw() -> void:
	var top_l := Vector2(TOP_LEFT, TOP_Y)
	var top_r := Vector2(TOP_RIGHT, TOP_Y)
	var bot_l := Vector2(BOTTOM_LEFT, BOTTOM_Y)
	var bot_r := Vector2(BOTTOM_RIGHT, BOTTOM_Y)
	draw_colored_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]), Color("030409eb"))
	for i in range(6):
		var fraction := float(i) / 5.0
		draw_line(top_l.lerp(top_r, fraction), bot_l.lerp(bot_r, fraction), Color("7481938c") if i == 0 or i == 5 else Color("5e698055"), 3.0 if i == 0 or i == 5 else 1.5)
	for i in range(13):
		var progress := fposmod(float(i) / 13.0 + float(main.elapsed) * 0.37, 1.0)
		var projected := progress * progress
		var y := lerpf(42.0, 690.0, projected)
		draw_line(Vector2(lerpf(top_l.x, bot_l.x, projected), y), Vector2(lerpf(top_r.x, bot_r.x, projected), y), Color("ffffff18"), 1.0)
	_draw_notes(top_l, top_r, bot_l, bot_r)
	var depth_at_hit := (TARGET_Y - TOP_Y) / (BOTTOM_Y - TOP_Y)
	var hit_left := lerpf(TOP_LEFT, BOTTOM_LEFT, depth_at_hit)
	var hit_right := lerpf(TOP_RIGHT, BOTTOM_RIGHT, depth_at_hit)
	draw_line(Vector2(hit_left, TARGET_Y), Vector2(hit_right, TARGET_Y), Color("ffffff72"), 3.0)
	for lane in range(5):
		var center_x := lerpf(hit_left, hit_right, (float(lane) + 0.5) / 5.0)
		var state := ROW_FRET
		if main.game.feedback_timer > 0.0 and main.game.last_hit_lane == lane and main.game.feedback != "MISS":
			state = ROW_HIT
		elif main.game.held_lanes[lane]:
			state = ROW_HIT
		var lane_width := (hit_right - hit_left) / 5.0
		var size := Vector2(lane_width * 0.90, 96.0)
		_draw_asset(lane, state, Rect2(Vector2(center_x, TARGET_Y) - size * 0.5, size))
		if main.game.feedback_timer > 0.0 and main.game.last_hit_lane == lane and main.game.feedback != "MISS":
			var intensity: float = clampf(main.game.feedback_timer / 0.28, 0.0, 1.0)
			_draw_hit_burst(Vector2(center_x, TARGET_Y), COLORS[lane], intensity, lane)

func _draw_notes(top_l: Vector2, top_r: Vector2, bot_l: Vector2, bot_r: Vector2) -> void:
	for note in main.game.notes:
		if int(note["state"]) != 0:
			continue
		var remaining: float = float(note["time"]) - float(main.game.time)
		if remaining < -0.18 or remaining > TRAVEL_SECONDS:
			continue
		var progress: float = clampf(1.0 - remaining / TRAVEL_SECONDS, 0.0, 1.0)
		var depth: float = progress * progress
		var lane: int = int(note["lane"])
		if lane < 0 or lane >= 5:
			continue
		var position_depth := depth * ((TARGET_Y - TOP_Y) / (BOTTOM_Y - TOP_Y))
		var left := lerpf(top_l.x, bot_l.x, position_depth)
		var right := lerpf(top_r.x, bot_r.x, position_depth)
		var center := Vector2(lerpf(left, right, (float(lane) + 0.5) / 5.0), lerpf(42.0, TARGET_Y, depth))
		var lane_width := (right - left) / 5.0
		var size := Vector2(lane_width * 0.88, lerpf(22.0, 92.0, depth))
		_draw_asset(lane, ROW_NORMAL, Rect2(center - size * 0.5, size))

func _draw_asset(lane: int, row: int, target: Rect2) -> void:
	if atlas != null:
		var source := Rect2(float(lane) * ATLAS_CELL.x, float(row) * ATLAS_CELL.y, ATLAS_CELL.x, ATLAS_CELL.y)
		draw_texture_rect_region(atlas, target, source)
	else:
		# A fallback is rendered only if the actual PNG has not been added.
		draw_circle(target.get_center(), target.size.y * 0.33, COLORS[lane])

func _draw_hit_burst(center: Vector2, hue: Color, intensity: float, lane: int) -> void:
	var power := 1.0 - intensity
	var radius := 32.0 + power * 56.0
	var glow := Color(hue.r, hue.g, hue.b, intensity * 0.75)
	draw_arc(center, radius, 0.0, TAU, 28, glow, 4.0 * intensity + 1.0)
	for i in range(9):
		var angle := TAU * float(i) / 9.0 + float(lane) * 0.27
		var near := center + Vector2(cos(angle), sin(angle)) * (22.0 + power * 25.0)
		var far := center + Vector2(cos(angle), sin(angle)) * (radius + 14.0)
		draw_line(near, far, glow, 1.0 + 3.0 * intensity)
