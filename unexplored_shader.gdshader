shader_type canvas_item;

uniform sampler2D explored_texture;
uniform vec2 map_offset; // World position of top-left corner of map
uniform vec2 map_size; // Size of the map in world units
uniform vec2 viewport_size;
uniform vec2 player_world_position; // Player's world position (camera center)
uniform float camera_zoom; // Camera zoom level

void fragment() {
	// Get current pixel position in screen space
	vec2 pixel_pos = SCREEN_UV * viewport_size;
	
	// Convert screen position to world position
	// Player is at screen center, so offset from center gives world offset
	vec2 screen_offset = pixel_pos - viewport_size * 0.5;
	// Account for camera zoom
	vec2 world_offset = screen_offset / camera_zoom;
	// Calculate actual world position
	vec2 world_pos = player_world_position + world_offset;
	
	// Convert world position to texture UV coordinates (0-1 range)
	vec2 world_relative = world_pos - map_offset;
	vec2 uv = world_relative / map_size;
	
	// Clamp UV to valid range
	uv = clamp(uv, vec2(0.0), vec2(1.0));
	
	// Sample the explored texture (white = explored, black = unexplored)
	float explored = texture(explored_texture, uv).r;
	
	// Output: black where unexplored (explored < 1.0), transparent where explored
	float unexplored_alpha = 1.0 - explored;
	COLOR = vec4(0.0, 0.0, 0.0, unexplored_alpha);
}

