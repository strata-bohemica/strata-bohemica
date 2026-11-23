shader_type spatial;
// Rain (SB-015): thin streaks in a box around the camera, moved by the museum clock, not by the engine's TIME, so a
// paused or scrubbed village shows the same rain for the same time (the CPU passes `drift`, the fall so far modulo the
// box, computed in double precision). One draw call, no particle simulation on the (single-threaded) web build.
// Each streak is four vertices with the same VERTEX (its place in the box) and its corner in UV; COLOR.r orders the
// streaks so that `amount` draws the first part of them and collapses the rest to a point (no fragments).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled, fog_disabled;

uniform vec3 box = vec3(48.0, 28.0, 48.0);
uniform vec3 drift = vec3(0.0);          // fall so far, modulo the box (world metres)
uniform vec3 anchor = vec3(0.0);         // the camera position: the box is centred on it
uniform vec3 fall_dir = vec3(0.0, -1.0, 0.0);
uniform float amount = 0.0;              // 0..1 share of the streaks drawn
uniform float streak_length = 0.85;
uniform float streak_width = 0.018;
uniform vec4 tint : source_color = vec4(0.78, 0.82, 0.88, 0.4);

varying float fade;

void vertex() {
	vec3 rel = mod(VERTEX - drift - anchor + box * 0.5, box) - box * 0.5;
	vec3 world = anchor + rel;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float dist = length(cam - world);
	vec3 side = normalize(cross(fall_dir, normalize(cam - world) + vec3(1e-4)));
	vec3 v = world + side * UV.x * streak_width + fall_dir * UV.y * streak_length;
	if (COLOR.r >= amount) {
		v = world;                        // not drawn: a point has no area
	}
	vec3 edge = abs(rel) / (box * 0.5);
	fade = smoothstep(3.0, 8.0, dist) * (1.0 - smoothstep(0.7, 1.0, max(edge.x, max(edge.y, edge.z))));
	VERTEX = (VIEW_MATRIX * vec4(v, 1.0)).xyz;
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}

void fragment() {
	ALBEDO = tint.rgb;
	ALPHA = tint.a * fade * (1.0 - abs(UV.x)) * smoothstep(0.0, 0.3, UV.y);
}
