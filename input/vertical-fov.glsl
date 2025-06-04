//! Input - vertical and fov

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curCamVertical, curFov, curCameraRoll, isChanged)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture.
	// TODO: Reduce the size of the texture to a 1x1?
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	float curVertical = prevState.x;
	float curFov = prevState.y;
	float curCameraRoll = prevState.z;

	// Camera
	if (isKeyDown(Key_Q)) {
		curVertical -= 0.1;
	}
	if (isKeyDown(Key_E)) {
		curVertical += 0.1;
	}

	// Fov
	if (isKeyDown(Key_1)) {
		curFov -= 1.0;
	}
	if (isKeyDown(Key_3)) {
		curFov += 1.0;
	}

	// Roll
	if (isKeyDown(Key_Z)) {
		curCameraRoll -= 0.01;
	}
	if (isKeyDown(Key_C)) {
		curCameraRoll += 0.01;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curVertical = 0.0;
		curFov = 0.0;
		curCameraRoll = 0.0;
	}

	gl_FragColor.x = curVertical;
	gl_FragColor.y = curFov;
	gl_FragColor.z = curCameraRoll;
	gl_FragColor.w = (curVertical != prevState.x || curFov != prevState.y || curCameraRoll != prevState.z) ? 1.0 : 0.0;
}
