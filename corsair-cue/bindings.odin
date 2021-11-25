package corsair_cue_sdk

/*
	Odin port of the Corsair CUE SDK bindings.

	The Corsair CUE SDK is licensed on Corsair's terms, see (https://github.com/CorsairOfficial/cue-sdk)
		for details and to download the library.

	This port is in the public domain (https://unlicense.org).
*/

import "core:dynlib"

when        ODIN_OS == "windows" {
	LIBRARY_NAME :: "CUE_internal.x64_2017.dll"
} else when ODIN_OS == "darwin" {
	LIBRARY_NAME :: "libCUE_internal.dylib"
} else {
	// Corsair CUE SDK is not supported on Linux, so we have no bindings for them.
}

// Called when an event is triggered
Event_Handler_Callback                 :: #type proc "c" (ctx: rawptr, event: ^Event)

// Same callback type for flush buffers async + set colors async
Async_Callback                         :: #type proc "c" (ctx: rawptr, result: b32, error: Error)

init :: proc(file_path := string("")) -> (ok: bool) {
	file_path := file_path
	if file_path == "" {
		file_path = LIBRARY_NAME
	}

	if _internal.handle, ok = dynlib.load_library(file_path); !ok { return false }

	symbol:    rawptr
	symbol_ok: bool

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLastError");                     !symbol_ok { return false }
	_internal.get_last_error                         = transmute(Get_Last_Error)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairPerformProtocolHandshake");         !symbol_ok { return false }
	_internal.perform_protocol_handshake             = transmute(Protocol_Handshake)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetDeviceCount");                   !symbol_ok { return false }
	_internal.get_device_count                       = transmute(Get_Device_Count)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetDeviceInfo");                    !symbol_ok { return false }
	_internal.get_device_info                        = transmute(Get_Device_Info)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetBoolPropertyValue");             !symbol_ok { return false }
	_internal.get_bool_property_value                = transmute(Get_Bool_Property_Value)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetInt32PropertyValue");            !symbol_ok { return false }
	_internal.get_i32_property_value                 = transmute(Get_Int32_Property_Value)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSubscribeForEvents");               !symbol_ok { return false }
	_internal.subscribe_for_events                   = transmute(Subscribe_For_Events)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairUnsubscribeFromEvents");            !symbol_ok { return false }
	_internal.unsubscribe_from_events                = transmute(Unsubscribe_From_Events)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLedIdForKeyName");               !symbol_ok { return false }
	_internal.get_led_id_for_key_name                = transmute(Get_Led_Id_For_Key_Name)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLedsColors");                    !symbol_ok { return false }
	_internal.set_leds_colors                        = transmute(Set_Leds_Colors)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLedsColorsAsync");               !symbol_ok { return false }
	_internal.set_leds_colors_async                  = transmute(Set_Leds_Colors_Async)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLedsColorsBufferByDeviceIndex"); !symbol_ok { return false }
	_internal.set_leds_colors_buffer_by_device_index = transmute(Set_Leds_Colors_Buffer_By_Device_Index)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLedsColorsFlushBuffer");         !symbol_ok { return false }
	_internal.set_leds_colors_flush_buffer           = transmute(Set_Leds_Colors_Flush_Buffer)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLedsColorsFlushBufferAsync");    !symbol_ok { return false }
	_internal.set_leds_colors_flush_buffer_async     = transmute(Set_Leds_Colors_Flush_Buffer_Async)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLedsColors");                    !symbol_ok { return false }
	_internal.get_leds_colors                        = transmute(Get_Leds_Colors)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLedsColorsByDeviceIndex");       !symbol_ok { return false }
	_internal.get_leds_colors_by_device_index        = transmute(Get_Leds_Colors_By_Device_Index)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairRequestControl");                   !symbol_ok { return false }
	_internal.request_control                        = transmute(Request_Control)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairReleaseControl");                   !symbol_ok { return false }
	_internal.release_control                        = transmute(Release_Control)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairSetLayerPriority");                 !symbol_ok { return false }
	_internal.set_layer_priority                     = transmute(Set_Layer_Priority)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLedPositionsByDeviceIndex");     !symbol_ok { return false }
	_internal.get_led_positions_by_device_index      = transmute(Get_Led_Positions_By_Device_Index)symbol

	if symbol, symbol_ok = dynlib.symbol_address(_internal.handle, "CorsairGetLedPositions");                  !symbol_ok { return false }
	_internal.get_led_positions                      = transmute(Get_Led_Positions)symbol

	return true
}

destroy :: proc() -> (ok: bool) {
	handle := _internal.handle
	_internal = {}

	return dynlib.unload_library(handle)
}

