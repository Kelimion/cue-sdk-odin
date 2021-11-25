package corsair_cue_example_events

import "core:runtime"
import "core:fmt"
import cue "../../corsair-cue"

QUIT := false

main :: proc() {
	using fmt

	if !cue.init("../../lib/CUESDK.x64_2017.dll") {
		println("Corsair SDK couldn't be initialized.")
		return
	}
	defer cue.destroy()

	using cue.sdk
	err:  cue.Error

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

	if !subscribe_for_events(handler, rawptr(event_printer)) {
		println("Error subscibing for events.")
		return
	}

	println("Subscibed for events. Press G6 to quit.")
	for !QUIT {

	}

	unsubscribe_from_events()
}

handler :: proc "c" (ctx: rawptr, event: ^cue.Event) {
	printer := transmute(proc "contextless" (event: ^cue.Event))ctx
	printer(event)
}

event_printer :: proc "contextless" (event: ^cue.Event) {
	context = runtime.default_context()
	using fmt

	switch event.id {
	case .Device_Connection_Status_Changed_Event:
		status := transmute(^cue.Device_Connection_Status_Changed_Event)event.device_connection_status
		printf("Device Connection Status Change: %v\n", status)

	case .Key_Event:
		key    := transmute(^cue.Key_Event)event.key
		device := cstring(raw_data(key.device_id[:]))

		println("Key Event:")
		printf("\tDevice:  %v\n", device)
		printf("\tKey:     %v\n", key.key_id)
		printf("\tPressed: %v\n", key.is_pressed)

		if key.key_id == .G6 {
			QUIT = true
		}

	case .Invalid: fallthrough
	case:
		println("Unrecognized Event.")
	}
}