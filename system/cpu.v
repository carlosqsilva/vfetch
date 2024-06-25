module system

import regex

@[inline]
fn get_cpu(str string) Result {
	mut re := regex.regex_opt(r'CPU\s(?P<cpu>.+)\sCORES\s(?P<cores>[0-9]+)') or { return failure }
	start, _ := re.find(str)

	if start >= 0 && 'cpu' in re.group_map && 'cores' in re.group_map {
		cpu := re.get_group_by_name(str, 'cpu')
		cores := re.get_group_by_name(str, 'cores')
		return success('${cpu} ${cores} cores (physical)')
	}

	return failure
}
