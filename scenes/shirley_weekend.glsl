//! Shirley-Weekend scene

#include "objects.glsl"

const vec3 worldLightsPos[] = vec3[](vec3(-10.0, 15.0, 0.0), vec3(8.0, 15.0, 3.0), vec3(1.0, 15.0, -9.0));
const Quad worldLights[] = Quad[](
	Quad(
		vec3(worldLightsPos[0].x + epsilon, worldLightsPos[0].y, worldLightsPos[0].z - epsilon),
		vec3(worldLightsPos[0].x + epsilon, worldLightsPos[0].y, worldLightsPos[0].z + epsilon),
		vec3(worldLightsPos[0].x - epsilon, worldLightsPos[0].y, worldLightsPos[0].z + epsilon),
		vec3(worldLightsPos[0].x - epsilon, worldLightsPos[0].y, worldLightsPos[0].z - epsilon)
	),
	Quad(
		vec3(worldLightsPos[1].x + epsilon, worldLightsPos[1].y, worldLightsPos[1].z - epsilon),
		vec3(worldLightsPos[1].x + epsilon, worldLightsPos[1].y, worldLightsPos[1].z + epsilon),
		vec3(worldLightsPos[1].x - epsilon, worldLightsPos[1].y, worldLightsPos[1].z + epsilon),
		vec3(worldLightsPos[1].x - epsilon, worldLightsPos[1].y, worldLightsPos[1].z - epsilon)
	),
	Quad(
		vec3(worldLightsPos[2].x + epsilon, worldLightsPos[2].y, worldLightsPos[2].z - epsilon),
		vec3(worldLightsPos[2].x + epsilon, worldLightsPos[2].y, worldLightsPos[2].z + epsilon),
		vec3(worldLightsPos[2].x - epsilon, worldLightsPos[2].y, worldLightsPos[2].z + epsilon),
		vec3(worldLightsPos[2].x - epsilon, worldLightsPos[2].y, worldLightsPos[2].z - epsilon)
	)
);

bool worldHit(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

	// Lights
	for (int lightIdx = 0; lightIdx < worldLights.length(); lightIdx++) {
		if (quadHit(worldLights[lightIdx], r, tmin, rec.t, rec)) {
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
		rec.material = createDiffuseMaterial(vec3(0.2, 0.95, 0.1));
		rec.material.specColor = vec3(0.04);
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
