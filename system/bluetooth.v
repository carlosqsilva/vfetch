module system

// #include <Foundation/Foundation.h>
// #include <IOBluetooth/IOBluetooth.h>
#include "@VMODROOT/system/bluetooth.m"

fn C.get_connected_devices() int

@[inline]
fn get_bluetooth_status() Result {
  devices_count := C.get_connected_devices()

  return match true {
    devices_count == 0 { failure }
    devices_count == 1 { success("1 device connected") }
    devices_count > 1 { success("${devices_count} devices connected") }
    else { failure }
  }
}
