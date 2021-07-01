extends Node2D

var font_size = 0

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	var size = get_viewport_rect().size
	font_size = (int(size.x * 0.02) | 0x03) + 1
	get("custom_fonts/font").set_size(font_size)
