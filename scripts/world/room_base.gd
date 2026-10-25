# room_base.gd
# VOIDSHIFT - Base Modular Room Controller for Roguelite Assembly
class_name RoomBase
extends Node2D

enum RoomState {
	UNEXPLORED,
	ACTIVE,
	CLEARED
}

@export var room_id: String = "room_01"
@export var is_cleared: bool = false
@export var room_dimensions: Vector2 = Vector2(960, 540)

var current_state: RoomState = RoomState.UNEXPLORED
var enemies_remaining: int = 0

var enemies_container: Node2D
var doors_container: Node2D
var triggers_container: Node2D

func _ready() -> void:
	add_to_group("rooms")
	enemies_container = get_node_or_null("Enemies") as Node2D
	doors_container = get_node_or_null("Doors") as Node2D
	triggers_container = get_node_or_null("Triggers") as Node2D
	_initialize_room()

func _initialize_room() -> void:
	if enemies_container:
		for child in enemies_container.get_children():
			if child is EnemyBase:
				enemies_remaining += 1
				
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)

func enter_room(player: Player) -> void:
	if current_state == RoomState.UNEXPLORED:
		current_state = RoomState.ACTIVE
		EventBus.room_entered.emit(self)
		
		if enemies_remaining > 0:
			_lock_doors(true)
		else:
			complete_room()

func _on_enemy_died(enemy: Node2D, _pos: Vector2) -> void:
	if enemies_container and (enemy.get_parent() == enemies_container or enemies_container.is_ancestor_of(enemy)):
		enemies_remaining = max(0, enemies_remaining - 1)
		if enemies_remaining <= 0 and current_state == RoomState.ACTIVE:
			complete_room()

func complete_room() -> void:
	current_state = RoomState.CLEARED
	is_cleared = true
	_lock_doors(false)
	EventBus.room_cleared.emit(self)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("door_open", -2.0, 1.2)

func _lock_doors(locked: bool) -> void:
	if not doors_container:
		return
	for door in doors_container.get_children():
		if door.has_method("set_locked"):
			door.set_locked(locked)
