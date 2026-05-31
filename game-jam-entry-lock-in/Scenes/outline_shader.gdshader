shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White
uniform float line_thickness : hint_range(0.0, 10.0) = 0.0; // 0 means OFF by default

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
	float alpha = texture(TEXTURE, UV).a;
	
	// Sample the 4 surrounding pixels
	float outline = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a + 
	                texture(TEXTURE, UV + vec2(size.x, 0.0)).a + 
	                texture(TEXTURE, UV + vec2(0.0, -size.y)).a + 
	                texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	
	// If the current pixel is empty space but right next to a solid pixel, draw outline
	if (alpha == 0.0 && outline > 0.0) {
		COLOR = outline_color;
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}
