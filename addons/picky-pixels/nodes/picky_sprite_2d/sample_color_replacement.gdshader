shader_type canvas_item;
render_mode unshaded;

// This is necessary because 2D arrays are not supported...
// Luckily, we know the length of arr, so we can make a Ramp struct.
struct Ramp {
	int[2] arr;
};

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const int LIGHT_LEVELS = 2;
// Maps a color index to a color
const vec4[] COLORS = { vec4(0.0), vec4(1.0) };
const Ramp[] RAMPS = {
	Ramp({ 0, 0 }), Ramp({ 0, 1 })
};

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	int light_level = int(round(c.r * float(LIGHT_LEVELS-1)));
	int ramp = int(round(c.g * 255.0));
	
	if (c.a > 0.95) {
		COLOR = COLORS[RAMPS[ramp].arr[light_level]];
	}
	else {
		COLOR = vec4(0.0);
	}
}