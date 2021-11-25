package corsair_cue_example_highlight

import "core:fmt"
import "core:time"
import cue "../../corsair-cue"

main :: proc() {
	using fmt
	using cue
	err:  Error

	if !init("../../lib/CUESDK.x64_2017.dll") {
		println("Corsair SDK couldn't be initialized.")
		return
	}
	defer destroy()

	protocol_details := perform_protocol_handshake()
	if err = get_last_error(); err != .None {
		printf("Error: %v\n", err)
		return
	}

	printf("Corsair CUE SDK version: %v\n", protocol_details.sdk_version)
	printf("Server      SDK version: %v\n", protocol_details.server_version)

	printf("SDK    protocol version: %v\n", protocol_details.sdk_protocol_version)
	printf("Server protocol version: %v\n", protocol_details.server_protocol_version)
	printf("Breaking changes:        %v\n", protocol_details.breaking_changes)

	println()

	text := "MMMMMM"

	request_control(.Exclusive_Lighting_Control)

	for c in text {
		led_id := get_led_id_for_key_name(u8(c))
		if led_id != .Invalid {
			highlight_key(led_id)
		}
	}
}

highlight_key :: proc(led: cue.Led_Id) {
	for x := 0.0; x < 2; x += 0.1 {
		val := i32((1.0 - abs(x - 1.0)) * 255.0)

		color := []cue.Led_Color{
			{led, {val, val, val }},
		}

		cue.set_leds_colors(color)
		time.sleep(30 * time.Millisecond)
	}
}