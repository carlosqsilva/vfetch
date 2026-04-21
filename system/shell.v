module system

import os

@[inline]
fn get_shell() Result {
  ppid := os.getppid()
  result := os.execute('ps -p ${ppid} -o comm=')
  if result.exit_code == 0 {
      shell := os.base(result.output.trim_space())
      return success(shell)
  }

  return failure
}
