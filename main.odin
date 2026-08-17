package main

import rl "vendor:raylib"
import "engine"

main :: proc() {
	player := engine.player_init()

	rl.InitWindow(engine.SCREEN_WIDTH, engine.SCREEN_HEIGHT, "Odin raycaster")
	rl.SetTargetFPS(60)

	engine.assets_load()
	engine.screen_init()
	defer engine.screen_shutdown()

	for !rl.WindowShouldClose() {
		frame_time := f64(rl.GetFrameTime())
		engine.player_update_speed(&player, frame_time)

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		engine.cast_floor(player)
		engine.cast_walls(player)

		engine.screen_present()
		engine.screen_buffer_clear()
		engine.player_move(&player)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}