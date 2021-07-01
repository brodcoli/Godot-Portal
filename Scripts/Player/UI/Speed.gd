extends Label

onready var _player = get_node("../..")

var _font_size = 4

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()
	_update_text()

func _on_resize():
	var size = get_viewport_rect().size
	_font_size = (int(size.x * 0.02) | 0x03) + 1
	$Sprite.scale = Vector2.ONE * (_font_size / 4)
	_update_text()
	
func _process(delta):
	var size = get_viewport_rect().size
	text = str(floor((sin(OS.get_ticks_msec() / 2000.0) + 1) * 60))
	rect_position = Vector2(size.x * 0.78 - (text.length() - 2) * _font_size, size.y * 0.8)
	$Sprite.position.x = _font_size * 2.6 + (text.length() - 2) * _font_size
	
func _update_text():
	var size = get_viewport_rect().size
	text = "54"
	rect_position = Vector2(size.x * 0.6, size.y * 0.8)
	$Sprite.position.x = _font_size * 2.6
	
func _speed_change():
	_update_text()
