module system

import os

@[inline]
fn get_user() Result {
  if user := os.getenv_opt("USER") {
    return success(user)
  }

	return failure
}

