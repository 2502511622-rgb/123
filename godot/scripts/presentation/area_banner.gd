class_name YinAreaBanner
extends Control
var game: Node2D
var zone: String="farm"
var elapsed: float=4
var coastal: bool=false
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	position=Vector2(193,25);size=Vector2(248,72)
func reveal(value: String) -> void:
	zone=value;elapsed=0;queue_redraw()
func _process(delta: float) -> void:
	if game.modal!=null:return
	var here=game.seamless and zone=="island" and YinLandscape29.COAST.has_point(game.player.position)
	if here!=coastal:coastal=here;elapsed=0
	elapsed+=delta
	visible=elapsed<3.2
	modulate.a=clampf(minf(elapsed/0.25,(3.2-elapsed)/0.8),0,1)
	queue_redraw()
func _draw() -> void:
	var style: Dictionary=YinRegionStyle.profile(zone)
	if coastal:
		style=style.duplicate();style.name="潮痕海岛遗迹";style.subtitle="断拱潮声 · 半埋旧文明";style.accent="aac5bf"
	var font: Font=ThemeDB.fallback_font
	var title_width: float=font.get_string_size(style.name,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
	draw_string(font,Vector2((248-title_width)/2+1,28),style.name,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("121c2bd9"))
	draw_string(font,Vector2((248-title_width)/2,27),style.name,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("eee1c5"))
	draw_line(Vector2(54,37),Vector2(194,37),Color(style.accent),1)
	var sub_width: float=font.get_string_size(style.subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string(font,Vector2((248-sub_width)/2,53),style.subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d2d3c8"))
