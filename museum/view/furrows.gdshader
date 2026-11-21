shader_type spatial;
// Furrows on a field (SB-008, irregular since SB-037): drawn from world position, no texture and no instances.
// The profile is a narrow groove with a low bank beside it; it gives the surface a normal and a shade.
// SB-037: (1) the furrows are hand-and-ox work, not a ruler. Each furrow's lateral position, depth, width, profile (U or V) and whether
// it exists at all (start, end, lifted gaps, deep patch) is a table made in GDScript from the field's record (core/furrow_field.gd,
// the model of research note E-furrow-irregularity.md, class F: our choice); the shader only reads it with texelFetch and draws the
// nearest furrow, so no formula is copied here; (2) the profile is band-limited: the groove is blurred by the pixel footprint (a Gaussian
// stays a Gaussian, so it is analytic and cheap) and the pattern fades out only when the period itself nears 2.5 pixels, instead of
// when the groove is 1.5 px wide; and nothing is computed where it has faded. The colour is the ground's own (vertex colour, set by
// terrain_view), so where the pattern has faded the field looks as before.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;      // the ground's own lighting model (StandardMaterial3D defaults)

uniform vec2 across = vec2(1.0, 0.0);     // unit vector across the furrows (xz)
uniform vec2 along = vec2(0.0, 1.0);      // unit vector along the furrows (xz)
uniform float spacing = 0.26;             // metres between furrows (nominal; also the unit of the profile)
uniform vec3 shade_mul = vec3(0.69, 0.63, 0.63);     // colour multiplier at the bottom of the groove (was soil 0.55,0.46,0.27 -> shade 0.38,0.29,0.17)
// the table (see core/furrow_field.gd): row = furrow, column = sample along the furrow; R lateral offset m, G depth m, B width m, A profile U=1 / V=0
uniform sampler2D furrow_tex : filter_nearest, repeat_disable;
uniform vec4 tex_info = vec4(0.0, 8.0, 2.0, 2.0);   // t0 (m along), 1/step, samples, rows
uniform float across_o = 0.0;             // across coordinate of row 0 (m)
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
	float a = dot(wpos.xz, across) - across_o;
	float f0 = fwidth(a) / spacing;             // furrow periods per pixel (taken outside the branches)
	float fclod = length(fwidth(wpos.xz / clod.y));   // clod cells per pixel; a derivative needs uniform control flow, so it is taken here too, not inside the branches
	if (f0 <= FADE_GONE * 1.1) {                // beyond that no furrow can show (a heading of 0.28 stretches the period by 4 % at most): no table reads, no clods
		float tf = clamp((dot(wpos.xz, along) - tex_info.x) * tex_info.y, 0.0, tex_info.z - 1.001);
		int i = int(tf);
		float fr = tf - float(i);
		int rmax = int(tex_info.w) - 1;
		// the furrow nearest to this point: the shared shape moves every row alike, so the row found from the nominal position and
		// refined once with that row's own offset is within one of the answer; try that one and its neighbours
		int r0 = clamp(int(floor(a / spacing + 0.5)), 0, rmax);
		float o0 = mix(texelFetch(furrow_tex, ivec2(i, r0), 0).x, texelFetch(furrow_tex, ivec2(i + 1, r0), 0).x, fr);
		int r1 = int(floor((a - o0) / spacing + 0.5));
		float best = 1e9;
		vec4 v = vec4(0.0);
		float slope = 0.0;
		float dist = 0.0;
		for (int c = -1; c <= 1; c++) {
			int r = clamp(r1 + c, 0, rmax);
			vec4 ta = texelFetch(furrow_tex, ivec2(i, r), 0);
			vec4 tb = texelFetch(furrow_tex, ivec2(i + 1, r), 0);
			vec4 tv = mix(ta, tb, fr);
			float dd = a - (float(r) * spacing + tv.x);
			if (abs(dd) < best) {
				best = abs(dd);
				v = tv;
				slope = (tb.x - ta.x) * tex_info.y;
				dist = dd;
			}
		}
		float cosphi = inversesqrt(1.0 + slope * slope);
		float f = f0 / cosphi;
		float vis = 1.0 - smoothstep(FADE_FULL, FADE_GONE, f);
		vis *= smoothstep(0.02, 0.2, COLOR.a);     // clipped to the field outline
		if (vis > 0.0) {                          // else faded after all: nothing more to compute
			float x = dist * cosphi / spacing;     // perpendicular distance to the furrow, in periods
			float gw = max(v.z * (0.85 + 0.3 * v.w) / spacing * 0.5, 0.02);   // U: a little wider, V: a little narrower
			float blur2 = 0.9 * f * f;            // 2 sigma^2 with sigma = 0.67 px: a Gaussian pre-filter that leaves nothing above Nyquist worth speaking of
			float gd;
			float bd;
			float bd2;
			float groove = blurred(x, 0.0, gw, blur2, gd);
			float bank = blurred(x, 2.6 * gw, 2.2 * gw, blur2, bd) + blurred(x, -2.6 * gw, 2.2 * gw, blur2, bd2);   // a bank on each side: smooth, no kink at the groove
			float dz = smoothstep(0.0, 0.02, v.y);   // a furrow of no depth leaves no mark at all
			float sl = v.y * (0.4 * (bd + bd2) - gd) / spacing * vis;
			vec3 n = wnormal + vec3(-sl * across.x, 0.0, -sl * across.y);
			float dark = groove * vis * dz;       // shade = the band-limited groove only (a clamp of the profile would put a kink, and with it moire, back in)
			float cl = 0.0;
			if (clod.x > 0.0) {                   // clods: one candidate per cell, a small bump that fades by its own footprint
				vec2 p = wpos.xz / clod.y;
				vec2 id = floor(p);
				vec3 q = fract(vec3(id.xyx) * vec3(0.1031, 0.1030, 0.0973));        // a hash without sin: three random numbers per cell
				q += dot(q, q.yzx + 33.33);
				vec3 r = fract((q.xxy + q.yzz) * q.zyx);
				vec2 d = fract(p) - (0.3 + 0.4 * r.xy);
				float bump = step(1.0 - clod.x, r.z) * (1.0 - smoothstep(0.0, 0.3, length(d))) * (1.0 - smoothstep(0.2, 0.5, fclod));
				cl = bump;
				n.xz += d * bump * 1.2;
			}
			NORMAL = normalize((VIEW_MATRIX * vec4(normalize(n), 0.0)).xyz);
			ALBEDO = COLOR.rgb * mix(vec3(1.0), shade_mul, dark * 0.5) * (1.0 - 0.2 * cl);
		}
	}
}
