extends Map



@onready var data_mod = get_node("/root/ModLoader/POModder-Dependency").data_mod
@onready var map_mods = get_tree().get_nodes_in_group("map-mods")
	


func revealTile(coord:Vector2):
	var typeId:int = tileData.get_resource(coord.x, coord.y)
	var invalids := []
	
	modifyTileWhenRevealed(coord,typeId)
	typeId = tileData.get_resource(coord.x, coord.y)
	
	### if tile is marker iron (in order to have exactly one iron per layer
	### used to know the layer numner), remove iron
	if tileRevealedListeners.has(coord):
		for listener in tileRevealedListeners[coord]:
			if is_instance_valid(listener):
				listener.tileRevealed(coord)
			else:
				invalids.append(listener)
		for invalid in invalids:
			tileRevealedListeners.erase(invalid)
	
	
	if typeId == Data.TILE_EMPTY:
		return

	if tiles.has(coord):
		return
	
	var tile = load("res://content/map/tile/Tile.tscn").instantiate()
	var biomeId:int = tileData.get_biome(coord.x, coord.y)
	tile.layer = biomeId
	tile.biome = biomes[tile.layer]
	tile.position = coord * GameWorld.TILE_SIZE
	tile.coord = coord
		
	tile.hardness = tileData.get_hardness(coord.x, coord.y)
	tile.type = data_mod.TILE_ID_TO_STRING_MAP.get(typeId, "dirt")

	match tile.type:
		CONST.IRON:
			tile.richness = Data.ofOr("map.ironrichness", 2)
			revealTileVisually(coord)
		CONST.SAND:
			tile.richness = Data.ofOr("map.cobaltrichness", 2)
			revealTileVisually(coord)
		CONST.WATER:
			tile.richness = Data.ofOr("map.waterrichness", 2.5)
			revealTileVisually(coord)
		_:
			for mod in map_mods:
				mod.revealTileVisually(self, tile, coord)
				
					
	tiles[coord] = tile 
	
	if tilesByType.has(tile.type):
		tilesByType[tile.type].append(tile)
	tile.connect("destroyed", Callable(self, "destroyTile").bind(tile))
	
	tiles_node.add_child(tile)

	# Allow border tiles to fade correctly at edges of the map
	visibleTileCoords[coord] = typeId
	

	
	
func modifyTileWhenRevealed(coord,typeId):
	for mod in map_mods:
		mod.modmodifyTileWhenRevealed(self,coord,typeId)
	
	
func addDrop(drop):
	var should_stop = false
	for mod in map_mods:
		should_stop = should_stop or mod.addDrop(self,drop)
	if should_stop:
		return
	
	if "worldmodifierbigdrops" in Level.loadout.modeConfig.get(CONST.MODE_CONFIG_WORLDMODIFIERS, []) and drop is Drop and \
	drop.global_position.y >= 20 and drop.carriedBy.size() == 0 :
		var count = 4
		if drop.type in data_mod.ALL_DROP_NAMES :
			count = 8
		if drop.type == "relic":
			count = 6
		
		add_child(drop)	
		Style.init(drop)
		for i in count:
			await get_tree().create_timer(0.1).timeout
			if ! is_instance_valid(drop):
				continue
			for child in drop.get_children():
				if "scale" in child:
					if child.name == "CollisionShape2D" and drop.type in ["gadget", "powercore"] and i >2:
						continue
					child.scale = Vector2(1.0 + 0.1*i, 1.1 + 0.1*i)
		return 
		
	if "worldmodifiersmalldrops" in Level.loadout.modeConfig.get(CONST.MODE_CONFIG_WORLDMODIFIERS, []) and("type" in drop) and \
	drop.type in data_mod.ALL_DROP_NAMES and !(drop.global_position.y <= 0 or drop.carriedBy.size()>0 ):
		add_child(drop)	
		Style.init(drop)
		for child in drop.get_children():
			if "scale" in child:
				child.scale = Vector2(0.5 , 0.5)
		return	
	
	add_child(drop)		
	Style.init(drop)
	


func destroyTile(tile, withDropsAndSound := true):
	super(tile, withDropsAndSound)

	for mod in map_mods:
		mod.destroyTile(self, tile, withDropsAndSound)
		
		
