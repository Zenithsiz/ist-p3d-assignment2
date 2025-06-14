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
	Material mat = rec.material;

	vec3 n = rec.normal;
	bool isInside = dot(rIn.d, n) > 0.0;
	vec3 ns = isInside ? -n : n;

	if (mat.type == MT_DIFFUSE) {
		// Scatter the rays in a semi-hemisphere point at the normal
		rScattered.o = rec.pos + ns * epsilon;
		rScattered.d = randomUnitVector(gSeed);
		if (dot(rScattered.d, ns) < 0.0) {
			rScattered.d = -rScattered.d;
		}

		atten = brdf(-rIn.d, rScattered.d, ns, mat);

		return true;
	} else if (mat.type == MT_METAL) {
		// Reflected direction, with fuzzy reflections
		vec3 reflectedDir = reflect(rIn.d, ns);
		float alpha = mat.roughness * mat.roughness;
		reflectedDir += alpha * randomUnitVector(gSeed);

		rScattered.o = rec.pos + ns * epsilon;
		rScattered.d = normalize(reflectedDir);

		atten = brdf(-rIn.d, rScattered.d, ns, mat);

		return true;
	} else if (mat.type == MT_DIELECTRIC) {
		// TODO: Is this correct? I don't think
		//       we should assume that it's either the material or air.
		float n1 = isInside ? mat.refIdx : 1.0;
		float n2 = isInside ? 1.0 : mat.refIdx;

		vec3 v = -rIn.d;
		vec3 vt = dot(v, ns) * ns - v;
		float sinIncident = length(vt);
		float cosIncident = -dot(rIn.d, ns);
		float sinTheta = n1 / n2 * sinIncident;

		float cosTheta = sqrt(1.0 - sinTheta * sinTheta);

		float reflectProb = sinTheta > 1.0 ? 1.0 : schlick(cosTheta, pow((n1 - n2) / (n1 + n2), 2.0));

		// Reflection
		if (hash1(gSeed) < reflectProb) {
			// Reflected direction, with fuzzy reflections
			vec3 reflectedDir = reflect(rIn.d, ns);
			float alpha = mat.roughness * mat.roughness;
			reflectedDir += alpha * randomUnitVector(gSeed);

			rScattered.o = rec.pos + ns * epsilon;
			rScattered.d = reflectedDir;
		}

		// Refraction
		else {
			vec3 t = normalize(vt);

			rScattered.o = rec.pos - ns * epsilon;
			rScattered.d = sinTheta * t - cosTheta * ns;
		}

		atten = isInside ? exp(-mat.refractColor * rec.t) : vec3(1.0);

		return true;
	} else if (mat.type == MT_PLASTIC) {
		// Reflected direction with fuzzy reflections
		vec3 reflectedDir = reflect(rIn.d, ns);
		reflectedDir += mat.roughness * randomUnitVector(gSeed);

		rScattered.o = rec.pos + ns * epsilon;
		rScattered.d = normalize(reflectedDir);

		atten = brdf(-rIn.d, rScattered.d, ns, mat);

		return true;
	}

	return false;
}

#endif
