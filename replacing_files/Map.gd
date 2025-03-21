extends Node


func revealTile(chain: ModLoaderHookChain, coord:Vector2):
	#print("reveal Tile debug success")
	var main_node = chain.reference_object
	var data_mod = main_node.get_node("/root/ModLoader/POModder-Dependency").data_mod
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")

	var typeId:int = main_node.tileData.get_resource(coord.x, coord.y)
	var invalids := []
	
	for mod in map_mods:
		mod.modmodifyTileWhenRevealed(main_node,coord,typeId)
		
	typeId = main_node.tileData.get_resource(coord.x, coord.y)
	
	if not(  typeId in data_mod.TILE_ID_TO_STRING_MAP.keys().slice(10) ):
		chain.execute_next([coord])
		return
		
	### if tile is marker iron (in order to have exactly one iron per layer
	### used to know the layer numner), remove iron
	if main_node.tileRevealedListeners.has(coord):
		for listener in main_node.tileRevealedListeners[coord]:
			if is_instance_valid(listener):
				listener.tileRevealed(coord)
			else:
				invalids.append(listener)
		for invalid in invalids:
			main_node.tileRevealedListeners.erase(invalid)
	
	if main_node.tiles.has(coord):
		return
	
	var tile = load("res://content/map/tile/Tile.tscn").instantiate()
	var biomeId:int = main_node.tileData.get_biome(coord.x, coord.y)
	tile.layer = biomeId
	tile.biome = main_node.biomes[tile.layer]
	tile.position = coord * GameWorld.TILE_SIZE
	tile.coord = coord
		
	tile.hardness = main_node.tileData.get_hardness(coord.x, coord.y)
	tile.type = data_mod.TILE_ID_TO_STRING_MAP.get(typeId, "dirt")

	match tile.type:
		CONST.IRON:
			tile.richness = Data.ofOr("map.ironrichness", 2)
			main_node.revealTileVisually(coord)
		CONST.SAND:
			tile.richness = Data.ofOr("map.cobaltrichness", 2)
			main_node.revealTileVisually(coord)
		CONST.WATER:
			tile.richness = Data.ofOr("map.waterrichness", 2.5)
			main_node.revealTileVisually(coord)
		_:
			for mod in map_mods:
				mod.revealTileVisually(main_node, tile, coord)
				
					
	main_node.tiles[coord] = tile 
	
	if main_node.tilesByType.has(tile.type):
		main_node.tilesByType[tile.type].append(tile)
	tile.connect("destroyed", Callable(main_node, "destroyTile").bind(tile))
	
	main_node.tiles_node.add_child(tile)

	# Allow border tiles to fade correctly at edges of the map
	main_node.visibleTileCoords[coord] = typeId
	

	
	

	
	
### Not compatible with other mods (how to do?)
func addDrop(chain: ModLoaderHookChain, drop):
	var main_node = chain.reference_object
	var data_mod = main_node.get_node("/root/ModLoader/POModder-Dependency").data_mod
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")
	
	var should_grow_count = 0
	var should_be_small_count = 0
	
	var should_stop = false
	for mod in map_mods:
		should_stop = should_stop or mod.addDrop(main_node,drop)

	
	var big = "worldmodifierbigdrops" in Level.loadout.modeConfig.get(CONST.MODE_CONFIG_WORLDMODIFIERS, []) or should_grow_count > 0
	var small = "worldmodifiersmalldrops" in Level.loadout.modeConfig.get(CONST.MODE_CONFIG_WORLDMODIFIERS, []) or should_be_small_count > 0
	
	if big and drop is Drop and \
	drop.global_position.y >= 20 and drop.carriedBy.size() == 0 :
		var count = 4
		if drop.type in data_mod.ALL_DROP_NAMES :
			count = 8
		elif drop.type == "relic":
			count = 6
			
		if should_grow_count == 1 :
			count = 4
			
		main_node.add_child(drop)	
		drop.apply_central_impulse(Vector2(0, 40).rotated(randf() * TAU))
		Style.init(drop)
		for i in count:
			await main_node.get_tree().create_timer(0.1).timeout
			if ! is_instance_valid(drop):
				continue
			for child in drop.get_children():
				if "scale" in child:
					if child.name == "CollisionShape2D" and drop.type in ["gadget", "powercore"] and i >2:
						continue
					child.scale = Vector2(1.0 + 0.1*i, 1.1 + 0.1*i)
		return 
		
	if small and("type" in drop) and \
	drop.type in data_mod.ALL_DROP_NAMES and !(drop.global_position.y <= 0 or drop.carriedBy.size()>0 ):
		main_node.add_child(drop)	
		drop.apply_central_impulse(Vector2(0, 40).rotated(randf() * TAU))
		Style.init(drop)
		if should_be_small_count == 1 :
			for child in drop.get_children():
				if "scale" in child:
					child.scale = Vector2(0.75 , 0.75)
			return
		for child in drop.get_children():
			if "scale" in child:
				child.scale = Vector2(0.5 , 0.5)
		return	

	if should_stop:
		return
			
	main_node.add_child(drop)	
	Style.init(drop)
	
	if false :
		chain.execute_next()


