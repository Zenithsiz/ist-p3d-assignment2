//! Shirley-Weekend scene

#include "objects.glsl"

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

	// Light up in the sky
	// TODO: Use a point light here once we
	//       can efficiently use those.
	float lightSize = 1.5;
	vec3 lightOffset = vec3(0.0, 5.0, 0.0);
	if (hit_quad(
			Quad(
				vec3(lightOffset.x - lightSize, lightOffset.y, lightOffset.z + lightSize),
				vec3(lightOffset.x - lightSize, lightOffset.y, lightOffset.z - lightSize),
				vec3(lightOffset.x + lightSize, lightOffset.y, lightOffset.z - lightSize),
				vec3(lightOffset.x + lightSize, lightOffset.y, lightOffset.z + lightSize)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.0));
		rec.material.emissive = vec3(1.0f, 1.0f, 1.0f) * 50.0f;
	}

	if (hit_quad(
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

	if (hit_sphere(Sphere(vec3(-4.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.2, 0.95, 0.1));
		// rec.material = createDiffuseMaterial(vec3(0.4, 0.2, 0.1));
	}

	if (hit_sphere(Sphere(vec3(4.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), 0.0);
	}

	if (hit_sphere(Sphere(vec3(-1.5, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
	}

	if (hit_sphere(Sphere(vec3(-1.5, 1.0, 0.0), -0.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
	}

	if (hit_sphere(Sphere(vec3(1.5, 1.0, 0.0), 1.0), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0, 0.9, 0.9), 1.5, 0.0);
	}

	int numxy = 5;

	for (int x = -numxy; x < numxy; ++x) {
		for (int y = -numxy; y < numxy; ++y) {
			float fx = float(x);
			float fy = float(y);
			float seed = fx + fy / 1000.0;
			vec3 rand1 = hash3(seed);
			vec3 center = vec3(fx + 0.9 * rand1.x, 0.2, fy + 0.9 * rand1.y);
			float chooseMaterial = rand1.z;
			if (distance(center, vec3(4.0, 0.2, 0.0)) > 0.9) {
				if (chooseMaterial < 0.3) {
					vec3 center1 = center + vec3(0.0, hash1(gSeed) * 0.5, 0.0);
					// diffuse
					if (hit_movingSphere(MovingSphere(center, center1, 0.2, 0.0, 1.0), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
					}
				} else if (chooseMaterial < 0.5) {
					// diffuse
					if (hit_sphere(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
					}
				} else if (chooseMaterial < 0.7) {
					// metal
					if (hit_sphere(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, 0.0);
					}
				} else if (chooseMaterial < 0.9) {
					// metal
					if (hit_sphere(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, hash1(seed));
					}
				} else {
					// glass (Dielectric)
					if (hit_sphere(Sphere(center, 0.2), r, tmin, rec.t, rec)) {
						hit = true;
						rec.material = createDielectricMaterial(hash3(seed), 1.33, 0.0);
					}
				}
			}
		}
	}

	return hit;
}
