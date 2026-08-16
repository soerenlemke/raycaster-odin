package engine

import "core:math"

cast_column :: proc(x: int, p: Player) {
	camera_x := 2 * f64(x) / f64(SCREEN_WIDTH) - 1
	ray_dir_x := p.dir_x + p.plane_x * camera_x
	ray_dir_y := p.dir_y + p.plane_y * camera_x

	map_x := int(p.pos_x)
	map_y := int(p.pos_y)

	side_dist_x: f64
	side_dist_y: f64

	delta_dist_x := math.abs(1 / ray_dir_x)
	delta_dist_y := math.abs(1 / ray_dir_y)
	perp_wall_dist: f64

	step_x: int
	step_y: int
	hit: bool
	side: int

	if ray_dir_x < 0 {
		step_x = -1
		side_dist_x = (p.pos_x - f64(map_x)) * delta_dist_x
	} else {
		step_x = 1
		side_dist_x = (f64(map_x) + 1.0 - p.pos_x) * delta_dist_x
	}
	if ray_dir_y < 0 {
		step_y = -1
		side_dist_y = (p.pos_y - f64(map_y)) * delta_dist_y
	} else {
		step_y = 1
		side_dist_y = (f64(map_y) + 1.0 - p.pos_y) * delta_dist_y
	}

	for !hit {
		if side_dist_x < side_dist_y {
			side_dist_x += delta_dist_x
			map_x += step_x
			side = 0
		} else {
			side_dist_y += delta_dist_y
			map_y += step_y
			side = 1
		}
		if world_map[map_x][map_y] > 0 do hit = true
	}

	if side == 0 do perp_wall_dist = side_dist_x - delta_dist_x
	else do perp_wall_dist = side_dist_y - delta_dist_y

	line_height := int(SCREEN_HEIGHT / perp_wall_dist)

	draw_start := -line_height / 2 + SCREEN_HEIGHT / 2
	if draw_start < 0 do draw_start = 0
	draw_end := line_height / 2 + SCREEN_HEIGHT / 2
	if draw_end >= SCREEN_HEIGHT do draw_end = SCREEN_HEIGHT - 1

	tex_num := world_map[map_x][map_y] - 1

	wall_x: f64
	if side == 0 do wall_x = p.pos_y + perp_wall_dist * ray_dir_y
	else do wall_x = p.pos_x + perp_wall_dist * ray_dir_x
	wall_x -= math.floor(wall_x)

	tex_x := int(wall_x * f64(TEX_WIDTH))
	if side == 0 && ray_dir_x > 0 do tex_x = TEX_WIDTH - tex_x - 1
	if side == 1 && ray_dir_y < 0 do tex_x = TEX_WIDTH - tex_x - 1

	step := 1.0 * f64(TEX_HEIGHT) / f64(line_height)
	tex_pos := (f64(draw_start) - f64(SCREEN_HEIGHT) / 2 + f64(line_height) / 2) * step

	for y in draw_start ..< draw_end {
		tex_y := int(tex_pos) & (TEX_HEIGHT - 1)
		tex_pos += step
		color := texture[tex_num][TEX_HEIGHT * tex_x + tex_y]
		if side == 1 do color = (color & 0xFF000000) | ((color >> 1) & 0x007F7F7F)
		screen_buffer[y][x] = color
	}
}