func getSceneForTileType(tileType:int) -> PackedScene:
	for mod in map_mods:
		var suggestion = mod.getSceneForTileType(tileType)
		if suggestion != null :
			return suggestion
	
	return super(tileType)
#
	
func init(fromDeserialize := false, defaultState := true):
	super(fromDeserialize,defaultState)
	
	for mod in map_mods:
		mod.init(self, fromDeserialize, defaultState)
	
	

func generateCaves(minDistanceToCenter := 10):
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
		if shouldGenerateDrillbertCave():
			cavePackeScenes.insert(0, preload("res://content/caves/drillicave/DrillbertCave.tscn"))
	
	
	for mod in map_mods:
		mod.beforeCaveGeneration(self, cavePackeScenes, minDistanceToCenter)
		
			
	var availableCaves:Array
	var caveCount := {}
	var maxLayer = startingIronCountByLayer.size()
	for layerIndex in maxLayer:
		if availableCaves.is_empty():
			availableCaves = cavePackeScenes.duplicate()
		for cavePackedScene in availableCaves:
			var cave = cavePackedScene.instantiate() # yeah this is shit, but probably not noticable
			var biomeFits = cave.biome == "" or biomes[layerIndex] == cave.biome 
			var minLayerFits = cave.minLayer <= layerIndex
			var relativeDepth = layerIndex / float(maxLayer)
			var minDepthFits = round(relativeDepth * cave.minRelativeDepth) <= layerIndex
			var maxDepthFits = layerIndex <= round(maxLayer * cave.maxRelativeDepth)
			var withinAllowedCount = caveCount.get(cavePackedScene, 0) < cave.maxCount
			if biomeFits and minLayerFits and minDepthFits and maxDepthFits and withinAllowedCount:
				addCave(rand, cave, layerIndex, minDistanceToCenter)
				availableCaves.erase(cavePackedScene)
				caveCount[cavePackedScene] = caveCount.get(cavePackedScene, 0) + 1
				break
			else:
				cave.queue_free()

	for mod in map_mods:
		mod.afterCaveGeneration(self)			
			
			
func addForcedCave(rand, cave, biomeIndex, minDistanceToCenter, accept_higher_layer = true):
	cave.updateUsedTileCoords()

	# try for a few times to find a suitable spot for the cave
	for _i in 150:
		var cells = tileData.get_biome_cells_by_index(biomeIndex)
		if cells.size() < cave.tileCoords.size():
			accept_higher_layer = true
			break
			
		var cell = cells[rand.randi() % cells.size()]
		if abs(cell.x) < minDistanceToCenter:
			continue
		
		var is_area_free = true
		for c in cave.tileCoords:
			var absCoord = Vector2(cell) + c
			is_area_free = is_area_free and not (tileData.get_resourcev(absCoord) in [data_mod.TILE_BAD_RELIC ,  Data.TILE_EMPTY, data_mod.TILE_SECRET_ROOM])
		if not is_area_free:
			continue
		
		addLandmark(cell, cave)
		for c in cave.tileCoords:
			var absCoord = Vector2(cell) + c
			tileData.clear_resource(absCoord)
		return
		
	if !accept_higher_layer:
		var cells = tileData.get_biome_cells_by_index(biomeIndex)
		var cell
		var can_spawn
		for _i in 30 :
			cell = cells[rand.randi() % cells.size()]
			can_spawn = true
			for c in cave.tileCoords:
				var absCoord = cell + c
				can_spawn = can_spawn and not (tileData.get_resourcev(absCoord) in [14, 15,-1])
			
			if can_spawn :
				break
		if can_spawn :
			for c in cave.tileCoords:
				var absCoord = Vector2(cell) + c
				tileData.clear_resource(absCoord)
			addLandmark(cell, cave)
			return
	
	for _i in 50:
		var cells = tileData.get_biome_cells_by_index(biomeIndex-1)
		if cells.size() < cave.tileCoords.size():
			return
		
		var cell = cells[rand.randi() % cells.size()]
		if abs(cell.x) < minDistanceToCenter:
			continue
		
		if not tileData.is_area_free(cell, cave.tileCoords):
			continue
		
		addLandmark(cell, cave)
		for c in cave.tileCoords:
			var absCoord = Vector2(cell) + c
			tileData.clear_resource(absCoord)
		return
		
		
