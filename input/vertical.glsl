//! Input - vertical

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curCamVertical, 0.0, 0.0, isChanged)

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

	// Camera
	if (isKeyDown(Key_Q)) {
		curVertical -= 0.1;
	}
	if (isKeyDown(Key_E)) {
		curVertical += 0.1;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curVertical = 0.0;
	}

	gl_FragColor.x = curVertical;
	gl_FragColor.w = (curVertical != prevState.x) ? 1.0 : 0.0;
}
