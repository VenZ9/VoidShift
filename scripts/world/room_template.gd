# room_template.gd
# VOIDSHIFT - Roguelite Room Template Data Resource
class_name RoomTemplate
extends Resource

enum RoomType {
	START,
	COMBAT,
	HAZARD,
	TREASURE,
	SHOP,
	BOSS
}

@export var template_id: String = "room_standard"
@export var room_type: RoomType = RoomType.COMBAT
@export var difficulty_tier: int = 1
@export var room_scene: PackedScene

# Door connection availability
@export var door_north: bool = true
@export var door_south: bool = true
@export var door_east: bool = true
@export var door_west: bool = true

# Allowed gravity directions in this room (some specialized rooms may restrict/force specific vectors)
@export var allowed_gravity: Array[int] = [0, 1, 2, 3]

func has_door(direction_index: int) -> bool:
	match direction_index:
		0: return door_south # DOWN
		1: return door_east  # RIGHT
		2: return door_north # UP
		3: return door_west  # LEFT
	return false
