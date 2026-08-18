class_name ConstellationData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var required_star_indices: Array[int] = []
## Each Vector2i represents a connection between two star indices.
@export var connections: Array[Vector2i] = []
var discovered: bool = false
