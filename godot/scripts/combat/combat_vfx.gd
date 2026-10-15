class_name YinCombatVfx
extends Node2D
var kind: String="sword"
var direction:=Vector2.RIGHT
var target:=Vector2.ZERO
var age: float=0
var duration: float=0.3
var tint:=Color("eccf99")
func _ready() -> void:
	z_index=30
	add_to_group("combat_vfx")
	if kind in ["fire","seal","curse","lightning","spirit"]:duration=0.55
	elif kind=="heavy":duration=0.42
	tint={"heavy":Color("f2c18b"),"fire":Color("f2a15e"),"seal":Color("9bd5c2"),"curse":Color("bc8fab"),"lightning":Color("b8bcf2"),"spirit":Color("a2d4c8")}.get(kind,tint)
func _process(delta: float) -> void:
	var game:=get_tree().get_first_node_in_group("yintian_game")
	if game!=null and game.modal!=null:return
	age+=delta
	if age>=duration:queue_free()
	queue_redraw()
func _draw() -> void:
	var progress: float=clampf(age/duration,0,1)
	var fade: float=1-progress
	var power: float=1.6 if kind=="heavy" else 1.0
	if target.length()>1:
		var travel: float=smoothstep(0,0.24,progress)
		for i in range(8):
			var p: float=clampf(travel-float(i)*0.035,0,1)
			var at: Vector2=target*p+Vector2(0,-sin(p*PI)*10)
			draw_circle(at,maxf(0.5,2.5-float(i)*0.25),Color(tint,fade*(1-float(i)/9.0)))
	var center: Vector2=target
	for i in range(9 if kind=="heavy" else 6):
		var angle_value: float=direction.angle()+float(i)*2.39996
		var ray:=Vector2.from_angle(angle_value)
		var distance_value: float=(5+progress*(18+i%3*7))*power
		draw_line(center+ray*distance_value*0.45,center+ray*distance_value,Color(tint,fade*fade),1.5 if i%3==0 else 1.0)
	if progress<0.24:
		var radius: float=(1-progress/0.24)*5*power
		draw_colored_polygon(PackedVector2Array([center+Vector2(-radius,0),center+Vector2(0,-radius*1.6),center+Vector2(radius,0),center+Vector2(0,radius*1.6)]),Color("fff1d7"))
	if kind in ["heavy","spirit"]:
		draw_set_transform(center+Vector2(0,12),0,Vector2(1,0.35))
		draw_arc(Vector2.ZERO,6+progress*31,0,TAU,40,Color(tint,fade*0.7),1.5)
		draw_set_transform(Vector2.ZERO)
	if kind=="fire":
		for i in range(10):
			var at:=center+Vector2(sin(float(i)*5.0+progress*3.0)*12,8-progress*(25+i%3*9))
			draw_circle(at,(1-progress)*float(2+i%3),Color(tint,fade*0.8))
	elif kind in ["seal","curse"]:
		draw_arc(center,10+progress*9,-age*4,TAU-age*4,32,Color(tint,fade),1)
		for i in range(4):
			var at:=center+Vector2.from_angle(PI/4+float(i)*PI/2+age)*float(13+progress*7)
			draw_rect(Rect2(at-Vector2(1,3),Vector2(2,6)),Color(tint,fade))
	elif kind=="lightning":
		var points:=PackedVector2Array()
		for i in range(7):points.append(center+Vector2(sin(float(i)*13+floor(age*24))*8,-30+float(i)*8))
		draw_polyline(points,Color(tint,fade),1.5)