error_check :: proc() -> (ok: bool, error: string) {
	err := _internal.get_last_error()
	switch err {
	case .None:
		// if previously called function completed successfully.
		return true, "success"
	case .Server_Not_Found:
		// CUE is not running or was shut down or third-party control is disabled in CUE settings(runtime error).
		return false, "server not found"
	case .No_Control:
		// if some other client has or took over exclusive control (runtime error).
		return false, "no control"
	case .Protocol_Handshake_Missing:
		// if developer did not perform protocol handshake(developer error).
		return false, "protocol handshake missing"
	case .Incompatible_Protocol:
		// if developer is calling the function that is not supported by the server (either because protocol has broken by server or client
		// or because the function is new and server is too old. Check CorsairProtocolDetails for details) (developer error).
		return false, "incompatible protocol"
	case .Invalid_Arguments:
		// if developer supplied invalid arguments to the function(for specifics look at function descriptions). (developer error).
		return false, "invalid argument"
	}
	return false, "unknown error"
}

/*
	Wrappers for the DLL functions.
*/

// returns last error that occured while using any of Corsair* functions.
get_last_error :: proc() -> Error {
	return _internal.get_last_error()
}
// checks file and protocol version of CUE to understand which of SDK functions can be used with this version of CUE.
perform_protocol_handshake :: proc() -> Protocol_Details {
	return _internal.perform_protocol_handshake()
}

// returns number of connected Corsair devices that support lighting control.
get_device_count :: proc() -> i32 {
	return _internal.get_device_count()
}

// returns information about device at provided index.
get_device_info :: proc(device_index: i32) -> (info: ^Device_Info) {
	return _internal.get_device_info(device_index)
}

// reads boolean property value for device at provided index.
get_bool_property_value :: proc(device_index: i32, property_id: Device_Property_Id) -> (value: bool, ok: bool) {
	val: b32
	ok = bool(_internal.get_bool_property_value(device_index, property_id, &val))

	return bool(val), ok
}

// reads i32 property value for device at provided index.
get_i32_property_value :: proc(device_index: i32, property_id: Device_Property_Id) -> (value: i32, ok: bool) {
	val: i32
	ok = bool(_internal.get_i32_property_value(device_index, property_id, &val))

	return val, ok
}

// registers a callback that will be called by SDK when some event happened.
subscribe_for_events :: proc(on_event: Event_Handler_Callback, ctx: rawptr) -> (ok: bool) {
	return bool(_internal.subscribe_for_events(on_event, ctx))
}

// unregisters event callback previously registered
unsubscribe_from_events :: proc() -> (ok: bool) {
	return bool(_internal.unsubscribe_from_events())
}

// retrieves led id for key name taking logical layout into account.
get_led_id_for_key_name :: proc(key: u8) -> (led_id: Led_Id) {
	return _internal.get_led_id_for_key_name(key)
}

// set current color for the list of requested LEDs.
set_leds_colors :: proc(led_colors: []Led_Color) {
	_internal.set_leds_colors(i32(len(led_colors)), raw_data(led_colors))
}

// set current color for the list of requested LEDs, asynchronously
set_leds_colors_async :: proc(led_colors: []Led_Color, callback: Async_Callback, ctx: rawptr) {
	_internal.set_leds_colors_async(i32(len(led_colors)), raw_data(led_colors), callback, ctx)
}

// set specified LEDs to some colors. This function set LEDs colors in the buffer which is written to the devices via CorsairSetLedsColorsFlushBuffer or CorsairSetLedsColorsFlushBufferAsync.
set_leds_colors_buffer_by_device_index :: proc(device_index: i32, led_colors: []Led_Color) {
	_internal.set_leds_colors_buffer_by_device_index(device_index, i32(len(led_colors)), raw_data(led_colors))
}

// writes to the devices LEDs colors buffer which is previously filled by the CorsairSetLedsColorsBufferByDeviceIndex function.
set_leds_colors_flush_buffer :: proc() -> (ok: bool) {
	return bool(_internal.set_leds_colors_flush_buffer())
}

set_leds_colors_flush_buffer_async :: proc(callback: Async_Callback, ctx: rawptr) {
	_internal.set_leds_colors_flush_buffer_async(callback, ctx)
}

// get current color for the list of requested LEDs.
get_leds_colors :: proc(led_colors: []Led_Color) {
	_internal.get_leds_colors(i32(len(led_colors)), raw_data(led_colors))
}

// get current color for the list of requested LEDs for specified device.
get_leds_colors_by_device_index :: proc(device_index: i32, led_colors: []Led_Color) {
	_internal.get_leds_colors_by_device_index(device_index, i32(len(led_colors)), raw_data(led_colors))
}

// provides list of keyboard, mouse, mousemat, headset, headset stand, DIY-devices, memory module and cooler LEDs by its index with their positions.
get_led_positions_by_device_index :: proc(device_index: i32) -> (led_positions: []Led_Position) {
	positions := _internal.get_led_positions_by_device_index(device_index)

	return positions.led_position[:positions.number_of_leds]
}

