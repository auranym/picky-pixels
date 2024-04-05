shader_type canvas_item;
render_mode unshaded;

struct Ramp {
	int[4] arr;
};

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const int LIGHT_LEVELS = 4;
const vec4[] COLORS = { vec4(0, 0, 0, 0), vec4(0.419607847929, 0, 0, 1), vec4(0.27450981736183, 0.43137255311012, 0.18823529779911, 1), vec4(0.37647059559822, 0.57254904508591, 0.24705882370472, 1), vec4(0.50196081399918, 0.71372550725937, 0.28627452254295, 1), vec4(0.78039216995239, 0.73333334922791, 0.2392156869173, 1), vec4(0.78039216995239, 0.09019608050585, 0, 1), vec4(0.85882353782654, 0.258823543787, 0.14117647707462, 1), vec4(0.85882353782654, 0.85882353782654, 0.30196079611778, 1) };
const Ramp[] RAMPS = { Ramp({ 0, 0, 0, 0 }), Ramp({ 1, 2, 3, 3 }), Ramp({ 1, 2, 3, 4 }), Ramp({ 1, 1, 1, 1 }), Ramp({ 1, 1, 4, 5 }), Ramp({ 1, 1, 6, 7 }), Ramp({ 1, 1, 6, 6 }), Ramp({ 1, 1, 5, 8 }), Ramp({ 1, 3, 5, 8 }), Ramp({ 1, 3, 4, 5 }), Ramp({ 1, 6, 6, 7 }), Ramp({ 1, 5, 5, 8 }), Ramp({ 1, 6, 4, 5 }), Ramp({ 1, 1, 3, 5 }), Ramp({ 1, 2, 4, 5 }), Ramp({ 1, 2, 6, 7 }), Ramp({ 1, 6, 6, 6 }), Ramp({ 1, 1, 1, 6 }), Ramp({ 1, 2, 2, 2 }), Ramp({ 1, 2, 3, 5 }) };

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