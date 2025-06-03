/**
 * common.glsl
 * Common types and functions used for ray tracing.
 */

#include "./camera.glsl"
#include "./material.glsl"
#include "./objects.glsl"
#include "./rand.glsl"


float schlick(float cosine, float refIdx) {
	return refIdx + (1.0 - refIdx) * pow(1.0 - cosine, 5.0);
}

bool scatter(Ray rIn, HitRecord rec, out vec3 atten, out Ray rScattered) {
	bool isInside = dot(rIn.d, rec.normal) > 0.0;
	vec3 n_s = isInside ? -rec.normal : rec.normal;

	if (rec.material.type == MT_DIFFUSE) {
		rScattered.o = rec.pos + n_s * epsilon;

		rScattered.d = randomUnitVector(gSeed);
		if (dot(rScattered.d, rec.normal) < 0.0) {
			rScattered.d = -rScattered.d;
		}

		vec3 diffCol = rec.material.albedo * max(dot(rScattered.d, rec.normal), 0.0) / pi;

		// Reflected direction
		vec3 reflected_dir = reflect(-rScattered.d, rec.normal);
		reflected_dir += rec.material.roughness * randomUnitVector(gSeed);
		vec3 specCol = rec.material.specColor * pow(max(dot(reflected_dir, -rIn.d), 0.0), 5.0);

		atten = diffCol + specCol;
		return true;
	}
	if (rec.material.type == MT_METAL) {
		atten = rec.material.specColor;

		// Reflected direction
		vec3 reflected_dir = reflect(rIn.d, rec.normal);

		// Fuzzy reflections
		reflected_dir += rec.material.roughness * randomUnitVector(gSeed);

		rScattered.o = rec.pos + n_s * epsilon;
		rScattered.d = normalize(reflected_dir);

		return true;
	}
	if (rec.material.type == MT_DIELECTRIC) {
		// TODO: Is this correct? I don't think
		//       we should assume that it's either the material or air.
		float n1 = isInside ? rec.material.refIdx : 1.0;
		float n2 = isInside ? 1.0 : rec.material.refIdx;

		atten = isInside ? exp(-rec.material.refractColor * rec.t) : vec3(1.0);

		vec3 v = -rIn.d;
		vec3 v_t = dot(v, n_s) * n_s - v;
		float sin_incident = length(v_t);
		float cos_incident = -dot(rIn.d, rec.normal);
		float sin_theta = n1 / n2 * sin_incident;

		float cos_theta = sqrt(1.0 - sin_theta * sin_theta);

		// TODO: Is this the correct argument to pass to schlick?
		float reflectProb = sin_theta > 1.0 ? 1.0 : schlick(cos_theta, pow((n1 - n2) / (n1 + n2), 2.0));

		// Reflection
		if (hash1(gSeed) < reflectProb) {
			vec3 reflected_dir = reflect(rIn.d, rec.normal);

			rScattered.o = rec.pos + rec.normal * epsilon;
			rScattered.d = reflected_dir;
		}

		// Refraction
		else {
			vec3 t = normalize(v_t);

			rScattered.o = rec.pos - n_s * epsilon;
			rScattered.d = sin_theta * t - cos_theta * n_s;
		}

		return true;
	}
	return false;
}
