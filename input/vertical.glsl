//! Input - vertical

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curCamVertical, curTargetVertical, prevCamVertical, prevTargetVertical)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture.
	// TODO: Reduce the size of the texture to a 1x1?
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec2 curVertical = prevState.xy;

	// Save the starting vertical so the user can check it.
	gl_FragColor.zw = curVertical;

	// Camera
	if (isKeyDown(Key_Q)) {
		curVertical.x -= 0.1;
	}
	if (isKeyDown(Key_E)) {
		curVertical.x += 0.1;
	}

	// Target
	if (isKeyDown(Key_PageDown)) {
		curVertical.y -= 0.1;
	}
	if (isKeyDown(Key_PageUp)) {
		curVertical.y += 0.1;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curVertical.xy = vec2(0.0);
	}

	gl_FragColor.xy = curVertical;
}
