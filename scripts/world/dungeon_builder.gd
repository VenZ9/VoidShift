# dungeon_builder.gd
# VOIDSHIFT - Procedural Roguelite Layout & Template Assembler
class_name DungeonBuilder
extends RefCounted

# Cardinal offsets for grid traversal: [DOWN, RIGHT, UP, LEFT]
const CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i(0, 1),   # SOUTH / DOWN
	Vector2i(1, 0),   # EAST / RIGHT
	Vector2i(0, -1),  # NORTH / UP
	Vector2i(-1, 0)   # WEST / LEFT
]

var sector_seed: int = 0
var max_rooms: int = 8
var room_grid: Dictionary = {} # Vector2i -> Dictionary (room metadata)

func generate_sector(seed_val: int, sector_num: int, target_rooms: int = 8) -> Dictionary:
	sector_seed = seed_val
	max_rooms = target_rooms
	room_grid.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = sector_seed
	
	# Place Start Room at (0, 0)
	room_grid[Vector2i.ZERO] = {
		"type": RoomTemplate.RoomType.START,
		"grid_pos": Vector2i.ZERO,
		"doors": [false, false, false, false],
		"connections": []
	}
	
	var frontier: Array[Vector2i] = [Vector2i.ZERO]
	var room_count = 1
	
	# Grow rooms randomly along grid
	while room_count < max_rooms and frontier.size() > 0:
		var current_cell = frontier[rng.randi() % frontier.size()]
		var available_dirs = []
		
		for dir_idx in range(4):
			var next_cell = current_cell + CARDINAL_DIRS[dir_idx]
			if not room_grid.has(next_cell):
				available_dirs.append(dir_idx)
				
		if available_dirs.is_empty():
			frontier.erase(current_cell)
			continue
			
		var chosen_dir = available_dirs[rng.randi() % available_dirs.size()]
		var new_cell = current_cell + CARDINAL_DIRS[chosen_dir]
		var opposite_dir = (chosen_dir + 2) % 4
		
		# Connect current to new
		room_grid[current_cell]["doors"][chosen_dir] = true
		room_grid[current_cell]["connections"].append(new_cell)
		
		# Create new room
		var r_type = RoomTemplate.RoomType.COMBAT
		if room_count == max_rooms - 1:
			r_type = RoomTemplate.RoomType.BOSS
		elif room_count == int(max_rooms / 2):
			r_type = RoomTemplate.RoomType.TREASURE
		elif room_count == 2:
			r_type = RoomTemplate.RoomType.HAZARD
			
		var new_doors = [false, false, false, false]
		new_doors[opposite_dir] = true
		
		room_grid[new_cell] = {
			"type": r_type,
			"grid_pos": new_cell,
			"doors": new_doors,
			"connections": [current_cell]
		}
		
		frontier.append(new_cell)
		room_count += 1
		
	return room_grid
