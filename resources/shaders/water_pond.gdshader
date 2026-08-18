shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.12, 0.22, 0.38, 0.88);
uniform vec4 shallow_color : source_color = vec4(0.20, 0.38, 0.55, 0.82);
uniform vec4 foam_color : source_color = vec4(0.70, 0.88, 0.95, 0.65);
uniform float speed : hint_range(0.2, 4.0) = 1.2;
uniform float wave_scale : hint_range(5.0, 50.0) = 22.0;

void fragment() {
	vec2 uv = UV;
	
	// Pixelate the wave coordinates
	vec2 pixel_uv = floor(uv * 48.0) / 48.0;
	
	// Create horizontal wave ripples
	float wave1 = sin(pixel_uv.y * wave_scale + TIME * speed * 1.5 + pixel_uv.x * 6.0);
	float wave2 = cos(pixel_uv.x * wave_scale * 0.8 - TIME * speed * 1.1 + pixel_uv.y * 8.0);
	float combined_wave = wave1 * 0.5 + wave2 * 0.5;
	
	// Depth gradient from center outwards
	float dist_from_center = length(uv - vec2(0.5, 0.5)) * 2.0;
	vec4 base_water = mix(deep_color, shallow_color, clamp(dist_from_center, 0.0, 1.0));
	
	// Sparkles / foam highlights on wave peaks
	float highlight = step(0.68, combined_wave);
	vec4 final_color = mix(base_water, foam_color, highlight * 0.5);
	
	// Outer edge soft darkening
	float rim = smoothstep(0.75, 0.98, dist_from_center);
	final_color.rgb = mix(final_color.rgb, final_color.rgb * 0.6, rim);
	
	COLOR = final_color;
}
