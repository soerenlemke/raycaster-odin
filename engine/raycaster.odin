package engine

import "core:math"

import rl "vendor:raylib"

cast_floor :: proc(#by_ptr p: Player) {
    for y in 0 ..< SCREEN_HEIGHT {
        // rayDir for leftmost ray (x = 0) and rightmost ray (x = w)
        ray_dir_x0 := p.dir_x - p.plane_x
        ray_dir_y0 := p.dir_y - p.plane_y
        ray_dir_x1 := p.dir_x + p.plane_x
        ray_dir_y1 := p.dir_y + p.plane_y

        // Current y position compared to the center of the screen (the horizon)
        cur_y_pos := y - SCREEN_HEIGHT / 2

        // Vertical position of the camera.
        pos_z := 0.5 * SCREEN_HEIGHT

        // Horizontal distance from the camera to the floor for the current row.
        // 0.5 is the z position exactly in the middle between floor and ceiling.
        row_distance := pos_z / f64(cur_y_pos)

        // calculate the real world step vector we have to add for each x (parallel to camera plane)
        // adding step by step avoids multiplications with a weight in the inner loop
        floor_step_x := row_distance * (ray_dir_x1 - ray_dir_x0) / SCREEN_WIDTH
        floor_step_y := row_distance * (ray_dir_y1 - ray_dir_y0) / SCREEN_WIDTH

        // real world coordinates of the leftmost column. This will be updated as we step to the right.
        floor_x := p.pos_x + row_distance * ray_dir_x0
        floor_y := p.pos_y + row_distance * ray_dir_y0

        for x in 0..<SCREEN_WIDTH {
            // the cell coord is simply got from the integer parts of floorX and floorY
            cell_x := int(floor_x)
            cell_y := int(floor_y)

            // get the texture coordinate from the fractional part
            tx := int(f64(TEX_WIDTH) * (floor_x - f64(cell_x))) & (TEX_WIDTH - 1)
            ty := int(f64(TEX_HEIGHT) * (floor_y - f64(cell_y))) & (TEX_HEIGHT - 1)

            floor_x += floor_step_x
            floor_y += floor_step_y

            // choose texture and draw the pixel
            floor_texture: int = 3
            ceiling_texture: int = 6

            // floor
            color := texture[floor_texture][TEX_WIDTH * ty + tx]
            color = (color & 0xFF000000) | ((color >> 1) & 0x007F7F7F)
            screen_buffer[y][x] = color

            // ceiling (symmetrical, at screenHeight - y - 1 instead of y)
            color = texture[ceiling_texture][TEX_WIDTH * ty + tx]
            color = (color & 0xFF000000) | ((color >> 1) & 0x007F7F7F) // make a bit darker, keep alpha
            screen_buffer[SCREEN_HEIGHT - y - 1][x] = color
        }
    }
}

cast_walls :: proc(#by_ptr p: Player) {
    for x in 0 ..< SCREEN_WIDTH {
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
}