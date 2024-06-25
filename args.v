module main

import flag
import os

struct Args {
	should_get_song    bool
	custom_image       string
	hide_colour_strip  bool
	no_colour_mode     bool
}

@[inline]
fn parse_args() &Args {
  mut fp := flag.new_flag_parser(os.args)
	fp.description('System fetch written in vlang')
	fp.skip_executable()
	
	return &Args {
		should_get_song: fp.bool('song', `s`, false, 'Print current playing music, works with Apple Music')
		custom_image: fp.string('image', `i`, '', 'Display custom image, only works with kitty terminal')
		hide_colour_strip: fp.bool('no-colour-demo', 0, false, 'Hide the colour demo strip')
		no_colour_mode: fp.bool('no-colour', `c`, false, 'Disables colour formatting')
	}
}


