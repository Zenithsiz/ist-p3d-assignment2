//! Scatter

#ifndef SCATTER_H
#define SCATTER_H

#include "brdf.glsl"
#include "camera.glsl"
#include "material.glsl"
#include "objects.glsl"
#include "rand.glsl"

float schlick(float cosine, float f0) {
	return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

bool scatter(Ray rIn, HitRecord rec, out vec3 atten, out Ray rScattered) {
	bool isInside = dot(rIn.d, rec.normal) > 0.0;
	vec3 ns = isInside ? -rec.normal : rec.normal;

	if (rec.material.type == MT_DIFFUSE) {
		rScattered.o = rec.pos + ns * epsilon;

		rScattered.d = randomUnitVector(gSeed);
		if (dot(rScattered.d, rec.normal) < 0.0) {
			rScattered.d = -rScattered.d;
		}

		atten = brdfMicrofacet(-rIn.d, rScattered.d, rec.normal, rec.material);
		return true;
	} else if (rec.material.type == MT_METAL) {
		atten = rec.material.specColor;

		// Reflected direction
		vec3 reflectedDir = reflect(rIn.d, rec.normal);

		// Fuzzy reflections
		reflectedDir += rec.material.roughness * randomUnitVector(gSeed);

		rScattered.o = rec.pos + ns * epsilon;
		rScattered.d = normalize(reflectedDir);

		return true;
	} else if (rec.material.type == MT_DIELECTRIC) {
		// TODO: Is this correct? I don't think
		//       we should assume that it's either the material or air.
		float n1 = isInside ? rec.material.refIdx : 1.0;
		float n2 = isInside ? 1.0 : rec.material.refIdx;

		atten = isInside ? exp(-rec.material.refractColor * rec.t) : vec3(1.0);

		vec3 v = -rIn.d;
		vec3 vt = dot(v, ns) * ns - v;
		float sinIncident = length(vt);
		float cosIncident = -dot(rIn.d, ns);
		float sinTheta = n1 / n2 * sinIncident;

		float cosTheta = sqrt(1.0 - sinTheta * sinTheta);

		// TODO: Is this the correct argument to pass to schlick?
		float reflectProb = sinTheta > 1.0 ? 1.0 : schlick(cosTheta, pow((n1 - n2) / (n1 + n2), 2.0));

		// Reflection
		if (hash1(gSeed) < reflectProb) {
			vec3 reflectedDir = reflect(rIn.d, rec.normal);

			rScattered.o = rec.pos + rec.normal * epsilon;
			rScattered.d = reflectedDir;
		}

		// Refraction
		else {
			vec3 t = normalize(vt);

			rScattered.o = rec.pos - ns * epsilon;
			rScattered.d = sinTheta * t - cosTheta * ns;
		}

		return true;
	} else if (rec.material.type == MT_PLASTIC) {
		// Reflected direction
		vec3 reflectedDir = reflect(rIn.d, rec.normal);

		// Fuzzy reflections
		reflectedDir += rec.material.roughness * randomUnitVector(gSeed);

		rScattered.o = rec.pos + ns * epsilon;
		rScattered.d = normalize(reflectedDir);

		atten = brdfMicrofacet(-rIn.d, rScattered.d, rec.normal, rec.material);

		return true;
	}
	return false;
}

#endif
