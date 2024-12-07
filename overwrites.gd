extends Node

func _init():
	var map = preload("res://mods-unpacked/POModder-Dependency/replacing_files/Map.tscn")
	map.take_over_path("res://content/map/Map.tscn")
	
