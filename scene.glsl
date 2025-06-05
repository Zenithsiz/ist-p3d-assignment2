//! Scene definition

#ifndef SCENE_H
#define SCENE_H

#define SCENE 3

#if SCENE == 0
	#include "scenes/shirley_weekend.glsl"
#elif SCENE == 1
	#include "scenes/scene1.glsl"
#elif SCENE == 2
	#include "scenes/cornell_box.glsl"
#elif SCENE == 3
	#include "scenes/pool.glsl"
#else
	#error "Unknown scene"
#endif

#endif
