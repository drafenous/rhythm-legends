extends Control

const DARK := Color("080b12")
const RED := Color("b82033")
const BLUE := Color("1b4675")

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    draw_rect(Rect2(Vector2.ZERO, size), DARK)
    for i in range(34):
        var y: float = h * float(i) / 34.0
        draw_rect(Rect2(0, y, w, h / 34.0 + 1), Color("121a28").lerp(DARK, float(i) / 37.0))
    var spots := [Vector2(w * 0.14, -12), Vector2(w * 0.38, -12), Vector2(w * 0.68, -12), Vector2(w * 0.87, -12)]
    var colors := [BLUE, RED, BLUE, RED]
    for i in range(spots.size()):
        var p: Vector2 = spots[i]
        var bottom := Vector2(p.x + (float(i) - 1.5) * 150, h * 0.85)
        draw_colored_polygon(PackedVector2Array([p, bottom + Vector2(-220, 0), bottom + Vector2(220, 0)]), Color(colors[i], 0.11))
        draw_circle(p, 26.0, Color(colors[i], 0.65))
    draw_rect(Rect2(0, h * 0.82, w, h * 0.18), Color(0, 0, 0, 0.40))
    for i in range(22):
        var x := (float(i) + 0.5) * w / 22.0
        var variation := sin(float(i) * 3.18) * 16.0
        draw_circle(Vector2(x, h * 0.93 + variation), 33.0 + float(i % 3) * 6.0, Color("030408"))
    draw_line(Vector2(0, h * 0.81), Vector2(w, h * 0.81), Color("bd2538"), 2.0)
