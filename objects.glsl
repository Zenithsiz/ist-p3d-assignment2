//! Objects

#ifndef OBJECTS_H
#define OBJECTS_H

#include "camera.glsl"
#include "material.glsl"
#include "rand.glsl"

struct HitRecord {
	vec3 pos;
	vec3 normal;
	float t; // ray parameter
	Material material;

	// Object-local hit coordinates
	vec2 coord;
};

struct Triangle {
	vec3 a;
	vec3 b;
	vec3 c;
};

bool triangleHit(Triangle tri, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 edge1 = tri.b - tri.a;
	vec3 edge2 = tri.c - tri.a;
	vec3 rayCrossE2 = cross(r.d, edge2);
	float det = dot(edge1, rayCrossE2);

	float invDet = 1.0 / det;
	vec3 s = r.o - tri.a;
	float u = invDet * dot(s, rayCrossE2);

	if ((u < 0.0 && abs(u) > epsilon) || (u > 1.0 && abs(u - 1.0) > epsilon)) {
		return false;
	}

	vec3 sCrossE1 = cross(s, edge1);
	float v = invDet * dot(r.d, sCrossE1);

	if ((v < 0.0 && abs(v) > epsilon) || (u + v > 1.0 && abs(u + v - 1.0) > epsilon)) {
		return false;
	}

	float t = invDet * dot(edge2, sCrossE1);
	if (t < epsilon || t < tmin || t > tmax) {
		return false;
	}

	rec.t = t;
	rec.pos = r.o + rec.t * r.d;
	rec.normal = normalize(cross(tri.b - tri.a, tri.c - tri.b));
	rec.coord = vec2(u, v);

	return true;
}

struct Quad {
	vec3 a;
	vec3 b;
	vec3 c;
	vec3 d;
};

bool quadHit(Quad q, Ray r, float tmin, float tmax, inout HitRecord rec) {
	if (triangleHit(Triangle(q.a, q.b, q.c), r, tmin, tmax, rec)) {
		rec.coord.x += rec.coord.y;
		return true;
	} else if (triangleHit(Triangle(q.a, q.c, q.d), r, tmin, tmax, rec)) {
		rec.coord.y += rec.coord.x;
		return true;
	} else {
		return false;
	}
}

vec3 quadRandPoint(Quad q, inout float seed) {
	vec3 d1 = q.b - q.a;
	vec3 d2 = q.d - q.a;

	return q.a + d1 * hash1(seed) + d2 * hash1(seed);
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
	vec3 center = mix(s.center0, s.center1, clamp(t, 0.0, 1.0));

	// Program it
	return center;
}

bool sphereHit(Sphere s, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 offset = r.o - s.center;

	float b = dot(offset, r.d);
	float c = dot(offset, offset) - s.radius * s.radius;

	bool isOutside = c > 0.0;

	if (isOutside && b > 0.0) {
		return false;
	}

	float disc = b * b - c;
	if (disc < 0.0) {
		return false;
	}

	float t = -b + (isOutside ? -sqrt(disc) : sqrt(disc));
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

bool movingSphereHit(MovingSphere s, Ray r, float tmin, float tmax, inout HitRecord rec) {
	vec3 center = movingSphereCenter(s, r.t);
	Sphere sphere = Sphere(center, s.radius);

	return sphereHit(sphere, r, tmin, tmax, rec);
}

#endif
