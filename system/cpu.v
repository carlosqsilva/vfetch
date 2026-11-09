module system

#include <sys/types.h>
#include <sys/sysctl.h>

fn C.sysctlbyname(name &char, oldp voidptr, oldlenp &uint, newp voidptr, newlen u64) int

@[inline]
fn get_cpu() Result {
  mut cpu_model := []u8{len: 256}
  mut len := uint(sizeof(cpu_model))
  if C.sysctlbyname("machdep.cpu.brand_string".str, &char(cpu_model.data), &len, 0, 0) != 0 {
    return failure
  }

  mut cores := 0
  mut cores_len := uint(sizeof(cores))
  if C.sysctlbyname("machdep.cpu.core_count".str, &cores, &cores_len, 0, 0) != 0 {
    return failure
  }

  return success("${cpu_model[..int(len)].bytestr().trim_space()} ${cores} cores")
}
