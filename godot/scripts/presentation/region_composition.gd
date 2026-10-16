class_name YinRegionComposition
extends Node2D
var world: FarmWorld
func _ready() -> void:
	name="RegionalGroundDetails"
	z_index=-2
func _draw() -> void:
	var style: Dictionary=YinRegionStyle.profile(world.state.zone)
	if world.state.zone=="temple":
		# Real courtyard openings receive steps, so height cues agree with traversable gaps.
		for rect in [Rect2(576,736,160,32),Rect2(1040,736,176,32),Rect2(992,320,32,128)]:
			stairs(rect,Color(style.stone))
		for at in [Vector2(656,912),Vector2(1136,544)]:
			draw_arc(at,64,0,TAU,40,Color("b6a17a55"),2)
			for angle in range(8):draw_line(at+Vector2.from_angle(angle*TAU/8)*42,at+Vector2.from_angle(angle*TAU/8)*62,Color("b6a17a66"),1)
	elif world.state.zone=="graveyard":
		for at in [Vector2(280,240),Vector2(380,390),Vector2(680,240)]:
			draw_set_transform(at,0,Vector2(1,0.45))
			draw_circle(Vector2.ZERO,48,Color("283e3b44"))
			draw_arc(Vector2.ZERO,51,PI*0.15,PI*0.85,24,Color("9aa79238"),2)
			draw_set_transform(Vector2.ZERO)
	elif world.state.zone=="island":
		# A readable timber landing at the actual ferry arrival.
		var dock:=Rect2(128,1392,256,96)
		draw_texture_rect(YinWorldArt.surface(3),dock,true,Color("b4a28c"))
		for x in range(128,385,64):
			draw_rect(Rect2(x-2,1390,4,98),Color("675d50"))
			draw_circle(Vector2(x,1392),3,Color("d6bb8d"))
	elif world.state.zone=="theatre":
		var stage:=Rect2(864,192,320,288)
		draw_texture_rect(YinWorldArt.surface(3),stage,true,Color("aa8882"))
		stairs(Rect2(864,480,320,48),Color("a0907e"))
		for x in [864,1178]:
			draw_rect(Rect2(x,192,6,288),Color("75494a"))
			draw_line(Vector2(x,192),Vector2(x+6,192),Color("d6b98b"),2)
func stairs(rect: Rect2,tint: Color) -> void:
	draw_rect(Rect2(rect.position+Vector2(3,5),rect.size),Color("182a3444"))
	draw_texture_rect(YinWorldArt.surface(1),rect,true,tint)
	for y in range(int(rect.position.y),int(rect.end.y),8):
		draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),Color("cfbea1aa"),1)
		draw_line(Vector2(rect.position.x,y+6),Vector2(rect.end.x,y+6),Color("3d4b5277"),2)
