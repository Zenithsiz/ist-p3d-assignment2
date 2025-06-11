//! P3D - Ray-tracer

#include "camera.glsl"
#include "material.glsl"
#include "objects.glsl"
#include "rand.glsl"
#include "scatter.glsl"
#include "scene.glsl"

#iChannel0 "self"
#iChannel1 "file://input/orbit.glsl"
#iChannel1::MinFilter "Nearest"
#iChannel1::MagFilter "Nearest"
#iChannel2 "file://input/cam-dist-roll-fov.glsl"
#iChannel2::MinFilter "Nearest"
#iChannel2::MagFilter "Nearest"
#iChannel3 "file://input/target-pos.glsl"
#iChannel3::MinFilter "Nearest"
#iChannel3::MagFilter "Nearest"
#iChannel4 "file://input/dof.glsl"
#iChannel4::MinFilter "Nearest"
#iChannel4::MagFilter "Nearest"

vec3 directLighting(Camera cam, Ray r, HitRecord rec) {
	Material mat = rec.material;

	// Start with the emissive color of the material
	vec3 col = mat.emissive;

	vec3 n = rec.normal;
	bool isInside = dot(r.d, n) > 0.0;
	vec3 ns = isInside ? -n : n;
	vec3 hitPos = rec.pos + 3.0 * ns * epsilon;

	// Then for each light
	for (int lightIdx = 0; lightIdx < worldLightsLen; lightIdx++) {
		// Choose a random point in the light
		vec3 lightPos = worldRandLight(lightIdx, gSeed);

		float lightDist = length(lightPos - hitPos);
		vec3 l = normalize(lightPos - hitPos);

		// If we hit the light, color it
		float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);
		Ray lightRay = Ray(hitPos, l, time);
		HitRecord lightRec;
		if (worldHit(lightRay, 0.001, lightDist + epsilon, lightRec) && lightRec.material.emissive != vec3(0.0)) {
			// Note: Ideally the light should be multiplied by the probability that a random
			//       ray would hit it, but calculating that would be too heavy, so we instead
			//       estimate it to be proportional to 1/r², where r is the distance to the light.
			//       To make a better estimate, we could also multiply by the area that a projection
			//       of the light source would make on a unit sphere around us (divided by the area of a unit sphere),
			//       but that would be a heavy operation for quads, and, for spheres, this approximation is good enough
			//       for distant spheres, which are the only sphere types we use.
			col += brdf(-r.d, l, n, mat) * lightRec.material.emissive / (1.0 + lightDist * lightDist);
		}
	}

	return col;
}

#define MAX_BOUNCES 10

vec3 rayColor(Camera cam, Ray r) {
	HitRecord rec;
	vec3 col = vec3(0.0);
	vec3 throughput = vec3(1.0, 1.0, 1.0);

	for (int i = 0; i < MAX_BOUNCES; ++i) {
		if (worldHit(r, 0.001, 10000.0, rec)) {
			vec3 n = rec.normal;
			bool isInside = dot(r.d, n) > 0.0;
			vec3 ns = isInside ? -n : n;

			// Calculate direct lighting
			float cosTheta = dot(-r.d, ns);
			col += directLighting(cam, r, rec) * throughput * cosTheta;

			// Then the secondary ray
			Ray scatterRay;
			vec3 atten;
			if (!scatter(r, rec, atten, scatterRay)) {
				break;
			}

			throughput *= atten;
			r = scatterRay;

			// Russian roulette
			float russianRouletteChance = (1.0 - throughput.x) * (1.0 - throughput.y) * (1.0 - throughput.z);
			if (hash1(gSeed) < russianRouletteChance) {
				break;
			} else {
				throughput *= 1.0 / (1.0 - russianRouletteChance);
			}
		}

		// background
		else {
			col += worldBackground(r) * throughput;
			break;
		}
	}

	return col;
}

#define MAX_SAMPLES 10000.0

void main() {
	vec4 prev = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec3 prevLinear = toLinear(prev.xyz);

	vec4 rawInputOrbitZoom = texture(iChannel1, vec2(0.0, 0.0) / iResolution.xy);
	vec2 inputOrbitZoom = rawInputOrbitZoom.xy;

	vec4 rawInputVerticalFov = texture(iChannel2, vec2(0.0, 0.0) / iResolution.xy);
	float inputDist = rawInputVerticalFov.x;
	float inputFov = rawInputVerticalFov.y;
	float inputRoll = rawInputVerticalFov.z;

	vec4 rawInputTarget = texture(iChannel3, vec2(0.0, 0.0) / iResolution.xy);
	vec3 inputTarget = rawInputTarget.xyz;

	vec4 rawInputDof = texture(iChannel4, vec2(0.0, 0.0) / iResolution.xy);
	float inputAperture = rawInputDof.x;
	float inputDistToFocus = rawInputDof.y;

	bool inputHasChanged = rawInputOrbitZoom.xy != rawInputOrbitZoom.zw || rawInputVerticalFov.w == 1.0 ||
	                       rawInputTarget.w == 1.0 || rawInputDof.w == 1.0;

	// If we're done rendering and the input hasn't changed, return
	if (prev.w > MAX_SAMPLES && !inputHasChanged) {
		gl_FragColor = prev;
		return;
	}

	gSeed = float(baseHash(floatBitsToUint(gl_FragCoord.xy))) / float(0xffffffffU) + iTime;

	float camYaw = camDefaultYaw + ((-inputOrbitZoom.x + 0.5) * 2.0 - 1.0) * pi;
	float camPitch = camDefaultPitch + ((-inputOrbitZoom.y + 0.5) * 2.0 - 1.0) * pi;
	float camRoll = inputRoll * pi;

	float camDist = camDefaultDist + inputDist;
	vec3 camTarget = camDefaultPos + vec3(inputTarget.x, inputTarget.y, inputTarget.z);
	vec3 camPos = camTarget + camDist * vec3(sin(camYaw) * cos(camPitch), sin(camPitch), cos(camYaw) * cos(camPitch));
	vec3 camUp = vec3(sin(camRoll), cos(camRoll), 0.0);

	float fovy = camDefaultFovY + inputFov;
	float aperture = inputAperture;
	float distToFocus = camDefaultDistToFocus + inputDistToFocus;
	float time0 = 0.0;
	float time1 = 1.0;
	Camera cam = createCamera(
		camPos, camTarget, camUp, fovy, iResolution.x / iResolution.y, aperture, distToFocus, time0, time1
	);

	vec2 ps = gl_FragCoord.xy + hash2(gSeed);
	vec3 color = rayColor(cam, getRay(cam, ps));

	// If the user inputted anything, reset the scene to this color
	if (inputHasChanged) {
		gl_FragColor = vec4(toGamma(color), 1.0);
	}

	// Otherwise, mix the previous frame with this one
	else {
		float w = prev.w + 1.0;
		color = mix(prevLinear, color, 1.0 / w);
		gl_FragColor = vec4(toGamma(color), w);
	}
}
