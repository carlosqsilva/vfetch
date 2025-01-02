module system

import json
import os

struct Result {
pub:
	success bool
	result  string
}

fn success(result string) Result {
	return Result{true, result}
}

const failure = Result{}

struct Display {
	main       string @[json: spdisplays_main]
	resolution string @[json: spdisplays_resolution]
}

struct GPUDevice {
	model       string    @[json: sppci_model]
	cores       string    @[json: sppci_cores]
	device_type string    @[json: sppci_device_type]
	displays    []Display @[json: spdisplays_ndrvs]
}

struct StorageDevice {
	free  u64    @[json: free_space_in_bytes]
	size  u64    @[json: size_in_bytes]
	mount string @[json: mount_point]
}

struct Storage {
	storages []StorageDevice @[json: SPStorageDataType]
}

struct HardwareDevice {
	machine string @[json: machine_name]
}

struct Machine {
	hardware []HardwareDevice @[json: SPHardwareDataType]
	storages []StorageDevice  @[json: SPStorageDataType]
	gpu      []GPUDevice      @[json: SPDisplaysDataType]
}

@[inline]
fn get_misc(str string) !Machine {
	return json.decode(Machine, str.trim_left('MISC '))
}

struct System {
pub mut:
	user       Result
	uptime     Result
	memory     Result
	cpu        Result
	gpu        Result
	resolution Result
	storage    Result
	os         Result
	term       Result
	machine    Result
	battery    Result
	packages   Result
	song       Result
}


@[inline]
pub fn new_system() ?&System {
	query := os.execute(r"echo USER $USER \|\
	TERM $TERM_PROGRAM $TERM \|\
	UPTIME $(sysctl -n kern.boottime) \|\
	MEMORY $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) \
	PAGE_SIZE $(sysctl -n hw.pagesize) \
	APP $(($(sysctl -n vm.page_pageable_internal_count) - $(sysctl -n vm.page_purgeable_count))) \
	WIRED $(vm_stat | awk '/ wired/ { print $4 }') \
	COMPRESSED $(vm_stat | awk '/ occupied/ { printf $5 }') \|\
	CPU $(sysctl -n machdep.cpu.brand_string) \
	CORES $(sysctl -n hw.physicalcpu_max) \|\
	PACKAGES $(ls /opt/homebrew/Cellar | wc -w; ls /opt/homebrew/Caskroom | wc -w) \|\
	MISC $(system_profiler SPHardwareDataType SPStorageDataType SPDisplaysDataType -detailLevel mini -json ) \|\
	OS $(awk -F'<|>' '/key|string/ {print $3}' /System/Library/CoreServices/SystemVersion.plist) \|\
	BATTERY $(pmset -g batt | grep -o '[0-9]*%')")

	if query.output.len == 0 {
		return none
	}

	if info := get_power_adapter_info() {
	 dump(info)
	}

	mut sys := &System{}

	for field in query.output.split('|') {
		match true {
			field.starts_with('USER') {
				sys.user = get_user(field)
			}
			field.starts_with('UPTIME') {
				sys.uptime = get_uptime(field)
			}
			field.starts_with('MEMORY') {
				sys.memory = get_memory(field)
			}
			field.starts_with('CPU') {
				sys.cpu = get_cpu(field)
			}
			field.starts_with('OS') {
				sys.os = get_os(field)
			}
			field.starts_with('TERM') {
				sys.term = get_term(field)
			}
			field.starts_with('BATTERY') {
				sys.battery = get_battery(field)
			}
			field.starts_with('PACKAGES') {
				sys.packages = get_packages(field)
			}
			field.starts_with('MISC') {
				data := get_misc(field) or { continue }
				sys.storage = get_storage(data)
				sys.machine = get_machine(data)
				sys.resolution = get_resolution(data)
				sys.gpu = get_gpu(data)
			}
			else {
				continue
			}
		}
	}

	return sys
}
