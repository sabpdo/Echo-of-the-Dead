shader_type canvas_item;

uniform vec2 player_position;
uniform vec2 viewport_size;
uniform float view_radius : hint_range(50.0, 500.0) = 150.0;
uniform float soft_edge : hint_range(0.0, 100.0) = 50.0;
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);
uniform float fog_opacity : hint_range(0.0, 1.0) = 0.85;

// Light sources array (max 16 lights)
uniform int light_count : hint_range(0, 16) = 0;
uniform vec2 light_positions[16];
uniform float light_radii[16];
uniform vec2 light_directions[16]; // Direction for oval orientation
uniform float light_aspects[16]; // Aspect ratio for oval (width/height)

void fragment() {
	// Get current pixel position in screen space
	vec2 pixel_pos = SCREEN_UV * viewport_size;
	
	// Calculate distance from player to current pixel
	float dist = distance(pixel_pos, player_position);
	
	// Create smooth transition at the edge for player view
	float visibility = 1.0 - smoothstep(view_radius - soft_edge, view_radius, dist);
	
	// Check all light sources
	for (int i = 0; i < light_count && i < 16; i++) {
		vec2 to_pixel = pixel_pos - light_positions[i];
		
		// Calculate elliptical distance for oval shape
		vec2 dir = normalize(light_directions[i]);
		if (length(dir) < 0.1) {
			// Fallback to circular if direction is invalid
			dir = vec2(1.0, 0.0);
		}
		
		// Rotate to align with direction
		float angle = atan(dir.y, dir.x);
		float cos_a = cos(-angle);
		float sin_a = sin(-angle);
		vec2 rotated = vec2(
			to_pixel.x * cos_a - to_pixel.y * sin_a,
			to_pixel.x * sin_a + to_pixel.y * cos_a
		);
		
		// Apply aspect ratio (stretch in direction of travel)
		float aspect = light_aspects[i];
		if (aspect < 0.1) {
			aspect = 1.0;
		}
		rotated.x /= aspect; // Stretch horizontally (in direction of travel)
		
		// Calculate elliptical distance
		float light_dist = length(rotated);
		float light_visibility = 1.0 - smoothstep(light_radii[i] - soft_edge * 0.5, light_radii[i], light_dist);
		// Take maximum visibility (light sources can reveal more)
		visibility = max(visibility, light_visibility);
	}
	
	// Calculate fog opacity based on distance (more opaque further away)
	float fog_alpha = (1.0 - visibility) * fog_opacity;
	
	// Output: translucent fog where dark, transparent where visible
	COLOR = vec4(fog_color.rgb, fog_alpha);
}

