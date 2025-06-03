//! Scatter

#ifndef SCATTER_H
#define SCATTER_H

#include "camera.glsl"
#include "material.glsl"
#include "objects.glsl"
#include "rand.glsl"

float schlick(float cosine, float f0) {
	return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

vec3 schlick3(float cosine, vec3 f0) {
	return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

/// Normalizing distribution function
float ndf_ggx(float noh, float roughness) {
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float noh2 = noh * noh;
	float b = (noh2 * (alpha2 - 1.0) + 1.0);
	return alpha2 / (pi * b * b);
}

float geometry_smith_schlick(float nov, float roughness) {
	float alpha = roughness * roughness;
	float k = alpha * sqrt(2.0 / pi);
	return nov / (nov * (1.0 - k) + k + epsilon);
}

float geometry_smith(float nov, float nol, float roughness) {
	return geometry_smith_schlick(nol, roughness) * geometry_smith_schlick(nov, roughness);
}

#define BRDF 3

vec3 brdf_microfacet(vec3 v, vec3 l, vec3 n, Material mat) {
	vec3 h = normalize(v + l);

	float nov = max(dot(n, v), 0.0);
	float nol = max(dot(n, l), 0.0);
	float noh = max(dot(n, h), 0.0);
	float voh = max(dot(v, h), 0.0);

	vec3 f0 = 0.16 * mat.specColor * mat.specColor;

	vec3 f = schlick3(voh, f0);
	float d = ndf_ggx(noh, mat.roughness);
	float g = geometry_smith(nov, nol, mat.roughness);

	vec3 specColor = vec3(f * d * g) / (4.0 * max(nov, epsilon) * max(nol, epsilon));

	vec3 diffColor = mat.albedo * max(dot(l, n), 0.0) * (1.0 - f) / pi;

	return mat.emissive + diffColor + specColor;
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

		atten = brdf_microfacet(-rIn.d, rScattered.d, rec.normal, rec.material);
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

#endif
