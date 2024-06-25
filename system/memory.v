module system

@[inline]
fn get_memory(str string) Result {
	mut total := 0.0
	mut pages_size := 0.0
	mut app := 0.0
	mut wired := 0.0
	mut compressed := 0.0

	fields := str.replace('.', '').replace('\n', '').split(' ')

	for index, field in fields {
		match field {
			'APP' { app = fields[index + 1].u64() }
			'WIRED' { wired = fields[index + 1].u64() }
			'COMPRESSED' { compressed = fields[index + 1].u64() }
			'PAGE_SIZE' { pages_size = fields[index + 1].u64() }
			'MEMORY' { total = fields[index + 1].u64() }
			else { continue }
		}
	}

	if 0 in [total, pages_size, app, wired, compressed] {
		return failure
	}

	mem_used := ((app + wired + compressed) * pages_size / 1024 / 1024) / 1024

	return success('${mem_used:.2} / ${total} GiB')
}
