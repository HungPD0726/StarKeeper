class_name StarKeeperWorld
extends Node2D

@onready var player: Player = %Player
@onready var telescope: Telescope = %Telescope
@onready var time_manager: TimeManager = %TimeManager
@onready var environment_tint: CanvasModulate = %EnvironmentTint
@onready var hud: HUD = %HUD
@onready var observatory_view: ObservatoryView = %ObservatoryView


func _ready() -> void:
	player.interaction_prompt_changed.connect(hud.set_interaction_prompt)
	telescope.observatory_requested.connect(_open_observatory)
	observatory_view.closed.connect(_on_observatory_closed)
	time_manager.time_changed.connect(_on_time_changed)
	_on_time_changed(time_manager.get_time_text(), time_manager.get_environment_color())


func _open_observatory() -> void:
	player.set_controls_enabled(false)
	hud.hide()
	observatory_view.open_view()


func _on_observatory_closed() -> void:
	observatory_view.hide()
	hud.show()
	player.set_controls_enabled(true)


func _on_time_changed(time_text: String, environment_color: Color) -> void:
	hud.set_time_text(time_text)
	environment_tint.color = environment_color
