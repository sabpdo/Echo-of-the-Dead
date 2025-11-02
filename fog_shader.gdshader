shader_type canvas_item;

uniform vec2 player_position;
uniform vec2 viewport_size;
uniform float view_radius : hint_range(50.0, 500.0) = 150.0;
uniform float soft_edge : hint_range(0.0, 100.0) = 50.0;
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);
uniform float fog_opacity : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	// Get current pixel position in screen space
	vec2 pixel_pos = SCREEN_UV * viewport_size;
	
	// Calculate distance from player to current pixel
	float dist = distance(pixel_pos, player_position);
	
	// Create smooth transition at the edge
	float visibility = 1.0 - smoothstep(view_radius - soft_edge, view_radius, dist);
	
	// Calculate fog opacity based on distance (more opaque further away)
	float fog_alpha = (1.0 - visibility) * fog_opacity;
	
	// Output: translucent fog where dark, transparent where visible
	COLOR = vec4(fog_color.rgb, fog_alpha);
}

