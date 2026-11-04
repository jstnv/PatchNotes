shader_type canvas_item;
render_mode unshaded, blend_add;
// Cached geometry carries route id, arc distance and cross-trace distance.
// Color is encoded by sign for blue/orange, or by a strength above 2 for neutral.
uniform vec4 pulses[128]; // route, head distance, tail length, encoded strength/color
uniform int pulse_slots = 0;
uniform float unit_scale = 1.0;
uniform float brightness = 0.8;
uniform float bass = 0.0;
uniform float bloom = 0.8;
uniform float title_right = 440.0;
varying float route_id;
varying float local_x;
varying vec2 edge_limits;
float gaussian(float distance) {
	return exp(-distance * distance);
}
void vertex() {
	route_id = round(COLOR.r * 16.0);
	local_x = VERTEX.x;
	edge_limits = COLOR.gb * 48.0 * unit_scale;
}
void fragment() {
	vec3 light = vec3(0.0);
	float cross_distance = UV.y / unit_scale;
	float core = gaussian(cross_distance / (0.85 + bass * 0.5));
	float halo = gaussian(cross_distance / (3.0 + bass * 1.8));
	float glow = gaussian(cross_distance / (10.0 + bass * 4.0));
	for (int i = 0; i < 128; i++) {
		if (i >= pulse_slots) { break; }
		if (abs(pulses[i].x - route_id) > 0.1 || pulses[i].w == 0.0) { continue; }
		float behind = pulses[i].y - UV.x;
		if (behind < -32.0 * unit_scale || behind > pulses[i].z) { continue; }
		float tail = pow(clamp(1.0 - max(behind, 0.0) / pulses[i].z, 0.0, 1.0), 1.7);
		float front = gaussian(min(behind, 0.0) / (1.7 * unit_scale));
		float aura_front = gaussian(min(behind, 0.0) / (8.0 * unit_scale));
		float tip = gaussian(behind / (6.0 * unit_scale));
		bool neutral = pulses[i].w > 1.5;
		float strength = neutral ? max(0.0, pulses[i].w - 2.0) : abs(pulses[i].w);
		vec3 accent = neutral ? vec3(0.35,0.37,0.42) : (pulses[i].w > 0.0 ? vec3(0.035,0.90,0.98) : vec3(1.0,0.40,0.075));
		light += strength * tail * brightness * (
			accent * (core * 1.35 * front + (halo * 0.65 + glow * 0.18) * bloom * aura_front)
			+ vec3(1.0,0.96,0.87) * tip * core * front * 1.2);
	}
	float legibility = mix(0.22, 1.0, smoothstep(title_right-30.0, title_right+180.0, local_x));
	// Fade before a clipped inner edge, rather than cutting the halo abruptly.
	float edge = UV.y < 0.0 ? edge_limits.x : edge_limits.y;
	float feather = smoothstep(0.0, min(10.0 * unit_scale, edge * 0.4), edge-abs(UV.y));
	COLOR = vec4(light, legibility * feather);
}
