extends RoomBase
class_name RuntimeRoom

const ROOM_SIZE := Vector2(960, 540)
const ROOM_STEP := Vector2(1040, 620)
const DRONE_SCENE := preload("res://scenes/enemies/sentry_drone.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/sentry_walker.tscn")
const LURKER_SCENE := preload("res://scenes/enemies/phase_lurker.tscn")
const BOSS_SCENE := preload("res://scenes/bosses/aegis_core.tscn")
const RAIL_SCRIPT := preload("res://scripts/world/gravity_rail.gd")
const BREACH_SCRIPT := preload("res://scripts/world/decompression_breach.gd")

var room_data: Dictionary = {}
var room_lookup: Dictionary = {}
var room_index: Vector2i = Vector2i.ZERO
var active_player: Player
var _door_blocks: Array[CollisionShape2D] = []
var _doors_open := false
var _entered_once := false
var _hazards: Array[Area2D] = []

func configure(data: Dictionary, lookup: Dictionary) -> void:
	room_data = data
	room_index = data.get("grid_pos", Vector2i.ZERO)
	room_lookup = lookup
	position = Vector2(room_index) * ROOM_STEP

func _ready() -> void:
	room_dimensions = ROOM_SIZE
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)
	doors_container = Node2D.new()
	doors_container.name = "Doors"
	add_child(doors_container)
	triggers_container = Node2D.new()
	triggers_container.name = "Triggers"
	add_child(triggers_container)
	_build_room()
	enemies_container = get_node("Enemies")
	doors_container = get_node("Doors")
	triggers_container = get_node("Triggers")
	_initialize_room()
	current_state = RoomState.UNEXPLORED

func enter_room(player: Player) -> void:
	active_player = player
	if current_state != RoomState.UNEXPLORED:
		return
	_entered_once = true
	if room_data.get("type", RoomTemplate.RoomType.COMBAT) != RoomTemplate.RoomType.START:
		_spawn_room_threats()
		for enemy in enemies_container.get_children():
			if enemy is EnemyBase:
				enemies_remaining += 1
	super.enter_room(player)
	if enemies_remaining == 0:
		_set_doors_open(true)

func complete_room() -> void:
	super.complete_room()
	_set_doors_open(true)

func _build_room() -> void:
	for dir in range(4):
		_build_edge(dir)
	for dir in range(4):
		if not room_data.get("doors", [false, false, false, false])[dir]:
			continue
		_create_door(dir)
	_add_art_and_hazards()
	queue_redraw()

func _spawn_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Constants.LAYER_WORLD
	body.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PROP
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
	body.add_child(shape)
	add_child(body)

func _build_edge(dir: int) -> void:
	var connected: bool = room_data.get("doors", [false, false, false, false])[dir]
	var mid := ROOM_SIZE.x * 0.5 if dir % 2 == 0 else ROOM_SIZE.y * 0.5
	var span := ROOM_SIZE.x if dir % 2 == 0 else ROOM_SIZE.y
	var wall_center := Vector2(mid, 12) if dir == 2 else (Vector2(mid, ROOM_SIZE.y - 12) if dir == 0 else (Vector2(12, mid) if dir == 3 else Vector2(ROOM_SIZE.x - 12, mid)))
	var thickness := Vector2(ROOM_SIZE.x, 24) if dir % 2 == 0 else Vector2(24, ROOM_SIZE.y)
	if not connected:
		_spawn_wall(wall_center, thickness)
		return
	var half_run := (span - 110.0) * 0.5
	var wall_size := Vector2(half_run, 24) if dir % 2 == 0 else Vector2(24, half_run)
	var offset := half_run * 0.5 + 27.5
	if dir % 2 == 0:
		_spawn_wall(wall_center + Vector2(-offset, 0), wall_size)
		_spawn_wall(wall_center + Vector2(offset, 0), wall_size)
	else:
		_spawn_wall(wall_center + Vector2(0, -offset), wall_size)
		_spawn_wall(wall_center + Vector2(0, offset), wall_size)

func _create_door(dir: int) -> void:
	var portal := Area2D.new()
	portal.name = "Airlock_%d" % dir
	portal.collision_layer = Constants.LAYER_PORTAL
	portal.collision_mask = Constants.LAYER_PLAYER
	portal.set_meta("direction", dir)
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(94, 74)
	area_shape.shape = area_rect
	area_shape.position = _door_position(dir)
	portal.add_child(area_shape)
	portal.body_entered.connect(_on_portal_body_entered.bind(dir))
	doors_container.add_child(portal)
	var block := CollisionShape2D.new()
	var block_rect := RectangleShape2D.new()
	block_rect.size = Vector2(82, 34) if dir % 2 == 0 else Vector2(34, 82)
	block.shape = block_rect
	block.position = _door_position(dir)
	var barrier := StaticBody2D.new()
	barrier.name = "DoorBarrier_%d" % dir
	barrier.collision_layer = Constants.LAYER_WORLD
	barrier.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY
	barrier.add_child(block)
	add_child(barrier)
	_door_blocks.append(block)

