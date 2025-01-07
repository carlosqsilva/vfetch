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
	swap       Result
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

fn human_readable_size(size u64) string {
  units := ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  mut index := 0
  mut size_f := f64(size)

  for size_f >= 1024 && index < units.len - 1 {
      size_f /= 1024
      index++
  }

  return '${size_f:.2f} ${units[index]}'
}

@[inline]
pub fn new_system() ?&System {
	query := os.execute(r"echo USER $USER \|\
	TERM $TERM_PROGRAM $TERM \|\
	CPU $(sysctl -n machdep.cpu.brand_string) \
	CORES $(sysctl -n hw.physicalcpu_max) \|\
	PACKAGES $(ls /opt/homebrew/Cellar | wc -w; ls /opt/homebrew/Caskroom | wc -w) \|\
	MISC $(system_profiler SPHardwareDataType SPStorageDataType SPDisplaysDataType -detailLevel mini -json ) \|\
	OS $(awk -F'<|>' '/key|string/ {print $3}' /System/Library/CoreServices/SystemVersion.plist)")

	if query.output.len == 0 {
		return none
	}

	mut sys := &System{}

	sys.battery = get_battery()
	sys.uptime = get_uptime()
	sys.swap = get_swap()
	sys.memory = get_memory()

	for field in query.output.split('|') {
		match true {
			field.starts_with('USER') {
				sys.user = get_user(field)
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
