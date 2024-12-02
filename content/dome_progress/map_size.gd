extends HBoxContainer

var sprite_width = 18

func set_map_size_to(map_size : String , col : int):
	match map_size:
		CONST.MAP_SMALL:
			$small.texture = load("res://mods-unpacked/POModder-Dependency/images/progress_map" + str(col+1) + ".png")
			$small.self_modulate = Color(1.0,1.0,1.0,1.0)
		CONST.MAP_MEDIUM:
			$medium.texture = load("res://mods-unpacked/POModder-Dependency/images/progress_map" + str(col+1) + ".png")
			$medium.self_modulate = Color(1.0,1.0,1.0,1.0)
		CONST.MAP_LARGE:
			$large.texture = load("res://mods-unpacked/POModder-Dependency/images/progress_map" + str(col+1) + ".png")
			$large.self_modulate = Color(1.0,1.0,1.0,1.0)
		CONST.MAP_HUGE:
			$huge.texture = load("res://mods-unpacked/POModder-Dependency/images/progress_map" + str(col+1) + ".png")
			$huge.self_modulate = Color(1.0,1.0,1.0,1.0)
			
func set_children_custom_size(multiplyier : float):
	for c in get_children():
		c.custom_minimum_size = c.get_minimum_size()*2
