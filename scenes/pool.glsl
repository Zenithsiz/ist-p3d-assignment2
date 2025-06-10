//! Cornell box scene

#include "objects.glsl"

const float poolWidth = 20.0;
const float poolDepth = 2.5;

const float wallHeight = 20.0;
const float wallPoolDist = 10.0 * epsilon;
const float wallDepth = poolDepth + wallPoolDist;
const float wallWidth = poolWidth + wallPoolDist;

const Quad worldLights[] = Quad[](Quad(
	vec3(wallWidth / 2.0, wallHeight, -wallWidth / 2.0),
	vec3(wallWidth / 2.0, wallHeight, wallWidth / 2.0),
	vec3(-wallWidth / 2.0, wallHeight, wallWidth / 2.0),
	vec3(-wallWidth / 2.0, wallHeight, -wallWidth / 2.0)
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
				vec3(-wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
				vec3(wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
				vec3(wallWidth / 2.0, -wallDepth, -wallWidth / 2.0),
				vec3(-wallWidth / 2.0, -wallDepth, -wallWidth / 2.0)
			),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDiffuseMaterial(vec3(1.0));
	}

	// Walls
	const Quad walls[] = Quad[](
		// Back
		Quad(
			vec3(-wallWidth / 2.0, -wallDepth, -wallWidth / 2.0),
			vec3(wallWidth / 2.0, -wallDepth, -wallWidth / 2.0),
			vec3(wallWidth / 2.0, wallHeight, -wallWidth / 2.0),
			vec3(-wallWidth / 2.0, wallHeight, -wallWidth / 2.0)
		),

		// Front
		Quad(
			vec3(wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
			vec3(-wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
			vec3(-wallWidth / 2.0, wallHeight, wallWidth / 2.0),
			vec3(wallWidth / 2.0, wallHeight, wallWidth / 2.0)
		),

		// Left
		Quad(
			vec3(-wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
			vec3(-wallWidth / 2.0, -wallDepth, -wallWidth / 2.0),
			vec3(-wallWidth / 2.0, wallHeight, -wallWidth / 2.0),
			vec3(-wallWidth / 2.0, wallHeight, wallWidth / 2.0)
		),

		// Right
		Quad(
			vec3(wallWidth / 2.0, -wallDepth, -wallWidth / 2.0),
			vec3(wallWidth / 2.0, -wallDepth, wallWidth / 2.0),
			vec3(wallWidth / 2.0, wallHeight, wallWidth / 2.0),
			vec3(wallWidth / 2.0, wallHeight, -wallWidth / 2.0)
		)
	);
	for (int i = 0; i < walls.length(); i++) {
		if (quadHit(walls[i], r, tmin, rec.t, rec)) {
			hit = true;

			float aspectRatio = wallWidth / (wallDepth + wallHeight);
			int tilesX = 10;

			float modX = mod(rec.coord.x, 1.0 / float(tilesX)) * float(tilesX);
			float modY = mod(rec.coord.y / aspectRatio, 1.0 / float(tilesX)) * float(tilesX);

			vec3 blue = vec3(0.1, 0.63, 0.73);
			vec3 color = blue * (modX < 0.1 || modX > 0.9 || modY < 0.1 || modY > 0.9 ? 1.0 : 0.8);

			rec.material = createDiffuseMaterial(vec3(color));
		}
	}

	// Pool
	if (aabbHit(
			AABB(vec3(-poolWidth / 2.0, -poolDepth, -poolWidth / 2.0), vec3(poolWidth / 2.0, 0.0, poolWidth / 2.0)),
			r,
			tmin,
			rec.t,
			rec
		)) {
		hit = true;
		rec.material = createDielectricMaterial(vec3(0.1, 0.0, 0.0), 1.5, 0.0);
	}

	// Lights
	for (int lightIdx = 0; lightIdx < worldLights.length(); lightIdx++) {
		if (quadHit(worldLights[lightIdx], r, tmin, rec.t, rec)) {
			hit = true;
			rec.material = createDiffuseMaterial(vec3(0.0));
			rec.material.emissive = vec3(1.0f, 1.0f, 1.0f) * 10.0;
		}
	}

	return hit;
}

vec3 worldBackground(Ray r) {
	return vec3(0.0);
}
