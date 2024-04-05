shader_type canvas_item;

uniform bool USES_NORMAL_MAP = false;

void light() {
	float cNdotL = 1.0;
	if (USES_NORMAL_MAP) {
		cNdotL = max(0.0, dot(NORMAL, LIGHT_DIRECTION));
	}
	float avg = (LIGHT_COLOR.r + LIGHT_COLOR.g + LIGHT_COLOR.b) / 3.0;
	float r = avg * LIGHT_ENERGY * cNdotL;
	LIGHT = vec4(r, 0.0, 0.0, 1.0);
}
