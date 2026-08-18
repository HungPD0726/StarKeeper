class_name Bench
extends Interactable

signal sitting_state_changed(is_sitting: bool)

var _is_sitting: bool = false


func _ready() -> void:
	prompt_text = "Nhấn E để ngồi nghỉ ngơi"


func interact(_player: Node2D) -> void:
	_is_sitting = !_is_sitting
	prompt_text = "Nhấn E để đứng dậy" if _is_sitting else "Nhấn E để ngồi nghỉ ngơi"
	sitting_state_changed.emit(_is_sitting)
