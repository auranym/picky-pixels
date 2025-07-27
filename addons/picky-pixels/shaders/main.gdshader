shader_type canvas_item;
render_mode unshaded;

const float DITHER_BASE = 0.5;

uniform vec4[{colors_size}] colors;
uniform int[{ramp_colors_size}] ramp_colors;
uniform int[{ramp_color_pointers_size}] ramp_color_pointers;
uniform int[{ramp_dither_transition_amounts_size}] ramp_dither_transition_amounts;

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
			// Get basic screen/pixel info.
			vec4 c = texture(TEXTURE, UV);
			ivec2 size = textureSize(TEXTURE, 0);
			ivec2 pixel = ivec2(
				int(floor(float(size.x) * UV.x)),
				int(floor(float(size.y) * UV.y))
			);

			// Calculate dither adjustment direction, based on pixel location.
			// This value is 1 or -1.
			float dither_dir = float(((pixel.x + pixel.y) % 2) * 2 - 1);

			// Get ramp info.
			// Ramp identified with both B and G channels,
			// with B being more significant.
			int ramp = 256 * int(255.0 * c.b) + int(255.0 * c.g);
			int ramp_color_pos = ramp_color_pointers[2 * ramp];
			int ramp_color_size = ramp_color_pointers[2 * ramp + 1];
			int ramp_dither_transition_amount = ramp_dither_transition_amounts[ramp];

			// Calculate dither adjustment and light level.
			float dither = dither_dir * DITHER_BASE / float(ramp_color_size) * float(ramp_dither_transition_amount) / 10.0;
			int light_level = min(int(floor(clamp(c.r + dither, 0.0, 1.0) * float(ramp_color_size))), ramp_color_size-1);

			// Determine the color!
			COLOR = colors[ramp_colors[ramp_color_pos+light_level]];
		}
	}
}