package main

import "core:c"
import "core:math"

import rl "vendor:raylib"

MAP_WIDTH :: 24
MAP_HEIGHT :: 24
SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 480

world_map: [MAP_WIDTH][MAP_HEIGHT]int = {
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

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

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin raycaster")
    rl.SetTargetFPS(60)

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

            //perform DDA
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

                //Check if ray has hit a wall
                if world_map[map_x][map_y] > 0 do hit = true;
            }

            //Calculate distance projected on camera direction (Euclidean distance would give fisheye effect!)
            if side == 0 do perp_wall_dist = side_dist_x - delta_dist_x
            else do perp_wall_dist = side_dist_y - delta_dist_y
            
            //Calculate height of line to draw on screen
            lineHeight := int(SCREEN_HEIGHT / perp_wall_dist)

            //calculate lowest and highest pixel to fill in current stripe
            drawStart := -lineHeight / 2 + SCREEN_HEIGHT / 2
            if(drawStart < 0) do drawStart = 0
            drawEnd := lineHeight / 2 + SCREEN_HEIGHT / 2;
            if(drawEnd >= SCREEN_HEIGHT) do drawEnd = SCREEN_HEIGHT - 1;

            //choose wall color
            color: rl.Color
            switch(world_map[map_x][map_y])
            {
                case 1: color = rl.RED
                case 2: color = rl.GREEN
                case 3: color = rl.BLUE
                case 4: color = rl.WHITE
                case: color = rl.YELLOW
            }

            //give x and y sides different brightness
            if (side == 1) do color = color / 2

            //draw the pixels of the stripe as a vertical line
            rl.DrawLine(c.int(x), c.int(drawStart), c.int(x), c.int(drawEnd), color)
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
