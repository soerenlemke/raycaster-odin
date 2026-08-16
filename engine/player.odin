package engine

import "core:math"

import rl "vendor:raylib"

Player :: struct {
	// x and y start position
	pos_x: f64,
	pos_y: f64,

	// initial direction vector
	dir_x: f64,
	dir_y: f64,

	// the 2d raycaster version of camera plane
	plane_x: f64,
	plane_y: f64,

	// speed modifiers, recalculated every frame
	move_speed: f64, // squares/second
	rot_speed:  f64, // radians/second
}

player_init :: proc() -> Player {
	return Player{
		pos_x   = 22,
		pos_y   = 12,
		dir_x   = -1,
		dir_y   = 0,
		plane_x = 0,
		plane_y = 0.66,
	}
}

player_update_speed :: proc(p: ^Player, frame_time: f64) {
	p.move_speed = frame_time * 5.0
	p.rot_speed  = frame_time * 3.0
}

player_move :: proc(p: ^Player) {
    // move forward if no wall in front of you
    if rl.IsKeyDown(.W) {
        if world_map[int(p.pos_x + p.dir_x * f64(p.move_speed))][int(p.pos_y)] == 0 do p.pos_x += p.dir_x * f64(p.move_speed)
        if world_map[int(p.pos_x)][int(p.pos_y + p.dir_y * f64(p.move_speed))] == 0 do p.pos_y += p.dir_y * f64(p.move_speed)
    }

    //move backwards if no wall behind you
    if rl.IsKeyDown(.S) {
        if(world_map[int(p.pos_x - p.dir_x * f64(p.move_speed))][int(p.pos_y)] == 0) do p.pos_x -= p.dir_x * f64(p.move_speed)
        if(world_map[int(p.pos_x)][int(p.pos_y - p.dir_y * f64(p.move_speed))] == 0) do p.pos_y -= p.dir_y * f64(p.move_speed)
    }

    // rotate to the right
    if rl.IsKeyDown(.D) {
        // both camera direction and camera plane must be rotated
        old_dir_x := p.dir_x
        p.dir_x = p.dir_x * math.cos(-p.rot_speed) - p.dir_y * math.sin(-p.rot_speed)
        p.dir_y = old_dir_x * math.sin(-p.rot_speed) + p.dir_y * math.cos(-p.rot_speed)

        old_plane_x := p.plane_x
        p.plane_x = p.plane_x * math.cos(-p.rot_speed) - p.plane_y * math.sin(-p.rot_speed)
        p.plane_y = old_plane_x * math.sin(-p.rot_speed) + p.plane_y * math.cos(-p.rot_speed)
    }

    // rotate to the left
    if rl.IsKeyDown(.A) {
        // both camera direction and camera plane must be rotated
        old_dir_x := p.dir_x
        p.dir_x = p.dir_x * math.cos(p.rot_speed) - p.dir_y * math.sin(p.rot_speed)
        p.dir_y = old_dir_x * math.sin(p.rot_speed) + p.dir_y * math.cos(p.rot_speed)

        old_plane_x := p.plane_x
        p.plane_x = p.plane_x * math.cos(p.rot_speed) - p.plane_y * math.sin(p.rot_speed)
        p.plane_y = old_plane_x * math.sin(p.rot_speed) + p.plane_y * math.cos(p.rot_speed)
    }
}