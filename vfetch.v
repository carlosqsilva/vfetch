import os
import flag
import regex
import term
import time
import json
import strings

struct Result {
	success bool
	result string
}

fn success(result string) Result {
	return Result{true, result}
}

const (
	logo = '
                      c.
                  ,xNMM.
                .OMMMMo
                OMMM0,
      .;loddo:.  .olloddol;.
    cKMMMMMMMMMMNWMMMMMMMMMM0:
  .KMMMMMMMMMMMMMMMMMMMMMMMWd.
  XMMMMMMMMMMMMMMMMMMMMMMMX.
 ;MMMMMMMMMMMMMMMMMMMMMMMM:
 :MMMMMMMMMMMMMMMMMMMMMMMM:
 .MMMMMMMMMMMMMMMMMMMMMMMMX.
  kMMMMMMMMMMMMMMMMMMMMMMMMWd.
  .XMMMMMMMMMMMMMMMMMMMMMMMMMMk
   .XMMMMMMMMMMMMMMMMMMMMMMMMK.
     kMMMMMMMMMMMMMMMMMMMMMMd
      ;KMMMMMMMWXXWMMMMMMMk.
        .cooc,.    .,coo:.'
	failure = Result{}
)

struct Info {
	logo []string = logo.split('\n')
	start_at int
	left_gap int
	image string
mut:
	gap int
	index int
	columns int
	can_display_image bool
	content strings.Builder = strings.new_builder(32768)
}

fn (mut info Info) start() {
	term.clear()
	info.can_display_image = os.exists_in_system_path('kitty')

	col, _ := term.get_terminal_size()
	info.columns = col

	for line in info.logo {
		if line.len > info.gap {
			info.gap = line.len
		}
	}

	info.gap += info.left_gap
}

fn (mut info Info) write_logo() {
	if info.index >= info.logo.len || info.image != '' {
		info.content.write_string(' '.repeat(info.gap))
		info.index++
		return
	}

	color := match info.index {
		0...5 { term.green }
		6...7 { term.yellow }
		8...11 { term.red }
		12...13 { term.magenta }
		else { term.blue }
	}

	str_logo := info.logo[info.index]
	str_color := term.colorize(color, str_logo)

	info.content.write_string(str_color)
	info.content.write_string(' '.repeat(info.gap - str_logo.len))
	info.index++
}

fn (mut info Info) add_line() {
	info.write_logo()
	info.content.write_string('\n')
}

fn (mut info Info) write_string(str string) {
	if info.index <= info.start_at {
		for _ in 0..info.start_at {
			info.add_line()
		}
	}

	info.write_logo()
	info.content.write_string(str)
	info.content.write_string('\n')
}

fn (mut info Info) print() {
	if info.index < info.logo.len {
		for _ in info.index..info.logo.len {
			info.write_logo()
			info.content.write_string('\n')
		}
	}

	if info.can_display_image && info.image != '' {
		image_path := os.real_path(info.image)
		if os.exists(image_path) {
			os.execute('kitty +kitten icat --align left --place ${32}x${24}@1x1 $image_path')
		}
	}

	println(info.content)
}

struct System {
	user Result
	uptime Result
	memory Result
	cpu Result
	gpu Result
	resolution Result
	storage Result
	os Result
	term Result
	machine Result
	battery Result
mut:
	song Result
}

struct DisplayDevice {
	model string [json: sppci_model]
	cores string [json: sppci_cores]
	device_type string [json: sppci_device_type]
}

struct Display {
	displays []DisplayDevice [json: SPDisplaysDataType]
}

struct StorageDevice {
	free u64 [json: free_space_in_bytes]
	size u64 [json: size_in_bytes]
	mount string [json: mount_point]
}

struct Storage {
	storages []StorageDevice [json: SPStorageDataType]
}

struct HardwareDevice {
	machine string [json: machine_name]
}

struct Machine {
	hardware []HardwareDevice [json: SPHardwareDataType]
	storages []StorageDevice [json: SPStorageDataType]
	displays []DisplayDevice [json: SPDisplaysDataType]
}

fn get_user(str string) Result {
	pieces := str.split(' ')

	if pieces.len >= 2 {
		return success(pieces[1])
	}

	return failure
}

fn get_uptime(str string) Result {
	mut re := regex.regex_opt(r'(?P<startup>[0-9]+),') or { return failure }
	start, _ := re.find(str)
	now := time.utc()
	mut startup := now

	if start >= 0 && 'startup' in re.group_map {
		startup = time.unix(re.get_group_by_name(str, 'startup').i64())
	}

	if now == startup {
		return failure
	}

	duration := (now - startup).str()

	return success(duration)
}

