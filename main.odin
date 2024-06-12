package gtime

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(.NONE)
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		if len(track.bad_free_array) > 0 {
			fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}
	rl.InitWindow(400, 800, "gtime")
	//t = time.time_add(time.now(), cast(time.Duration)-59 * time.Second)

	args := os.args[1:]
	split_args: []string
	wait_minutes, wait_seconds: f64
	for i in 0 ..< len(args) {
		split_args = strings.split(args[0], ":", context.temp_allocator)
		fmt.println(split_args)
		wait_minutes = strconv.atof(split_args[0])
		wait_seconds = strconv.atof(split_args[1])
		fmt.println(wait_minutes, ":", wait_seconds, sep = "")
	}

	should_close := false
	should_check_time := true
	seconds_passed: cstring
	color: rl.Color = rl.LIGHTGRAY
	wait_time: time.Time = time.now()
	width := rl.GetScreenWidth() / 2
	height := rl.GetScreenHeight() / 2
	buff: [8]byte
	t := time.now()
	s: f64
	for should_close == false {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		switch should_check_time {
		case true:
			if (time.duration_milliseconds(time.since(wait_time)) >= 100) {
				s = time.duration_seconds(time.since(t))
				wait_time = time.now()
				seconds_passed = strings.clone_to_cstring(
					strconv.ftoa(buff[:], s, 'f', 1, 64),
					context.temp_allocator,
				)
				if (s >= wait_minutes * 60 + wait_seconds) {
					should_check_time = false
					color = rl.GRAY
				}
			}
		}
		rl.DrawText(seconds_passed, width, height, 18, color)

		key := rl.GetKeyPressed()
		if (key == rl.KeyboardKey.Q || key == rl.KeyboardKey.ESCAPE) {
			should_close = true
		}
		rl.EndDrawing()
	}
}
