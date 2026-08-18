class_name HUD
extends Control

@onready var time_label: Label = %TimeLabel
@onready var interaction_panel: PanelContainer = %InteractionPanel
@onready var prompt_label: Label = %PromptLabel


func _ready() -> void:
	interaction_panel.hide()


func set_time_text(text: String) -> void:
	if time_label.text != text:
		time_label.text = text


func set_interaction_prompt(text: String, is_visible: bool) -> void:
	prompt_label.text = text
	interaction_panel.visible = is_visible
