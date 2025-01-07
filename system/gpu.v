module system

@[inline]
fn get_gpu(data Machine) Result {
	for gpu in data.gpu {
		if gpu.device_type == 'spdisplays_gpu' {
			model := gpu.model
			cores := gpu.cores

			if cores == '' {
				return success(model)
			}

			return success('${model} ${cores} cores')
		}
	}

	return failure
}
