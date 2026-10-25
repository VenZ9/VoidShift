# pickup_base.gd
# VOIDSHIFT - Magnetic Pickup Collectible Base
class_name PickupBase
extends Area2D

enum PickupType {
	SCRAP,
	ENERGY
}

@export var pickup_type: PickupType = PickupType.SCRAP
@export var value: float = 1.0
@export var magnet_speed: float = 340.0
@export var magnet_radius: float = 90.0

var target_player: CharacterBody2D
var _bob_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = Constants.LAYER_PICKUP
	collision_mask = Constants.LAYER_PLAYER
	
	body_entered.connect(_on_body_entered)
	_bob_time = randf() * TAU

func set_value(new_val: float) -> void:
	value = new_val

func set_energy_amount(energy: float) -> void:
	value = energy
	pickup_type = PickupType.ENERGY

func _process(delta: float) -> void:
	_bob_time += delta * 4.0
	if sprite:
		sprite.position.y = sin(_bob_time) * 3.0
		
	# Check for player proximity to magnetize
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
			
	if target_player and is_instance_valid(target_player):
		var radius = magnet_radius
		if LootManager.has_upgrade("magnetic_attractor"):
			radius *= 2.0
			
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= radius:
			var dir = (target_player.global_position - global_position).normalized()
			global_position += dir * magnet_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collect(body as Player)

func collect(player: Player) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("pickup", -2.0, randf_range(0.95, 1.15))
		
	if pickup_type == PickupType.SCRAP:
		var scrap_int = int(value)
		SaveManager.add_scrap(scrap_int)
		EventBus.scrap_collected.emit(scrap_int, SaveManager.profile_data["available_scrap"])
	elif pickup_type == PickupType.ENERGY:
		player.current_energy = minf(player.max_energy, player.current_energy + value)
		EventBus.player_energy_changed.emit(player.current_energy, player.max_energy)
		EventBus.energy_cell_collected.emit(value)
		
	queue_free()
