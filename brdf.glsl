
#include "camera.glsl"
#include "material.glsl"

vec3 schlick3(float cosine, vec3 f0) {
	return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

/// Normalizing distribution function
float ndfGgx(float noh, float roughness) {
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float noh2 = noh * noh;
	float b = (noh2 * (alpha2 - 1.0) + 1.0);
	return alpha2 / (pi * b * b + epsilon);
}

float geometrySmithSchlick(float nov, float roughness) {
	float alpha = roughness * roughness;
	float k = alpha * sqrt(2.0 / pi);
	return nov / (nov * (1.0 - k) + k + epsilon);
}

float geometrySmith(float nov, float nol, float roughness) {
	return geometrySmithSchlick(nol, roughness) * geometrySmithSchlick(nov, roughness);
}

#define BRDF 3

vec3 brdfMicrofacet(vec3 v, vec3 l, vec3 n, Material mat) {
	vec3 h = normalize(v + l);

	float nov = max(dot(n, v), 0.0);
	float nol = max(dot(n, l), 0.0);
	float noh = max(dot(n, h), 0.0);
	float voh = max(dot(v, h), 0.0);

	vec3 f0 = 0.16 * mat.specColor * mat.specColor;

	vec3 f = schlick3(voh, f0);
	float d = ndfGgx(noh, mat.roughness);
	float g = geometrySmith(nov, nol, mat.roughness);

	vec3 specColor = vec3(f * d * g) / (4.0 * max(nov, epsilon) * max(nol, epsilon));

	vec3 diffColor = mat.albedo * max(dot(l, n), 0.0) * (1.0 - f) / pi;

	return mat.emissive + diffColor + specColor;
}
