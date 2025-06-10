//! Shirley-Weekend scene

#include "objects.glsl"

const float lightSize = 3.0;
const Sphere worldLights[] = Sphere[](
	Sphere(vec3(-10.0, 15.0, 0.0), lightSize),
	Sphere(vec3(8.0, 15.0, 3.0), lightSize),
	Sphere(vec3(1.0, 15.0, -9.0), lightSize)
);

const int worldLightsLen = worldLights.length();
vec3 worldRandLight(int lightIdx, inout float seed) {
	return sphereRandPoint(worldLights[lightIdx], seed);
}

bool worldHit(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

	// Lights
	for (int lightIdx = 0; lightIdx < worldLights.length(); lightIdx++) {
		if (sphereHit(worldLights[lightIdx], r, tmin, rec.t, rec)) {
			hit = true;
			rec.material = createDiffuseMaterial(vec3(0.0));
			rec.material.emissive = vec3(1.0f, 1.0f, 1.0f);
		}
	}

	if (quadHit(
			Quad(
				vec3(-10.0, -0.05, 10.0), vec3(10.0, -0.05, 10.0), vec3(10.0, -0.05, -10.0), vec3(-10.0, -0.05, -10.0)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.2));
	}

	if (sphereHit(Sphere(vec3(-4.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createPlasticMaterial(vec3(0.2, 0.95, 0.1), 0.7);
	}

	if (sphereHit(Sphere(vec3(4.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), 0.0);
	}

	if (sphereHit(Sphere(vec3(-1.5, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
	}

	if (sphereHit(Sphere(vec3(-1.5, 1.0, 0.0), -0.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
	}

	if (sphereHit(Sphere(vec3(1.5, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0, 0.9, 0.9), 1.5, 0.0);
	}

	int numxy = 4;

	float seed = 0.0;
	for (int x = -numxy; x < numxy; ++x) {
		for (int y = -numxy; y < numxy; ++y) {
			float fx = float(x);
			float fy = float(y);
			vec3 rand1 = hash3(seed);
			vec3 center = vec3(fx + 0.9 * rand1.x, 0.2, fy + 0.9 * rand1.y);
			float chooseMaterial = rand1.z;
			if (distance(center, vec3(4.0, 0.2, 0.0)) > 0.9) {
				if (chooseMaterial < 0.3) {
					vec3 center1 = center + vec3(0.0, hash1(gSeed) * 0.5, 0.0);
					// diffuse
					if (movingSphereHit(MovingSphere(center, center1, 0.2, 0.0, 1.0), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
					}
				} else if (chooseMaterial < 0.5) {
					// diffuse
					if (sphereHit(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
					}
				} else if (chooseMaterial < 0.7) {
					// metal
					if (sphereHit(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, 0.0);
					}
				} else if (chooseMaterial < 0.9) {
					// metal
					if (sphereHit(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, hash1(seed));
					}
				} else {
					// glass (Dielectric)
					if (sphereHit(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDielectricMaterial(hash3(seed), 1.33, 0.0);
					}
				}
			}
		}
	}

	return hit;
}

vec3 worldBackground(Ray r) {
	float t = 0.8 * (r.d.y + 1.0);
	return mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
}
