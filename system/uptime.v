module system

import time
import math

#include <sys/sysctl.h>

struct C.timeval {
  tv_sec  u64
  tv_usec u64
}

fn C.gettimeofday(tv &C.timeval, tz voidptr) int

@[inline]
fn get_uptime() Result {
    mut boottime := C.timeval{}
    mut boottime_len := usize(sizeof(C.timeval))
    mib := [1, 21]!

    // Get the boot time using sysctl
    if C.sysctl(mib, 2, &boottime, &boottime_len, C.NULL, 0) < 0 {
      return failure
    }

    // Get the current time
    now := time.utc()

    // Calculate the uptime in seconds
    duration := now - time.unix(boottime.tv_sec)
    formatted := format_time(duration)

    return success(formatted)
}


@[inline]
fn format_time(duration time.Duration) string {
  minutes := duration.minutes()
  hours := duration.hours()
  days := u8(duration.days())

  remaining_hours := u8(math.fmod(hours, 24))
  remaining_minutes := u8(math.fmod(minutes, 60))

  mut parts := []string{}

  if days > 0 {
    suffix := if days == 1 { 'day' } else { 'days' }
    parts << '${days} ${suffix}'
  }
  if remaining_hours > 0 {
    suffix := if remaining_hours == 1 { 'hour' } else { 'hours' }
    parts << '${remaining_hours} ${suffix}'
  }
  if remaining_minutes > 0 {
    suffix := if remaining_minutes == 1 { 'min' } else { 'mins' }
    parts << '${remaining_minutes} ${suffix}'
  }

  return parts.join(', ')
}
