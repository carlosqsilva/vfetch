module system

import arrays

@[inline]
fn get_packages(str string) Result {
	numbers := str.trim_space().trim_left('PACKAGES ').split(' ').map(it.int())
	packages := arrays.fold(numbers, 0, fn(acc int, num int) int {return acc + num})
	if packages > 0 {
		return success('${packages} (homebrew)')
	}

	return failure
}
