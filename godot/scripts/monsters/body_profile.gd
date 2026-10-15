class_name YinBodyProfile
extends RefCounted
const HEAVY=["brute","kumbhanda","boss","asura","yaksha","ryomen_sukuna","well_boss","opera_boss","itsumade","daitengu"]
const FLOATING=["wraith","chochin","sogenbi","lantern"]
static func spec(kind: String) -> Dictionary:
	var boss: bool=kind in YinAbilities.BOSSES
	var size_value:=Vector2(20,12)
	if kind in HEAVY:size_value=Vector2(34,18) if boss else Vector2(28,16)
	if kind=="jorogumo":size_value=Vector2(34,16)
	if kind in FLOATING:size_value=Vector2(18,12)
	if kind=="ippon_datara":size_value=Vector2(22,14)
	return {"size":size_value,"half":size_value*0.5,"mass":3.0 if boss else (1.7 if kind in HEAVY else 1.0),"height":78.0 if boss else 54.0,"stride":36.0 if boss else (29.0 if kind=="ippon_datara" else 26.0),"floating":kind in FLOATING}
static func shape(kind: String) -> CapsuleShape2D:
	var data: Dictionary=spec(kind)
	var capsule:=CapsuleShape2D.new()
	capsule.radius=data.size.y*0.5
	capsule.height=data.size.x
	return capsule
