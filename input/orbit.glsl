//! Input - Orbit

#include "consts.glsl"

#iChannel0 "self"
#iChannel0::MinFilter "Nearest"
#iChannel0::MagFilter "Nearest"
#iKeyboard

// Output: vec4(curMouse.x, curMouse.y, startMouse.x, startMouse.y)

void main() {
	// Note: We try to compute only a single pixel to avoid having to
	//       write out the whole texture.
	// TODO: Reduce the size of the texture to a 1x1?
	if (gl_FragCoord.x < -1.0 || gl_FragCoord.x > 1.0 || gl_FragCoord.y < -1.0 || gl_FragCoord.y > 1.0) {
		discard;
	}

	// Previous frame's output
	vec4 prevState = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec2 prevPos = prevState.xy;
	vec2 curStartPos = prevState.zw;

	// If the button is being pressed, update the position
	if (iMouseButton.x == 1.0) {
		vec2 posDelta = (iMouse.xy - abs(iMouse.zw)) / iResolution.xy;
		vec2 newPos = curStartPos + posDelta;

		float minPosY = -0.25 + camDefaultPosY / (2.0 * pi);
		float maxPosY = 0.25 + camDefaultPosY / (2.0 * pi);
		newPos.y = clamp(newPos.y, minPosY + epsilon, maxPosY - epsilon);

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
		curStartPos.x += 0.01;
	}
	if (isKeyDown(Key_D)) {
		curStartPos.x -= 0.01;
	}

	// Forward/Back
	if (isKeyDown(Key_W)) {
		curStartPos.y -= 0.01;
	}
	if (isKeyDown(Key_S)) {
		curStartPos.y += 0.01;
	}

	// Reset
	if (isKeyDown(Key_R)) {
		curStartPos.xy = vec2(0.0, 0.0);
	}

	gl_FragColor.xy = curStartPos;
}
