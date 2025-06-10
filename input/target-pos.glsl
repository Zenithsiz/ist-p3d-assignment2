//! Input - Target position (xz)

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curTarget.x, curTarget.y, prevTarget.z, isChanged)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture, since we can't make this
	//       shader have a 1x1 resolution
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec3 curTarget = prevState.xyz;

	// Left-right
	if (isKeyDown(Key_LeftArrow)) {
		curTarget.x -= 0.1;
	}
	if (isKeyDown(Key_RightArrow)) {
		curTarget.x += 0.1;
	}

	// Up-down
	if (isKeyDown(Key_PageDown)) {
		curTarget.y -= 0.1;
	}
	if (isKeyDown(Key_PageUp)) {
		curTarget.y += 0.1;
	}

	// Forward-backwards
	if (isKeyDown(Key_UpArrow)) {
		curTarget.z -= 0.1;
	}
	if (isKeyDown(Key_DownArrow)) {
		curTarget.z += 0.1;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curTarget = vec3(0.0, 0.0, 0.0);
	}

	gl_FragColor.xyz = curTarget;
	gl_FragColor.w = (curTarget != prevState.xyz) ? 1.0 : 0.0;
}
