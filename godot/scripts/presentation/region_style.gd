class_name YinRegionStyle
extends RefCounted
# Shared art direction for terrain, vegetation, atmosphere and destination cards.
const STYLES={
	"farm":{"name":"义庄营地","subtitle":"纸灯与归途","turf":"64734b","stone":"a69b7a","fog":"c1ba9d","ink":"26352d","accent":"d8ac64","tree":["tree","tree_autumn","tree"]},
	"village":{"name":"青槐村","subtitle":"人间烟火","turf":"657853","stone":"b5a483","fog":"c7b49a","ink":"314537","accent":"ddb873","tree":["tree","tree","tree_autumn"]},
	"graveyard":{"name":"乱葬岗","subtitle":"石碑之下 · 无名之声","turf":"3a4e4a","stone":"737a82","fog":"9eb6be","ink":"273542","accent":"8eb6c0","tree":["tree_pine","tree_pine","tree_autumn"]},
	"forest":{"name":"后山铳林","subtitle":"幽深树海 · 枪声回响","turf":"385446","stone":"7f8a78","fog":"8cae9a","ink":"233d36","accent":"9bb898","tree":["tree","tree_pine","tree"]},
	"island":{"name":"岛国","subtitle":"裂海彼岸 · 朱鸟与古神","turf":"69724e","stone":"b6a181","fog":"c1baa5","ink":"33484d","accent":"d59a69","tree":["tree_pine","tree_autumn","tree_autumn"]},
	"temple":{"name":"大佛寺","subtitle":"梵钟不响 · 六道纷争","turf":"5c674f","stone":"b4ab91","fog":"c6bfaa","ink":"3e4242","accent":"d5b469","tree":["tree_pine","tree_pine","tree"]},
	"sunken":{"name":"沉水村","subtitle":"井中旧梦 · 潮声未息","turf":"3e5858","stone":"6e9193","fog":"94babc","ink":"253e48","accent":"8bbec0","tree":["tree_pine","tree_pine","tree"]},
	"theatre":{"name":"废戏台","subtitle":"红幕之后 · 无面之人","turf":"5b514b","stone":"968675","fog":"bfa79c","ink":"42313b","accent":"cf8b7c","tree":["tree_autumn","tree_pine","tree_autumn"]},
	"hall":{"name":"义庄","subtitle":"归处 · 整备与休憩","turf":"6f674e","stone":"a39679","fog":"d0b38b","ink":"302b30","accent":"dfb476","tree":["tree"]},
	"shop":{"name":"杂货铺","subtitle":"行囊与旅装","turf":"6f674e","stone":"a39679","fog":"d0b38b","ink":"302b30","accent":"dfb476","tree":["tree"]}
}
static func profile(zone: String) -> Dictionary:return STYLES.get(zone,STYLES.farm)
static func tree(zone: String,at: Vector2) -> String:
	var options: Array=profile(zone).tree
	return options[absi(hash(at))%options.size()]
static func apply_terrain(material: ShaderMaterial,zone: String) -> void:
	var art: Dictionary=profile(zone)
	material.set_shader_parameter("turf_tint",Color(art.turf))
	material.set_shader_parameter("stone_tint",Color(art.stone))
	material.set_shader_parameter("water_tint",Color("5a9caa") if zone=="island" else Color("426b77"))
