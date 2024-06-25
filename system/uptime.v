module system

import regex
import time

@[inline]
fn get_uptime(str string) Result {
	mut re := regex.regex_opt(r'(?P<startup>[0-9]+),') or { return failure }
	start, _ := re.find(str)
	now := time.utc()
	mut startup := now

	if start >= 0 && 'startup' in re.group_map {
		startup = time.unix(re.get_group_by_name(str, 'startup').i64())
	}

	if now == startup {
		return failure
	}

	duration := (now - startup).str()

	return success(duration)
}

