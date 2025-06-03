//! P3D - Ray-tracer

#include "camera.glsl"
#include "material.glsl"
#include "objects.glsl"
#include "rand.glsl"
#include "scatter.glsl"
#include "scene.glsl"

#iChannel0 "self"

vec3 directLighting(Ray r, HitRecord rec) {
	vec3 n = rec.normal;
	vec3 hitPoint = rec.pos + n * epsilon;

	if (dot(r.d, n) > 0.0) {
		return vec3(0.0);
	}

	vec3 color = rec.material.emissive;

	return color;
}

#define MAX_BOUNCES 10

vec3 rayColor(Camera cam, Ray r) {
	HitRecord rec;
	vec3 col = vec3(0.0);
	vec3 throughput = vec3(1.0f, 1.0f, 1.0f);

	for (int i = 0; i < MAX_BOUNCES; ++i) {
		if (hit_world(r, 0.001, 10000.0, rec)) {
			col += directLighting(r, rec) * throughput;

			// calculate secondary ray and update throughput
			Ray scatterRay;
			vec3 atten;
			if (!scatter(r, rec, atten, scatterRay)) {
				break;
			}

			r = scatterRay;
			throughput *= atten;
		}

		// background
		else {
#if SCENE == 0 || SCENE == 1
			float t = 0.8 * (r.d.y + 1.0);
			col += throughput * mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
#endif
			break;
		}
	}

	return col;
}

#define MAX_SAMPLES 10000.0

void main() {
	vec4 prev = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec3 prevLinear = toLinear(prev.xyz);

	// If we're done rendering and the user isn't moving around, skip everything else
	if (prev.w > MAX_SAMPLES && iMouseButton.x == 0.0) {
		gl_FragColor = prev;
		return;
	}

	gSeed = float(baseHash(floatBitsToUint(gl_FragCoord.xy))) / float(0xffffffffU) + iTime;

	vec2 mouse = iMouse.xy / iResolution.xy;
	mouse.x = mouse.x * 2.0 - 1.0;
	mouse.y = mouse.y * 2.0 - 1.0;

	vec3 camPos = vec3(mouse.x * 10.0, mouse.y * 5.0, 8.0);
	vec3 camTarget = vec3(0.0, 0.0, -1.0);
	float fovy = 10.0; // TODO: This shouldn't be so low
	float aperture = 0.0;
	float distToFocus = 1.0;
	float time0 = 0.0;
	float time1 = 1.0;
	Camera cam = createCamera(
		camPos,
		camTarget,
		vec3(0.0, 1.0, 0.0), // world up vector
		fovy,
		iResolution.x / iResolution.y,
		aperture,
		distToFocus,
		time0,
		time1
	);

	vec2 ps = gl_FragCoord.xy + hash2(gSeed);
	vec3 color = rayColor(cam, getRay(cam, ps));

	// If the user just pressed the mouse, reset the scene to this color
	if (iMouseButton.x != 0.0) {
		gl_FragColor = vec4(toGamma(color), 1.0);
	}

	// Otherwise, mix the previous frame with this one
	else {
		float w = prev.w + 1.0;
		color = mix(prevLinear, color, 1.0 / w);
		gl_FragColor = vec4(toGamma(color), w);
	}
}
