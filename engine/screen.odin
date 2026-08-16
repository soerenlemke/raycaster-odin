package engine

import rl "vendor:raylib"

SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 480

screen_buffer: [SCREEN_HEIGHT][SCREEN_WIDTH]u32
screen_texture: rl.Texture2D

screen_init :: proc() {
	img := rl.GenImageColor(SCREEN_WIDTH, SCREEN_HEIGHT, rl.BLACK)
	screen_texture = rl.LoadTextureFromImage(img)
	rl.UnloadImage(img)
}

screen_shutdown :: proc() {
	rl.UnloadTexture(screen_texture)
}

screen_present :: proc() {
	rl.UpdateTexture(screen_texture, &screen_buffer[0][0])
	rl.DrawTexture(screen_texture, 0, 0, rl.WHITE)
}

screen_buffer_clear :: proc() {
	for y in 0 ..< SCREEN_HEIGHT {
		for x in 0 ..< SCREEN_WIDTH {
			screen_buffer[y][x] = 0
		}
	}
}