package corsair_cue_example_highlight

import "core:fmt"
import "core:time"
import "core:math"
import "core:runtime"
import cue "../../corsair-cue"

/*
	1 - Direct
	2 - Direct, Async
	3 - Using buffer + flush
	4 - Using buffer + async flush

*/
Color_Set_Mode :: 1

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

	positions := get_led_positions()[:6]

	colors := make([]Led_Color, len(positions))
	for p, i in positions {
		colors[i].led_id = p.led_id
	}

	get_leds_colors_by_device_index(0, colors)
	println("Current colors:", colors)

	// request_control(.Exclusive_Lighting_Control)

	for led in positions {
 		highlight_key(led.led_id)
	}
}

async_callback :: proc "c" (ctx: rawptr, result: b32, error: cue.Error) {
	context = runtime.default_context()
	fmt.printf("[Async] Result: %v, Error: %v\n", result, error)
}

highlight_key :: proc(led: cue.Led_Id) {
	using cue

	for x := 0.0; x < 2; x += 0.1 {
		val := i32((1 - math.pow(x - 1, 2)) * 255)

		color := []cue.Led_Color{
			{led, {val, val, val }},
		}

		when Color_Set_Mode == 1 {
			set_leds_colors(color)
		} else when Color_Set_Mode == 2 {
			set_leds_colors_async(color, async_callback, nil)

		} else when Color_Set_Mode == 3 {
			set_leds_colors_buffer_by_device_index(0, color)
			set_leds_colors_flush_buffer()
		} else {
			set_leds_colors_buffer_by_device_index(0, color)
			set_leds_colors_flush_buffer_async(async_callback, nil)
		}

		time.sleep(30 * time.Millisecond)
	}
}