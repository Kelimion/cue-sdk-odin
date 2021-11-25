package corsair_cue_example_properties

import "core:fmt"
import cue "../../corsair-cue"

print_device_info :: proc(di: ^cue.Device_Info, index: i32) {
	assert(di != nil)
	using fmt

	using di
	printf("\tDevice Type:     %v\n", type)
	printf("\tDevice Model:    %v\n", model)
	printf("\tPhysical Layout: %v\n", physical_layout)
	printf("\tLogical Layout:  %v\n", logical_layout)
	printf("\tLEDs count:      %v\n", leds_count)

	device := cstring(raw_data(di.device_id[:]))
	printf("\tDevice ID:       %v\n", device)

	println("\tCapabilities:")

	if .Lighting in capabilities {
		println("\t\tLighting")
	}

	if .Property_Lookup in capabilities {
		println("\t\tProperty Lookup")
		print_device_caps(index)
	}
}

print_device_caps :: proc(index: i32) {
	using fmt
	using cue

	println("\tProperties:")
	if val, ok := get_bool_property_value(index, .Headset_Mic_Enabled); ok {
		printf("\t\tHeadset mic enabled value:   %v", val)
	}

	if val, ok := get_bool_property_value(index, .Headset_Surround_Sound_Enabled); ok {
		printf("\t\tHeadset surround enabled val: %v", val)
	}

	if val, ok := get_bool_property_value(index, .Headset_Sidetone_Enabled); ok {
		printf("\t\tHeadset sidetone enabled val: %v", val)
	}

	if val, ok := get_i32_property_value(index, .Headset_Equalizer_Preset); ok {
		printf("\t\tActive headset equalize preset index: %v", val)
	}
}

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

	device_count := get_device_count()
	if device_count == 0 {
		println("No devices connected.")
	} else {
		for i := i32(0); i < device_count; i += 1 {
			printf("Device: #%v\n", i)
			di := get_device_info(i)
			print_device_info(di, i)
		}
	}
}