extends "res://stages/manager/StageManager.gd"

var stage = null
var custom_achievements_manager
var saver 

func startStage(stageName:String, data:Array=[], tabula:bool = true):
	if stageName == "stages/loadout/multiplayerloadout":
		stageName = "mods-unpacked/POModder-Dependency/stages/MultiplayerloadoutMod"
	super(stageName, data, tabula)
	
func _addNewStage():
	custom_achievements_manager = get_node("/root/ModLoader/POModder-Dependency").custom_achievements
	saver = get_node("/root/ModLoader/POModder-Dependency").saver
	super()
	await get_tree().create_timer(0.3).timeout
	stage = StageManager.currentStage
	saver.change_stage()
	custom_achievements_manager.change_stage(stage.name)
	
