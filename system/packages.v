module system

import os

const homebrew_prefix = "/opt/homebrew"

@[inline]
fn get_packages() Result {
  mut prefix := os.getenv_opt("HOMEBREW_PREFIX") or {
    homebrew_prefix
  }

  packages := count_elements(os.join_path(prefix, "Cellar"))
  casks := count_elements(os.join_path(prefix, "Caskroom"))
  total := packages + casks

	if total > 0 {
		return success('${total} (homebrew)')
	}

	return failure
}

fn count_elements(path string) u32 {
  items := os.ls(path) or { return 0 }

  mut count := u32(0)

  for item in items {
    full_path := os.join_path(path, item)
    if os.is_dir(full_path) {
      count++
    }
  }

  return count
}
