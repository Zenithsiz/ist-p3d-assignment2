//! Shirley-Weekend scene

#include "objects.glsl"

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec) {
	bool hit = false;
	rec.t = tmax;

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

	return hit;
}
