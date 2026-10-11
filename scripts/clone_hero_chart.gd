extends RefCounted
## .chart reader: SyncTrack tempo and 5-fret single note events.
const SECTIONS := ["EasySingle","MediumSingle","HardSingle","ExpertSingle"]
func read(path: String) -> Dictionary:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null:
  return {"error":"Nao foi possivel ler notes.chart"}
 var text_data := file.get_as_text()
 var resolution := 192
 var section := ""
 var pending_section := ""
 var sync: Array[Dictionary] = [{"tick":0,"tempo":500000}]
 var raw := [[],[],[],[]]
 for original in text_data.split("\n"):
  var line := original.strip_edges().trim_prefix("\ufeff")
  if line.begins_with("[") and line.ends_with("]"):
   pending_section = line.substr(1,line.length()-2)
  elif line == "{":
   section = pending_section
  elif line == "}":
   section = ""
  elif line.contains("="):
   var parts := line.split("=",false,1)
   if parts.size() != 2:
    continue
   var key := parts[0].strip_edges()
   var value := parts[1].strip_edges()
   if section == "Song" and key == "Resolution":
    resolution = maxi(1,int(value.trim_prefix("\"").trim_suffix("\"")))
   elif section == "SyncTrack":
    var tokens := value.split(" ",false)
    if tokens.size() >= 2 and tokens[0] == "B":
     var bpm_thousand := float(tokens[1])
     if bpm_thousand > 0:
      sync.append({"tick":int(key),"tempo":roundi(60000000000.0/bpm_thousand)})
   else:
    var difficulty := SECTIONS.find(section)
    if difficulty >= 0:
     var tokens := value.split(" ",false)
     if tokens.size() >= 3 and tokens[0] == "N":
      var lane := int(tokens[1])
      if lane >= 0 and lane <= 4:
       raw[difficulty].append({"tick":int(key),"lane":lane,"length":int(tokens[2])})
 sync.sort_custom(func(a: Dictionary,b: Dictionary):return int(a["tick"])<int(b["tick"]))
 var result := [[],[],[],[]]
 for d in range(4):
  for note in raw[d]:
   var start := _seconds(int(note["tick"]),sync,resolution)
   var end := _seconds(int(note["tick"])+int(note["length"]),sync,resolution)
   result[d].append({"time":start,"lane":int(note["lane"]),"length":maxf(0.0,end-start),"state":0})
  result[d].sort_custom(func(a: Dictionary,b: Dictionary):return float(a["time"])<float(b["time"]))
 return {"notes":result,"format":"chart","division":resolution}

func _seconds(tick: int, sync: Array[Dictionary], division: int) -> float:
 var value := 0.0
 var last_tick := 0
 var tempo := 500000
 for event in sync:
  var at := int(event["tick"])
  if at > tick:
   break
  value += float(at-last_tick)*float(tempo)/float(division)
  last_tick = at
  tempo = int(event["tempo"])
 return (value+float(tick-last_tick)*float(tempo)/float(division))/1000000.0
