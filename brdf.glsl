
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
	float b = noh2 * (alpha2 - 1.0) + 1.0;
	return alpha2 / (pi * b * b);
}

float geometrySmithSchlick(float d, float roughness) {
	float k = roughness * roughness / 2.0;
	return d / (d * (1.0 - k) + k);
}

float geometrySmith(float nov, float nol, float roughness) {
	return geometrySmithSchlick(nol, roughness) * geometrySmithSchlick(nov, roughness);
}

// Calculates the diffuse-only brdf, without any emissive or diffuse.
vec3 brdfDiffuse(vec3 v, vec3 l, vec3 n, Material mat) {
	return mat.albedo / pi;
}

// Calculates the specular-only brdf, without emissive or diffuse.
//
// Returns the `f` parameter from the schlick calculation.
vec3 brdfSpecular(vec3 v, vec3 l, vec3 n, Material mat, out vec3 f) {
	float lightDist = 1.0; // length(lightPos - hitPos);
	vec3 h = normalize(v + l);

	float nov = max(dot(n, v), 0.0);
	float nol = max(dot(n, l), 0.0);
	float noh = max(dot(n, h), 0.0);
	float voh = max(dot(v, h), 0.0);

	float roughness = max(mat.roughness, epsilon);

	f = schlick3(voh, mat.specColor);
	float ndf = noh > 1.0 - epsilon ? 1.0 : ndfGgx(noh, roughness);
	float g = geometrySmith(nov, nol, roughness);

	// TODO: Even with ` + epsilon` here, we still get some NaNs
	//       at some places.
	return (f * ndf * g) / (4.0 * nov * nol + epsilon);
}

// Calculates the full brdf with both reflective and specular components
vec3 brdf(vec3 v, vec3 l, vec3 n, Material mat) {
	vec3 f;
	vec3 diffColor = brdfDiffuse(v, l, n, mat);
	vec3 specColor = brdfSpecular(v, l, n, mat, f);

	return diffColor * (1.0 - f) + specColor;
}
