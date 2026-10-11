extends Control

var main: Control
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
 for i in range(19):
  var z:=fposmod(float(i)*0.137+float(main.elapsed)*0.19,1.0)
  var perspective:=z*z
  var lane: int=(i*7+i/3)%5
  var left:=lerpf(top_l.x,bot_l.x,perspective)
  var right:=lerpf(top_r.x,bot_r.x,perspective)
  var x:=lerpf(left,right,(float(lane)+0.5)/5.0)
  var y:=42.0+648.0*perspective
  var r:=7.0+30.0*perspective
  draw_circle(Vector2(x,y),r+4,Color("000000"))
  draw_circle(Vector2(x,y),r,LANES[lane].darkened(0.45))
  draw_arc(Vector2(x,y),r-2,0,TAU,24,LANES[lane],4)
  draw_circle(Vector2(x,y-3),r*0.43,LANES[lane].lightened(0.5))
 for i in range(5):
  var x:=lerpf(bot_l.x,bot_r.x,(float(i)+0.5)/5.0)
  var radius:=48.0
  draw_circle(Vector2(x,650),radius+6,Color("08090e"))
  draw_circle(Vector2(x,650),radius,LANES[i].darkened(0.55))
  draw_arc(Vector2(x,650),radius-3,0,TAU,40,LANES[i].lightened(main.key_flash[i]*0.7),7)
  draw_circle(Vector2(x,639),radius*0.6,LANES[i].lightened(main.key_flash[i]*0.45))
