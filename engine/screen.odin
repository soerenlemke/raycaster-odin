package engine

SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 480

screen_buffer: [SCREEN_HEIGHT][SCREEN_WIDTH]u32 // y-coordinate first because it works per scanline

screen_buffer_clear :: proc() {
    for y in 0..<SCREEN_HEIGHT {
        for x in 0..<SCREEN_WIDTH {
            screen_buffer[y][x] = 0
        }
    }
}
