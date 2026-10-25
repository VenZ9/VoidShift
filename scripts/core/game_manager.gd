# game_manager.gd
# VOIDSHIFT - Master Game State, Run Flow & Input Action Configuration
extends Node

var current_state: int = Constants.GameState.TITLE
var current_sector: int = 1
var run_scrap_collected: int = 0
var run_enemies_defeated: int = 0
var run_rooms_cleared: int = 0
var run_time: float = 0.0
var is_run_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_default_input_actions()
	_connect_events()

func _process(delta: float) -> void:
	if is_run_active and current_state != Constants.GameState.PAUSED:
		run_time += delta
	
	# Global pause trigger check
	if Input.is_action_just_pressed("pause") and not get_tree().paused:
		toggle_pause()
	
	# Gravity shift input: keyboard. Touch buttons route through the same event bus.
	if not get_tree().paused and is_run_active and current_state != Constants.GameState.GAME_OVER:
		if Input.is_action_just_pressed("shift_cw"):
			EventBus.gravity_shift_requested.emit(1)
		elif Input.is_action_just_pressed("shift_ccw"):
			EventBus.gravity_shift_requested.emit(-1)
		elif Input.is_action_just_pressed("shift_invert"):
			EventBus.gravity_shift_requested.emit(2)

func _connect_events() -> void:
	EventBus.enemy_died.connect(func(_enemy, _pos): run_enemies_defeated += 1)
	EventBus.scrap_collected.connect(func(amount, _total): run_scrap_collected += amount)
	EventBus.room_cleared.connect(func(_room): run_rooms_cleared += 1)
	EventBus.player_died.connect(_on_player_died)

func _setup_default_input_actions() -> void:
	# Programmatic guarantee for all required action bindings
	var action_keys = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"shift_cw": [KEY_E],
		"shift_ccw": [KEY_Q],
		"shift_invert": [KEY_R],
		"fire": [KEY_SPACE],
		"dash": [KEY_SHIFT],
		"interact": [KEY_F, KEY_ENTER],
		"pause": [KEY_ESCAPE, KEY_P]
	}
	
	for action in action_keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key_code in action_keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key_code
			# Only add if not already present
			var already_has = false
			for existing in InputMap.action_get_events(action):
				if existing is InputEventKey and existing.physical_keycode == key_code:
					already_has = true
					break
			if not already_has:
				InputMap.action_add_event(action, event)
			# Movement actions are driven by the analog virtual joystick as well; a
			# default deadzone (0.5) would rescale/swallow joystick strengths.
			InputMap.action_set_deadzone(action, 0.0 if action.begins_with("move_") else 0.2)
				
	# Add mouse button left to fire action
	if InputMap.has_action("fire"):
		var has_mb = false
		for ev in InputMap.action_get_events("fire"):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				has_mb = true
				break
		if not has_mb:
			var mb = InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			InputMap.action_add_event("fire", mb)

func change_state(new_state: int) -> void:
	if current_state == new_state:
		return
	var old_state = current_state
	current_state = new_state
	EventBus.game_state_changed.emit(new_state, old_state)

func start_new_run() -> void:
	run_scrap_collected = 0
	run_enemies_defeated = 0
	run_rooms_cleared = 0
	run_time = 0.0
	current_sector = 1
	is_run_active = true
	get_tree().paused = false
	change_state(Constants.GameState.EXPLORATION)
	GravityManager.reset_gravity()
	LootManager.reset_run_upgrades()
	# Install persistent upgrades purchased in the Engineering Bay into this run.
	for upgrade_id in SaveManager.profile_data.get("unlocked_upgrades", []):
		if LootManager.UPGRADES.has(upgrade_id):
			LootManager.apply_upgrade(upgrade_id)
	get_tree().change_scene_to_file("res://scenes/world/test_sector.tscn")

var _state_before_pause: int = Constants.GameState.TITLE

func toggle_pause() -> void:
	var protected := [
		Constants.GameState.TITLE,
		Constants.GameState.GAME_OVER,
		Constants.GameState.VICTORY
	]
	if current_state in protected:
		return
	set_paused(not get_tree().paused)

func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		if current_state != Constants.GameState.PAUSED:
			_state_before_pause = current_state
		change_state(Constants.GameState.PAUSED)
	else:
		# Restore the pre-pause gameplay state instead of forcing EXPLORATION.
		var restored := _state_before_pause
		if restored in [Constants.GameState.PAUSED, Constants.GameState.TITLE, Constants.GameState.GAME_OVER, Constants.GameState.VICTORY]:
			restored = Constants.GameState.EXPLORATION
		change_state(restored)
	EventBus.game_paused.emit(paused)

func return_to_main_menu() -> void:
	is_run_active = false
	get_tree().paused = false
	change_state(Constants.GameState.TITLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_player_died() -> void:
	is_run_active = false
	change_state(Constants.GameState.GAME_OVER)
	SaveManager.record_run_completion(false, current_sector)
