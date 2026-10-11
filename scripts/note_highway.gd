extends Control

var main: Control
const LANES := [Color("4cfb7d"), Color("fe4a58"), Color("ffe43f"), Color("33c7ff"), Color("ff9c36")]
const STRIP_FILES := ["green_strip.png", "red_strip.png", "yellow_strip.png", "blue_strip.png", "orange_strip.png"]
const FRET_SPRITE_SIZE := Vector2(156.0, 112.0)
const FRAME_WIDTH := 362.0
const FRAME_HEIGHT := 724.0
var fret_strips: Array[Texture2D] = []

func _ready() -> void:
	fret_strips.clear()
	for filename in STRIP_FILES:
		var absolute := ProjectSettings.globalize_path("res://assets/frets/" + filename)
		var texture: Texture2D = null
		if FileAccess.file_exists(absolute):
			var image := Image.load_from_file(absolute)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
		fret_strips.append(texture)

func _draw() -> void:
	var top_l := Vector2(300,42)
	var top_r := Vector2(610,42)
	var bot_l := Vector2(75,690)
	var bot_r := Vector2(845,690)
	draw_colored_polygon(PackedVector2Array([top_l,top_r,bot_r,bot_l]),Color("030409eb"))
	for i in range(6):
		var t := float(i) / 5.0
		draw_line(top_l.lerp(top_r,t),bot_l.lerp(bot_r,t),Color("7481938c") if i==0 or i==5 else Color("5e698055"),3.0 if i==0 or i==5 else 1.5)
	for i in range(13):
		var z := fposmod(float(i)/13.0 + float(main.elapsed)*0.37,1.0)
		var depth := z*z
		var y := lerpf(42.0,690.0,depth)
		var left := lerpf(top_l.x,bot_l.x,depth)
		var right := lerpf(top_r.x,bot_r.x,depth)
		draw_line(Vector2(left,y),Vector2(right,y),Color("ffffff18"),1.0)
	var target_y := 650.0
	var travel_seconds := 2.0
	for note in main.game.notes:
		if int(note["state"]) != 0:
			continue
		var remaining: float = float(note["time"]) - main.game.time
		if remaining < -0.18 or remaining > travel_seconds:
			continue
		var z: float = clampf(1.0 - remaining/travel_seconds,0.0,1.0)
		var depth: float = z*z
		var lane: int = int(note["lane"])
		if lane < 0 or lane > 4:
			continue
		var left := lerpf(top_l.x,bot_l.x,depth)
		var right := lerpf(top_r.x,bot_r.x,depth)
		var x := lerpf(left,right,(float(lane)+0.5)/5.0)
		var y := lerpf(42.0,target_y,depth)
		var radius := lerpf(8.0,34.0,depth)
		draw_circle(Vector2(x,y),radius+5.0,Color("030409"))
		draw_circle(Vector2(x,y),radius,LANES[lane].darkened(0.42))
		draw_arc(Vector2(x,y),radius-2.0,0.0,TAU,28,LANES[lane],4.0)
		draw_circle(Vector2(x,y-3.0),radius*0.44,LANES[lane].lightened(0.5))
	draw_line(Vector2(88,target_y),Vector2(832,target_y),Color("ffffff72"),3.0)
	for lane in range(5):
		var x := lerpf(bot_l.x,bot_r.x,(float(lane)+0.5)/5.0)
		var state := _state(lane)
		var destination := Rect2(Vector2(x-FRET_SPRITE_SIZE.x*0.5,target_y-FRET_SPRITE_SIZE.y*0.5),FRET_SPRITE_SIZE)
		if fret_strips.size() > lane and fret_strips[lane] != null:
			draw_texture_rect_region(fret_strips[lane],destination,Rect2(float(state)*FRAME_WIDTH,0.0,FRAME_WIDTH,FRAME_HEIGHT))
		else:
			# Fallback keeps this branch runnable until the PNG assets are installed.
			draw_circle(Vector2(x,target_y),43.0,LANES[lane].darkened(0.45))
			draw_arc(Vector2(x,target_y),40.0,0.0,TAU,40,LANES[lane],6.0)

func _state(lane: int) -> int:
	if main.game.feedback_timer > 0.0 and main.game.last_hit_lane == lane and main.game.feedback != "MISS":
		return 3 # hit
	if main.game.feedback_timer > 0.0 and main.game.last_miss_lane == lane and main.game.feedback == "MISS":
		return 5 # disabled (miss visual)
	if main.game.held_lanes[lane]:
		for note in main.game.notes:
			if int(note["lane"]) == lane and int(note["state"]) == 1 and float(note.get("length",0.0)) > 0.12 and main.game.time < float(note["time"])+float(note["length"]):
				return 4 # sustain
		return 2 # pressed
	for note in main.game.notes:
		if int(note["state"]) == 0 and int(note["lane"]) == lane:
			var remaining: float = float(note["time"])-main.game.time
			if remaining >= 0.0 and remaining < 0.18:
				return 1 # glow
	return 0 # normal
