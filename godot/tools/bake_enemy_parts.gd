extends SceneTree
# Build anatomical alpha layers from source pixels. No source colors are repainted.
const OUT = "res://assets/jrpg/parts/"
const JOINTS = ["body","head","arm","arm_left","leg","leg_left"]
var output: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func kind_for(key: String) -> String:
	return "daitengu" if key.begins_with("daitengu:") else key
func classify(kind: String,p: Vector2,split: float,head: Vector3) -> String:
	if kind in ["sogenbi","chochin"]:return "head" if p.y<0.65 else "body"
	var neck: float=clampf(split,head.x+0.06,head.y-0.06)
	var t: float=clampf((p.y-head.z*0.65)/(head.z*0.35),0,1)
	var left: float=lerpf(head.x,neck-0.08,t)
	var right: float=lerpf(head.y,neck+0.08,t)
	if p.y<head.z and p.x>=left and p.x<=right:return "head"
	if p.y>0.73:
		if kind=="ippon_datara":
			if absf(p.x-split)<0.30:return "leg"
		else:
			var spread: float=lerpf(0.15,0.29,clampf((p.y-0.73)/0.27,0,1))
			if p.x>=split and p.x<split+spread:return "leg"
			if p.x<split and p.x>split-spread:return "leg_left"
	if p.y>=0.28 and p.y<0.74:
		var edge: float=lerpf(0.65,0.76,(p.y-0.28)/0.46)
		if p.x>edge:return "arm"
		if p.x<1.0-edge:return "arm_left"
	return "body"
func bake(key: String,image: Image,frame: Dictionary,head: Vector3) -> void:
	var values: Array=frame.rect
	var source:=Rect2i(values[0],values[1],values[2],values[3])
	var raw: Image=image.get_region(source)
	var split: float=clampf(float(frame.anchor[0])/source.size.x,0.25,0.75)
	var kind: String=kind_for(key)
	var layers: Dictionary={}
	for joint in JOINTS:layers[joint]=Image.create(source.size.x,source.size.y,false,Image.FORMAT_RGBA8)
	for y in range(source.size.y):
		for x in range(source.size.x):
			var pixel: Color=raw.get_pixel(x,y)
			if pixel.a<=0:continue
			var joint: String=classify(kind,Vector2((x+0.5)/source.size.x,(y+0.5)/source.size.y),split,head)
			layers[joint].set_pixel(x,y,pixel)
	var parts: Array=[]
	for joint in JOINTS:
		var layer: Image=layers[joint]
		var bounds: Rect2i=layer.get_used_rect()
		if not bounds.has_area():continue
		var path: String=OUT+key.replace(":","_")+"_"+joint+".png"
		if layer.get_region(bounds).save_png(path)!=OK:
			push_error("Cannot save anatomical part "+path)
			quit(1)
			return
		var pivot:=Vector2(split,0.52)
		if joint=="head":pivot=Vector2(split,head.z)
		elif joint=="arm":pivot=Vector2(0.69,0.34)
		elif joint=="arm_left":pivot=Vector2(0.31,0.34)
		elif joint=="leg":pivot=Vector2(split+0.07,0.75)
		elif joint=="leg_left":pivot=Vector2(split-0.07,0.75)
		parts.append({"joint":joint,"part":joint if joint in ["head","arm","leg"] else "body","path":path,"crop":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"pivot":[pivot.x,pivot.y]})
	output[key]={"frame":frame,"parts":parts,"atlas":"tengu" if key.begins_with("daitengu:") else "roster"}
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var atlas: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/jrpg/atlas.json"))
	var roster:=Image.load_from_file("res://assets/jrpg/roster.png")
	var tengu:=Image.load_from_file("res://assets/jrpg/tengu.png")
	for kind in atlas.roster:
		if kind=="daitengu_extra":continue
		var head:=Vector3(0.20,0.80,0.33)
		if kind=="kappa":head=Vector3(0.03,0.73,0.34)
		elif kind=="brute":head=Vector3(0.18,0.88,0.39)
		elif kind in ["asura","yaksha","rakshasa"]:head=Vector3(0.22,0.78,0.36)
		bake(kind,roster,atlas.roster[kind],head)
	for row in range(4):
		for column in range(4):
			var attack: bool=column==3
			var head:=Vector3(0.56 if attack else (0.30 if row in [1,3] else 0.0),1.0 if attack or row in [1,3] else 0.68,0.28 if attack else 0.34)
			bake("daitengu:%d:%d"%[row,column],tengu,atlas.tengu[row][column],head)
	var file:=FileAccess.open(OUT+"parts.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	file.close()
	print("BAKED anatomical source layers: ",output.size()," poses")
	quit()
