/**
 * common.glsl
 * Common types and functions used for ray tracing.
 */

const float pi = 3.14159265358979;
const float epsilon = 0.001;

struct Ray {
	vec3 o;  // origin
	vec3 d;  // direction - always set with normalized vector
	float t; // time, for motion blur
};

Ray createRay(vec3 o, vec3 d, float t) {
	Ray r;
	r.o = o;
	r.d = d;
	r.t = t;
	return r;
}

Ray createRay(vec3 o, vec3 d) {
	return createRay(o, d, 0.0);
}

vec3 pointOnRay(Ray r, float t) {
	return r.o + r.d * t;
}

float gSeed = 0.0;

uint baseHash(uvec2 p) {
	p = 1103515245U * ((p >> 1U) ^ (p.yx));
	uint h32 = 1103515245U * ((p.x) ^ (p.y >> 3U));
	return h32 ^ (h32 >> 16);
}

float hash1(inout float seed) {
	uint n = baseHash(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
	return float(n) / float(0xffffffffU);
}

vec2 hash2(inout float seed) {
	uint n = baseHash(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
	uvec2 rz = uvec2(n, n * 48271U);
	return vec2(rz.xy & uvec2(0x7fffffffU)) / float(0x7fffffff);
}

vec3 hash3(inout float seed) {
	uint n = baseHash(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
	uvec3 rz = uvec3(n, n * 16807U, n * 48271U);
	return vec3(rz & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

float rand(vec2 v) {
	return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 toLinear(vec3 c) {
	return pow(c, vec3(2.2));
}

vec3 toGamma(vec3 c) {
	return pow(c, vec3(1.0 / 2.2));
}

vec2 randomInUnitDisk(inout float seed) {
	vec2 h = hash2(seed) * vec2(1.0, 6.28318530718);
	float phi = h.y;
	float r = sqrt(h.x);
	return r * vec2(sin(phi), cos(phi));
}

vec3 randomInUnitSphere(inout float seed) {
	vec3 h = hash3(seed) * vec3(2.0, 6.28318530718, 1.0) - vec3(1.0, 0.0, 0.0);
	float phi = h.y;
	float r = pow(h.z, 1.0 / 3.0);
	return r * vec3(sqrt(1.0 - h.x * h.x) * vec2(sin(phi), cos(phi)), h.x);
}

vec3 randomUnitVector(inout float seed) // to be used in diffuse reflections
                                        // with distribution cosine
{
	return (normalize(randomInUnitSphere(seed)));
}

struct Camera {
	vec3 eye;
	vec3 u, v, n;
	float width, height;
	float lensRadius;
	float planeDist, focusDist;
	float time0, time1;
};

Camera createCamera(
	vec3 eye,
	vec3 at,
	vec3 worldUp,
	float fovy,
	float aspect,
	float aperture,  // diametro em multiplos do pixel size
	float focusDist, // focal ratio
	float time0,
	float time1
) {
	Camera cam;
	if (aperture == 0.0) {
		cam.focusDist = 1.0; // pinhole camera then focus in on vis plane
	} else {
		cam.focusDist = focusDist;
	}
	vec3 w = eye - at;
	cam.planeDist = length(w);
	cam.height = 2.0 * cam.planeDist * tan(fovy * pi / 180.0 * 0.5);
	cam.width = aspect * cam.height;

	cam.lensRadius =
		aperture * 0.5 * cam.width / iResolution.x; // aperture ratio * pixel size; (1 pixel=lente raio 0.5)
	cam.eye = eye;
	cam.n = normalize(w);
	cam.u = normalize(cross(worldUp, cam.n));
	cam.v = cross(cam.n, cam.u);
	cam.time0 = time0;
	cam.time1 = time1;
	return cam;
}

Ray getRay(
	Camera cam,
	vec2 pixel_sample
) // rnd pixel_sample viewport coordinates
{
	vec2 ls = cam.lensRadius * randomInUnitDisk(gSeed); // ls - lens sample for
	                                                    // DOF
	float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);

	// Calculate eye_offset and ray direction

	float d = length(cam.n);
	float f = d * cam.focusDist;

	vec3 p_s = vec3(
		cam.width * ((pixel_sample.x + 0.5) / iResolution.x - 0.5),
		cam.height * ((pixel_sample.y + 0.5) / iResolution.y - 0.5),
		-d
	);

	vec3 p = p_s * cam.focusDist;

	vec3 eye_offset = cam.eye + ls.x * cam.u + ls.y * cam.v;
	vec3 ray_dir = (p.x - ls.x) * cam.u + (p.y - ls.y) * cam.v - f * cam.n;

	return createRay(eye_offset, normalize(ray_dir), time);
}

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
	m.roughness = 1.0; // ser usado na iluminação direta
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

struct HitRecord {
	vec3 pos;
	vec3 normal;
	float t; // ray parameter
	Material material;
};

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

struct Triangle {
	vec3 a;
	vec3 b;
	vec3 c;
};

bool hit_triangle(Triangle tri, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 edge1 = tri.b - tri.a;
	vec3 edge2 = tri.c - tri.a;
	vec3 ray_cross_e2 = cross(r.d, edge2);
	float det = dot(edge1, ray_cross_e2);

	float inv_det = 1.0 / det;
	vec3 s = r.o - tri.a;
	float u = inv_det * dot(s, ray_cross_e2);

	if ((u < 0.0 && abs(u) > epsilon) || (u > 1.0 && abs(u - 1.0) > epsilon)) {
		return false;
	}

	vec3 s_cross_e1 = cross(s, edge1);
	float v = inv_det * dot(r.d, s_cross_e1);

	if ((v < 0.0 && abs(v) > epsilon) || (u + v > 1.0 && abs(u + v - 1.0) > epsilon)) {
		return false;
	}

	float t = inv_det * dot(edge2, s_cross_e1);
	if (t < epsilon || t < tmin || t > tmax) {
		return false;
	}

	rec.t = t;
	rec.pos = r.o + rec.t * r.d;
	rec.normal = normalize(cross(tri.b - tri.a, tri.c - tri.b));

	return true;
}

struct Quad {
	vec3 a;
	vec3 b;
	vec3 c;
	vec3 d;
};

bool hit_quad(Quad q, Ray r, float tmin, float tmax, inout HitRecord rec) {
	return hit_triangle(Triangle(q.a, q.b, q.c), r, tmin, tmax, rec) ||
	       hit_triangle(Triangle(q.a, q.c, q.d), r, tmin, tmax, rec);
}

struct Sphere {
	vec3 center;
	float radius;
};

struct MovingSphere {
	vec3 center0, center1;
	float radius;
	float time0, time1;
};

vec3 movingSphereCenter(MovingSphere s, float time) {
	float t = (time - s.time0) / (s.time1 - s.time0);
	vec3 moving_center = mix(s.center0, s.center1, clamp(t, 0.0, 1.0));

	// Program it
	return moving_center;
}

/*
 * The function naming convention changes with these functions to show that they
 * implement a sort of interface for the book's notion of "hittable". E.g.
 * hit_<type>.
 */

bool hit_sphere(Sphere s, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 offset = r.o - s.center;

	float b = dot(offset, r.d);
	float c = dot(offset, offset) - s.radius * s.radius;

	bool is_outside = c > 0.0;

	if (is_outside && b > 0.0) {
		return false;
	}

	float disc = b * b - c;
	if (disc < 0.0) {
		return false;
	}

	float t = -b + (is_outside ? -sqrt(disc) : sqrt(disc));
	if (t < tmin || t > tmax) {
		return false;
	}

	rec.t = t;
	rec.pos = r.o + r.d * rec.t;
	rec.normal = normalize(rec.pos - s.center);
	if (s.radius < 0.0) {
		rec.normal = -rec.normal;
	}

	return true;
}

bool hit_movingSphere(MovingSphere s, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 center = movingSphereCenter(s, r.t);
	Sphere sphere = Sphere(center, s.radius);

	return hit_sphere(sphere, r, tmin, tmax, rec);
}

struct pointLight {
	vec3 pos;
	vec3 color;
};

pointLight createPointLight(vec3 pos, vec3 color) {
	pointLight l;
	l.pos = pos;
	l.color = color;
	return l;
}
