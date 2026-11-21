shader_type spatial;
// Furrows on a field (SB-008, irregular since SB-037): drawn from world position, no texture and no instances.
// The profile is a narrow groove with a low bank beside it; it gives the surface a normal and a shade.
// SB-037: (1) the furrows are hand-and-ox work, not a ruler: each path wavers in a slow wide wave, the spacing, depth and width drift
// within the cited ranges, some furrows have a shallow stretch, they start and stop unevenly at the headland and a few clods lie in
// the field (all parameters in breznice-furrows.json, our choice, class F; the same formula is in core/furrow_wave.gd, which the tests use);
// (2) the profile is band-limited: the groove is blurred by the pixel footprint (a Gaussian stays a Gaussian, so it is analytic and
// cheap) and the pattern fades out only when the period itself nears 2.5 pixels, instead of when the groove is 1.5 px wide; and
// nothing is computed where it has faded. The colour is the ground's own (vertex colour, set by terrain_view), so where the pattern
// has faded the field looks as before.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;      // the ground's own lighting model (StandardMaterial3D defaults)

uniform vec2 across = vec2(1.0, 0.0);     // unit vector across the furrows (xz)
uniform vec2 along = vec2(0.0, 1.0);      // unit vector along the furrows (xz)
uniform float spacing = 0.26;             // metres between furrows (nominal)
uniform float width = 0.05;               // metres, groove width (nominal)
uniform float depth = 0.10;               // metres, groove depth (nominal)
uniform vec3 shade_mul = vec3(0.69, 0.63, 0.63);     // colour multiplier at the bottom of the groove (was soil 0.55,0.46,0.27 -> shade 0.38,0.29,0.17)
// irregularity (see core/furrow_wave.gd for the meaning and the CPU copy of the formulas)
uniform vec2 warp_amp = vec2(0.0);        // path wave amplitudes, in furrow periods
uniform vec2 warp_k = vec2(0.5, 1.5);     // path wave numbers, rad per metre along the furrow
uniform vec2 warp_c = vec2(0.0);          // phase advance per furrow, rad (this is what makes the spacing vary)
uniform vec4 phase = vec4(0.0);           // phases: wave 1, wave 2, depth/width, gap/ends
uniform vec4 vary = vec4(0.0);            // depth jitter, width jitter, gap strength, end wobble
uniform vec2 clod = vec2(0.0, 0.2);       // clod density 0..1, clod cell size in metres

const float FADE_FULL = 0.17;             // furrow periods per pixel: fully drawn up to ~6 px per period
const float FADE_GONE = 0.40;             // gone from ~2.5 px per period (Nyquist is 2 px)

varying vec3 wpos;
varying vec3 wnormal;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

// A Gaussian of height 1, width w centred on c, seen through a pixel footprint (blur2 = 2 sigma^2 in period^2): still a Gaussian, lower and wider. dx = its slope.
float blurred(float x, float c, float w, float blur2, out float dx) {
	float w2 = w * w + blur2;
	float iw2 = 1.0 / w2;
	float v = w * sqrt(iw2) * exp(-(x - c) * (x - c) * iw2);
	dx = -2.0 * (x - c) * iw2 * v;
	return v;
}

void fragment() {
	ALBEDO = COLOR.rgb;                         // where the pattern has faded the field is just the ground
	ROUGHNESS = 1.0;
	ALPHA = COLOR.a * 0.92;
	float s0 = dot(wpos.xz, across) / spacing;
	float f0 = fwidth(s0);
	if (f0 <= FADE_GONE * 1.15) {               // beyond that no furrow can show (the waver stretches the period by 12 % at most): no profile, no waver, no clods
		float t = dot(wpos.xz, along);
		// path waver: two slow waves along the furrow whose phase moves from furrow to furrow
		float s = s0 + warp_amp.x * sin(warp_k.x * t + warp_c.x * s0 + phase.x) + warp_amp.y * sin(warp_k.y * t + warp_c.y * s0 + phase.y);
		float f = max(fwidth(s), 1e-4);
		float vis = 1.0 - smoothstep(FADE_FULL, FADE_GONE, f);
		if (vis > 0.0) {                          // else faded after all: nothing more to compute
			// uneven start and end at the headland: each furrow stops at its own place inside the field mask
			float th = 0.45 + vary.w * (0.6 * sin(3.7 * s0 + phase.w) + 0.4 * sin(8.9 * s0 + phase.z));
			vis *= smoothstep(th - 0.15, th + 0.15, COLOR.a);
			// a stretch where the ard was lifted: a shallow groove now and then
			vis *= 1.0 - vary.z * smoothstep(0.55, 0.9, 0.5 + 0.5 * sin(0.97 * t + 4.1 * s0 + phase.w));
			float dj = 1.0 + vary.x * (0.6 * sin(1.19 * t + 1.9 * s0 + phase.z) + 0.4 * sin(2.99 * t + 3.1 * s0 + phase.w));
			float wj = 1.0 + vary.y * sin(0.82 * t + 2.3 * s0 + phase.z);
			float x = fract(s) - 0.5;
			float gw = max(width * wj / spacing * 0.5, 0.02);
			float blur2 = 0.9 * f * f;            // 2 sigma^2 with sigma = 0.67 px: a Gaussian pre-filter that leaves nothing above Nyquist worth speaking of
			float gd;
			float bd;
			float bd2;
			float groove = blurred(x, 0.0, gw, blur2, gd);
			float bank = blurred(x, 2.6 * gw, 2.2 * gw, blur2, bd) + blurred(x, -2.6 * gw, 2.2 * gw, blur2, bd2);   // a bank on each side: smooth, no kink at the groove
			float slope = depth * dj * (0.4 * (bd + bd2) - gd) / spacing * vis;
			vec3 n = wnormal + vec3(-slope * across.x, 0.0, -slope * across.y);
			float dark = groove * vis;            // shade = the band-limited groove only (a clamp of the profile would put a kink, and with it moire, back in)
			float cl = 0.0;
			if (clod.x > 0.0) {                   // clods: one candidate per cell, a small bump that fades by its own footprint
				vec2 p = wpos.xz / clod.y;
				vec2 id = floor(p);
				vec3 q = fract(vec3(id.xyx) * vec3(0.1031, 0.1030, 0.0973));        // a hash without sin: three random numbers per cell
				q += dot(q, q.yzx + 33.33);
				vec3 r = fract((q.xxy + q.yzz) * q.zyx);
				vec2 d = fract(p) - (0.3 + 0.4 * r.xy);
				float bump = step(1.0 - clod.x, r.z) * (1.0 - smoothstep(0.0, 0.3, length(d))) * (1.0 - smoothstep(0.2, 0.5, length(fwidth(p))));
				cl = bump;
				n.xz += d * bump * 1.2;
			}
			NORMAL = normalize((VIEW_MATRIX * vec4(normalize(n), 0.0)).xyz);
			ALBEDO = COLOR.rgb * mix(vec3(1.0), shade_mul, dark * 0.5) * (1.0 - 0.2 * cl);
		}
	}
}