func destroyTile(chain: ModLoaderHookChain, tile, withDropsAndSound := true):
	var main_node = chain.reference_object
	var data_mod = main_node.get_node("/root/ModLoader/POModder-Dependency").data_mod
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")
	
	chain.execute_next([tile, withDropsAndSound])

	for mod in map_mods:
		mod.destroyTile(main_node, tile, withDropsAndSound)
		
		
func getSceneForTileType(chain: ModLoaderHookChain, tileType:int) -> PackedScene:
	var main_node = chain.reference_object
	var data_mod = main_node.get_node("/root/ModLoader/POModder-Dependency").data_mod
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")
	
	for mod in map_mods:
		var suggestion = mod.getSceneForTileType(tileType)
		if suggestion != null :
			return suggestion
	
	return chain.execute_next([tileType])
#
	
func init(chain: ModLoaderHookChain, fromDeserialize := false, defaultState := true):
	var main_node = chain.reference_object
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")
	
	chain.execute_next([fromDeserialize,defaultState])
	
	for mod in map_mods :
		mod.init(chain.reference_object, fromDeserialize, defaultState)
	
	

### Not compatible with other mods (how to do?)
func generateCaves(chain: ModLoaderHookChain, minDistanceToCenter := 10):
	var main_node = chain.reference_object
	var map_mods = main_node.get_tree().get_nodes_in_group("map-mods")
	
	var rand = RandomNumberGenerator.new()
	rand.seed = Level.levelSeed
	var caveScenesById = Data.CAVE_SCENES.duplicate()

	var cavePackeScenes := []
	# SPECIAL CAVES
	if Level.loadout.modeId == CONST.MODE_RELICHUNT:
		if GameWorld.isPetUnlockable():
			cavePackeScenes.append(preload("res://content/map/chamber/nest/NestCave.tscn"))

	if GameWorld.useCustomCaveOrder and GameWorld.customCaveOrder and GameWorld.customCaveOrder.size() > 0:
		for caveId in GameWorld.customCaveOrder:
			if caveScenesById.has(caveId):
				cavePackeScenes.append(caveScenesById[caveId])
	else:
		for caveId in Data.CAVE_SCENES:
			if caveScenesById.has(caveId):
				cavePackeScenes.append(caveScenesById[caveId])
		Utils.shuffle(cavePackeScenes,rand)

	if Level.loadout.modeId == CONST.MODE_RELICHUNT:
		for keeper in Level.loadout.keepers:
			if keeper.keeperId == "keeper1":
				if GameWorld.isHalloween and Level.loadout.modeId == CONST.MODE_RELICHUNT:
					cavePackeScenes.insert(0, preload("res://content/caves/halloweencave/HalloweenSkeletonCave.tscn"))
					break
		if GameWorld.isLunarNewYear and not GameWorld.unlockedPets.has("pet8"):
			cavePackeScenes.insert(0, preload("res://content/caves/dragoncave/LunarNewYearDragonCave.tscn"))
		if main_node.shouldGenerateDrillbertCave():
			cavePackeScenes.insert(0, preload("res://content/caves/drillicave/DrillbertCave.tscn"))
	
	
	for mod in map_mods:
		mod.beforeCaveGeneration(main_node, cavePackeScenes, minDistanceToCenter,rand)
		
			
	var availableCaves:Array
	var caveCount := {}
	var maxLayer = main_node.startingIronCountByLayer.size()
	for layerIndex in maxLayer:
		if availableCaves.is_empty():
			availableCaves = cavePackeScenes.duplicate()
		for cavePackedScene in availableCaves:
			var cave = cavePackedScene.instantiate() # yeah this is shit, but probably not noticable
			var biomeFits = cave.biome == "" or main_node.biomes[layerIndex] == cave.biome 
			var minLayerFits = cave.minLayer <= layerIndex
			var relativeDepth = layerIndex / float(maxLayer)
			var minDepthFits = round(relativeDepth * cave.minRelativeDepth) <= layerIndex
			var maxDepthFits = layerIndex <= round(maxLayer * cave.maxRelativeDepth)
			var withinAllowedCount = caveCount.get(cavePackedScene, 0) < cave.maxCount
			if biomeFits and minLayerFits and minDepthFits and maxDepthFits and withinAllowedCount:
				main_node.addCave(rand, cave, layerIndex, minDistanceToCenter)
				availableCaves.erase(cavePackedScene)
				caveCount[cavePackedScene] = caveCount.get(cavePackedScene, 0) + 1
				break
			else:
				cave.queue_free()
		
	for mod in map_mods:
		mod.afterCaveGeneration(main_node, rand)			
			
	if false :
		chain.execute_next()