// provides list of keyboard LEDs with their physical positions.
get_led_positions :: proc() -> (led_positions: []Led_Position) {
	positions := _internal.get_led_positions()
	return positions.led_position[:positions.number_of_leds]
}

// requestes control using specified access mode. By default client has shared control over lighting so there is no need to call CorsairRequestControl unless client requires exclusive control.
request_control :: proc(mode: Access_Mode) -> bool {
	return bool(_internal.request_control(mode))
}

// releases previously requested control for specified access mode.
release_control :: proc(mode: Access_Mode) -> bool {
	return bool(_internal.release_control(mode))
}

// set layer priority for this shared client.
set_layer_priority :: proc(priority: i32) -> bool {
	return bool(_internal.set_layer_priority(priority))
}


/*
	Internal. DLL function signatures and symbol pointers.
*/
@(private="package")
_internal := struct {
	handle: dynlib.Library,

	get_last_error:                         Get_Last_Error,
	perform_protocol_handshake:             Protocol_Handshake,

	get_device_count:                       Get_Device_Count,
	get_device_info:                        Get_Device_Info,
	get_bool_property_value:                Get_Bool_Property_Value,
	get_i32_property_value:                 Get_Int32_Property_Value,

	get_led_id_for_key_name:                Get_Led_Id_For_Key_Name,
	get_led_positions_by_device_index:      Get_Led_Positions_By_Device_Index,
	get_led_positions:                      Get_Led_Positions,

	set_leds_colors:                        Set_Leds_Colors,
	set_leds_colors_async:                  Set_Leds_Colors_Async,

	set_leds_colors_buffer_by_device_index: Set_Leds_Colors_Buffer_By_Device_Index,
	set_leds_colors_flush_buffer:           Set_Leds_Colors_Flush_Buffer,
	set_leds_colors_flush_buffer_async:     Set_Leds_Colors_Flush_Buffer_Async,

	get_leds_colors:                        Get_Leds_Colors,
	get_leds_colors_by_device_index:        Get_Leds_Colors_By_Device_Index,

	request_control:                        Request_Control,
	release_control:                        Release_Control,
	set_layer_priority:                     Set_Layer_Priority,

	subscribe_for_events:                   Subscribe_For_Events,
	unsubscribe_from_events:                Unsubscribe_From_Events,
}{}

Protocol_Handshake                     :: #type proc "c" () -> Protocol_Details
Get_Last_Error                         :: #type proc "c" () -> Error
Get_Device_Count                       :: #type proc "c" () -> i32
Get_Device_Info                        :: #type proc "c" (device_index: i32) -> (info: ^Device_Info)
Get_Bool_Property_Value                :: #type proc "c" (device_index: i32, property_id: Device_Property_Id, value: ^b32) -> (ok: b32)
Get_Int32_Property_Value               :: #type proc "c" (device_index: i32, property_id: Device_Property_Id, value: ^i32) -> (ok: b32)

Subscribe_For_Events                   :: #type proc "c" (on_event: Event_Handler_Callback, ctx: rawptr) -> (ok: b32)
Unsubscribe_From_Events                :: #type proc "c" () -> (ok: b32)

Get_Led_Id_For_Key_Name                :: #type proc "c" (key_name: u8) -> Led_Id

Set_Leds_Colors                        :: #type proc "c" (size: i32, colors: [^]Led_Color)
Set_Leds_Colors_Async                  :: #type proc "c" (size: i32, colors: [^]Led_Color, callback: Async_Callback, ctx: rawptr) -> (ok: bool)
Set_Leds_Colors_Buffer_By_Device_Index :: #type proc "c" (device_index: i32, size: i32, colors: [^]Led_Color) -> (ok: b32)
Set_Leds_Colors_Flush_Buffer           :: #type proc "c" () -> (ok: b32)
Set_Leds_Colors_Flush_Buffer_Async     :: #type proc "c" (callback: Async_Callback, ctx: rawptr)

Get_Leds_Colors                        :: #type proc "c" (size: i32, colors: [^]Led_Color)
Get_Leds_Colors_By_Device_Index        :: #type proc "c" (device_index: i32, size: i32, colors: [^]Led_Color)

Request_Control                        :: #type proc "c" (access_mode: Access_Mode) -> (ok: b32)
Release_Control                        :: #type proc "c" (access_mode: Access_Mode) -> (ok: b32)
Set_Layer_Priority                     :: #type proc "c" (priority: i32) -> (ok: b32)

Get_Led_Positions_By_Device_Index      :: #type proc "c" (device_index: i32) -> (led_positions: ^Led_Positions)
Get_Led_Positions                      :: #type proc "c" () -> (led_positions: ^Led_Positions)