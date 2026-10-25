# constants.gd
# VOIDSHIFT - Global Game Constants and Enums
extends Node

# Gravity Directions (Cardinal 90-degree rotations)
enum GravityDirection {
	DOWN = 0,   # 0 deg (Standard down: (0, 1))
	RIGHT = 1,  # 90 deg clockwise (Gravity pulls right: (1, 0))
	UP = 2,     # 180 deg (Inverted / Ceiling: (0, -1))
	LEFT = 3    # 270 deg (Gravity pulls left: (-1, 0))
}

# Gravity Vectors matching the enum indices
const GRAVITY_VECTORS: Array[Vector2] = [
	Vector2(0, 1),   # DOWN
	Vector2(1, 0),   # RIGHT
	Vector2(0, -1),  # UP
	Vector2(-1, 0)   # LEFT
]

# Rotation Angles in Radians corresponding to each gravity direction
const GRAVITY_ANGLES: Array[float] = [
	0.0,             # DOWN
	PI * 0.5,        # RIGHT
	PI,              # UP
	PI * 1.5         # LEFT
]

# Game States
enum GameState {
	TITLE,
	EXPLORATION,
	COMBAT,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# Team / Combat Affiliation
enum CombatTeam {
	PLAYER,
	ENEMY,
	ENVIRONMENT
}

# Collision Layers (Godot 2D Physics)
# Layer 1: World / Walls / Bulkheads
# Layer 2: Player Hurtbox & Collision
# Layer 3: Enemies Hurtbox & Collision
# Layer 4: Player Projectiles
# Layer 5: Enemy Projectiles
# Layer 6: Pickups & Loot
# Layer 7: Interactive Props / Physics Crates
# Layer 8: Triggers / Room Portals
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_PLAYER_PROJECTILE: int = 8
const LAYER_ENEMY_PROJECTILE: int = 16
const LAYER_PICKUP: int = 32
const LAYER_PROP: int = 64
const LAYER_PORTAL: int = 128

# Standard Roguelite Gameplay Values
const PLAYER_BASE_HP: float = 100.0
const PLAYER_BASE_ENERGY: float = 100.0
const PLAYER_BASE_SPEED: float = 180.0
const PLAYER_DASH_SPEED: float = 400.0
const PLAYER_DASH_DURATION: float = 0.2
const PLAYER_DASH_COST: float = 20.0
const GRAVITY_SHIFT_COST: float = 15.0
const GRAVITY_SHIFT_COOLDOWN: float = 0.4
const ENERGY_REGEN_RATE: float = 15.0 # per second

# Physics & World
const GRAVITY_FORCE: float = 400.0
const TILE_SIZE: int = 32
