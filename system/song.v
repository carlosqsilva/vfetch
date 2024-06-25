module system

import os

@[inline]
pub fn (mut sys System) get_song() {
	data := os.execute('osascript -e \'tell application "Music" to artist of current track as string & " - " & name of current track as string\'')

	result := data.output.trim_space()
	if data.exit_code == 0 && result.len > 0 {
		sys.song = success(result)
	}
}

