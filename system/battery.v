module system

#flag darwin -framework IOKit -framework CoreFoundation

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>

type C.CFDictionaryRef = voidptr
type C.CFTypeRef = voidptr
type C.CFStringRef = voidptr
type C.CFArrayRef = voidptr

// C function declarations
fn C.IOPSCopyPowerSourcesInfo() &C.CFTypeRef
fn C.IOPSCopyPowerSourcesList(power_source &C.CFTypeRef) &C.CFArrayRef
fn C.CFArrayGetCount(sources &C.CFArrayRef) int
fn C.CFArrayGetValueAtIndex(array &C.CFArrayRef, idx int) &C.CFTypeRef
fn C.IOPSGetPowerSourceDescription(source &C.CFTypeRef, value &C.CFTypeRef) &C.CFDictionaryRef

fn C.IOPSCopyExternalPowerAdapterDetails() &C.CFDictionaryRef
fn C.CFDictionaryGetValue(theDict &C.CFDictionaryRef, key &C.CFStringRef) &C.CFTypeRef
fn C.CFStringGetCString(theString &C.CFStringRef, buffer &char, bufferSize usize, encoding int) bool
fn C.CFNumberGetValue(number &C.CFNumberRef, theType int, valuePtr voidptr) bool
fn C.CFRelease(cf &C.CFTypeRef)
fn C.CFStringCreateWithCString(alloc &C.CFAllocatorRef, cStr &char, encoding int) &C.CFStringRef

const string_encoding = 0x08000100
const number_int_type = 9

fn get_number_value(dict &C.CFDictionaryRef, key string) ?int {
	dict_key := C.CFStringCreateWithCString(0, key.str, string_encoding)

	defer {
		C.CFRelease(dict_key)
	}

	mut value := 0
	value_ref := unsafe {
		&C.CFNumberRef(C.CFDictionaryGetValue(dict, dict_key))
	}

	if value_ref != 0 {
		C.CFNumberGetValue(value_ref, number_int_type, &value)
	} else {
		return none
	}

	return value
}

fn get_string_value(dict &C.CFDictionaryRef, key string) ?string {
	dict_key := C.CFStringCreateWithCString(0, key.str, string_encoding)

	defer {
		C.CFRelease(dict_key)
	}

	value_ref := &C.CFStringRef(C.CFDictionaryGetValue(dict, dict_key))

	if value_ref == 0 {
		return none
	}

	buffer_size := 256
	mut buffer := []u8{len: buffer_size}
	C.CFStringGetCString(value_ref, &char(buffer.data), buffer_size, string_encoding)

	return buffer.bytestr()
}

fn get_external_power_adapter() ?string {
	adapter_details := C.IOPSCopyExternalPowerAdapterDetails()

	if adapter_details == 0 {
		return none
	}

	defer { C.CFRelease(adapter_details) }

	// if transport_type := get_string_value(adapter_details, 'Transport Type') {
	// 	dump(transport_type)
	// }

	// if type := get_string_value(adapter_details, 'Vendor Specific Data') {
	// 	dump(type)
	// }

	if name := get_string_value(adapter_details, 'Name') {
	  return name
	}

	return none
}

fn get_power_source() ?string {
	source_info := C.IOPSCopyPowerSourcesInfo()
	if source_info == C.NULL {
		return none
	}

	power_sources := C.IOPSCopyPowerSourcesList(source_info)
	if source_info == C.NULL {
		return none
	}

	defer {
		C.CFRelease(source_info)
		C.CFRelease(power_sources)
	}

	if C.CFArrayGetCount(power_sources) == 0 {
		return none
	}

	power_source := C.IOPSGetPowerSourceDescription(source_info, C.CFArrayGetValueAtIndex(power_sources,
		0))
	if power_source == C.NULL {
		return none
	}

	if capacity := get_number_value(power_source, 'Current Capacity') {
		percentage := '${capacity.str()}%'
		mut source := percentage

		if state := get_string_value(power_source, 'Power Source State') {
			source = '${percentage} ${state}'
		}

		return source
	}

	return none
}

@[inline]
fn get_battery() Result {
	if battery := get_power_source() {
		if adapter := get_external_power_adapter() {
			return success('${battery} (${adapter})')
		}

		return success(battery)
	}

	return failure
}
