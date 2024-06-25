module system

@[inline]
fn get_machine(data Machine) Result {
	if data.hardware.len > 0 {
		for hardware in data.hardware {
			if hardware.machine.len > 0 {
				return success(hardware.machine)
			}
		}
	}

	return failure
}