fn get_memory(str string) Result {
	mut total := 0.0
	mut pages_size := 0.0
	mut app := 0.0
	mut wired := 0.0
	mut compressed := 0.0

	fields := str.replace('.', '').replace('\n', '').split(' ')

	for index, field in fields {
		match field {
			'APP' { app = fields[index + 1].u64()}
			'WIRED' { wired = fields[index + 1].u64()}
			'COMPRESSED' { compressed = fields[index + 1].u64()}
			'PAGE_SIZE' { pages_size = fields[index + 1].u64()}
			'MEMORY' { total = fields[index + 1].u64()}
			else { continue }
		}
	}

	if 0 in [total, pages_size, app, wired, compressed] {
		return failure
	}

	mem_used := ((app + wired + compressed) * pages_size / 1024 / 1024) / 1024

	return success('${mem_used:.2} / $total GiB')
}

fn get_cpu(str string) Result {
	mut re := regex.regex_opt(r'CPU\s(?P<cpu>.+)\sCORES\s(?P<cores>[0-9]+)') or { return failure }
	start, _ := re.find(str)

	if start >= 0 && 'cpu' in re.group_map && 'cores' in re.group_map {
		cpu := re.get_group_by_name(str, 'cpu')
		cores := re.get_group_by_name(str, 'cores')
		return success('$cpu $cores cores (physical)')
	}

	return failure
}

fn get_gpu(data Machine) Result {
	mut model := ''
	mut cores := ''

	if data.displays.len > 0 {
		for display in data.displays {
			if display.device_type == 'spdisplays_gpu' {
				model = display.model
				cores = display.cores
				break
			}
		}
	} else {
		return failure
	}

	if cores == '' {
		return success(model)
	}

	return success('$model ($cores cores)')
}

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

	return success('$used / $total GB')
}

fn get_resolution(str string) Result {
	mut re := regex.regex_opt(r'RESOLUTION\s(?P<res>[0-9]+x[0-9]+).+@(?P<freq>[0-9]+)$') or {
		println(err)
		return failure
	}

	start, _ := re.find(str)
	if start >= 0 && 'res' in re.group_map && 'freq' in re.group_map {
		res := re.get_group_by_name(str, 'res')
		freq := re.get_group_by_name(str, 'freq')
		return success('$res @ ${freq}Hz')
	}

	return failure
}

fn get_os(str string) Result {

	mut product_name := ''
	mut product_version := ''
	mut product_build_version := ''

	fields := str.split(' ')

	for index, field in fields {
		match field {
			'ProductName' { product_name = fields[index + 1] }
			'ProductVersion' { product_version = fields[index + 1] }
			'ProductBuildVersion' { product_build_version = fields[index + 1]}
			else { continue }
		}
	}

	if product_name == '' || product_version == '' || product_build_version == '' {
		return failure
	}

	return success('$product_name $product_version ($product_build_version)')
}

fn get_term(str string) Result {
	fields := str.trim_space().split(' ')
	if fields.len > 0 {
		return success(fields[1])
	}

	return failure
}

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

fn get_battery(str string) Result {
	parts := str.trim_space().split(' ')
	if parts.len > 1 {
		return success(parts[1])
	}

	return failure
}

fn get_misc(str string) !Machine {
	return json.decode(Machine, str.trim_left('MISC '))
}

