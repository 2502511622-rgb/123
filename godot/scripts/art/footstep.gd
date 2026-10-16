class_name YinFootstep
extends RefCounted

# One continuous mesh keeps the trousers connected at the hips. Each boot has
# its own swing/stance phase; lifting a boot never translates the torso.
const XS=[0.0,.15,.30,.42,.48,.50,.52,.58,.70,.85,1.0]
const YS=[0.0,.52,.64,.72,.80,.88,.94,1.0]
static var indices:=PackedInt32Array()

static func foot_offset(phase: float,side: int,row: int) -> Vector2:
	var cycle=phase+side*PI
	var lift=maxf(0,sin(cycle))*4.5
	var stride=-cos(cycle)
	if row>=2:
		return Vector2(stride*3.5*(-1 if row==2 else 1),-lift)
	return Vector2(stride*.65,stride*(1.8 if row==0 else -1.8)-lift)

static func displacement(f: Vector2,phase: float,strength: float,row: int,body_offset: Vector2) -> Vector2:
	var leg=smoothstep(.64,.88,f.y)*strength
	# Complementary weights: the old unweighted strip through the middle of
	# the sprite pinned overlapping boot pixels to the floor in front views.
	var right=smoothstep(.48,.52,f.x)
	var left=1-right
	return (foot_offset(phase,0,row)*left+foot_offset(phase,1,row)*right-body_offset)*leg

static func draw(canvas: CanvasItem,pose: Dictionary,destination: Rect2,color: Color,body_offset: Vector2) -> void:
	if indices.is_empty():
		for y in range(YS.size()-1):
			for x in range(XS.size()-1):
				var a=y*XS.size()+x;var b=a+XS.size()
				indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]))
	var vertices:=PackedVector2Array();var uvs:=PackedVector2Array()
	var tex_size: Vector2=pose.texture.get_size()
	for y in YS:
		for x in XS:
			var f=Vector2(x,y)
			var shift=displacement(f,pose.gait_phase,pose.gait_strength,pose.gait_row,body_offset)
			if pose.flip:shift.x=-shift.x
			vertices.append(destination.position+destination.size*f+shift)
			uvs.append((pose.source.position+pose.source.size*f)/tex_size)
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),indices,vertices,PackedColorArray([color]),uvs,PackedInt32Array(),PackedFloat32Array(),pose.texture.get_rid())
