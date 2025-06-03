//! Cornell box scene

#include "objects.glsl"

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

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

	return hit;
}