func _door_position(dir: int) -> Vector2:
	match dir:
		0: return Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y - 28)
		1: return Vector2(ROOM_SIZE.x - 28, ROOM_SIZE.y * 0.5)
		2: return Vector2(ROOM_SIZE.x * 0.5, 28)
		_: return Vector2(28, ROOM_SIZE.y * 0.5)

func _set_doors_open(open: bool) -> void:
	_doors_open = open
	for shape in _door_blocks:
		shape.set_deferred("disabled", open)
	queue_redraw()

func _on_portal_body_entered(body: Node2D, dir: int) -> void:
	if not body is Player or not _doors_open:
		return
	var next_index: Vector2i = room_index + DungeonBuilder.CARDINAL_DIRS[dir]
	var next_room := room_lookup.get(next_index) as RuntimeRoom
	if next_room == null:
		return
	var arrival_dir := (dir + 2) % 4
	body.global_position = next_room.global_position + next_room._door_position(arrival_dir) + Vector2(DungeonBuilder.CARDINAL_DIRS[dir]) * 72.0
	next_room.enter_room(body)
	EventBus.ui_notification_requested.emit(_room_title(next_room.room_data.get("type", 1)), Color(0.1, 0.9, 1.0))

func _room_title(kind: int) -> String:
	match kind:
		RoomTemplate.RoomType.START: return "AIRLOCK // SAFE ROOM"
		RoomTemplate.RoomType.TREASURE: return "SALVAGE CACHE"
		RoomTemplate.RoomType.BOSS: return "AEGIS SECURITY CORE"
		_: return "THREATS DETECTED // CLEAR THE ROOM"

func _spawn_room_threats() -> void:
	var kind: int = room_data.get("type", RoomTemplate.RoomType.COMBAT)
	if kind == RoomTemplate.RoomType.BOSS:
		var boss = BOSS_SCENE.instantiate()
		boss.position = ROOM_SIZE * 0.5
		enemies_container.add_child(boss)
		return
	if kind == RoomTemplate.RoomType.TREASURE:
		_set_doors_open(true)
		return
	var seed_value: int = int(room_data.get("seed", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + room_index.x * 87 + room_index.y * 113
	var amount := clampi(1 + int(float(room_data.get("difficulty", 1)) * 0.75), 1, 4)
	for i in amount:
		var scene: PackedScene = DRONE_SCENE if i == 0 else (WALKER_SCENE if rng.randf() < 0.55 else LURKER_SCENE)
		var enemy = scene.instantiate()
		enemy.position = Vector2(270 + rng.randi_range(0, 420), 150 + rng.randi_range(0, 240))
		enemies_container.add_child(enemy)

func _add_art_and_hazards() -> void:
	var rail := RAIL_SCRIPT.new()
	rail.position = Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y * 0.5)
	add_child(rail)
	if int(room_data.get("type", 0)) == RoomTemplate.RoomType.HAZARD:
		var breach := BREACH_SCRIPT.new()
		breach.position = Vector2(ROOM_SIZE.x - 140, ROOM_SIZE.y * 0.5)
		add_child(breach)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color("101a2a"), true)
	for x in range(32, int(ROOM_SIZE.x), 64):
		draw_line(Vector2(x, 24), Vector2(x, ROOM_SIZE.y - 24), Color(0.10, 0.19, 0.28, 0.55), 1.0)
	for y in range(32, int(ROOM_SIZE.y), 64):
		draw_line(Vector2(24, y), Vector2(ROOM_SIZE.x - 24, y), Color(0.10, 0.19, 0.28, 0.55), 1.0)
	draw_rect(Rect2(Vector2(22, 22), ROOM_SIZE - Vector2(44, 44)), Color("4c687a"), false, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(44, 56), _room_title(room_data.get("type", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8deeff"))
	for dir in range(4):
		if room_data.get("doors", [false, false, false, false])[dir]:
			var p := _door_position(dir)
			draw_rect(Rect2(p - Vector2(32, 12), Vector2(64, 24)) if dir % 2 == 0 else Rect2(p - Vector2(12, 32), Vector2(24, 64)), Color("16d6e8" if _doors_open else "ed9d42"), false, 3.0)

func _exit_tree() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)
