module system

import os
import semver

const file_path = "/System/Library/CoreServices/SystemVersion.plist"

fn parse_plist_file(content string) map[string]string {
  lines := content.split_into_lines()
  mut result := map[string]string{}

  for index, item in lines {
    mut line := item.trim_space()
    if line.starts_with('<key>') {
      key := line.all_after('<key>').all_before('</key>').trim_space()

      if index + 1 < lines.len {
        next_line := lines[index + 1].trim_space()
        if next_line.starts_with('<string>') {
          value := next_line.all_after('<string>').all_before('</string>').trim_space()
          result[key] = value
        }
      }
    }
  }

  return result
}

@[inline]
fn get_os() Result {
  content := os.read_file(file_path) or {
    return failure
  }

	mut product_name := ''
	mut product_version := ''
	mut product_build_version := ''

  result := parse_plist_file(content)

  if name := result['ProductName'] {
    product_name = name
  }

  if version := result['ProductVersion'] {
    product_version = version
  }

  if build := result['ProductBuildVersion'] {
    product_build_version = build
  }

	if '' in [product_name, product_version,  product_build_version] {
		return failure
	}

	get_name := fn (version semver.Version) ?string {
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

	version := semver.coerce(product_version) or { return failure }

	if name := get_name(version) {
		return success('${product_name} ${name} ${product_version} (${product_build_version})')
	}

	return success('${product_name} ${product_version} (${product_build_version})')
}
