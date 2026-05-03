// Aspect-correct circular wipe. Fills the screen with `fill_color` outside a
// circle of the given `radius` (centered on screen). Animate `radius` from
// large to 0 to close the iris, or from 0 to large to open it.
shader_type canvas_item;

uniform float radius : hint_range(0.0, 2.0) = 1.5;
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 d = (SCREEN_UV - vec2(0.5)) * 2.0;
	// SCREEN_PIXEL_SIZE = (1/w, 1/h); SCREEN_PIXEL_SIZE.x / .y = h / w.
	float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	d.y *= aspect;
	float dist = length(d);
	float a = step(radius, dist);
	COLOR = vec4(fill_color.rgb, fill_color.a * a);
}
