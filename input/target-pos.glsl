//! Input - Target position (xz)

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curTarget.x, curTarget.y, prevTarget.x, prevTarget.y)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture.
	// TODO: Reduce the size of the texture to a 1x1?
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec2 curTarget = prevState.xy;

	// Save the starting target so the user can check it.
	gl_FragColor.zw = curTarget;

	// Left-right
	if (isKeyDown(Key_LeftArrow)) {
		curTarget.x -= 0.1;
	}
	if (isKeyDown(Key_RightArrow)) {
		curTarget.x += 0.1;
	}

	// Up-down
	if (isKeyDown(Key_UpArrow)) {
		curTarget.y -= 0.1;
	}
	if (isKeyDown(Key_DownArrow)) {
		curTarget.y += 0.1;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curTarget = vec2(0.0, 0.0);
	}

	gl_FragColor.xy = curTarget;
}
