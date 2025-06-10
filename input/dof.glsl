//! Input - depth of field

#include "consts.glsl"

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curAperture, curDistToFocus, 0.0, isChanged)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture, since we can't make this
	//       shader have a 1x1 resolution
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	float curAperture = prevState.x;
	float curDistToFocus = prevState.y;

	// Aperture
	if (isKeyDown(Key_T)) {
		curAperture -= 1.0;
	}
	if (isKeyDown(Key_Y)) {
		curAperture += 1.0;
	}
	curAperture = max(curAperture, 0.0);

	// Distance to focus
	if (isKeyDown(Key_G)) {
		curDistToFocus -= 0.01;
	}
	if (isKeyDown(Key_H)) {
		curDistToFocus += 0.01;
	}
	curDistToFocus = max(curDistToFocus, -camDefaultDistToFocus + epsilon);

	// Reset
	if (isKeyDown(Key_R)) {
		curAperture = 0.0;
		curDistToFocus = 0.0;
	}

	gl_FragColor.x = curAperture;
	gl_FragColor.y = curDistToFocus;
	gl_FragColor.w = (curAperture != prevState.x || curDistToFocus != prevState.y) ? 1.0 : 0.0;
}
