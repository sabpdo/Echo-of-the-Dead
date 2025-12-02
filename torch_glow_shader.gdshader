shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float blur_amount : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	// Normalize distance (UV is 0-1, so max distance is 0.707 from center to corner)
	// Scale by radius to control size
	float normalized_dist = dist / (radius * 0.707);
	
	// Create extremely soft falloff with heavy blur - no hard edges
	// Use a very gradual exponential falloff
	float alpha = exp(-normalized_dist * normalized_dist / (blur_amount * blur_amount * 0.5));
	
	// Additional smoothstep for extra softness at edges
	alpha *= smoothstep(1.2, 0.0, normalized_dist);
	
	// Make the falloff even smoother with a power curve
	alpha = pow(alpha, 0.7);
	
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha);
}

