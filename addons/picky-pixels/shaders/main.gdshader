shader_type canvas_item;
render_mode unshaded;

uniform vec4[{colors_size}] colors;
uniform int[{ramp_colors_size}] ramp_colors;
uniform int[{ramp_color_pointers_size}] ramp_color_pointers;

uniform bool in_editor;

bool is_in_palette(vec4 color) {
	// Ignore transparency
	if (color.a < 1.0) {
		return true;
	}

	for (int i = 0; i < colors.length(); i++) {
		if (length(color - colors[i]) < 0.0001) {
			return true;
		}
	}
	return false;
}

void fragment() {
	if (!in_editor && !is_in_palette(COLOR)) {
		if (abs(COLOR.a - 1.0) < 0.0001) {
			vec4 c = texture(TEXTURE, UV);
			// Ramp identified with both B and G channels,
			// with B being more significant.
			int ramp = 256 * int(255.0 * c.b) + int(255.0 * c.g);
			int ramp_pos = ramp_color_pointers[2 * ramp];
			int ramp_size = ramp_color_pointers[2 * ramp + 1];
			int light_level = min(int(floor(c.r * float(ramp_size))), ramp_size-1);

			COLOR = colors[ramp_colors[ramp_pos+light_level]];
		}
	}
}