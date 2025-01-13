module system

import os

@[inline]
fn get_term() Result {
  if term := os.getenv_opt("TERM_PROGRAM") {
    return success(term)
  }

	return failure
}

