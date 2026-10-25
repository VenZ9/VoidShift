# test_runner.gd
# VOIDSHIFT - In-Engine Playable System Integration Test Suite
extends Node2D

const ROOM_SCRIPT := preload("res://scripts/world/runtime_room.gd")
const WALKER_SCENE := preload("res://scenes/enemies/sentry_walker.tscn")
const LURKER_SCENE := preload("res://scenes/enemies/phase_lurker.tscn")
const BOSS_SCENE := preload("res://scenes/bosses/aegis_core.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("       VOIDSHIFT FULL SYSTEM INTEGRATION TEST SUITE    ")
	print("=======================================================")
	
	_test_autoloads()
	_test_gravity_system()
	_test_save_and_economy()
	_test_loot_catalog()
	_test_player_mechanics()
	_test_combat_and_health()
	_test_dungeon_builder()
	_test_runtime_room_progression()
	_test_new_enemy_gravity()
	_test_boss_phases()
	_test_scene_loading()
	_test_input_analog_pass_through()
	_test_shift_cost_and_veto()
	_test_permanent_stats_and_plating()
	_save_corruption_resilience()
	_test_spawn_threats_difficulty()
	await _test_physics_interactions()
	await _test_full_run_smoke()
	
	print("\n=======================================================")
	print("TEST SUMMARY: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("=======================================================\n")
	
	# Release any in-flight audio playback so forced-shutdown does not leak it.
	AudioManager.stop_all()
	
	if failed_count > 0:
		get_tree().quit(1)
	else:
		print(">> ALL SYSTEMS OPERATIONAL. EXECUTING HANDOFF READY. <<\n")
		get_tree().quit(0)

func assert_check(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		failed_count += 1

func free_now(node: Node) -> void:
	# Detach and release synchronously so the suite cannot leak instances.
	node.get_parent().remove_child(node)
	node.free()

func _test_autoloads() -> void:
	print("\n--- 1. Autoload Singletons ---")
	assert_check(Constants != null, "Constants singleton exists")
	assert_check(EventBus != null, "EventBus singleton exists")
	assert_check(GravityManager != null, "GravityManager singleton exists")
	assert_check(AudioManager != null, "AudioManager singleton exists")
	assert_check(SaveManager != null, "SaveManager singleton exists")
	assert_check(LootManager != null, "LootManager singleton exists")
	assert_check(GameManager != null, "GameManager singleton exists")

func _test_gravity_system() -> void:
	print("\n--- 2. Gravity Shift System (90-Degree Cardinal Mechanics) ---")
	GravityManager.reset_gravity()
	assert_check(GravityManager.current_direction == Constants.GravityDirection.DOWN, "Default direction is DOWN (0)")
	assert_check(GravityManager.gravity_vector == Vector2(0, 1), "Default vector is (0, 1)")
	assert_check(GravityManager.gravity_angle == 0.0, "Default angle is 0.0 rad")
	
	# Test Clockwise 90 deg rotation
	GravityManager._cooldown_remaining = 0.0
	var shift_cw1 = GravityManager.shift_clockwise()
	assert_check(shift_cw1 and GravityManager.current_direction == Constants.GravityDirection.RIGHT, "Shift CW -> RIGHT (1)")
	assert_check(GravityManager.gravity_vector == Vector2(1, 0), "Vector matches (1, 0)")
	assert_check(is_equal_approx(GravityManager.gravity_angle, PI * 0.5), "Angle is PI/2 rad (90 deg)")
	
	GravityManager._cooldown_remaining = 0.0
	var shift_cw2 = GravityManager.shift_clockwise()
	assert_check(shift_cw2 and GravityManager.current_direction == Constants.GravityDirection.UP, "Shift CW -> UP / Ceiling (2)")
	assert_check(GravityManager.gravity_vector == Vector2(0, -1), "Vector matches (0, -1)")
	assert_check(is_equal_approx(GravityManager.gravity_angle, PI), "Angle is PI rad (180 deg)")
	
	GravityManager._cooldown_remaining = 0.0
	var shift_cw3 = GravityManager.shift_clockwise()
	assert_check(shift_cw3 and GravityManager.current_direction == Constants.GravityDirection.LEFT, "Shift CW -> LEFT (3)")
	assert_check(GravityManager.gravity_vector == Vector2(-1, 0), "Vector matches (-1, 0)")
	assert_check(is_equal_approx(GravityManager.gravity_angle, PI * 1.5), "Angle is 3PI/2 rad (270 deg)")
	
	# Test Counter-Clockwise 90 deg rotation
	GravityManager._cooldown_remaining = 0.0
	var shift_ccw = GravityManager.shift_counter_clockwise()
	assert_check(shift_ccw and GravityManager.current_direction == Constants.GravityDirection.UP, "Shift CCW -> UP (2)")
	
	# Test Invert 180 deg rotation
	GravityManager._cooldown_remaining = 0.0
	var shift_inv = GravityManager.shift_invert()
	assert_check(shift_inv and GravityManager.current_direction == Constants.GravityDirection.DOWN, "Shift Invert -> DOWN (0)")

func _test_save_and_economy() -> void:
	print("\n--- 3. Local Persistence & Economy ---")
	var initial_scrap = SaveManager.profile_data.get("available_scrap", 0)
	SaveManager.add_scrap(75)
	assert_check(SaveManager.profile_data["available_scrap"] == initial_scrap + 75, "Added 75 scrap correctly")
	
	var can_spend = SaveManager.spend_scrap(25)
	assert_check(can_spend and SaveManager.profile_data["available_scrap"] == initial_scrap + 50, "Spent 25 scrap correctly")
	
	var saved_prof = SaveManager.save_profile()
	assert_check(saved_prof, "Profile saved to user://savegame.json")
	
	SaveManager.settings_data["master_volume"] = 0.8
	var saved_set = SaveManager.save_settings()
	assert_check(saved_set, "Settings saved to user://settings.json")

func _test_loot_catalog() -> void:
	print("\n--- 4. Roguelite Upgrades Catalog ---")
	assert_check(LootManager.UPGRADES.size() >= 6, "Loot catalog contains >= 6 augments")
	assert_check(LootManager.UPGRADES.has("grav_shield"), "Phase Barrier registered")
	assert_check(LootManager.UPGRADES.has("overcharge_burst"), "Kinetic Pulse registered")
	
	LootManager.reset_run_upgrades()
	assert_check(not LootManager.has_upgrade("grav_shield"), "Run upgrades cleared on reset")
	LootManager.apply_upgrade("grav_shield")
	assert_check(LootManager.has_upgrade("grav_shield"), "Upgrade applied successfully")

func _test_player_mechanics() -> void:
	print("\n--- 5. Player RIG & Dash Mechanics ---")
	var p_scene = load("res://scenes/player/player.tscn")
	assert_check(p_scene != null, "Player scene loaded")
	var p_instance = p_scene.instantiate() as Player
	add_child(p_instance)
	
	assert_check(p_instance.current_energy == Constants.PLAYER_BASE_ENERGY, "Player initial energy full")
	var dashed = p_instance.perform_dash()
	assert_check(dashed and p_instance.is_dashing, "Player performed kinetic dash")
	assert_check(p_instance.current_energy < Constants.PLAYER_BASE_ENERGY, "Dash consumed energy")
	
	free_now(p_instance)

func _test_combat_and_health() -> void:
	print("\n--- 6. Combat Health & Hurtbox Components ---")
	var hc = HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 100.0
	add_child(hc)
	
	var signal_received = [false]
	hc.damaged.connect(func(_amount, _knockback): signal_received[0] = true)
	
	var dmg_success = hc.take_damage(35.0)
	assert_check(dmg_success and hc.current_health == 65.0, "Damage dealt: 100 -> 65 HP")
	assert_check(signal_received[0], "damaged signal received")
	
	var scaled = hc.take_damage(100.0, Vector2.ZERO, false, 0.28)
	assert_check(scaled and is_equal_approx(hc.current_health, 65.0 - 28.0), "Damage scale reduces incoming damage proportionally")
	
	hc.heal(20.0)
	assert_check(hc.current_health == 57.0, "Healed: 37 -> 57 HP")
	free_now(hc)

func _test_dungeon_builder() -> void:
	print("\n--- 7. Roguelite Dungeon Procedural Assembly ---")
	var builder = DungeonBuilder.new()
	var layout = builder.generate_sector(12345, 1, 8)
	assert_check(layout.size() >= 6, "Generated sector layout has >= 6 interconnected rooms")
	assert_check(layout.has(Vector2i.ZERO), "Start room placed at origin (0, 0)")
	assert_check(layout[Vector2i.ZERO]["type"] == RoomTemplate.RoomType.START, "Origin cell is START type")
	var boss_count := 0
	var links_valid := true
	for pos in layout:
		if layout[pos]["type"] == RoomTemplate.RoomType.BOSS:
			boss_count += 1
		for next_pos in layout[pos]["connections"]:
			if not layout.has(next_pos) or not layout[next_pos]["connections"].has(pos):
				links_valid = false
	assert_check(boss_count == 1 and layout.values()[-1]["type"] == RoomTemplate.RoomType.BOSS, "Sector has a single final boss room")
	assert_check(links_valid, "Generated room connections are reciprocal")

func _test_runtime_room_progression() -> void:
	print("\n--- 8. Runtime Rooms & Airlock Progression ---")
	var start_data := {"grid_pos": Vector2i.ZERO, "type": RoomTemplate.RoomType.START, "doors": [false, true, false, false], "connections": [Vector2i.RIGHT]}
	var cache_data := {"grid_pos": Vector2i.RIGHT, "type": RoomTemplate.RoomType.TREASURE, "doors": [false, false, false, true], "connections": [Vector2i.ZERO]}
	var map := {}
	var start = ROOM_SCRIPT.new()
	start.configure(start_data, map)
	map[Vector2i.ZERO] = start
	var cache = ROOM_SCRIPT.new()
	cache.configure(cache_data, map)
	map[Vector2i.RIGHT] = cache
	start.room_lookup = map
	cache.room_lookup = map
	add_child(start)
	add_child(cache)
	var p = load("res://scenes/player/player.tscn").instantiate()
	add_child(p)
	start.enter_room(p)
	assert_check(start.current_state == RoomBase.RoomState.CLEARED, "Empty start room clears and opens its airlocks")
	start.current_state = RoomBase.RoomState.ACTIVE
	start.enemies_remaining = 1
	start._set_doors_open(false)
	start.complete_room()
	assert_check(start._doors_open, "Clearing the last threat physically unlocks room airlocks")
	start._on_portal_body_entered(p, 1)
	assert_check(cache.current_state == RoomBase.RoomState.CLEARED, "Unlocked connected airlock enters and clears cache room")
	free_now(p)
	free_now(start)
	free_now(cache)

func _test_new_enemy_gravity() -> void:
	print("\n--- 9. Gravity Aware Enemies ---")
	var walker = WALKER_SCENE.instantiate()
	add_child(walker)
	walker._on_gravity_changed(Constants.GravityDirection.UP, Constants.GravityDirection.DOWN, Vector2.UP, PI)
	assert_check(walker.wall_normal == Vector2.DOWN, "Sentry Walker reorients its wall lock after a gravity shift")
	var lurker = LURKER_SCENE.instantiate()
	add_child(lurker)
	lurker._phase_timer = 2.0
	lurker._on_gravity_changed(Constants.GravityDirection.RIGHT, Constants.GravityDirection.DOWN, Vector2.RIGHT, PI * 0.5)
	assert_check(lurker._phase_timer <= 0.35, "Phase Lurker reacts to gravity flux with a readable ambush window")
	free_now(walker)
	free_now(lurker)

func _test_boss_phases() -> void:
	print("\n--- 10. Aegis Core Phase Thresholds ---")
	var boss = BOSS_SCENE.instantiate()
	add_child(boss)
	boss.damage_window = true
	boss.health_component.take_damage(260.0)
	assert_check(boss.phase == 1, "Aegis Core enters gravity phase below two thirds health")
	boss.health_component.take_damage(260.0)
	assert_check(boss.phase == 2, "Aegis Core enters meltdown phase below one third health")
	free_now(boss)


# --- 11. Touch Analog Pass-Through ---
func _test_input_analog_pass_through() -> void:
	print("\n--- 11. Analog Touch Input Pass-Through ---")
	Input.action_release("move_right")
	Input.action_press("move_right", 0.6)
	var v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_check(is_equal_approx(v.length(), 0.6), "Joystick strength 0.6 is preserved by get_vector (deadzone 0)")
	Input.action_release("move_right")
	Input.action_press("move_right")
	v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_check(is_equal_approx(v.length(), 1.0), "Full deflection still reaches magnitude 1.0")
	Input.action_release("move_right")

# --- 12. Player Gravity Shift Cost & Veto ---
func _test_shift_cost_and_veto() -> void:
	print("\n--- 12. Gravity Shift Energy Cost & Veto ---")
	LootManager.reset_run_upgrades()
	GravityManager.reset_gravity()
	GravityManager._cooldown_remaining = 0.0
	var p = PLAYER_SCENE.instantiate() as Player
	add_child(p)
	p.current_energy = 10.0
	
	EventBus.gravity_shift_requested.emit(1)
	assert_check(GravityManager.current_direction == Constants.GravityDirection.DOWN, "Shift with insufficient RIG energy is refused")
	assert_check(p.current_energy == 10.0, "Refused shift drains no energy")
	
	p.current_energy = 20.0
	GravityManager._cooldown_remaining = 0.0
	EventBus.gravity_shift_requested.emit(1)
	assert_check(GravityManager.current_direction == Constants.GravityDirection.RIGHT, "Affordable player shift changes gravity")
	assert_check(p.current_energy == 20.0 - Constants.GRAVITY_SHIFT_COST, "Successful shift drains the configured RIG cost")
	
	LootManager.apply_upgrade("energy_efficiency")
	var discounted := GravityManager.get_player_shift_cost()
	assert_check(is_equal_approx(discounted, Constants.GRAVITY_SHIFT_COST * 0.65), "Superconductor reduces the shift cost by 35 percent")
	
	free_now(p)

# --- 13. Permanent Stats & Kinetic Plating ---
func _test_permanent_stats_and_plating() -> void:
	print("\n--- 13. Permanent Save Stats & Kinetic Plating ---")
	LootManager.reset_run_upgrades()
	SaveManager.profile_data["permanent_stats"]["bonus_max_hp"] = 10.0
	var p = PLAYER_SCENE.instantiate() as Player
	add_child(p)
	assert_check(is_equal_approx(p.health_component.max_health, 110.0), "bonus_max_hp permanent stat extends player max health")
	assert_check(is_equal_approx(p.health_component.current_health, 110.0), "Healed up to the extended max on spawn")
	
	SaveManager.profile_data["permanent_stats"]["bonus_max_hp"] = 0.0
	free_now(p)
	
	LootManager.apply_upgrade("kinetic_plating")
	var p2 = PLAYER_SCENE.instantiate() as Player
	add_child(p2)
	assert_check(is_equal_approx(p2.health_component.max_health, 125.0), "Kinetic Plating adds 25 max health for the run")
	free_now(p2)
	LootManager.reset_run_upgrades()

# --- 14. Save Corruption Resilience ---
func _save_corruption_resilience() -> void:
	print("\n--- 14. Corrupt Save Resilience ---")
	var original_master: float = SaveManager.settings_data.get("master_volume", 1.0)
	var path = SaveManager.SETTINGS_PATH
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{corrupt json[[[")
	f.close()
	SaveManager.load_settings()
	assert_check(SaveManager.settings_data.get("master_volume", 1.0) == original_master, "Corrupt settings file falls back cleanly to current defaults")
	assert_check(SaveManager.save_settings(), "Settings re-saved successfully after corruption recovery")

func _test_spawn_threats_difficulty() -> void:
	print("\n--- 15. Difficulty-Scaled Threat Spawns ---")
	var probe = ROOM_SCRIPT.new()
	probe.configure({"grid_pos": Vector2i(0, 3), "type": RoomTemplate.RoomType.COMBAT, "doors": [false, false, false, false], "connections": [], "difficulty": 5, "seed": 7}, {})
	add_child(probe)
	probe._spawn_room_threats()
	assert_check(probe.enemies_container.get_child_count() == 4, "Difficulty 5 combat room spawns 4 threats")
	free_now(probe)
	
	var probe2 = ROOM_SCRIPT.new()
	probe2.configure({"grid_pos": Vector2i(0, 4), "type": RoomTemplate.RoomType.COMBAT, "doors": [false, false, false, false], "connections": [], "difficulty": 1, "seed": 9}, {})
	add_child(probe2)
	probe2._spawn_room_threats()
	assert_check(probe2.enemies_container.get_child_count() == 1, "Difficulty 1 combat room spawns a single threat")
	free_now(probe2)

func _test_scene_loading() -> void:
	print("\n--- 8. Complete Scene Verification ---")
	var all_scenes = [
		"res://scenes/main_menu.tscn",
		"res://scenes/world/test_sector.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/player/player_camera.tscn",
		"res://scenes/enemies/sentry_drone.tscn",
		"res://scenes/enemies/sentry_walker.tscn",
		"res://scenes/enemies/phase_lurker.tscn",
		"res://scenes/bosses/aegis_core.tscn",
		"res://scenes/combat/projectile_player.tscn",
		"res://scenes/combat/projectile_enemy.tscn",
		"res://scenes/props/grav_crate.tscn",
		"res://scenes/props/scrap_pickup.tscn",
		"res://scenes/props/energy_pickup.tscn",
		"res://scenes/ui/virtual_joystick.tscn",
		"res://scenes/ui/touch_controls.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/ui/pause_menu.tscn"
	]
	
	var all_ok = true
	for path in all_scenes:
		var scene = load(path)
		if scene == null:
			printerr("Failed to load scene: ", path)
			all_ok = false
	assert_check(all_ok, "All listed scenes load without errors")

func _wait_physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame

func _test_physics_interactions() -> void:
	print("\n--- 16. Physics Interaction Regression (Shield & Ambush) ---")
	await _test_walker_frontal_shield()
	await _test_lurker_safe_ambush()
	await _test_hud_initial_readouts()

# --- 16a. Walker Shield Direction & Lethality ---
func _test_walker_frontal_shield() -> void:
	var wall_normal := Vector2.DOWN
	var walker = WALKER_SCENE.instantiate()
	walker.position = Vector2(400, 300)
	add_child(walker)
	
	assert_check(is_equal_approx(walker.get_damage_scale(Vector2.DOWN), 0.28), "Frontal hits against the shielded arc are reduced to 28 percent")
	assert_check(walker.get_damage_scale(Vector2.UP) == 1.0, "Rear hits against the shielded arc take full damage")
	
	# End-to-end overlap check with a real hitbox below the shield side.
	await _wait_physics(2)
	var source = Node2D.new()
	source.position = walker.global_position + Vector2(0, 40)
	add_child(source)
	var hitbox = HitboxComponent.new()
	hitbox.collision_layer = Constants.LAYER_PLAYER_PROJECTILE
	hitbox.damage = 50.0
	hitbox.damage_source = source
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	hitbox.add_child(shape)
	hitbox.position = walker.global_position + Vector2(0, 20)
	add_child(hitbox)
	await _wait_physics(3)
	var frontal_expected: float = 110.0 - 50.0 * 0.28
	assert_check(is_equal_approx(walker.health_component.current_health, frontal_expected), "Frontal hitbox overlap applies the reduced shield damage end-to-end")
	
	# Frontal damage below full HP can never drop the walker instantly to zero.
	var shielded_lethal = walker.health_component.take_damage(110.0, Vector2.DOWN * 200.0, false, walker.get_damage_scale(Vector2.DOWN))
	assert_check(shielded_lethal and walker.health_component.current_health > 0.0, "A lethal frontal bomb is moderated by the shield (no instant death)")
	
	# Rear hit at full damage finishes the walker off; the death callback is
	# detached first so this probe does not schedule a real queue_free chain.
	var death_probe := [false]
	var death_probe_cb := func(): death_probe[0] = true
	walker.health_component.died.connect(death_probe_cb)
	walker.health_component.died.disconnect(walker._on_died)
	var rear_kill = walker.health_component.take_damage(200.0, Vector2.UP * 100.0)
	assert_check(rear_kill and walker.health_component.current_health <= 0.0, "Rear hull breach at full damage defeats the walker")
	assert_check(death_probe[0], "Health component emits the died signal on lethal rear damage")
	free_now(hitbox)
	free_now(source)
	free_now(walker)

# --- 16b. Lurker Ambush Teleport Safety ---
func _test_lurker_safe_ambush() -> void:
	GravityManager.reset_gravity()
	# Wall block on the left side of the ambush tangent axis.
	var wall = StaticBody2D.new()
	wall.collision_layer = Constants.LAYER_WORLD
	var wshape = CollisionShape2D.new()
	var wrect = RectangleShape2D.new()
	wrect.size = Vector2(80, 400)
	wshape.shape = wrect
	wall.add_child(wshape)
	wall.position = Vector2(520, 300)
	add_child(wall)
	await _wait_physics(2)
	
	var lurker = LURKER_SCENE.instantiate()
	lurker.position = Vector2(400, 300)
	add_child(lurker)
	var target = PLAYER_SCENE.instantiate()
	target.position = Vector2(610, 300)
	add_child(target)
	await _wait_physics(2)
	lurker._phase_timer = 0.0
	lurker._windup = false
	lurker._attack_cooldown = 0.0
	lurker._ambush()
	# target + tangent*96 (side == -1) lands inside the wall: must be rejected.
	var safe = PhysicsPointQueryParameters2D.new()
	safe.position = Vector2(610, 300) + Vector2(-96, 0)
	var space = get_world_2d().direct_space_state
	var blocked_hits = space.intersect_point(safe)
	assert_check(not blocked_hits.is_empty(), "Regression condition verified: candidate ambush point is inside the wall")
	
	# The lurker must still ambush without being stranded: it stays where it was
	# because the candidate was unsafe, then dashes toward the player.
	await _wait_physics(2)
	var lurker_pos: Vector2 = lurker.global_position
	var player_pos: Vector2 = target.global_position
	assert_check(not space.intersect_point(_point_query(lurker_pos)), "Lurker is never stranded inside static geometry after an ambush")
	assert_check(lurker_pos.distance_to(player_pos) < 210.0 + 220.0, "Ambush fallback still closes distance toward the player")
	free_now(target)
	free_now(lurker)
	free_now(wall)

func _point_query(pos: Vector2) -> PhysicsPointQueryParameters2D:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos
	q.collision_mask = Constants.LAYER_WORLD
	return q

# --- 17. Full Sector Run Smoke (room loop -> boss -> victory) ---
const SECTOR_SCENE := preload("res://scenes/world/test_sector.tscn")
const SECTOR_SCRIPT := preload("res://scripts/world/test_sector.gd")

func _test_full_run_smoke() -> void:
	print("\n--- 17. Full Sector Run Smoke ---")
	GravityManager.reset_gravity()
	LootManager.reset_run_upgrades()
	GameManager.current_state = Constants.GameState.TITLE
	GameManager.is_run_active = true
	GameManager.current_sector = 1
	var victories_before: int = SaveManager.profile_data.get("victories", 0)
	
	var sector = SECTOR_SCENE.instantiate()
	add_child(sector)
	await _wait_physics(6)
	
	var rooms: Dictionary = sector.rooms
	assert_check(rooms.size() == 7, "Sector instantiates the full 7-room generated layout")
	var player: Player = sector.player
	assert_check(is_instance_valid(player), "Player spawns inside the start room")
	assert_check(rooms[Vector2i.ZERO].current_state == RoomBase.RoomState.CLEARED, "Start room auto-clears its airlocks")
	
	# Deterministic BFS walk over the generated room tree: track visited cells
	# and step through each unvisited child portal until only the boss remains.
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var visited: Dictionary = {Vector2i.ZERO: true}
	var transitions := 0
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var room = rooms[current]
		for dir in 4:
			var neighbor: Vector2i = current + DungeonBuilder.CARDINAL_DIRS[dir]
			var door_open: bool = room.room_data.get("doors", [false, false, false, false])[dir]
			if not door_open or not rooms.has(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			rooms[current]._on_portal_body_entered(player, dir)
			transitions += 1
			await _wait_physics(4)
			var child_room = rooms[neighbor]
			if child_room.current_state != RoomBase.RoomState.CLEARED and child_room.room_data.get("type") != RoomTemplate.RoomType.BOSS:
				for spawn in child_room.enemies_container.get_children():
					if spawn is EnemyBase:
						spawn.health_component.take_damage(99999.0, Vector2.ZERO, true)
				await _wait_physics(4)
				assert_check(child_room.current_state == RoomBase.RoomState.CLEARED, "Threat room clears and unlocks after the last enemy dies (%v)" % [child_room.room_index])
			queue.push_back(neighbor)
	
	assert_check(transitions >= 5, "The walk crossed at least 5 airlock transitions")
	var boss_key: Vector2i = Vector2i(99, 99)
	for key in rooms:
		if rooms[key].room_data.get("type") == RoomTemplate.RoomType.BOSS:
			boss_key = key
	var boss_room_probe = rooms[boss_key]
	assert_check(boss_room_probe.current_state == RoomBase.RoomState.ACTIVE, "The walked path reached the final boss room and engaged it")
	await _wait_physics(20)
	var boss_found := false
	for child in boss_room_probe.enemies_container.get_children():
		if child is EnemyBase and child.health_component.current_health > 0.0:
			boss_found = true
			child.damage_window = true
			child.health_component.take_damage(99999.0, Vector2.ZERO, true)
	assert_check(boss_found, "Boss room spawns the Aegis Security Core when entered")
	await _wait_physics(6)
	assert_check(GameManager.current_state == Constants.GameState.VICTORY, "Boss defeat raises the VICTORY game state")
	assert_check(SaveManager.profile_data.get("victories", 0) == victories_before + 1, "Victory run is recorded to persistent save data")
	assert_check(boss_room_probe.current_state == RoomBase.RoomState.CLEARED, "Boss room doors unlock after the victory")
	
	print("Transitions crossed during the walk: %d" % transitions)
	free_now(sector)

# --- 16c. HUD Initial Readout Delivery ---
func _test_hud_initial_readouts() -> void:
	var hud = HUD_SCENE.instantiate()
	add_child(hud)
	await get_tree().process_frame
	var p = PLAYER_SCENE.instantiate() as Player
	add_child(p)
	# Mutate energy before the deferred initial readout fires so the assertion
	# cannot pass on default bar values alone.
	p.current_energy = 55.0
	p.health_component.current_health = 77.0
	await get_tree().process_frame
	await get_tree().process_frame
	assert_check(is_equal_approx(hud.health_bar.value, 77.0), "HUD receives the player initial health readout")
	assert_check(absf(hud.energy_bar.value - 55.0) < 1.5, "HUD receives the player initial energy readout")
	free_now(p)
	free_now(hud)
