module system

#include <sys/sysctl.h>

struct C.xsw_usage {
	xsu_total     u64
	xsu_avail     u64
	xsu_used      u64
	xsu_pagesize  u32
	xsu_encrypted bool
};

fn C.sysctl(mib [2]int, miblen u8, oldp voidptr, oldlenp &usize, newp voidptr, newlen u32) int

@[inline]
fn get_swap() Result {
  mut swap_info := C.xsw_usage{}
  mut swap_info_len := usize(sizeof(C.xsw_usage))
  mib := [2, 5]!

  // Get the boot time using sysctl
  if C.sysctl(mib, 2, &swap_info, &swap_info_len, C.NULL, 0) < 0 {
    return failure
  }

  if swap_info.xsu_total == 0 {
    return failure
  }

  return success("${human_readable_size(swap_info.xsu_used)} / ${human_readable_size(swap_info.xsu_total)}")
}
