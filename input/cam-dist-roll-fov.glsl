//! Input - Camera distance, fov & roll

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curDist, curFov, curRoll, isChanged)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture.
	// TODO: Reduce the size of the texture to a 1x1?
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	float curDist = prevState.x;
	float curFov = prevState.y;
	float curRoll = prevState.z;

	// Dist
	if (isKeyDown(Key_1)) {
		curDist += 0.1;
	}
	if (isKeyDown(Key_2)) {
		curDist -= 0.1;
	}

	// Fov
	if (isKeyDown(Key_Z)) {
		curFov -= 0.01;
	}
	if (isKeyDown(Key_C)) {
		curFov += 0.01;
	}

	// Roll
	if (isKeyDown(Key_Q)) {
		curRoll -= 0.01;
	}
	if (isKeyDown(Key_E)) {
		curRoll += 0.01;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curDist = 0.0;
		curFov = 0.0;
		curRoll = 0.0;
	}

	gl_FragColor.x = curDist;
	gl_FragColor.y = curFov;
	gl_FragColor.z = curRoll;
	gl_FragColor.w = (curDist != prevState.x || curFov != prevState.y || curRoll != prevState.z) ? 1.0 : 0.0;
}
