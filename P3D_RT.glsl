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
	// Start with the emissive color of the material
	vec3 col = rec.material.emissive;

	vec3 n = rec.normal;
	vec3 hitPos = rec.pos + n * epsilon;

	// Then for each light
	for (int lightIdx = 0; lightIdx < worldLights.length(); lightIdx++) {
		// Choose a random point in the light
		Quad light = worldLights[lightIdx];
		vec3 lightPos = quadRandPoint(light, gSeed);

		float lightDist = length(lightPos - hitPos);
		vec3 l = normalize(lightPos - hitPos);

		// If we hit the light, color it
		float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);
		Ray lightRay = Ray(hitPos, l, time);
		HitRecord lightRec;
		if (worldHit(lightRay, 0.001, lightDist + epsilon, lightRec) && lightRec.material.emissive != vec3(0.0)) {
			float cosTheta = dot(-r.d, rec.normal);
			col += brdfDiffuse(-r.d, l, rec.normal, rec.material) * lightRec.material.emissive * cosTheta;
		}
	}

	return col;
}

#define MAX_BOUNCES 10

vec3 rayColor(Camera cam, Ray r) {
	HitRecord rec;
	vec3 col = vec3(0.0);
	vec3 throughput = vec3(1.0f, 1.0f, 1.0f);

	for (int i = 0; i < MAX_BOUNCES; ++i) {
		if (worldHit(r, 0.001, 10000.0, rec)) {
			// Calculate direct lighting
			col += directLighting(cam, r, rec) * throughput;

			// Then the secondary ray
			Ray scatterRay;
			vec3 atten;
			if (!scatter(r, rec, atten, scatterRay)) {
				break;
			}

			throughput *= atten * dot(-r.d, rec.normal);
			r = scatterRay;
		}

		// background
		else {
#if SCENE == 0
			float t = 0.8 * (r.d.y + 1.0);
			col += throughput * mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
#elif SCENE == 1

			float pitch = asin(r.d.y);
			float yaw = atan(r.d.x, r.d.z);

			float pitchT = pitch / (2.0 * pi) + 0.5;
			float yawT = yaw / (2.0 * pi) + 0.5;

			int numLightsX = 30;
			float t = 1.0 / float(numLightsX);
			vec3 color;
			if (mod(yawT, t) / t < 0.5 && mod(pitchT, t) / t < 0.5) {
				color = vec3(0.8, 0.3, 0.1);
			} else {
				color = vec3(0.2, 0.7, 0.9);
			}

			col += throughput * color;
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

	float camYaw = ((-inputOrbitZoom.x + 0.5) * 2.0 - 1.0) * pi;
	float camPitch = ((-inputOrbitZoom.y + 0.5) * 2.0 - 1.0) * pi + radians(20.0);
	float camRoll = inputRoll * pi;

	float camDist = 10.0 + inputDist;
	vec3 camTarget = vec3(inputTarget.x, inputTarget.y, inputTarget.z);
	vec3 camPos = camTarget + camDist * vec3(sin(camYaw) * cos(camPitch), sin(camPitch), cos(camYaw) * cos(camPitch));
	vec3 camUp = vec3(sin(camRoll), cos(camRoll), 0.0);

	float fovy = radians(60.0 + inputFov);
	float aperture = inputAperture;
	float distToFocus = 1.0 + inputDistToFocus;
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
