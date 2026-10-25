# main_menu.gd
# VOIDSHIFT - Title Screen & Meta-Hub Controller
class_name MainMenu
extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_upgrades: Button = $VBoxContainer/BtnUpgrades
@onready var btn_quit: Button = $VBoxContainer/BtnQuit
@onready var stats_label: Label = $StatsContainer/StatsLabel
@onready var upgrades_panel: PanelContainer = $UpgradesPanel
@onready var btn_close_upgrades: Button = $UpgradesPanel/VBox/BtnCloseUpgrades
@onready var upgrades_vbox: VBoxContainer = $UpgradesPanel/VBox/Scroll/UpgradesVBox

func _ready() -> void:
	GameManager.change_state(Constants.GameState.TITLE)
	get_tree().paused = false
	
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)
	if btn_upgrades:
		btn_upgrades.pressed.connect(_on_upgrades_pressed)
	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)
	if btn_close_upgrades:
		btn_close_upgrades.pressed.connect(func(): upgrades_panel.visible = false)
		
	_update_stats_display()
	_populate_upgrades()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_ambient()

func _update_stats_display() -> void:
	if not stats_label:
		return
	var p = SaveManager.profile_data
	stats_label.text = "STATION LOGS\nRuns: %d | Victories: %d\nHighest Sector: %d\nTotal Scrap: %d" % [
		p.get("total_runs", 0),
		p.get("victories", 0),
		p.get("highest_sector", 1),
		p.get("available_scrap", 0)
	]

func _populate_upgrades() -> void:
	if not upgrades_vbox:
		return
	# Clear previous children
	for child in upgrades_vbox.get_children():
		child.queue_free()
		
	var available_scrap = SaveManager.profile_data.get("available_scrap", 0)
	
	for upgrade_id in LootManager.UPGRADES:
		var u_data = LootManager.UPGRADES[upgrade_id]
		var hbox = HBoxContainer.new()
		
		var lbl = Label.new()
		lbl.text = "%s [%s]\n%s" % [u_data["name"], u_data["rarity"].to_upper(), u_data["desc"]]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)
		
		var buy_btn = Button.new()
		var unlocked = SaveManager.profile_data.get("unlocked_upgrades", []).has(upgrade_id)
		if unlocked:
			buy_btn.text = "INSTALLED"
			buy_btn.disabled = true
		else:
			buy_btn.text = "BUY (%d Scrap)" % u_data["cost"]
			buy_btn.disabled = (available_scrap < u_data["cost"])
			buy_btn.pressed.connect(func(): _buy_upgrade(upgrade_id, u_data["cost"]))
			
		hbox.add_child(buy_btn)
		upgrades_vbox.add_child(hbox)

func _buy_upgrade(upgrade_id: String, cost: int) -> void:
	if SaveManager.spend_scrap(cost):
		var unlocked = SaveManager.profile_data.get("unlocked_upgrades", [])
		if not unlocked.has(upgrade_id):
			unlocked.append(upgrade_id)
		SaveManager.profile_data["unlocked_upgrades"] = unlocked
		SaveManager.save_profile()
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("pickup")
		_update_stats_display()
		_populate_upgrades()

func _on_start_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	GameManager.start_new_run()

func _on_upgrades_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	_populate_upgrades()
	if upgrades_panel:
		upgrades_panel.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
