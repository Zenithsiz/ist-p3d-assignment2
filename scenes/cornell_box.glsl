//! Cornell box scene

#include "objects.glsl"

const float wallPos = 4.0;
const float wallHeight = 6.0;

const vec3 lightSize = vec3(1.0, 0.0, 1.0) * 4.0;
const vec3 lightOffset = vec3(wallPos, 2.0 * epsilon, wallPos) - lightSize / 2.0;

const Quad worldLights[] = Quad[](Quad(
	vec3(-wallPos + lightOffset.x, wallHeight - lightOffset.y, -wallPos + lightOffset.z + lightSize.z),
	vec3(-wallPos + lightOffset.x, wallHeight - lightOffset.y, -wallPos + lightOffset.z),
	vec3(-wallPos + lightOffset.x + lightSize.x, wallHeight - lightOffset.y, -wallPos + lightOffset.z),
	vec3(-wallPos + lightOffset.x + lightSize.x, wallHeight - lightOffset.y, -wallPos + lightOffset.z + lightSize.z)
));

const int worldLightsLen = worldLights.length();
vec3 worldRandLight(int lightIdx, inout float seed) {
	return quadRandPoint(worldLights[lightIdx], seed);
}

bool worldHit(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

	// Bottom
	if (quadHit(
			Quad(
				vec3(-wallPos, 0.0, wallPos),
				vec3(wallPos, 0.0, wallPos),
				vec3(wallPos, 0.0, -wallPos),
				vec3(-wallPos, 0.0, -wallPos)
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
	if (quadHit(
			Quad(
				vec3(wallPos, wallHeight, -wallPos),
				vec3(wallPos, wallHeight, wallPos),
				vec3(-wallPos, wallHeight, wallPos),
				vec3(-wallPos, wallHeight, -wallPos)
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
	if (quadHit(
			Quad(
				vec3(-wallPos, wallHeight, wallPos),
				vec3(-wallPos, 0.0, wallPos),
				vec3(-wallPos, 0.0, -wallPos),
				vec3(-wallPos, wallHeight, -wallPos)
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
	if (quadHit(
			Quad(
				vec3(wallPos, 0.0, wallPos),
				vec3(wallPos, wallHeight, wallPos),
				vec3(wallPos, wallHeight, -wallPos),
				vec3(wallPos, 0.0, -wallPos)
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
	if (quadHit(
			Quad(
				vec3(wallPos, 0.0, -wallPos),
				vec3(wallPos, wallHeight, -wallPos),
				vec3(-wallPos, wallHeight, -wallPos),
				vec3(-wallPos, 0.0, -wallPos)
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
	if (quadHit(worldLights[0], r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));

		float u = rec.coord.x;
		float v = rec.coord.y;
		float u2 = 4.0 * (u - 0.5) * (u - 0.5);
		float v2 = 4.0 * (v - 0.5) * (v - 0.5);
		float angle = atan(v - 0.5, u - 0.5);
		float len = length(vec2(u - 0.5, v - 0.5)) * 2.0;
		if (len < 1.0) {
			float lightStrength = 20.0;
			if (angle < 0.0) {
				rec.material.emissive = vec3(1.0, 1.0, 0.0) * lightStrength;
			} else {
				rec.material.emissive = vec3(0.0, 0.0, 1.0) * lightStrength;
			}
		}
	}

	if (sphereHit(Sphere(vec3(-2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createPlasticMaterial(vec3(0.1, 0.1, 0.9), 0.5);
	}

	if (sphereHit(Sphere(vec3(0.0, 1.5, 1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.5);
	}

	if (sphereHit(Sphere(vec3(2.0, 1.5, -1.5), 1.5), r, tmin, rec.t, rec)) {
		hit = true;
		rec.material = createMetalMaterial(vec3(0.955, 0.638, 0.538), 0.0);
	}

	return hit;
}

vec3 worldBackground(Ray r) {
	return vec3(0.0);
}
