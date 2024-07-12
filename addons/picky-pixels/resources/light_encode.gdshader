shader_type canvas_item;

uniform bool in_editor = false;
uniform bool uses_normal_map = false;

void light() {
	if (in_editor) {
		LIGHT = vec4(0.0);
	}
	else {
		float cNdotL = 1.0;
		if (uses_normal_map) {
			cNdotL = max(0.0, dot(NORMAL, LIGHT_DIRECTION));
		}
		float avg = (LIGHT_COLOR.r + LIGHT_COLOR.g + LIGHT_COLOR.b) / 3.0;
		float r = avg * LIGHT_ENERGY * LIGHT_COLOR.a * cNdotL;
		LIGHT = vec4(r, 0.0, 0.0, 1.0);
	}
}
