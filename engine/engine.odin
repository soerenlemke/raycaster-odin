package engine

/*
    TODO: notes from the blog on performance

    There are at least two issues holding back speed of the raycaster code in this tutorial, 
    which you can take into account if you'd like to make a super fast raycaster for very 
    high resolutions:

    - Raycasting works with vertical stripes, but the screen buffer in memory is laid out 
    with horizontal scanlines. So drawing vertical stripes is bad for memory locality for 
    caching (it is in fact a worst case scenario), and the loss of good caching may hurt the 
    speed more than some of the 3D computations on modern machines. It may be possible to 
    program this with better caching behavior (e.g. processing multiple stripes at once, 
    using a cache-oblivious transpose algorithm, or having a 90 degree rotated raycaster), 
    but for simplicity the rest of this tutorial ignores this caching issue.
    - This is using software blitting with SDL (in QuickCG, in redraw()), which is slow for 
    large resolutions compared to hardware rendering. Likely QuickCG's usage of SDL itself 
    is not optimal and e.g. using OpenGL (even for software rendering) may be faster, so 
    that may be fixable behind the scenes. Since this CG tutorial is about software rendering 
    this issue is ignored here as well.
*/

import "core:slice"

import rl "vendor:raylib"

MAP_WIDTH :: 24
MAP_HEIGHT :: 24
TEX_WIDTH :: 64
TEX_HEIGHT :: 64

texture: [8][dynamic]u32

world_map: [MAP_WIDTH][MAP_HEIGHT]int = {
    {8,8,8,8,8,8,8,8,8,8,8,4,4,6,4,4,6,4,6,4,4,4,6,4},
    {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
    {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,6},
    {8,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6},
    {8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
    {8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,6,6,6,0,6,4,6},
    {8,8,8,8,0,8,8,8,8,8,8,4,4,4,4,4,4,6,0,0,0,0,0,6},
    {7,7,7,7,0,7,7,7,7,0,8,0,8,0,8,0,8,4,0,4,0,6,0,6},
    {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,0,0,0,0,0,6},
    {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,0,0,0,0,4},
    {7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,6,0,6,0,6},
    {7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,4,6,0,6,6,6},
    {7,7,7,7,0,7,7,7,7,8,8,4,0,6,8,4,8,3,3,3,0,3,3,3},
    {2,2,2,2,0,2,2,2,2,4,6,4,0,0,6,0,6,3,0,0,0,0,0,3},
    {2,2,0,0,0,0,0,2,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
    {2,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
    {1,0,0,0,0,0,0,0,1,4,4,4,4,4,6,0,6,3,3,0,0,0,3,3},
    {2,0,0,0,0,0,0,0,2,2,2,1,2,2,2,6,6,0,0,5,0,5,0,5},
    {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
    {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5},
    {2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
    {2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
    {2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,5,5,5,5,5,5,5,5,5}
}

// TODO: refactor for loading assets
// maybe loading assets into some "asset store"?
assets_load :: proc() {
    texture_files := [8]cstring{
        "assets/eagle.png",
        "assets/redbrick.png",
        "assets/purplestone.png",
        "assets/greystone.png",
        "assets/bluestone.png",
        "assets/mossy.png",
        "assets/wood.png",
        "assets/colorstone.png",
    }

    // generate some textures
    for i in 0..<8 {
        img := rl.LoadImage(texture_files[i])
        defer rl.UnloadImage(img)

        // Ensure the format matches our u32 buffer (R8G8B8A8)
        rl.ImageFormat(&img, .UNCOMPRESSED_R8G8B8A8)

        pixel_count := int(img.width) * int(img.height)
        resize(&texture[i], pixel_count)

        // Reinterpret the raw pointer as a slice
        pixels := (^u32)(img.data)
        pixel_slice := slice.from_ptr(pixels, pixel_count)
        copy(texture[i][:], pixel_slice)
    }
}