//! Mouse control shader

// TODO: Not calculate and write the mouse information to each pixel?

#iChannel0 "self"
#iKeyboard

// Output: vec4(curPos, curStartPos)

void main() {
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec2 prevPos = prevState.xy;
	vec2 curStartPos = prevState.zw;

	// If the button is being pressed, update the position
	if (iMouseButton.x == 1.0) {
		vec2 posDelta = iMouse.xy - abs(iMouse.zw);
		vec2 newPos = curStartPos + posDelta;

		gl_FragColor.xy = newPos;
		gl_FragColor.zw = curStartPos;
		return;
	}

	// Else if this is the first frame after lifting up the button,
	// save the position
	if (prevPos != curStartPos) {
		gl_FragColor.xy = prevPos;
		gl_FragColor.zw = prevPos;
		return;
	}

	// Otherwise, check for keyboard inputs
	// Note: We save the actual current position first
	//       to ensure the user can check for when we
	//       receive keyboard input (xy != zw).
	gl_FragColor.zw = curStartPos;

	// Left-right
	if (isKeyDown(Key_A)) {
		curStartPos.x -= 5.0;
	}
	if (isKeyDown(Key_D)) {
		curStartPos.x += 5.0;
	}

	// Forward/Back
	if (isKeyDown(Key_W)) {
		curStartPos.y += 5.0;
	}
	if (isKeyDown(Key_S)) {
		curStartPos.y -= 5.0;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curStartPos.xy = vec2(0.0, 0.0);
	}

	gl_FragColor.xy = curStartPos;
}
