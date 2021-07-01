extends Label

onready var _player = $"../.."

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	var size = get_viewport_rect().size
	var _font_size = (int(size.x * 0.02) | 0x03) + 1
	rect_position = Vector2(size.x / 2 - _font_size * 2.5, size.y / 2 - _font_size * 2.2)
	
func _process(delta):
	#if body and "only_exists_in_vending_machine" in body:
	if _player.look_area is VehicleUseArea:
		if _player.is_riding:
			text = "CLICK TO LEAVE"
		else:
			text = "CLICK TO RIDE"
		visible = true
	else:
		visible = false
