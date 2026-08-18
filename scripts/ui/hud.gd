class_name HUD
extends Control

@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var interaction_panel: PanelContainer = %InteractionPanel
@onready var prompt_label: Label = %PromptLabel
@onready var notification_label: Label = %NotificationLabel
@onready var journal_hint: Label = %JournalHint


func _ready() -> void:
	interaction_panel.hide()
	notification_label.hide()


func set_day_text(text: String) -> void:
	if day_label.text != text:
		day_label.text = text


func set_time_text(text: String) -> void:
	if time_label.text != text:
		time_label.text = text



func set_interaction_prompt(text: String, is_visible: bool) -> void:
	prompt_label.text = text
	interaction_panel.visible = is_visible


func show_notification(text: String, duration: float = 2.5) -> void:
	notification_label.text = text
	notification_label.modulate.a = 0.0
	notification_label.show()

	var tween: Tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(notification_label.hide)
