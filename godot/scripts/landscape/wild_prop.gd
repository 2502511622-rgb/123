class_name YinWildProp29
extends Node2D
var world: FarmWorld
var art: String
var sprite: Sprite2D
var foliage: bool=false
func _ready():
 add_to_group("landscape_props29")
 sprite=Sprite2D.new();sprite.texture=YinWilderness29.art_texture(art);sprite.centered=false
 sprite.position=Vector2(-sprite.texture.get_width()/2.0,-sprite.texture.get_height());sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
 if foliage:sprite.material=world.environment.wilderness29.foliage_material
func _process(delta: float):
 if not is_instance_valid(world.player):return
 if position.distance_squared_to(world.player.position)>640*640:return
 var relative=world.player.position-position
 var behind=absf(relative.x)<sprite.texture.get_width()*.44 and relative.y< -5 and relative.y> -sprite.texture.get_height()*.85
 sprite.modulate.a=move_toward(sprite.modulate.a,.48 if behind else 1.0,delta*3)
