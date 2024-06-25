module system

@[inline]
fn get_user(str string) Result {
	pieces := str.split(' ')

	if pieces.len >= 2 {
		return success(pieces[1])
	}

	return failure
}

