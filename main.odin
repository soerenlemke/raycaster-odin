package main

import "core:c"
import "core:math"
import "core:slice"

import rl "vendor:raylib"

import "engine"



main :: proc() {
    player := engine.player_init()

    rl.InitWindow(engine.SCREEN_WIDTH, engine.SCREEN_HEIGHT, "Odin raycaster")
    rl.SetTargetFPS(60)

    engine.load_assets()

    // setup for passing the buffer to raylib in the main loop
    screen_image := rl.GenImageColor(engine.SCREEN_WIDTH, engine.SCREEN_HEIGHT, rl.BLACK)
    screen_texture := rl.LoadTextureFromImage(screen_image)
    rl.UnloadImage(screen_image)
    defer rl.UnloadTexture(screen_texture)

	for !rl.WindowShouldClose() {
        frame_time: f64 = f64(rl.GetFrameTime())
        engine.player_update_speed(&player, frame_time)
	    
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

        for x in 0..<engine.SCREEN_WIDTH {
            //calculate ray position and direction
            camera_x: f64 = 2 * f64(x) / f64(engine.SCREEN_WIDTH) - 1
            ray_dir_x := player.dir_x + player.plane_x * camera_x
            ray_dir_y := player.dir_y + player.plane_y * camera_x

            // which box the map are we in
            map_x := int(player.pos_x)
            map_y := int(player.pos_y)

            // length of ray from current position to next x or y-side
            side_dist_x: f64
            side_dist_y: f64

            // length of ray from one x or y-side to next x or y-side 
            // -> IEEE 754 supported by Odin simplifies formulas
            delta_dist_x := math.abs(1 / ray_dir_x)
            delta_dist_y := math.abs(1 / ray_dir_y)
            perp_wall_dist: f64

            // what direction to step in x or y-direction (either +1 or -1)
            step_x: int
            step_y: int

            hit: bool // was there a wall hit?
            side: int  // was a NS or a EW wall hit?

            // calculate step and initial sideDist
            if (ray_dir_x < 0)
            {
                step_x = -1;
                side_dist_x = (player.pos_x - f64(map_x)) * delta_dist_x;
            }
            else
            {
                step_x = 1;
                side_dist_x = (f64(map_x) + 1.0 - player.pos_x) * delta_dist_x;
            }
            if (ray_dir_y < 0)
            {
                step_y = -1;
                side_dist_y = (player.pos_y - f64(map_y)) * delta_dist_y;
            }
            else
            {
                step_y = 1;
                side_dist_y = (f64(map_y) + 1.0 - player.pos_y) * delta_dist_y;
            }

            // perform DDA
            for (hit == false)
            {
                //jump to next map square, either in x-direction, or in y-direction
                if side_dist_x < side_dist_y {
                    side_dist_x += delta_dist_x
                    map_x += step_x
                    side = 0
                } else {
                    side_dist_y += delta_dist_y
                    map_y += step_y
                    side = 1
                }

                // Check if ray has hit a wall
                if engine.world_map[map_x][map_y] > 0 do hit = true;
            }

            // Calculate distance projected on camera direction (Euclidean distance would give fisheye effect!)
            if side == 0 do perp_wall_dist = side_dist_x - delta_dist_x
            else do perp_wall_dist = side_dist_y - delta_dist_y
            
            // Calculate height of line to draw on screen
            line_height := int(engine.SCREEN_HEIGHT / perp_wall_dist)

            // calculate lowest and highest pixel to fill in current stripe
            draw_start := -line_height / 2 + engine.SCREEN_HEIGHT / 2
            if(draw_start < 0) do draw_start = 0
            draw_end := line_height / 2 + engine.SCREEN_HEIGHT / 2;
            if(draw_end >= engine.SCREEN_HEIGHT) do draw_end = engine.SCREEN_HEIGHT - 1;

            //texturing calculations
            tex_num := engine.world_map[map_x][map_y] - 1; // 1 subtracted from it so that texture 0 can be used!

            // calculate value of wallX
            wall_x: f64 //where exactly the wall was hit
            if (side == 0) do wall_x = player.pos_y + perp_wall_dist * ray_dir_y
            else do wall_x = player.pos_x + perp_wall_dist * ray_dir_x
            wall_x -= math.floor(wall_x)

            // x coordinate on the texture
            tex_x := int(wall_x * f64(engine.TEX_WIDTH))
            if(side == 0 && ray_dir_x > 0) do tex_x = engine.TEX_WIDTH - tex_x - 1
            if(side == 1 && ray_dir_y < 0) do tex_x = engine.TEX_WIDTH - tex_x - 1

            // How much to increase the texture coordinate per screen pixel
            step: f64 = 1.0 * f64(engine.TEX_HEIGHT) / f64(line_height)
            // Starting texture coordinate
            tex_pos: f64 = (f64(draw_start) - f64(engine.SCREEN_HEIGHT) / 2 + f64(line_height) / 2) * step
            for y in draw_start..<draw_end {
                // Cast the texture coordinate to integer, and mask with (tex_height - 1) in case of overflow
                tex_y := int(tex_pos) & (engine.TEX_HEIGHT - 1)
                tex_pos += step
                color := engine.texture[tex_num][engine.TEX_HEIGHT * tex_x + tex_y]
                // make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
                if side == 1 do color = (color & 0xFF000000) | ((color >> 1) & 0x007F7F7F)
                engine.screen_buffer[y][x] = color
            }
        }

        rl.UpdateTexture(screen_texture, &engine.screen_buffer[0][0])
        rl.DrawTexture(screen_texture, 0, 0, rl.WHITE)

        engine.screen_buffer_clear() // clear the buffer instead of cls()
        engine.player_move(&player)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
