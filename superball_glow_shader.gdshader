shader_type canvas_item;

uniform sampler2D fireball_texture : source_color;
uniform vec4 glow_color : source_color = vec4(0.2, 1.0, 0.3, 1.0);
uniform float blur_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Sample the fireball texture to get its shape
	vec4 tex_color = texture(fireball_texture, UV);
	
	// Use the alpha channel to determine the shape
	float shape_alpha = tex_color.a;
	
	// Create blur effect by sampling nearby pixels in a circle
	float blurred_alpha = 0.0;
	float total_weight = 0.0;
	
	// Sample in a circular pattern for blur
	for (int i = 0; i < 12; i++) {
		float angle = float(i) / 12.0 * 6.28318; // 2*PI
		float radius = blur_amount * 0.03;
		vec2 offset = vec2(cos(angle), sin(angle)) * radius;
		vec2 sample_uv = clamp(UV + offset, vec2(0.0), vec2(1.0));
		vec4 sample_color = texture(fireball_texture, sample_uv);
		float weight = 1.0;
		blurred_alpha += sample_color.a * weight;
		total_weight += weight;
	}
	
	if (total_weight > 0.0) {
		blurred_alpha /= total_weight;
	}
	
	// Combine original shape with blurred version for glow
	float final_alpha = max(shape_alpha * 0.3, blurred_alpha * 0.7);
	
	COLOR = vec4(glow_color.rgb, glow_color.a * final_alpha);
}

