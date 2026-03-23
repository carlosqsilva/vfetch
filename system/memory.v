module system

#include <mach/mach_host.h>
#include <mach/mach_init.h>
#include <mach/mach_types.h>
#include <mach/vm_statistics.h>
#include <stdio.h>
#include <sys/sysctl.h>
#include <sys/types.h>

struct C.vm_statistics64 {
  free_count                             u64
  active_count                           u64
  inactive_count                         u64
  wire_count                             u64
  zero_fill_count                        u64
  reactivations                          u64
  pageins                                u64
  pageouts                               u64
  faults                                 u64
  cow_faults                             u64
  lookups                                u64
  hits                                   u64
  purges                                 u64
  purgeable_count                        u64
  speculative_count                      u64
  decompressions                         u64
  compressions                           u64
  swapins                                u64
  swapouts                               u64
  compressor_page_count                  u64
  throttled_count                        u64
  external_page_count                    u64
  internal_page_count                    u64
  total_uncompressed_pages_in_compressor u64
}

fn C.mach_host_self() int
fn C.host_page_size(host int, page_size &u64) int
fn C.host_statistics64(host int, flavor int, info &C.vm_statistics64, count &int) int
fn C.sysctlbyname(name &char, oldp voidptr, oldlenp &usize, newp voidptr, newlen usize) int

const host_vm_info64       = 4
const host_vm_info64_count = 38

const pressure_normal   = u32(1)
const pressure_warning  = u32(2)
const pressure_critical = u32(4)

@[inline]
fn memory_pressure() ?string {
  mut level := u32(0)
  mut size := usize(sizeof(level))
  if C.sysctlbyname(c'kern.memorystatus_vm_pressure_level', &level, &size, unsafe { nil }, 0) != 0 {
    return '?'
  }
  return match level {
    pressure_warning  { 'warning' }
    pressure_critical { 'critical' }
    pressure_normal   { none }
    else              { none }
  }
}

@[inline]
fn get_memory() Result {
  mib := [6, 24]!
  mut total := u64(0)
  mut total_length := usize(sizeof(total))
  if C.sysctl(mib, 2, &total, &total_length, 0, 0) < 0 {
    return failure
  }

  mut page_size := u64(0)
  if C.host_page_size(C.mach_host_self(), &page_size) != 0 {
    return failure
  }

  mut stats := C.vm_statistics64{}
  mut count := int(host_vm_info64_count)
  if C.host_statistics64(C.mach_host_self(), host_vm_info64, &stats, &count) != 0 {
    return failure
  }

  mut used := (
    stats.active_count
    + stats.inactive_count
    + stats.speculative_count
    + stats.wire_count
    + stats.compressor_page_count - stats.purgeable_count - stats.external_page_count) * page_size

  if mem_pressure := memory_pressure() {
    return success("${human_readable_size(used)} / ${human_readable_size(total)} [${mem_pressure}]")
  }

  return success("${human_readable_size(used)} / ${human_readable_size(total)}")
}
