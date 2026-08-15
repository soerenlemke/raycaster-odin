package main

import "core:c"
import "core:math"

import rl "vendor:raylib"

MAP_WIDTH :: 24
MAP_HEIGHT :: 24
SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 480
TEX_WIDTH :: 64
TEX_HEIGHT :: 64

world_map: [MAP_WIDTH][MAP_HEIGHT]int = {
    {4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,7,7,7,7,7,7,7,7},
    {4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
    {4,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
    {4,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
    {4,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
    {4,0,4,0,0,0,0,5,5,5,5,5,5,5,5,5,7,7,0,7,7,7,7,7},
    {4,0,5,0,0,0,0,5,0,5,0,5,0,5,0,5,7,0,0,0,7,7,7,1},
    {4,0,6,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
    {4,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,1},
    {4,0,8,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
    {4,0,0,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,7,7,7,1},
    {4,0,0,0,0,0,0,5,5,5,5,0,5,5,5,5,7,7,7,7,7,7,7,1},
    {6,6,6,6,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
    {8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4},
    {6,6,6,6,6,6,0,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
    {4,4,4,4,4,4,0,4,4,4,6,0,6,2,2,2,2,2,2,2,3,3,3,3},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,0,0,0,6,2,0,0,5,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
    {4,0,6,0,6,0,0,0,0,4,6,0,0,0,0,0,5,0,0,0,0,0,0,2},
    {4,0,0,5,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
    {4,0,6,0,6,0,0,0,0,4,6,0,6,2,0,0,5,0,0,2,0,0,0,2},
    {4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
    {4,4,4,4,4,4,4,4,4,4,1,1,1,2,2,2,2,2,2,3,3,3,3,3}
}

buffer: [SCREEN_HEIGHT][SCREEN_WIDTH]u32 // y-coordinate first because it works per scanline

main :: proc() {
    // x and y start position
    pos_x: f64 = 22
    pos_y: f64 = 12

    // initial direction vector
    dir_x: f64 = -1
    dir_y: f64 = 0

    // the 2d raycaster version of camera plane
    plane_x: f64 = 0
    plane_y: f64 = 0.66

    texture: [8][dynamic]u32
    for i in 0..<8 {
        resize(&texture[i], TEX_WIDTH * TEX_HEIGHT)
    }

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin raycaster")
    rl.SetTargetFPS(60)

    pack_rgba :: proc(r, g, b: u32) -> u32 {
        return r | (g << 8) | (b << 16) | (0xFF << 24)
    }

    //generate some textures
    for x in 0..<TEX_WIDTH {
        for y in 0..<TEX_HEIGHT {
            xorcolor := u32((x * 256 / TEX_WIDTH) ~ (y * 256 / TEX_HEIGHT))
            ycolor := u32(y * 256 / TEX_HEIGHT)
            xycolor := u32(y * 128 / TEX_HEIGHT + x * 128 / TEX_WIDTH)

            cross := u32(254 * int(x != y && x != TEX_WIDTH - y))
            bricks := u32(192 * int(x % 16 != 0 && y % 16 != 0))

            texture[0][TEX_WIDTH * y + x] = pack_rgba(cross, 0, 0)                    // flat red mit schwarzem Kreuz
            texture[1][TEX_WIDTH * y + x] = pack_rgba(xycolor, xycolor, xycolor)      // sloped greyscale
            texture[2][TEX_WIDTH * y + x] = pack_rgba(xycolor, xycolor, 0)            // sloped yellow gradient
            texture[3][TEX_WIDTH * y + x] = pack_rgba(xorcolor, xorcolor, xorcolor)   // xor greyscale
            texture[4][TEX_WIDTH * y + x] = pack_rgba(0, xorcolor, 0)                 // xor green
            texture[5][TEX_WIDTH * y + x] = pack_rgba(bricks, 0, 0)                   // red bricks
            texture[6][TEX_WIDTH * y + x] = pack_rgba(ycolor, 0, 0)                   // red gradient
            texture[7][TEX_WIDTH * y + x] = pack_rgba(128, 128, 128)                  // flat grey
        }
    }

    // setup for passing the buffer to raylib in the main loop
    screen_image := rl.GenImageColor(SCREEN_WIDTH, SCREEN_HEIGHT, rl.BLACK)
    screen_texture := rl.LoadTextureFromImage(screen_image)
    rl.UnloadImage(screen_image)
    defer rl.UnloadTexture(screen_texture)

	for !rl.WindowShouldClose() {
        frame_time: f64 = f64(rl.GetFrameTime())

        //speed modifiers
        move_speed: f64 = frame_time * 5.0 // the constant value is in squares/second
        rot_speed:  f64 = frame_time * 3.0 // the constant value is in radians/second
	    
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

        for x in 0..<SCREEN_WIDTH {
            //calculate ray position and direction
            camera_x: f64 = 2 * f64(x) / f64(SCREEN_WIDTH) - 1
            ray_dir_x := dir_x + plane_x * camera_x
            ray_dir_y := dir_y + plane_y * camera_x

            // which box the map are we in
            map_x := int(pos_x)
            map_y := int(pos_y)

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
                side_dist_x = (pos_x - f64(map_x)) * delta_dist_x;
            }
            else
            {
                step_x = 1;
                side_dist_x = (f64(map_x) + 1.0 - pos_x) * delta_dist_x;
            }
            if (ray_dir_y < 0)
            {
                step_y = -1;
                side_dist_y = (pos_y - f64(map_y)) * delta_dist_y;
            }
            else
            {
                step_y = 1;
                side_dist_y = (f64(map_y) + 1.0 - pos_y) * delta_dist_y;
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
                if world_map[map_x][map_y] > 0 do hit = true;
            }

            // Calculate distance projected on camera direction (Euclidean distance would give fisheye effect!)
            if side == 0 do perp_wall_dist = side_dist_x - delta_dist_x
            else do perp_wall_dist = side_dist_y - delta_dist_y
            
            // Calculate height of line to draw on screen
            line_height := int(SCREEN_HEIGHT / perp_wall_dist)

            // calculate lowest and highest pixel to fill in current stripe
            draw_start := -line_height / 2 + SCREEN_HEIGHT / 2
            if(draw_start < 0) do draw_start = 0
            draw_end := line_height / 2 + SCREEN_HEIGHT / 2;
            if(draw_end >= SCREEN_HEIGHT) do draw_end = SCREEN_HEIGHT - 1;

            //texturing calculations
            tex_num := world_map[map_x][map_y] - 1; // 1 subtracted from it so that texture 0 can be used!

            // calculate value of wallX
            wall_x: f64 //where exactly the wall was hit
            if (side == 0) do wall_x = pos_y + perp_wall_dist * ray_dir_y
            else do wall_x = pos_x + perp_wall_dist * ray_dir_x
            wall_x -= math.floor(wall_x)

            // x coordinate on the texture
            tex_x := int(wall_x * f64(TEX_WIDTH))
            if(side == 0 && ray_dir_x > 0) do tex_x = TEX_WIDTH - tex_x - 1
            if(side == 1 && ray_dir_y < 0) do tex_x = TEX_WIDTH - tex_x - 1

            // How much to increase the texture coordinate per screen pixel
            step: f64 = 1.0 * f64(TEX_HEIGHT) / f64(line_height)
            // Starting texture coordinate
            tex_pos: f64 = (f64(draw_start) - f64(SCREEN_HEIGHT) / 2 + f64(line_height) / 2) * step
            for y in draw_start..<draw_end {
                // Cast the texture coordinate to integer, and mask with (tex_height - 1) in case of overflow
                tex_y := int(tex_pos) & (TEX_HEIGHT - 1)
                tex_pos += step
                color := texture[tex_num][TEX_HEIGHT * tex_x + tex_y]
                // make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
                if side == 1 do color = (color & 0xFF000000) | ((color >> 1) & 0x007F7F7F)
                buffer[y][x] = color
            }
        }

        rl.UpdateTexture(screen_texture, &buffer[0][0])
        rl.DrawTexture(screen_texture, 0, 0, rl.WHITE)

        // clear the buffer instead of cls()
        for y in 0..<SCREEN_HEIGHT {
            for x in 0..<SCREEN_WIDTH {
                buffer[y][x] = 0
            }
        }

        // move forward if no wall in front of you
        if rl.IsKeyDown(.W) {
            if world_map[int(pos_x + dir_x * f64(move_speed))][int(pos_y)] == 0 do pos_x += dir_x * f64(move_speed)
            if world_map[int(pos_x)][int(pos_y + dir_y * f64(move_speed))] == 0 do pos_y += dir_y * f64(move_speed)
        }
        //move backwards if no wall behind you
        if rl.IsKeyDown(.S) {
            if(world_map[int(pos_x - dir_x * f64(move_speed))][int(pos_y)] == 0) do pos_x -= dir_x * f64(move_speed)
            if(world_map[int(pos_x)][int(pos_y - dir_y * f64(move_speed))] == 0) do pos_y -= dir_y * f64(move_speed)
        }
        // rotate to the right
        if rl.IsKeyDown(.D) {
            // both camera direction and camera plane must be rotated
            old_dir_x := dir_x
            dir_x = dir_x * math.cos(-rot_speed) - dir_y * math.sin(-rot_speed)
            dir_y = old_dir_x * math.sin(-rot_speed) + dir_y * math.cos(-rot_speed)

            old_plane_x := plane_x
            plane_x = plane_x * math.cos(-rot_speed) - plane_y * math.sin(-rot_speed)
            plane_y = old_plane_x * math.sin(-rot_speed) + plane_y * math.cos(-rot_speed)
        }
        // rotate to the left
        if rl.IsKeyDown(.A) {
            // both camera direction and camera plane must be rotated
            old_dir_x := dir_x
            dir_x = dir_x * math.cos(rot_speed) - dir_y * math.sin(rot_speed)
            dir_y = old_dir_x * math.sin(rot_speed) + dir_y * math.cos(rot_speed)

            old_plane_x := plane_x
            plane_x = plane_x * math.cos(rot_speed) - plane_y * math.sin(rot_speed)
            plane_y = old_plane_x * math.sin(rot_speed) + plane_y * math.cos(rot_speed)
        }

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
