//! Scene definition

#ifndef SCENE_H
#define SCENE_H

#include "camera.glsl"
#include "objects.glsl"

#define SCENE 2

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

#if SCENE == 0 // Shirley Weekend scene
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
					if (hit_movingSphere(createMovingSphere(center, center1, 0.2, 0.0, 1.0), r, tmin, rec.t, rec)) {
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

#elif SCENE == 1
	// from
	// https://blog.demofox.org/2020/06/14/casual-shadertoy-path-tracing-3-fresnel-rough-refraction-absorption-orbit-camera/

	// diffuse floor

	vec3 A = vec3(-25.0f, -12.5f, 10.0f);
	vec3 B = vec3(25.0f, -12.5f, 10.0f);
	vec3 C = vec3(25.0f, -12.5f, -5.0f);
	vec3 D = vec3(-25.0f, -12.5f, -5.0f);

	if (hit_quad(Quad(A, B, C, D), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.7));
	}

	// stripped background
	{
		vec3 A = vec3(-25.0f, -10.5f, -5.0f);
		vec3 B = vec3(25.0f, -10.5f, -5.0f);
		vec3 C = vec3(25.0f, -1.5f, -5.0f);
		vec3 D = vec3(-25.0f, -1.5f, -5.0f);

		if (hit_quad(Quad(A, B, C, D), r, tmin, rec.t, rec)) {
			hit = true;
			float shade = floor(mod(rec.pos.x, 1.0f) * 2.0f);
			rec.material = createDiffuseMaterial(vec3(shade));
		}
	}

	// ceiling piece above light

	{
		vec3 A = vec3(-7.5f, 12.5f, 5.0f);
		vec3 B = vec3(7.5f, 12.5f, 5.0f);
		vec3 C = vec3(7.5f, 12.5f, -5.0f);
		vec3 D = vec3(-7.5f, 12.5f, -5.0f);

		if (hit_quad(Quad(A, B, C, D), r, tmin, rec.t, rec)) {
			hit = true;
			rec.material = createDiffuseMaterial(vec3(0.7));
		}
	}

	// light

	{
		vec3 A = vec3(-5.0f, 12.3f, 2.5f);
		vec3 B = vec3(5.0f, 12.3f, 2.5f);
		vec3 C = vec3(5.0f, 12.3f, -2.5f);
		vec3 D = vec3(-5.0f, 12.3f, -2.5f);

		if (hit_quad(Quad(A, B, C, D), r, tmin, rec.t, rec)) {
			hit = true;
			rec.material = createDiffuseMaterial(vec3(0.0));
			rec.material.emissive = vec3(1.0f, 0.9f, 0.9f) * 20.0f;
		}
	}

	const int c_numSpheres = 7;
	for (int sphereIndex = 0; sphereIndex < c_numSpheres; ++sphereIndex) {
		vec3 center = vec3(-18.0 + 6.0 * float(sphereIndex), -8.0, 0.0);
		if (hit_sphere(Sphere(center, 2.8), r, tmin, rec.t, rec)) {
			hit = true;
			float r = float(sphereIndex) / float(c_numSpheres - 1) * 0.1f;
			rec.material = createDielectricMaterial(vec3(0.0, 0.5, 1.0), 1.1, r);
		}
	}

#elif SCENE == 2
	float wall_pos = 4.0;
	float wall_height = 6.0;

	// Bottom
	if (hit_quad(
			Quad(
				vec3(-wall_pos, 0.0, wall_pos),
				vec3(wall_pos, 0.0, wall_pos),
				vec3(wall_pos, 0.0, -wall_pos),
				vec3(-wall_pos, 0.0, -wall_pos)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));
	}

	// Top
	if (hit_quad(
			Quad(
				vec3(wall_pos, wall_height, -wall_pos),
				vec3(wall_pos, wall_height, wall_pos),
				vec3(-wall_pos, wall_height, wall_pos),
				vec3(-wall_pos, wall_height, -wall_pos)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));
	}

	// Left
	if (hit_quad(
			Quad(
				vec3(-wall_pos, wall_height, wall_pos),
				vec3(-wall_pos, 0.0, wall_pos),
				vec3(-wall_pos, 0.0, -wall_pos),
				vec3(-wall_pos, wall_height, -wall_pos)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.9, 0.1, 0.1));
	}

	// Right
	if (hit_quad(
			Quad(
				vec3(wall_pos, 0.0, wall_pos),
				vec3(wall_pos, wall_height, wall_pos),
				vec3(wall_pos, wall_height, -wall_pos),
				vec3(wall_pos, 0.0, -wall_pos)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.1, 0.9, 0.1));
	}

	// Back
	if (hit_quad(
			Quad(
				vec3(wall_pos, 0.0, -wall_pos),
				vec3(wall_pos, wall_height, -wall_pos),
				vec3(-wall_pos, wall_height, -wall_pos),
				vec3(-wall_pos, 0.0, -wall_pos)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));
	}

	// Light
	float lightSize = 2.0;
	if (hit_quad(
			Quad(
				vec3(-lightSize, wall_height - 0.05, lightSize),
				vec3(-lightSize, wall_height - 0.05, -lightSize),
				vec3(lightSize, wall_height - 0.05, -lightSize),
				vec3(lightSize, wall_height - 0.05, lightSize)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.0));
		rec.material.emissive = vec3(1.0f, 1.0f, 1.0f) * 20.0f;
	}

	if (hit_sphere(Sphere(vec3(-2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.1, 0.1, 0.9));
		rec.material.specColor = vec3(0.05);
	}

	if (hit_sphere(Sphere(vec3(2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), 0.0);
	}

#elif SCENE == 3
#endif

	return hit;
}

#endif
