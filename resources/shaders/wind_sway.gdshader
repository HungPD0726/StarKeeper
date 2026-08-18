shader_type canvas_item;

uniform float speed : hint_range(0.5, 6.0) = 2.2;
uniform float strength : hint_range(0.0, 10.0) = 2.0;
uniform float detail : hint_range(0.1, 5.0) = 1.0;

void vertex() {
	// Sway only the upper part of the sprite (1.0 - UV.y is 1.0 at top, 0.0 at base)
	float sway_factor = clamp(1.0 - UV.y, 0.0, 1.0);
	float wave = sin(TIME * speed + VERTEX.y * 0.05 * detail) * 0.7 + sin(TIME * speed * 1.7 + VERTEX.x * 0.03) * 0.3;
	VERTEX.x += wave * strength * sway_factor;
}
