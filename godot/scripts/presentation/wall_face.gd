class_name YinWallFace
extends Node2D
var cell_size:=Vector2(32,32)
func _draw() -> void:
	var face:=Rect2(-cell_size.x*0.5,-cell_size.y,cell_size.x,cell_size.y)
	draw_rect(face,Color("555c66"))
	draw_texture_rect(YinWorldArt.surface(1),Rect2(face.position-Vector2(0,12),Vector2(face.size.x,12)),true,Color("d8d1b6"))
	draw_line(face.position-Vector2(0,12),face.position+Vector2(face.size.x,-12),Color("e1d3ad"),1)
	for row in range(2):
		var y: float=-cell_size.y+row*12
		draw_line(Vector2(face.position.x,y),Vector2(face.end.x,y),Color("333e49"),1)
		draw_line(Vector2(0 if row%2 else -8,y),Vector2(0 if row%2 else -8,minf(y+12,0)),Color("3e4852"),1)
	draw_line(Vector2(face.position.x,-1),Vector2(face.end.x,-1),Color("293b45"),2)
static func install(world: FarmWorld,rect: Rect2) -> void:
	for y in range(int(rect.position.y),int(rect.end.y),32):
		for x in range(int(rect.position.x),int(rect.end.x),32):
			var wall:=YinWallFace.new()
			wall.cell_size=Vector2(minf(32,rect.end.x-x),minf(32,rect.end.y-y))
			wall.position=Vector2(x+wall.cell_size.x*0.5,y+wall.cell_size.y)
			wall.add_to_group("diorama_walls")
			world.actors.add_child(wall)
