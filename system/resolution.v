module system

@[inline]
fn get_resolution(data Machine) Result {
	for gpu in data.gpu {
		for display in gpu.displays {
			if display.main == 'spdisplays_yes' && display.resolution != '' {
				return success(display.resolution)
			}
		}
	}

	return failure
}

