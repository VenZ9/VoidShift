extends Area2D
class_name GravityRail

var _reward_cooldown := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(430, 34)
	shape.shape = rect
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_reward_cooldown = maxf(0.0, _reward_cooldown - delta)
	var axis := Vector2(-GravityManager.gravity_vector.y, GravityManager.gravity_vector.x)
	if axis.x < 0.0:
		axis = -axis
	for body in get_overlapping_bodies():
		if body is Player:
			var player := body as Player
			var speed_along: float = player.velocity.dot(axis)
			if absf(speed_along) > 90.0:
				player.velocity += axis * signf(speed_along) * 220.0 * delta
				if _reward_cooldown == 0.0:
					player.current_energy = minf(player.max_energy, player.current_energy + 5.0)
					EventBus.player_energy_changed.emit(player.current_energy, player.max_energy)
					_reward_cooldown = 0.65

func _draw() -> void:
	draw_rect(Rect2(Vector2(-210, -12), Vector2(420, 24)), Color("173a50"), true)
	draw_rect(Rect2(Vector2(-210, -12), Vector2(420, 24)), Color("24d5ef"), false, 2.0)
	for x in range(-180, 181, 60):
		draw_line(Vector2(x, -8), Vector2(x + 20, 8), Color("74f4ff"), 3.0)
