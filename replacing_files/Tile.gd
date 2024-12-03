extends Tile 

var detonator = null #QLafitte Added
var destroyer = null
var chaos = null

var mod_info = {}

@onready var data_mod = get_node("/root/ModLoader/POModder-Dependency").data_mod
@onready var tile_mods = get_tree().get_nodes_in_group("tile-mods")


func serialize():
	super()
	for mod in tile_mods :
		mod.serialize(self)
	
func deserialize(data: Dictionary):
	super(data)
	
	for mod in tile_mods :
		mod.deserialize(self)
		if mod.set_meta_destructable(self,type) :
			set_meta("destructable", true)
	
func setType(type:String):
	super.setType(type)
	for mod in tile_mods :
		if mod.set_meta_destructable(self,type) :
			set_meta("destructable", true)
			
	if type == "chaos":
		print("debug")
	if ! (type in data_mod.TILE_ID_TO_STRING_MAP.values()):
		return
		
	var baseHealth:float = Data.of("map.tileBaseHealth")
	
	for mod in tile_mods :
		baseHealth = mod.setType(self,type, baseHealth)
		if mod.set_meta_destructable(self,type) :
			set_meta("destructable", true)
			
	var healthMultiplier = hardnessMultiplier
	healthMultiplier *= (pow(Data.of("map.tileHealthMultiplierPerLayer"), layer))
	
	max_health = max(1, round(healthMultiplier * baseHealth))
	health = max_health 
	
	
func customInitResourceSprite(v : Vector2, h_frames = 5 , v_frames = 2, path : String = "res://mods-unpacked/POModder-AllYouCanMine/images/mod_resource_sheet.png"):
	res_sprite.hframes = h_frames
	res_sprite.vframes = v_frames
	res_sprite.texture = load(path)
	res_sprite.set_frame_coords(v)
	Style.init(self)
	
func hit(dir:Vector2, dmg:float):
	for mod in tile_mods :
		mod.hit(self,type,dir,dmg)
	
	if health - dmg <= 0:
		for mod in tile_mods :
			mod.tileBreak(self,type,dir,dmg)
			
	super.hit(dir,dmg)
