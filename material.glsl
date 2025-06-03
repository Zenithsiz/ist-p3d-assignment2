//! Material definition

#ifndef MATERIAL_H
#define MATERIAL_H

// MT_ material type
#define MT_DIFFUSE 0
#define MT_METAL 1
#define MT_DIELECTRIC 2

struct Material {
	int type;
	vec3 albedo;       // diffuse color
	vec3 specColor;    // the color tint for specular reflections. for metals and
	                   // opaque dieletrics like coloured glossy plastic
	vec3 emissive;     //
	float roughness;   // controls roughness for metals. It can be used for rough
	                   // refractions
	float refIdx;      // index of refraction for Dielectric
	vec3 refractColor; // absorption for beer's law
};

Material createDiffuseMaterial(vec3 albedo) {
	Material m;
	m.type = MT_DIFFUSE;
	m.albedo = albedo;
	m.specColor = vec3(0.0);
	m.roughness = 1.0;
	m.refIdx = 1.0;
	m.refractColor = vec3(0.0);
	m.emissive = vec3(0.0);
	return m;
}

Material createMetalMaterial(vec3 specClr, float roughness) {
	Material m;
	m.type = MT_METAL;
	m.albedo = vec3(0.0);
	m.specColor = specClr;
	m.roughness = roughness;
	m.emissive = vec3(0.0);
	return m;
}

Material createDielectricMaterial(vec3 refractClr, float refIdx, float roughness) {
	Material m;
	m.type = MT_DIELECTRIC;
	m.albedo = vec3(0.0);
	m.specColor = vec3(0.04);
	m.refIdx = refIdx;
	m.refractColor = refractClr;
	m.roughness = roughness;
	m.emissive = vec3(0.0);
	return m;
}

#endif
