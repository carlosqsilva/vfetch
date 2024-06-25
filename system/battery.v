module system

@[inline]
fn get_battery(str string) Result {
	parts := str.trim_space().split(' ')
	if parts.len > 1 {
		return success(parts[1])
	}

	return failure
}
