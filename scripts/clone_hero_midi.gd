extends RefCounted
## Standard MIDI file reader for Clone Hero 5-fret guitar (PART GUITAR).
const TRACK_NAME := 0x03
const TEMPO := 0x51
const NOTE_ON := 0x90
const NOTE_OFF := 0x80
const BASE_NOTES := [60, 72, 84, 96] # Easy, Medium, Hard, Expert

func read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error":"Nao foi possivel abrir notes.mid"}
	var data := file.get_buffer(file.get_length())
	if data.size() < 14 or _ascii(data, 0, 4) != "MThd":
		return {"error":"Cabecalho MIDI invalido"}
	var header_size := _be32(data, 4)
	var tracks := _be16(data, 10)
	var division := _be16(data, 12)
	if division == 0 or (division & 0x8000) != 0:
		return {"error":"Divisao MIDI SMPTE nao suportada"}
	var index := 8 + header_size
	var events: Array[Dictionary] = []
	var tempos: Array[Dictionary] = [{"tick":0,"tempo":500000}]
	for t in range(tracks):
		if index + 8 > data.size() or _ascii(data,index,4) != "MTrk":
			return {"error":"Trilha MIDI corrompida"}
		var finish := mini(data.size(), index + 8 + _be32(data,index+4))
		var pos := index + 8
		var tick := 0
		var running := 0
		var track_name := ""
		var track_events: Array[Dictionary] = []
		var open_notes := {}
		while pos < finish:
			var delta := _vlq(data,pos,finish)
			pos = int(delta["pos"])
			if pos >= finish:
				break
			tick += int(delta["value"])
			var status := int(data[pos])
			if status >= 0x80:
				pos += 1
				if status < 0xF0:
					running = status
			elif running > 0:
				status = running
			else:
				break
			if status == 0xFF:
				if pos >= finish:
					break
				var meta_type := int(data[pos])
				pos += 1
				var length := _vlq(data,pos,finish)
				pos = int(length["pos"])
				var amount := int(length["value"])
				if pos + amount > finish:
					break
				if meta_type == TRACK_NAME:
					track_name = _ascii(data,pos,amount).strip_edges().to_upper()
				elif meta_type == TEMPO and amount == 3:
					tempos.append({"tick":tick,"tempo":(int(data[pos])<<16)|(int(data[pos+1])<<8)|int(data[pos+2])})
				pos += amount
				continue
			if status == 0xF0 or status == 0xF7:
				var length := _vlq(data,pos,finish)
				pos = mini(finish,int(length["pos"])+int(length["value"]))
				continue
			if status >= 0xF0:
				var needed := 1 if status == 0xF1 or status == 0xF3 else 2 if status == 0xF2 else 0
				pos += needed
				continue
			var kind := status & 0xF0
			var needed := 1 if kind == 0xC0 or kind == 0xD0 else 2
			if pos + needed > finish:
				break
			var pitch := int(data[pos])
			var velocity := int(data[pos+1]) if needed == 2 else 0
			pos += needed
			if kind == NOTE_ON and velocity > 0:
				open_notes[pitch] = tick
			elif kind == NOTE_OFF or (kind == NOTE_ON and velocity == 0):
				if open_notes.has(pitch):
					track_events.append({"tick":open_notes[pitch],"pitch":pitch,"length":maxi(0,tick-int(open_notes[pitch]))})
					open_notes.erase(pitch)
		if track_name == "PART GUITAR":
			events = track_events
		index = finish
	tempos.sort_custom(func(a: Dictionary,b: Dictionary): return int(a["tick"]) < int(b["tick"]))
	var notes_by_difficulty := [[],[],[],[]]
	for event in events:
		for difficulty in range(4):
			var lane: int = int(event["pitch"]) - int(BASE_NOTES[difficulty])
			if lane >= 0 and lane < 5:
				var second := _tick_seconds(int(event["tick"]),tempos,division)
				var end_second := _tick_seconds(int(event["tick"])+int(event["length"]),tempos,division)
				notes_by_difficulty[difficulty].append({"time":second,"lane":lane,"length":maxf(0.0,end_second-second),"state":0})
	for notes in notes_by_difficulty:
		notes.sort_custom(func(a: Dictionary,b: Dictionary): return float(a["time"]) < float(b["time"]))
	return {"notes":notes_by_difficulty,"format":"mid","division":division}

func _tick_seconds(tick: int, tempos: Array[Dictionary], division: int) -> float:
	var microseconds := 0.0
	var previous_tick := 0
	var tempo := 500000
	for event in tempos:
		var position := int(event["tick"])
		if position > tick:
			break
		microseconds += float(position-previous_tick)*float(tempo)/float(division)
		previous_tick = position
		tempo = int(event["tempo"])
	microseconds += float(tick-previous_tick)*float(tempo)/float(division)
	return microseconds/1000000.0

func _vlq(data: PackedByteArray, start: int, end: int) -> Dictionary:
	var value := 0
	var pos := start
	for i in range(4):
		if pos >= end:
			break
		var b := int(data[pos])
		pos += 1
		value = (value << 7) | (b & 0x7F)
		if b < 128:
			break
	return {"value":value,"pos":pos}

func _ascii(data: PackedByteArray,start: int,length: int) -> String:
	return data.slice(start,start+length).get_string_from_ascii()

func _be16(data: PackedByteArray,i: int) -> int:
	return (int(data[i])<<8)|int(data[i+1])

func _be32(data: PackedByteArray,i: int) -> int:
	return (int(data[i])<<24)|(int(data[i+1])<<16)|(int(data[i+2])<<8)|int(data[i+3])
