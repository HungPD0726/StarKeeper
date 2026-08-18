class_name CelestialEventManager
extends Node

signal celestial_event_started(event_type: String, banner_text: String)

enum EventType {
	CLEAR_NIGHT,
	METEOR_SHOWER,
}

@export_range(0.0, 1.0, 0.05) var meteor_shower_chance: float = 0.45

var current_event: EventType = EventType.CLEAR_NIGHT
var _has_rolled_tonight: bool = false


func check_night_transition(is_night: bool) -> void:
	if is_night:
		if not _has_rolled_tonight:
			_has_rolled_tonight = true
			_roll_night_event()
	else:
		_has_rolled_tonight = false
		current_event = EventType.CLEAR_NIGHT


func _roll_night_event() -> void:
	if randf() < meteor_shower_chance:
		current_event = EventType.METEOR_SHOWER
		celestial_event_started.emit(
			"meteor_shower",
			"🌠 Đêm nay xuất hiện Mưa Sao Băng rực rỡ trên bầu trời!"
		)
	else:
		current_event = EventType.CLEAR_NIGHT


func is_meteor_shower() -> bool:
	return current_event == EventType.METEOR_SHOWER
