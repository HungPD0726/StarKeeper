class_name JournalPanel
extends Control

signal closed

@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var progress_label: Label = %ProgressLabel

var _catalog: ConstellationCatalog


func _ready() -> void:
	hide()
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("journal") or event.is_action_pressed("cancel")):
		close_journal()
		get_viewport().set_input_as_handled()


func setup(catalog: ConstellationCatalog) -> void:
	_catalog = catalog
	_rebuild_entries()


func open_journal() -> void:
	_rebuild_entries()
	show()
	set_process_unhandled_input(true)


func close_journal() -> void:
	hide()
	set_process_unhandled_input(false)
	closed.emit()



func _rebuild_entries() -> void:
	if _catalog == null:
		return

	# Clear old entries
	for child: Node in entries_container.get_children():
		child.queue_free()

	for constellation: ConstellationData in _catalog.constellations:
		var entry: PanelContainer = _create_entry(constellation)
		entries_container.add_child(entry)

	var discovered: int = _catalog.get_discovered_count()
	var total: int = _catalog.get_total_count()
	progress_label.text = "Tiến độ: %d / %d chòm sao" % [discovered, total]


func _create_entry(constellation: ConstellationData) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.16, 0.85)
	style.border_color = Color(0.35, 0.45, 0.65, 0.5) if constellation.discovered else Color(0.2, 0.25, 0.35, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.add_theme_font_size_override("font_size", 12)
	if constellation.discovered:
		title.text = "✦ %s" % constellation.display_name
		title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5, 1.0))
	else:
		title.text = "??? — Chưa khám phá"
		title.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 1.0))
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.add_theme_font_size_override("font_size", 9)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if constellation.discovered:
		desc.text = constellation.description
		desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 1.0))
	else:
		desc.text = "Hãy quan sát bầu trời đêm và nối các vì sao để khám phá."
		desc.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 1.0))
	vbox.add_child(desc)

	return panel