func addCaveStartAndDirection(rand, cave, start, direction : Vector2):
	cave.updateUsedTileCoords()
	var maxLayer = startingIronCountByLayer.size()
	var max_y = 0
	for i in range(1000):
		var pos = Vector2(randi_range(-15,15),max_y+5)
		if not( $MapData.get_resourcev(pos) in [16, 17, 19]) and $MapData.get_biomev(pos) != -1:
			max_y +=2
			
	var cell
	var can_spawn = false
	var spawn_tries = 0
	while !can_spawn:
		cell = start
		
		# Look for a cell to start building the cave
		var k = 0
		while cell == start :
			cell = find_in_direction(start + (-1)**k * k * Vector2(direction.y , direction.x),direction,floor(max_y*1.5))
			k += 1

		if tileData.get_resourcev(cell + Vector2.DOWN) != 19:
			spawn_tries += 1
			start = start + (-1)**spawn_tries * spawn_tries * Vector2(direction.y , direction.x)
			continue
			
		can_spawn = true
		for c in cave.tileCoords:
			var absCoord = cell + c
			can_spawn = can_spawn and not (tileData.get_resourcev(absCoord) in [14, 15,-1])
		
		spawn_tries += 1
		start = start + (-1)**spawn_tries * spawn_tries * Vector2(direction.y , direction.x)
	for c in cave.tileCoords:
		var absCoord = Vector2(cell) + c
		tileData.clear_resource(absCoord)
	addLandmark(cell, cave)
	return
	
func spawn_glass():
	var possible_spawn_ranges = [[Vector2.LEFT, 0.48, 0.62] , 
		[Vector2.LEFT, 0.68, 0.82] ,
		[Vector2.LEFT, 0.88, 1.0] ,
		[Vector2.RIGHT, 0.45, 0.62] ,
		[Vector2.RIGHT, 0.68, 0.82] ,
		[Vector2.RIGHT, 0.88, 1.0] ,]
	possible_spawn_ranges.shuffle() 
	var chosen_positions = possible_spawn_ranges.slice(0,4)
	var maxLayer = startingIronCountByLayer.size()
	var max_y = 0
	for i in range(1000):
		var pos = Vector2(randi_range(-15,15),max_y+5)
		if not( $MapData.get_resourcev(pos) in [16, 17, 19]) and $MapData.get_biomev(pos) != -1:
			max_y +=2
			
	for c in chosen_positions:
		var direction = c[0]
		var start = Vector2(0,floor(max_y*randf_range(c[1],c[2]) ))
		var cell = start
		var k = 0
		while cell == start :
			direction *= -1
			cell = find_in_direction(start + k*Vector2.UP,direction)
			k += 1
		tileData.set_resourcev(cell, data_mod.TILE_GLASS)

func find_in_direction(start,direction,max_distance_from_start = 30):
	var moved = direction
	var last_available_position = start
	# Setting depth and then checking all tiles to the left / right to see where the glass can be placed
	while abs(moved.x)+abs(moved.y) < max_distance_from_start:
		if tileData.get_resourcev(start + moved ) == 10:
			last_available_position = start + moved
		moved += direction
		
	return last_available_position

func find_wall_in_direction(start,direction,max_distance_from_start = 100):
	var can_spawn = false
	var last_available_position
	while not can_spawn:
		var moved = direction
		var last_type = 19
		last_available_position = start
		# Setting depth and then checking all tiles to the left / right to see where the glass can be placed
		while abs(moved.x)+abs(moved.y) < max_distance_from_start:
			if tileData.get_resourcev(start + moved ) == 19 and not( last_type in [16, 17, 19]):
				last_available_position = start + moved
			last_type = tileData.get_resourcev(start + moved )
			moved += direction
		
		can_spawn = true
		for height in range(-3,4):
			for depth in range(1,5):
				can_spawn = can_spawn and tileData.get_resourcev(last_available_position) in [-1,19]
		start += Vector2.UP
		
	return last_available_position
