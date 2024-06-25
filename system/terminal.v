module system

@[inline]
fn get_term(str string) Result {
	fields := str.trim_space().split(' ')
	if fields.len > 0 {
		return success(fields[1])
	}

	return failure
}

