//! Camera

#ifndef CAMERA_H
#define CAMERA_H

#include "rand.glsl"

// TODO: Move these elsewhere
const float pi = 3.14159265358979;
const float epsilon = 0.001;

struct Camera {
	vec3 eye;
	vec3 u, v, n;
	float width, height;
	float lensRadius;
	float planeDist, focusDist;
	float time0, time1;
};

Camera createCamera(
	vec3 eye,
	vec3 at,
	vec3 worldUp,
	float fovy,
	float aspect,
	float aperture,  // diametro em multiplos do pixel size
	float focusDist, // focal ratio
	float time0,
	float time1
) {
	Camera cam;
	if (aperture == 0.0) {
		cam.focusDist = 1.0; // pinhole camera then focus in on vis plane
	} else {
		cam.focusDist = focusDist;
	}
	vec3 w = eye - at;
	cam.planeDist = length(w);
	cam.height = 2.0 * cam.planeDist * tan(fovy * 0.5);
	cam.width = aspect * cam.height;

	cam.lensRadius =
		aperture * 0.5 * cam.width / iResolution.x; // aperture ratio * pixel size; (1 pixel=lente raio 0.5)
	cam.eye = eye;
	cam.n = normalize(w);
	cam.u = normalize(cross(worldUp, cam.n));
	cam.v = cross(cam.n, cam.u);
	cam.time0 = time0;
	cam.time1 = time1;
	return cam;
}

struct Ray {
	vec3 o;  // origin
	vec3 d;  // direction - always set with normalized vector
	float t; // time, for motion blur
};

vec3 pointOnRay(Ray r, float t) {
	return r.o + r.d * t;
}

Ray getRay(Camera cam, vec2 pixelSample) {
	vec2 ls = cam.lensRadius * randomInUnitDisk(gSeed);
	float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);

	float d = cam.planeDist;
	float f = d * cam.focusDist;

	vec3 ps = vec3(
		cam.width * ((pixelSample.x + 0.5) / iResolution.x - 0.5),
		cam.height * ((pixelSample.y + 0.5) / iResolution.y - 0.5),
		-d
	);

	vec3 p = ps * cam.focusDist;

	vec3 eyeOffset = cam.eye + ls.x * cam.u + ls.y * cam.v;
	vec3 rayDir = (p.x - ls.x) * cam.u + (p.y - ls.y) * cam.v - f * cam.n;

	return Ray(eyeOffset, normalize(rayDir), time);
}

#endif
