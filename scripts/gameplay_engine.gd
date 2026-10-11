extends RefCounted
## Gameplay deterministico de 5 pistas, desacoplado da interface.
const BPM := 120.0
const LEAD_IN := 2.0
const SONG_LENGTH := 35.0
const PERFECT_WINDOW := 0.055
const GOOD_WINDOW := 0.115
const HIT_WINDOW := 0.160

var notes: Array[Dictionary] = []
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
var feedback_timer := 0.0
var held_lanes := [false, false, false, false, false]

func start(difficulty: int = 1) -> void:
 notes.clear()
 time = 0.0
 score = 0
 combo = 0
 max_combo = 0
 hits = 0
 misses = 0
 perfects = 0
 goods = 0
 feedback = ""
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
 time += delta
 feedback_timer = maxf(0.0, feedback_timer - delta)
 for note in notes:
  if int(note["state"]) == 0 and float(note["time"]) < time - HIT_WINDOW:
   note["state"] = 2
   misses += 1
   combo = 0
   feedback = "MISS"
   feedback_timer = 0.45

func press_lane(lane: int) -> void:
 if lane < 0 or lane > 4:
  return
 held_lanes[lane] = true
 var nearest: Dictionary = {}
 var best := HIT_WINDOW + 0.001
 for note in notes:
  if int(note["state"]) != 0 or int(note["lane"]) != lane:
   continue
  var distance := absf(float(note["time"]) - time)
  if distance < best:
   best = distance
   nearest = note
 if nearest.is_empty():
  return
 nearest["state"] = 1
 hits += 1
 combo += 1
 max_combo = maxi(max_combo, combo)
 if best <= PERFECT_WINDOW:
  perfects += 1
  feedback = "PERFECT!"
  score += 100 * multiplier()
 else:
  goods += 1
  feedback = "GOOD"
  score += 50 * multiplier()
 feedback_timer = 0.5

func release_lane(lane: int) -> void:
 if lane >= 0 and lane < 5:
  held_lanes[lane] = false

func multiplier() -> int:
 return mini(4, 1 + int(combo / 10))

func accuracy() -> float:
 if total_notes == 0:
  return 0.0
 return 100.0 * float(perfects + goods * 0.5) / float(total_notes)

func completed() -> bool:
 return time >= SONG_LENGTH
