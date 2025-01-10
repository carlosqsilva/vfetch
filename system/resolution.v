module system

#flag darwin -framework IOKit -framework CoreGraphics

#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/graphics/IOGraphicsLib.h>

// Define necessary types and constants
type CGDirectDisplayID = u32
type CGDisplayModeRef = voidptr
type CGError = u32

// Bindings for CoreGraphics functions
fn C.CGGetActiveDisplayList(u32, &CGDirectDisplayID, &u32) CGError
fn C.CGDisplayCopyDisplayMode(CGDirectDisplayID) CGDisplayModeRef
fn C.CGDisplayModeGetWidth(CGDisplayModeRef) usize
fn C.CGDisplayModeGetHeight(CGDisplayModeRef) usize
fn C.CGDisplayModeGetRefreshRate(CGDisplayModeRef) f64
fn C.CGDisplayModeRelease(CGDisplayModeRef)

@[inline]
fn get_resolution() Result {
  mut display_count := u32(0)
  mut displays := [16]CGDirectDisplayID{}

  if C.CGGetActiveDisplayList(16, &displays[0], &display_count) != 0 {
    return failure
  }

  mode := C.CGDisplayCopyDisplayMode(0)
  defer {
    C.CGDisplayModeRelease(mode)
  }

  if mode == 0 {
    return failure
  }

  width := C.CGDisplayModeGetWidth(mode)
  height := C.CGDisplayModeGetHeight(mode)
  refresh_rate := C.CGDisplayModeGetRefreshRate(mode)

  return success("${width} x ${height} @ ${int(refresh_rate)} Hz")
}
