extends Object

func serialize(chain: ModLoaderHookChain):
	var main_node : Node = chain.reference_object
	var tile_mods = chain.reference_object.get_tree().get_nodes_in_group("tile-mods")
	chain.execute_next()
	for mod in tile_mods :
		mod.serialize(main_node)
	
func deserialize(chain: ModLoaderHookChain, data: Dictionary):
	var main_node : Node = chain.reference_object
	var tile_mods = chain.reference_object.get_tree().get_nodes_in_group("tile-mods")
	
	chain.execute_next([data])
	
	for mod in tile_mods :
		mod.deserialize(main_node)
		if mod.set_meta_destructable(main_node,main_node.type) :
			set_meta("destructable", true)
	
func setType(chain: ModLoaderHookChain, type:String):
	var data_mod = chain.reference_object.get_node("/root/ModLoader/POModder-Dependency").data_mod
	var tile_mods = chain.reference_object.get_tree().get_nodes_in_group("tile-mods")
	var main_node : Node = chain.reference_object
	
	chain.execute_next([type])
	for mod in tile_mods :
		if mod.set_meta_destructable(main_node,type) :
			set_meta("destructable", true)
			
	if type == "chaos":
		print("debug")
	if ! (type in data_mod.TILE_ID_TO_STRING_MAP.values()):
		return
		
	var baseHealth:float = Data.of("map.tileBaseHealth")
	
	for mod in tile_mods :
		baseHealth = mod.setType(main_node,type, baseHealth)
		if mod.set_meta_destructable(main_node,type) :
			set_meta("destructable", true)
			
	var healthMultiplier = main_node.hardnessMultiplier
	healthMultiplier *= (pow(Data.of("map.tileHealthMultiplierPerLayer"), main_node.layer))
	
	main_node.max_health = max(1, round(healthMultiplier * baseHealth))
	main_node.health = main_node.max_health 

	
func hit(chain: ModLoaderHookChain, dir:Vector2, dmg:float):
	var tile_mods = chain.reference_object.get_tree().get_nodes_in_group("tile-mods")
	var main_node : Node = chain.reference_object
	
	for mod in tile_mods :
		mod.hit(main_node,main_node.type, dir, dmg) 
	
	if main_node.health - dmg <= 0:
		for mod in tile_mods :
			mod.tileBreak(main_node,main_node.type, dir, dmg)
	chain.execute_next([dir,dmg])