fn new_system() ?System {
	query := os.execute(r"echo \
		USER $USER \|\
		TERM $TERM_PROGRAM $TERM \|\
		UPTIME $(sysctl -n kern.boottime) \|\
		MEMORY $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) \
		PAGE_SIZE $(sysctl -n hw.pagesize) \
		APP $(($(sysctl -n vm.page_pageable_internal_count) - $(sysctl -n vm.page_purgeable_count))) \
		WIRED $(vm_stat | awk '/ wired/ { print $4 }') \
		COMPRESSED $(vm_stat | awk '/ occupied/ { printf $5 }') \|\
		CPU $(sysctl -n machdep.cpu.brand_string) \
		CORES $(sysctl -n hw.physicalcpu_max) \|\
		RESOLUTION $(screenresolution get 2>&1 | awk '/Display/ {printf $6 }') \|\
		MISC $(system_profiler SPHardwareDataType SPStorageDataType SPDisplaysDataType -detailLevel mini -json ) \|\
		OS $(awk -F'<|>' '/key|string/ {print $3}' /System/Library/CoreServices/SystemVersion.plist) \|\
		BATTERY $(pmset -g batt | grep -o '[0-9]*%')
		")

	if query.output.len == 0 {
		return none
	}

	mut user := failure
	mut uptime := failure
	mut memory := failure
	mut cpu := failure
	mut gpu := failure
	mut resolution := failure
	mut storage := failure
	mut myos := failure
	mut machine := failure
	mut battery := failure
	mut myterm := failure

	for field in query.output.split('|') {
		match true {
			field.starts_with('USER') { user = get_user(field) }
			field.starts_with('UPTIME') { uptime = get_uptime(field) }
			field.starts_with('MEMORY') { memory = get_memory(field) }
			field.starts_with('CPU') { cpu = get_cpu(field) }
			field.starts_with('RESOLUTION') { resolution = get_resolution(field) }
			field.starts_with('OS') { myos = get_os(field) }
			field.starts_with('TERM') { myterm = get_term(field) }
			field.starts_with('BATTERY') { battery = get_battery(field) }
			field.starts_with('MISC') {
				data := get_misc(field) or {
					continue
				}
				machine = get_machine(data)
				storage = get_storage(data)
				gpu = get_gpu(data)
			}
			else {continue}
		}
	}

	return System{
		user: user,
		uptime: uptime,
		memory: memory,
		cpu: cpu,
		gpu: gpu,
		resolution: resolution,
		storage: storage,
		os: myos,
		term: myterm,
		machine: machine,
		battery: battery
	}
}

fn (mut sys System) get_song() {
	data := os.execute("osascript -e 'tell application \"Music\" to artist of current track as string & \" - \" & name of current track as string'")

	result := data.output.trim_space()
	if data.exit_code == 0 && result.len > 0 {
		sys.song = success(result)
	}
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.description('System fetch written in vlang')
	fp.skip_executable()
	should_get_song := fp.bool('song', `s`, false, 'Print current playing music, works with Apple Music')
	custom_image := fp.string('image', `i`, '', 'Display custom image, only works with kitty terminal')

	mut sys := new_system()?

	mut info := Info{start_at: 2, left_gap: 4, image: custom_image}

	info.start()
	info.write_string(term.bright_yellow('╭────────────╮'))

	if sys.user.success {
		info.write_string(term.bright_yellow('│ USER       │ : ${term.underline(sys.user.result)}'))
	}

	if sys.machine.success {
		info.write_string(term.bright_yellow('│ MACHINE    │ : $sys.machine.result'))
	}

	if sys.os.success {
		info.write_string(term.bright_yellow('│ OS         │ : $sys.os.result'))
	}

	if sys.cpu.success {
		info.write_string(term.bright_yellow('│ CPU        │ : $sys.cpu.result'))
	}

	if sys.gpu.success {
		info.write_string(term.bright_yellow('│ GPU        │ : $sys.gpu.result'))
	}

	if sys.resolution.success {
		info.write_string(term.bright_yellow('│ RESOLUTION │ : $sys.resolution.result'))
	}

	if sys.memory.success {
		info.write_string(term.bright_yellow('│ MEMORY     │ : $sys.memory.result'))
	}

	if sys.storage.success {
		info.write_string(term.bright_yellow('│ STORAGE    │ : $sys.storage.result'))
	}

	if sys.uptime.success {
		info.write_string(term.bright_yellow('│ UPTIME     │ : $sys.uptime.result'))
	}

	if sys.battery.success {
		info.write_string(term.bright_yellow('│ BATTERY    │ : $sys.battery.result'))
	}

	if sys.term.success {
		info.write_string(term.bright_yellow('│ TERMINAL   │ : $sys.term.result'))
	}


	dot := '■'
	info.write_string(term.bright_yellow('├────────────┤'))
	info.write_string(term.bright_yellow('│ COLORS     │ ${term.white(dot)} ${term.gray(dot)} ${term.red(dot)} ${term.yellow(dot)} ${term.green(dot)} ${term.blue(dot)} ${term.magenta(dot)}'))
	info.write_string(term.bright_yellow('╰────────────╯'))

	if should_get_song {
		sys.get_song()
	}

	if sys.song.success {
		info.add_line()
		info.write_string(term.bright_yellow('Song : ${term.red(sys.song.result)}'))
	}

	info.print()
}
