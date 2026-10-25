extends Node2D
class_name TestSector

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_SCENE := preload("res://scenes/player/player_camera.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const TOUCH_SCENE := preload("res://scenes/ui/touch_controls.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const ROOM_SCRIPT := preload("res://scripts/world/runtime_room.gd")
const TARGET_ROOMS := 7

var player: Player
var dungeon: DungeonBuilder
var rooms: Dictionary = {}
var seed_value: int = 0
var _end_screen: Control

func _ready() -> void:
	GameManager.change_state(Constants.GameState.EXPLORATION)
	seed_value = int(Time.get_unix_time_from_system())
	_build_dungeon()
	player = PLAYER_SCENE.instantiate() as Player
	player.global_position = rooms[Vector2i.ZERO].global_position + ROOM_SCRIPT.ROOM_SIZE * 0.5
	add_child(player)
	var camera: PlayerCamera = CAMERA_SCENE.instantiate()
	camera.target_node = player
	camera.global_position = player.global_position
	add_child(camera)
	add_child(HUD_SCENE.instantiate())
	add_child(TOUCH_SCENE.instantiate())
	add_child(PAUSE_SCENE.instantiate())
	rooms[Vector2i.ZERO].enter_room(player)
	EventBus.sector_transition_started.emit(GameManager.current_sector)
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.game_state_changed.connect(_on_game_state_changed)

func _build_dungeon() -> void:
	dungeon = DungeonBuilder.new()
	var layout := dungeon.generate_sector(seed_value, GameManager.current_sector, TARGET_ROOMS)
	for grid_pos in layout:
		var data: Dictionary = layout[grid_pos]
		data["seed"] = seed_value
		data["difficulty"] = 1 + int(grid_pos.distance_to(Vector2i.ZERO) / 2.0)
		var room = ROOM_SCRIPT.new()
		room.configure(data, rooms)
		rooms[grid_pos] = room
		add_child(room)
	# Resolve forward references after the complete grid has been created.
	for room in rooms.values():
		room.room_lookup = rooms

func _on_room_entered(room_node: Node2D) -> void:
	if room_node.get_script() == ROOM_SCRIPT and room_node.room_data.get("type") == RoomTemplate.RoomType.BOSS:
		EventBus.ui_notification_requested.emit("FINAL AIRLOCK // AEGIS CORE", Color("ff8a66"))

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	if new_state == Constants.GameState.VICTORY:
		_show_end_screen("STATION SECURED", "Aegis-IV is silent. Run complete.")
	elif new_state == Constants.GameState.GAME_OVER:
		_show_end_screen("RIG SIGNAL LOST", "The station purge continues.")
	else:
		return
	# Gameplay input overlay is disabled once the run has ended.
	var touch_layer := get_node_or_null("TouchControls")
	if touch_layer:
		touch_layer.visible = false
		touch_layer.process_mode = Node.PROCESS_MODE_DISABLED

var _end_layer: CanvasLayer

func _show_end_screen(title: String, subtitle: String) -> void:
	if is_instance_valid(_end_screen):
		return
	if not _end_layer:
		_end_layer = CanvasLayer.new()
		_end_layer.layer = 30
		add_child(_end_layer)
	_end_screen = Control.new()
	_end_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_layer.add_child(_end_screen)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.04, 0.08, 0.9)
	_end_screen.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position = Vector2(-230, -90)
	box.size = Vector2(460, 180)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_end_screen.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("76edff") if GameManager.current_state == Constants.GameState.VICTORY else Color("ff8274"))
	box.add_child(heading)
	var desc := Label.new()
	desc.text = subtitle
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(desc)
	var button := Button.new()
	button.text = "RETURN TO STATION"
	button.custom_minimum_size = Vector2(210, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(GameManager.return_to_main_menu)
	box.add_child(button)
