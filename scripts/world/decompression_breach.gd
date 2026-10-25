extends Area2D
class_name DecompressionBreach

var _damage_timer := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 118.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_damage_timer = maxf(0.0, _damage_timer - delta)
	for body in get_overlapping_bodies():
		if not body is CharacterBody2D:
			continue
		var pull := (global_position - body.global_position).normalized()
		body.velocity += pull * 190.0 * delta
		if _damage_timer == 0.0:
			var health := body.get_node_or_null("HealthComponent") as HealthComponent
			if health:
				health.take_damage(5.0, -pull * 80.0)
			_damage_timer = 0.8

func _draw() -> void:
	draw_circle(Vector2.ZERO, 112.0, Color(0.9, 0.22, 0.12, 0.13))
	draw_arc(Vector2.ZERO, 110.0, 0.0, TAU, 32, Color("ff6b4f"), 4.0)
	draw_line(Vector2(-16, 0), Vector2(16, 0), Color("fff0b0"), 3.0)
