# audio_manager.gd
# VOIDSHIFT - Sound Effects, Ambient Streaming & Haptics Singleton
extends Node

const SFX_MAP = {
	"grav_shift": "res://assets/audio/sfx/sfx_grav_shift.wav",
	"laser_shoot": "res://assets/audio/sfx/sfx_laser_shoot.wav",
	"hit": "res://assets/audio/sfx/sfx_hit.wav",
	"pickup": "res://assets/audio/sfx/sfx_pickup.wav",
	"ui_click": "res://assets/audio/sfx/sfx_ui_click.wav",
	"door_open": "res://assets/audio/sfx/sfx_door_open.wav",
}

const AMBIENT_TRACK = "res://assets/audio/ambient/ambient_station_drone.wav"
const POOL_SIZE: int = 8

var _loaded_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _ambient_player: AudioStreamPlayer

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 0.9
var ambient_volume: float = 0.6
var haptics_enabled: bool = true

func _ready() -> void:
	# Configure persistence across pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Preload SFX streams
	for key in SFX_MAP:
		var path = SFX_MAP[key]
		if ResourceLoader.exists(path):
			_loaded_streams[key] = load(path)
	
	# Create SFX Player Pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)
		
	# Create Ambient Player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	if ResourceLoader.exists(AMBIENT_TRACK):
		var amb_stream = load(AMBIENT_TRACK)
		if amb_stream is AudioStreamWAV:
			amb_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_ambient_player.stream = amb_stream
	add_child(_ambient_player)
	
	# Start ambient station drone automatically
	play_ambient()

func stop_all() -> void:
	# Immediate silence: used for clean scene exits to release active playbacks.
	for player in _sfx_players:
		player.stop()
		player.stream = null
	if _ambient_player:
		stop_ambient()
		_ambient_player.stream = null
	_loaded_streams.clear()

func _exit_tree() -> void:
	# Release in-flight playbacks and cached streams so engine shutdown does not
	# report them as still-in-use resources.
	stop_all()

func play_sfx(name: String, volume_db_offset: float = 0.0, pitch: float = 1.0) -> void:
	if not _loaded_streams.has(name) or sfx_volume <= 0.001:
		return
	var stream = _loaded_streams[name]
	var player = _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % POOL_SIZE
	
	player.stream = stream
	var final_db = linear_to_db(sfx_volume * master_volume) + volume_db_offset
	player.volume_db = final_db
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.play()
	
	# Haptic feedback on impact/shift
	if haptics_enabled:
		if name == "grav_shift":
			trigger_haptic(45)
		elif name == "hit":
			trigger_haptic(30)

func play_ambient() -> void:
	if _ambient_player.stream == null:
		return
	var final_db = linear_to_db(ambient_volume * master_volume)
	_ambient_player.volume_db = final_db
	if not _ambient_player.playing:
		_ambient_player.play()

func stop_ambient() -> void:
	if _ambient_player.playing:
		_ambient_player.stop()

func set_master_volume(linear_val: float) -> void:
	master_volume = clampf(linear_val, 0.0, 1.0)
	_update_ambient_volume()

func set_sfx_volume(linear_val: float) -> void:
	sfx_volume = clampf(linear_val, 0.0, 1.0)

func set_ambient_volume(linear_val: float) -> void:
	ambient_volume = clampf(linear_val, 0.0, 1.0)
	_update_ambient_volume()

func _update_ambient_volume() -> void:
	if _ambient_player:
		if ambient_volume <= 0.001 or master_volume <= 0.001:
			_ambient_player.volume_db = -80.0
		else:
			_ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)

func trigger_haptic(duration_ms: int = 30) -> void:
	if not haptics_enabled:
		return
	if OS.has_feature("mobile") or OS.has_feature("android"):
		Input.vibrate_handheld(duration_ms)
