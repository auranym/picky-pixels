shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
const int LIGHT_LEVELS = 3;

uniform vec3 COLOR_0 : source_color;
uniform vec3 COLOR_1 : source_color;
uniform vec3 COLOR_2 : source_color;
uniform vec3 COLOR_3 : source_color;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	float light_level_minus_one = float(LIGHT_LEVELS-1);
	
	if (c.a > 0.001) {
		switch (int(round(c.r * light_level_minus_one))) {
			case 0:
				COLOR.rgb = COLOR_0;
				break;
			case 1:
				COLOR.rgb = COLOR_1;
				break;
			case 2:
				COLOR.rgb = COLOR_2;
				break;
			case 3:
				COLOR.rgb = COLOR_3;
				break;
		}
	}
	else {
		COLOR = vec4(0.0);
	}
}
