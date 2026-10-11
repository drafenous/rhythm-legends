extends RefCounted
## Gameplay deterministico de 5 pistas, desacoplado da interface.
const BPM := 120.0
const LEAD_IN := 2.0
const SONG_LENGTH := 35.0
const PERFECT_WINDOW := 0.055
const GOOD_WINDOW := 0.115
const HIT_WINDOW := 0.160

var notes: Array[Dictionary] = []
var song_length := SONG_LENGTH
var time := 0.0
var score := 0
var combo := 0
var max_combo := 0
var hits := 0
var misses := 0
var perfects := 0
var goods := 0
var total_notes := 0
var feedback := ""
var last_hit_lane := -1
var last_miss_lane := -1
var feedback_timer := 0.0
var rock_meter := 0.5
var judged_notes := 0
var last_hit_time := -10.0
var last_hit_lanes: Array[int] = []
var held_lanes := [false, false, false, false, false]

func start(difficulty: int = 1) -> void:
	notes.clear()
	song_length = SONG_LENGTH
	time = 0.0
	score = 0
	combo = 0
	max_combo = 0
	hits = 0
	misses = 0
	perfects = 0
	goods = 0
	feedback = ""
	rock_meter = 0.5
	judged_notes = 0
	last_hit_time = -10.0
	last_hit_lanes.clear()
	last_hit_lane = -1
	last_miss_lane = -1
	feedback_timer = 0.0
	held_lanes = [false, false, false, false, false]
	var step := 60.0 / BPM
	var subdivision: float = [2.0, 1.0, 0.5, 0.5][clampi(difficulty, 0, 3)]
	var interval := step * subdivision
	var count := int((SONG_LENGTH - LEAD_IN - 2.0) / interval)
	for i in range(count):
		var beat_time := LEAD_IN + i * interval
		var lane := (i * 7 + int(i / 4)) % 5
		notes.append({"time": beat_time, "lane": lane, "state": 0})
		if difficulty >= 2 and i % 8 == 4:
			notes.append({"time": beat_time, "lane": (lane + 2) % 5, "state": 0})
	total_notes = notes.size()

func advance(delta: float) -> void:
	advance_to(time + delta,delta)

func advance_to(new_time: float, delta: float) -> void:
	time = maxf(time, new_time)
	feedback_timer = maxf(0.0, feedback_timer - delta)
	for note in notes:
		if int(note["state"]) == 0 and float(note["time"]) < time - HIT_WINDOW:
			_mark_miss(note)

func _mark_miss(note: Dictionary) -> void:
	note["state"] = 2
	misses += 1
	judged_notes += 1
	combo = 0
	rock_meter = maxf(0.0, rock_meter - 0.035)
	last_miss_lane = int(note["lane"])
	feedback = "MISS"
	feedback_timer = 0.40

func press_lane(lane: int) -> void:
	if lane < 0 or lane > 4:
		return
	held_lanes[lane] = true
	# Locate nearest pending note in this lane; simultaneous chord notes
	# are judged independently and may be played with multiple held keys.
	var chosen: Dictionary = {}
	var best: float = HIT_WINDOW + 0.001
	for note in notes:
		if int(note["state"]) != 0 or int(note["lane"]) != lane:
			continue
		var distance: float = absf(float(note["time"]) - time)
		if distance <= HIT_WINDOW and distance < best:
			best = distance
			chosen = note
	if chosen.is_empty():
		return
	chosen["state"] = 1
	judged_notes += 1
	hits += 1
	combo += 1
	max_combo = maxi(max_combo, combo)
	last_hit_lane = lane
	last_hit_time = time
	last_hit_lanes = [lane]
	rock_meter = minf(1.0, rock_meter + 0.012)
	if best <= PERFECT_WINDOW:
		perfects += 1
		feedback = "PERFECT!"
		score += 100 * multiplier()
	else:
		goods += 1
		feedback = "GOOD"
		score += 50 * multiplier()
	feedback_timer = 0.28

func release_lane(lane: int) -> void:
	if lane >= 0 and lane < 5:
		held_lanes[lane] = false

func multiplier() -> int:
	return mini(4, 1 + int(combo / 10))

func accuracy() -> float:
	if total_notes == 0:
		return 0.0
	return 100.0 * float(perfects + goods * 0.5) / float(maxi(1,judged_notes))

func completed() -> bool:
	return time >= song_length

func start_chart(chart_notes: Array) -> void:
	start(1)
	notes.clear()
	for source in chart_notes:
		var note: Dictionary = source.duplicate()
		note["state"] = 0
		notes.append(note)
	total_notes = notes.size()
	var end_time := 0.0
	for note in notes:
		end_time = maxf(end_time,float(note["time"])+float(note.get("length",0.0)))
	song_length = maxf(3.0,end_time+3.0)
