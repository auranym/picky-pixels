shader_type canvas_item;

void fragment() {
	float cycle = (sin(3.14159 * TIME) + 1.0) / 2.0;
	COLOR = vec4(cycle, 1.0 - cycle, 0, COLOR.a);
}