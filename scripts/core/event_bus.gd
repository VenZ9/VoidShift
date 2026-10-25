# event_bus.gd
# VOIDSHIFT - Central Decoupled Event Bus Singleton
extends Node

# --- Gravity Shift Signals ---
signal gravity_changed(new_dir: int, old_dir: int, gravity_vector: Vector2, angle_rad: float)
signal gravity_shift_requested(direction_step: int) # +1 for CW, -1 for CCW, 2 for 180

# --- Player Signals ---
signal player_spawned(player_node: CharacterBody2D)
signal player_health_changed(current_hp: float, max_hp: float)
signal player_energy_changed(current_energy: float, max_energy: float)
signal player_died()
signal player_dashed(direction: Vector2)
signal player_fired_weapon(spawn_pos: Vector2, direction: Vector2)

# --- Combat & Enemy Signals ---
signal enemy_spawned(enemy_node: Node2D)
signal enemy_damaged(enemy_node: Node2D, damage_taken: float, current_hp: float)
signal enemy_died(enemy_node: Node2D, death_pos: Vector2)
signal camera_shake_requested(intensity: float, duration: float)

# --- Room & Sector Progression Signals ---
signal room_entered(room_node: Node2D)
signal room_cleared(room_node: Node2D)
signal sector_transition_started(sector_id: int)
signal sector_completed(sector_id: int)

# --- Loot & Economy Signals ---
signal scrap_collected(amount: int, total_scrap: int)
signal energy_cell_collected(energy_restored: float)
signal upgrade_applied(upgrade_id: String, metadata: Dictionary)

# --- Game Flow & UI Signals ---
signal game_state_changed(new_state: int, old_state: int)
signal game_paused(is_paused: bool)
signal ui_notification_requested(message: String, color: Color)
