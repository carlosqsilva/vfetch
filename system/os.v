module system

import semver

@[inline]
fn get_os(str string) Result {
	mut product_name := ''
	mut product_version := ''
	mut product_build_version := ''

	fields := str.split(' ')

	for index, field in fields {
		match field {
			'ProductName' { product_name = fields[index + 1] }
			'ProductVersion' { product_version = fields[index + 1] }
			'ProductBuildVersion' { product_build_version = fields[index + 1] }
			else { continue }
		}
	}

	if product_name == '' || product_version == '' || product_build_version == '' {
		return failure
	}

	get_os_name := fn (input string) ?string {
		version := semver.coerce(input) or { return none }

		return match true {
			version >= semver.build(15, 0, 0) { 'Sequoia' }
			version >= semver.build(14, 0, 0) { 'Sonoma' }
			version >= semver.build(13, 0, 0) { 'Ventura' }
			version >= semver.build(12, 0, 0) { 'Monterey' }
			version >= semver.build(11, 0, 0) { 'Big Sur' }
			version >= semver.build(10, 15, 0) { 'Catalina' }
			version >= semver.build(10, 14, 0) { 'Mojave' }
			version >= semver.build(10, 13, 0) { 'High Sierra' }
			version >= semver.build(10, 12, 0) { 'Sierra' }
			version >= semver.build(10, 11, 0) { 'El Capitan' }
			version >= semver.build(10, 10, 0) { 'Yosemite' }
			version >= semver.build(10, 9, 0) { 'Mavericks' }
			version >= semver.build(10, 8, 0) { 'Mountain Lion' }
			version >= semver.build(10, 7, 0) { 'Lion' }
			version >= semver.build(10, 6, 0) { 'Snow Leopard' }
			version >= semver.build(10, 5, 0) { 'Leopard' }
			version >= semver.build(10, 4, 0) { 'Tiger' }
			version >= semver.build(10, 3, 0) { 'Panther' }
			version >= semver.build(10, 2, 0) { 'Jaguar' }
			version >= semver.build(10, 1, 0) { 'Puma' }
			version >= semver.build(10, 0, 0) { 'Cheetah' }
			else { none }
		}
	}

	if os_name := get_os_name(product_version) {
		return success('${product_name} ${os_name} ${product_version} (${product_build_version})')
	}
		
	return success('${product_name} ${product_version} (${product_build_version})')
}
