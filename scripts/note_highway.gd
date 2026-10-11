extends Control

var main: Control
const FRET_ATLAS = preload("res://assets/frets/fret_atlas.svg")
const FRET_SIZE := Vector2(256.0,256.0)
const LANES := [Color("4cfb7d"),Color("fe4a58"),Color("ffe43f"),Color("33c7ff"),Color("ff9c36")]

func _draw() -> void:
	var top_l:=Vector2(300,42)
	var top_r:=Vector2(610,42)
	var bot_l:=Vector2(75,690)
	var bot_r:=Vector2(845,690)
	draw_colored_polygon(PackedVector2Array([top_l,top_r,bot_r,bot_l]),Color("030409eb"))
	for i in range(6):
		var t:=float(i)/5.0
		draw_line(top_l.lerp(top_r,t),bot_l.lerp(bot_r,t),Color("7481938c") if i==0 or i==5 else Color("5e698055"),3.0 if i==0 or i==5 else 1.5)
	for i in range(13):
		var z:=fposmod(float(i)/13.0+float(main.elapsed)*0.37,1.0)
		var y:=42+648*z*z
		var left:=lerpf(top_l.x,bot_l.x,z*z)
		var right:=lerpf(top_r.x,bot_r.x,z*z)
		draw_line(Vector2(left,y),Vector2(right,y),Color("ffffff18"),1)
	# Notas reais do chart de teste, posicionadas pelo tempo ate o acerto.
	var target_y := 650.0
	var travel_seconds := 2.0
	for note in main.game.notes:
		if int(note["state"]) != 0:
			continue
		var remaining: float = float(note["time"]) - main.game.time
		if remaining < -0.18 or remaining > travel_seconds:
			continue
		var z: float = clampf(1.0 - remaining / travel_seconds, 0.0, 1.0)
		var depth: float = z * z
		var lane: int = int(note["lane"])
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
	# Buttons and notes share the same projected lane centers.
	# Atlas rows: normal, pressed, hit, sustain, miss, disabled.
	for i in range(5):
		var x := lerpf(bot_l.x,bot_r.x,(float(i)+0.5)/5.0)
		var state := 0
		if main.game.feedback_timer > 0.0 and main.game.last_hit_lane == i and main.game.feedback != "MISS":
			state = 2
		elif main.game.feedback_timer > 0.0 and main.game.last_miss_lane == i and main.game.feedback == "MISS":
			state = 4
		elif main.game.held_lanes[i]:
			state = 1
		var width := 147.0
		var height := 105.0
		var destination := Rect2(x-width*0.5, 650.0-height*0.5, width, height)
		var region := Rect2(float(i)*256.0,float(state)*256.0,256.0,256.0)
		draw_texture_rect_region(FRET_ATLAS,destination,region)
