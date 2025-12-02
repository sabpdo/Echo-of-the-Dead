shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float base_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.3;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	// Normalized UV across the rect (0..1)
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);

	// Vignette mask: 0 in the center, 1 towards edges
	float vignette = smoothstep(inner_radius, outer_radius, dist);

	float intensity = clamp(base_intensity + flash_intensity, 0.0, 1.0);
	float alpha = vignette * intensity * vignette_color.a;

	COLOR = vec4(vignette_color.rgb, alpha);
}


