module system

@[inline]
fn get_storage(data Machine) Result {
	mut used := 0.0
	mut total := 0.0

	for device in data.storages {
		if device.mount == '/' {
			total = device.size / 1_000_000_000
			used = total - (device.free / 1_000_000_000)
			break
		}
	}

	if 0.0 in [used, total] {
		return failure
	}

	return success('${used} / ${total} GB')
}

