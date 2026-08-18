class_name Telescope
extends Interactable

signal observatory_requested


func interact(_player: Node2D) -> void:
	observatory_requested.emit()
