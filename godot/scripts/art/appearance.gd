class_name YinAppearance
extends RefCounted
const COLORS = {
	"hair": [Color("e3e4df"),Color("302d38"),Color("795344"),Color("d4b675"),Color("46688a"),Color("9e494d"),Color("74918a"),Color("9c86b0")],
	"coat": [Color("344e7a"),Color("9a444a"),Color("3b6958"),Color("746080"),Color("d7cab0"),Color("363a48"),Color("916b46"),Color("427e94")],
	"scarf": [Color("b84d45"),Color("4d949b"),Color("c99b58"),Color("dfd4bd"),Color("343945"),Color("a17c9e"),Color("718556"),Color("4b5f91")],
	"trousers": [Color("d9ccb0"),Color("73747a"),Color("353d54"),Color("9c8265"),Color("8aabb8")],
	"boots": [Color("705345"),Color("32333c"),Color("a3a49a"),Color("77434b")],
	"skin": [Color("e5b68d"),Color("c3936e"),Color("9a7054"),Color("76513f")],
	"trim": [Color("c7a25e"),Color("b8c2c8"),Color("ac7658"),Color("719987")]
}
const LABELS = {
	"body": ["旅行剑士","符术旅人"],
	"hair": ["霜白","墨黑","栗棕","浅金","靛蓝","枣红","青灰","藤紫"],
	"coat": ["靛青","朱砂","墨绿","紫藤","象牙","深墨","赭石","海蓝"],
	"scarf": ["朱红","湖青","金橙","素白","鸦黑","藤紫","苔绿","靛蓝"],
	"trousers": ["米白","墨灰","靛黑","砂褐","雾蓝"],
	"boots": ["深棕","墨黑","灰白","酒红"],
	"skin": ["浅肤","暖麦","棕肤","深肤"],
	"trim": ["旧金","银灰","赤铜","青玉"]
}
const NAMES = {"body":"造型","hair":"发色","coat":"衣装","scarf":"围巾","trousers":"下装","boots":"鞋靴","skin":"肤色","trim":"饰件"}
static func initial() -> Dictionary:
	return {"name":"行者","body":0,"hair":0,"coat":0,"scarf":0,"trousers":0,"boots":0,"skin":0,"trim":0}
static func validate(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=9 or not value.get("name") is String: return false
	var name_value: String = value.name
	if name_value.strip_edges().is_empty() or name_value.length()>12: return false
	for i in range(name_value.length()):
		if name_value.unicode_at(i)<32: return false
	for key in LABELS:
		var index: Variant = value.get(key)
		if not (index is int or index is float) or not is_finite(float(index)) or float(index)!=floor(float(index)) or index<0 or index>=LABELS[key].size(): return false
	return true
static func configure(mat: ShaderMaterial, value: Dictionary) -> void:
	mat.set_shader_parameter("avatar_enabled",true)
	for key in COLORS: mat.set_shader_parameter("avatar_"+key,COLORS[key][int(value.get(key,0))])
static func pose_uniforms(mat: ShaderMaterial, pose: Dictionary) -> void:
	mat.set_shader_parameter("avatar_texture_size",pose.texture.get_size())
	mat.set_shader_parameter("avatar_region",Vector4(pose.source.position.x,pose.source.position.y,pose.source.size.x,pose.source.size.y))

static var names_font: SystemFont
static func name_font() -> Font:
	if names_font==null:
		names_font=SystemFont.new()
		names_font.font_names=PackedStringArray(["Noto Sans CJK SC","Microsoft YaHei","PingFang SC","sans-serif"])
	return names_font
