module system

#flag darwin -framework IOKit -framework CoreFoundation

#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#include <CoreFoundation/CoreFoundation.h>

// C definitions
// [c: 'CFTypeRef']
type CFTypeRef = voidptr

// [c: 'CFDictionaryRef']
type CFDictionaryRef = voidptr

// [c: 'CFArrayRef']
type CFArrayRef = voidptr

// Import C functions
fn C.IOPSCopyPowerSourcesInfo() CFTypeRef
fn C.IOPSCopyPowerSourcesList(CFTypeRef) CFArrayRef
fn C.IOPSGetPowerSourceDescription(CFTypeRef, CFTypeRef) CFDictionaryRef
fn C.CFArrayGetCount(CFArrayRef) int
fn C.CFArrayGetValueAtIndex(CFArrayRef, int) voidptr
fn C.CFDictionaryGetValue(CFDictionaryRef, &char) voidptr
fn C.CFStringGetCStringPtr(voidptr, int) &char

// Struct to hold power adapter information
struct PowerAdapterInfo {
mut:
    name    string
    watts   int
    model   string
}

fn get_power_adapter_info() ?PowerAdapterInfo {
  // Get power sources info
  power_source := C.IOPSCopyPowerSourcesInfo()
  if power_source == 0 {
    // return error('Failed to get power sources info')
    print("here 1")
    return none
  }

  // Get power sources list
  sources_list := C.IOPSCopyPowerSourcesList(power_source)
  if sources_list == 0 {
    // return error('Failed to get power sources list')
    print("here 2")
    return none
  }

  // Get first power source
  count := C.CFArrayGetCount(sources_list)
  if count == 0 {
    // return error('No power sources found')
    print("here 3")
    return none
  }

  first_source := C.CFArrayGetValueAtIndex(sources_list, 0)
  if first_source == 0 {
    // return error('Failed to get first power source')
    print("here 4")
    return none
  }

  // Get power source description
  description := C.IOPSGetPowerSourceDescription(power_source, first_source)
  if description == 0 {
    // return error('Failed to get power source description')
    return none
  }

  // Create and populate power adapter info
  mut info := PowerAdapterInfo{
    name: ''
    watts: 0
    model: ''
  }

  // Get name
  name_key := c'Name'
  name_ref := C.CFDictionaryGetValue(description, name_key)
  if name_ref != 0 {
    name_ptr := C.CFStringGetCStringPtr(name_ref, 0)
    if name_ptr != 0 {
      info.name = unsafe { cstring_to_vstring(name_ptr) }
    }
  }

  // Get wattage
  watts_key := c'Watts'
  watts_ref := C.CFDictionaryGetValue(description, watts_key)
  if watts_ref != 0 {
    info.watts = int(watts_ref)
  }

  // Get model
  model_key := c'Model'
  model_ref := C.CFDictionaryGetValue(description, model_key)
  if model_ref != 0 {
    model_ptr := C.CFStringGetCStringPtr(model_ref, 0)
    if model_ptr != 0 {
      info.model = unsafe { cstring_to_vstring(model_ptr) }
    }
  }

  return info
}
