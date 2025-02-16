import os
import regex
import term
import strings
import system

struct Result {
	success bool
	result  string
}

fn success(result string) Result {
	return Result{true, result}
}

const logo = '
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

struct Info {
	logo           []string = logo.split('\n')
	start_at       int
	left_gap       int
	image          string
	no_colour_mode bool
mut:
	gap               int
	index             int
	columns           int
	can_display_image bool
	content           strings.Builder = strings.new_builder(32768)
	remove_colours_re regex.RE        = regex.regex_opt('\x1b\\[[0-9;]*[a-zA-Z]') or { panic(err) }
}

fn (mut info Info) start() {
	$if prod { term.clear()	}

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
		0...4 { term.green }
		5...7 { term.yellow }
		8...11 { term.red }
		12...14 { term.magenta }
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
		for _ in 0 .. info.start_at {
			info.add_line()
		}
	}

	info.write_logo()
	info.content.write_string(str)
	info.content.write_string('\n')
}

fn (mut info Info) print() {
	if info.index < info.logo.len {
		for _ in info.index .. info.logo.len {
			info.write_logo()
			info.content.write_string('\n')
		}
	}

	if info.can_display_image && info.image != '' {
		image_path := os.real_path(info.image)
		if os.exists(image_path) {
			result := os.execute('kitten icat --clear --align left --place 32x24@1x4 ${image_path}')
      if result.exit_code == 0 { print(result.output) }
		}
	}

	mut to_print := info.content.str()
	if info.no_colour_mode {
		to_print = info.remove_colours_re.replace(to_print, '')
	}

	println(to_print)
}

fn main() {
	args := parse_args()

	mut sys := system.new_system()?

	mut info := Info{
		start_at: 2
		left_gap: 4
		image: args.custom_image
		no_colour_mode: args.no_colour_mode
	}

	info.start()
	info.write_string(term.bright_yellow('╭────────────╮'))

	if sys.user.success {
		info.write_string(term.bright_yellow('│ USER       │ : ${term.underline(sys.user.result)}'))
	}

	if sys.machine.success {
		info.write_string(term.bright_yellow('│ MACHINE    │ : ${sys.machine.result}'))
	}

	if sys.os.success {
		info.write_string(term.bright_yellow('│ OS         │ : ${sys.os.result}'))
	}

	if sys.cpu.success {
		info.write_string(term.bright_yellow('│ CPU        │ : ${sys.cpu.result}'))
	}

	if sys.gpu.success {
		info.write_string(term.bright_yellow('│ GPU        │ : ${sys.gpu.result}'))
	}

	if sys.resolution.success {
		info.write_string(term.bright_yellow('│ RESOLUTION │ : ${sys.resolution.result}'))
	}

	if sys.memory.success {
		info.write_string(term.bright_yellow('│ MEMORY     │ : ${sys.memory.result}'))
	}

	if sys.swap.success {
		info.write_string(term.bright_yellow('│ SWAP       │ : ${sys.swap.result}'))
	}

	if sys.storage.success {
		info.write_string(term.bright_yellow('│ STORAGE    │ : ${sys.storage.result}'))
	}

	if sys.packages.success {
		info.write_string(term.bright_yellow('│ PACKAGES   │ : ${sys.packages.result}'))
	}

	if sys.uptime.success {
		info.write_string(term.bright_yellow('│ UPTIME     │ : ${sys.uptime.result}'))
	}

	if sys.battery.success {
		info.write_string(term.bright_yellow('│ BATTERY    │ : ${sys.battery.result}'))
	}

	if sys.bluetooth.success {
		info.write_string(term.bright_yellow('│ BLUETOOTH  │ : ${sys.bluetooth.result}'))
	}

	if sys.term.success {
		info.write_string(term.bright_yellow('│ TERMINAL   │ : ${sys.term.result}'))
	}

	if !args.hide_colour_strip && !args.no_colour_mode {
		dot := "◼"
		info.write_string(term.bright_yellow('├────────────┤'))
		info.write_string(term.bright_yellow('│ COLORS     │ ${term.white(dot)} ${term.gray(dot)} ${term.red(dot)} ${term.yellow(dot)} ${term.green(dot)} ${term.blue(dot)} ${term.magenta(dot)}'))
	}

	info.write_string(term.bright_yellow('╰────────────╯'))

	if args.should_get_song {
		sys.get_song()
	}

	if sys.song.success {
		info.add_line()
		info.write_string(term.bright_yellow('Song : ${term.red(sys.song.result)}'))
	}

	info.print()
}
