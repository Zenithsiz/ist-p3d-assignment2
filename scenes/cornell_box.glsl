//! Cornell box scene

#include "objects.glsl"

const float wall_pos = 4.0;
const float wall_height = 6.0;

const vec3 lightSize = vec3(1.0, 0.0, 1.0) * 4.0;
const vec3 lightOffset = vec3(wall_pos, epsilon, wall_pos) - lightSize / 2.0;

const Quad worldLights[] = Quad[](Quad(
	vec3(-wall_pos + lightOffset.x, wall_height - lightOffset.y, -wall_pos + lightOffset.z + lightSize.z),
	vec3(-wall_pos + lightOffset.x, wall_height - lightOffset.y, -wall_pos + lightOffset.z),
	vec3(-wall_pos + lightOffset.x + lightSize.x, wall_height - lightOffset.y, -wall_pos + lightOffset.z),
	vec3(-wall_pos + lightOffset.x + lightSize.x, wall_height - lightOffset.y, -wall_pos + lightOffset.z + lightSize.z)
));

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

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

	// Lights
	if (hit_quad(worldLights[0], r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));

		float u = rec.coord.x;
		float v = rec.coord.y;
		float u2 = 4.0 * (u - 0.5) * (u - 0.5);
		float v2 = 4.0 * (v - 0.5) * (v - 0.5);
		float angle = atan(v - 0.5, u - 0.5);
		float len = length(vec2(u - 0.5, v - 0.5)) * 2.0;
		if (len < 1.0) {
			if (angle < 0.0) {
				rec.material.emissive = vec3(1.0, 1.0, 0.0) * 5.0;
			} else {
				rec.material.emissive = vec3(0.0, 0.0, 1.0) * 5.0;
			}
		}
	}

	if (hit_sphere(Sphere(vec3(-2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(0.1, 0.1, 0.9));
		rec.material.specColor = vec3(0.01);
	}

	if (hit_sphere(Sphere(vec3(2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), 0.0);
	}

	return hit;
}
