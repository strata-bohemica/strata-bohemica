shader_type spatial;
// Furrows on a field (SB-008): drawn from world position, no texture and no instances. The profile is a narrow groove
// with a low bank beside it; it gives the surface a normal and a shade, and fades out where one period gets smaller than
// ~2 screen pixels (far away, or the web build on a small canvas), so it never shimmers.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;

uniform vec2 across = vec2(1.0, 0.0);     // unit vector across the furrows (xz)
uniform float spacing = 0.26;             // metres between furrows
uniform float width = 0.05;               // metres, groove width
uniform float depth = 0.10;               // metres, groove depth
uniform vec3 soil : source_color = vec3(0.55, 0.46, 0.27);
uniform vec3 shade : source_color = vec3(0.38, 0.29, 0.17);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// metres of height at signed distance x (in periods) from the groove centre
float profile(float x) {
	float gw = max(width / spacing * 0.5, 0.02);
	float groove = exp(-pow(x / gw, 2.0));
	float bank = exp(-pow((abs(x) - 2.6 * gw) / (2.2 * gw), 2.0));
	return depth * (0.4 * bank - groove);
}

void fragment() {
	float s = dot(wpos.xz, across) / spacing;
	float fine = fwidth(s);
	float vis = 1.0 - smoothstep(0.2, 0.5, fine);        // 0.5 cycle per pixel is the limit
	float x = fract(s) - 0.5;
	float e = 0.01;
	float slope = (profile(x + e) - profile(x - e)) / (2.0 * e * spacing) * vis;
	vec3 n = normalize(vec3(-slope * across.x, 1.0, -slope * across.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float dark = clamp(-profile(x) / depth, 0.0, 1.0) * vis;
	ALBEDO = mix(soil, shade, dark * 0.5) * COLOR.rgb;
	ROUGHNESS = 1.0;
	ALPHA = COLOR.a * 0.92;
}
