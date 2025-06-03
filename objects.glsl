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
};

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

#endif
