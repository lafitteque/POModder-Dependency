extends Node

const MYMODNAME_LOG = "POModder-Dependency"
const MYMODNAME_MOD_DIR = "POModder-Dependency/"

var dir = ""
var ext_dir = ""

var trans_dir = "res://mods-unpacked/POModder-Dependency/translations/"

var data_achievements 
var data_mod 
var custom_achievements 
var saver


func _init():
	ModLoaderLog.info("Init", MYMODNAME_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
	ext_dir = dir + "extensions/"
	
	# Add extensions
	for loc in ["en" , "es" , "fr"]:
		ModLoaderMod.add_translation(trans_dir + "translations." + loc + ".translation")
	
	ModLoaderMod.install_script_extension(ext_dir + "StageManager.gd")
	
	ModLoaderMod.install_script_hooks("res://content/map/tile/Tile.gd", "res://mods-unpacked/POModder-Dependency/replacing_files/Tile.gd")
	ModLoaderMod.install_script_hooks("res://content/map/Map.gd", "res://mods-unpacked/POModder-Dependency/replacing_files/Map.gd")
	
func modInit():
	pass
	
func _ready():
	ModLoaderLog.info("Done", MYMODNAME_LOG)
	add_to_group("mod_init")
	
	data_achievements = preload("res://mods-unpacked/POModder-Dependency/content/Data/DataForAchievements.tscn").instantiate()
	data_mod = preload("res://mods-unpacked/POModder-Dependency/content/Data/DataForMod.tscn").instantiate()
	add_child(data_achievements)
	add_child(data_mod)
	
	saver = preload("res://mods-unpacked/POModder-Dependency/content/Save/Saver.tscn").instantiate()
	add_child(saver)
	custom_achievements = preload("res://mods-unpacked/POModder-Dependency/content/Data/CustomAchievements.tscn").instantiate()
	add_child(custom_achievements)
		
	
	


