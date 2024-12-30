package game

import rl "vendor:raylib"
import animations "animations"

import "core:time"
import "core:log"
import "core:math/rand"
import "core:fmt"
import "core:strings"

Game_Mode :: enum {
    Paint,
    Dialogue,
    Journal,
    Pause,
}

Game_Info :: struct {
    window_size: rl.Vector2,
    dialogue_box: rl.Rectangle,
    assets: ^Assets_Manager,
    canvas: Canvas,
    mode: Game_Mode,
    game_time: animations.Game_Time,
    blink: animations.Curtain_Animation,
    blink_timer: f32,
    blink_interval: f32,
    random_blink_interval: proc() -> f32,
    blink_count: int,
    next_canvas_state_on_blink: ^rl.Texture,
    next_time_skip_on_blink: f32, // in seconds
    next_animation_on_blink: ^animations.Text_Animation,
    current_animation: ^animations.Text_Animation,
    paused_mouse_position: rl.Vector2,
    mode_to_resume: Game_Mode,
}

make_game_info :: proc(assets: ^Assets_Manager) -> Game_Info {
    ws := rl.Vector2{ cast(f32)rl.GetRenderWidth(), cast(f32)rl.GetRenderHeight() }
    
    DIALOGUE_BOX_DELIMITER :f32: 12
    DIALOGUE_BOX_POSITION_Y :f32: (DIALOGUE_BOX_DELIMITER - 1) / DIALOGUE_BOX_DELIMITER
    DIALOGUE_BOX_HEIGHT_Y :f32: 1 / DIALOGUE_BOX_DELIMITER

    db := rl.Rectangle{ 0, ws.y * DIALOGUE_BOX_POSITION_Y, ws.x, ws.y * DIALOGUE_BOX_HEIGHT_Y }
    cb := rl.Rectangle{ 0, 0, ws.x, ws.y - db.height }
    
    crt := rl.LoadRenderTexture(i32(ws.x), i32(ws.y))
    
    return {
        window_size = ws,
        dialogue_box = db,
        assets = assets,
        canvas = make_canvas(assets, crt, cb),
        mode = .Paint,
        game_time = {
            style = { assets.fonts[.VT323_Regular_32], 32, 2, rl.WHITE },
            year = 2000,
            month = 4,
            day = 24,
            hours = 14,
            minutes = 44,
            seconds = 11
        },
        blink = {
            frames_in = 8,
            frames_wait = 4,
            frames_out = 8,
            color = rl.ColorAlpha(rl.BLACK, 0.9),
            stage = .Done,
            current = 0
        },
        blink_timer = 0,
        blink_interval = 5 + 10 * rand.float32(),
        random_blink_interval = proc() -> f32 { return 5 + 5 * rand.float32() },
        blink_count = 0,
        next_canvas_state_on_blink = nil,
        next_time_skip_on_blink = 0,
        next_animation_on_blink = nil,
        current_animation = nil,
        paused_mouse_position = {},
        mode_to_resume = .Paint,
    }
}

delete_game_info :: proc(gi: ^Game_Info) {
    delete_canvas(&gi.canvas)
}

start_dialogue_on_next_blink :: proc(gi: ^Game_Info, anim: ^animations.Text_Animation, dt: f32 = 0, canvas: ^rl.Texture = nil) {
    gi.next_animation_on_blink = anim
    gi.next_time_skip_on_blink = dt
    gi.next_canvas_state_on_blink = canvas
}

// todo: find way to clone Texture on gpu
_cached_texture_data: rl.Texture
cache_canvas_state :: proc(canvas: ^Canvas) {

    if canvas.cached_state != nil {
        rl.UnloadTexture(canvas.cached_state^)
        canvas.cached_state = nil
    }

    temporary_image := rl.LoadImageFromTexture(canvas.render_texture.texture)
    defer rl.UnloadImage(temporary_image)
    
    _cached_texture_data = rl.LoadTextureFromImage(temporary_image)
    canvas.cached_state = &_cached_texture_data

    for &line in canvas.lines {
        if len(line.points) > 0 do delete(line.points)
    }
    clear(&canvas.lines)
}

clear_canvas_state :: proc(canvas: ^Canvas) {
    screenshot := rl.LoadImageFromTexture(canvas.render_texture.texture)
    defer rl.UnloadImage(screenshot)
    
    t := time.now()
    dt, ok := time.time_to_compound(t)
    assert(ok)

    filename_buf: [256]u8
    s := fmt.bprintf(filename_buf[:], "./painting_%04i_%02i_%02i_%02i_%02i.png\x00", dt.year, dt.month, dt.day, dt.hour, dt.minute)
    rl.ExportImage(screenshot, strings.unsafe_string_to_cstring(s))

    if canvas.cached_state != nil do rl.UnloadTexture(canvas.cached_state^)

    canvas.cached_state = nil
    canvas.extra_state = nil
    for &line in canvas.lines {
        if len(line.points) > 0 do delete(line.points)
    }
    clear(&canvas.lines)
}

// returns true if should quit the game
update_game_info :: proc(gi: ^Game_Info, dt: f32) -> bool {
    esc := rl.IsKeyPressed(.ESCAPE)
    if gi.mode == .Dialogue && esc {
        return true
    }

    if gi.mode == .Pause {
        if rl.IsKeyPressed(.Q) {
            return true
        }
        if esc {
            gi.mode = gi.mode_to_resume
            rl.SetMousePosition(i32(gi.paused_mouse_position.x), i32(gi.paused_mouse_position.y))
        }
        return false
    } else if esc {
        gi.mode_to_resume = gi.mode
        gi.paused_mouse_position = rl.GetMousePosition()
        gi.mode = .Pause
        return false
    }

    gi.blink_timer += dt
    if gi.blink_timer >= gi.blink_interval {
        animations.reset_curtain_animation(&gi.blink)
        gi.blink_count += 1
        gi.blink_timer = 0
        gi.blink_interval = gi.random_blink_interval()
    }

    animations.update_game_time_animation(&gi.game_time, dt)

    if gi.mode == .Paint do update_canvas(&gi.canvas)
    return false
}

render_game_info :: proc(gi: ^Game_Info) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    if gi.mode == .Dialogue || (gi.mode == .Pause && gi.mode_to_resume == .Dialogue) {
        rl.ClearBackground(rl.BLACK)
        rl.DrawTextEx(gi.assets.fonts[.VT323_Regular_32], "Thanks for playing!", {100, 100}, 32, 2, rl.WHITE)
        rl.DrawTextEx(gi.assets.fonts[.VT323_Regular_32], "Unfortunately it's all I made in time! But there's a lot more I wanted... :(", {100, 200}, 32, 2, rl.WHITE)
        rl.DrawTextEx(gi.assets.fonts[.VT323_Regular_32], "In memory of my Grandpa", {100, 300}, 32, 2, rl.WHITE)
        rl.DrawTextEx(gi.assets.fonts[.VT323_Regular_32], "by vince (discord: @bullyingteen)", {100, 400}, 32, 2, rl.WHITE)
        return
    }

    // draw background first
    rl.DrawTexture(gi.assets.textures[.Background], 0, 0, rl.WHITE)

    animations.render_game_time_animation(gi.game_time)
    
    if gi.current_animation != nil {
        kf, text := animations.update_text_animation(gi.current_animation)
        animations.render_text_animation(gi.current_animation.avatar, gi.dialogue_box, kf, text)
        
        if gi.current_animation.finished && gi.blink.stage == .Done {
            animations.reset_curtain_animation(&gi.blink)
            gi.blink_count += 1
            gi.blink_timer = 0
            gi.blink_interval = gi.random_blink_interval()
        }
    }

    render_canvas(gi.canvas, gi.mode == .Pause ? gi.paused_mouse_position : rl.GetMousePosition(), gi.mode == .Paint)

    if gi.blink.stage != .Done {
        animations.update_curtain_animation(&gi.blink, gi.window_size)
    }

    if gi.blink.stage == .Wait {
        if gi.current_animation == nil {
            if gi.next_animation_on_blink != nil {
                gi.current_animation = gi.next_animation_on_blink
                gi.next_animation_on_blink = nil
            }
    
            if gi.next_time_skip_on_blink != 0 {
                animations.update_game_time_animation(&gi.game_time, gi.next_time_skip_on_blink)
                gi.next_time_skip_on_blink = 0
            }
    
            if gi.next_canvas_state_on_blink != nil {
                cache_canvas_state(&gi.canvas)
                gi.canvas.extra_state = gi.next_canvas_state_on_blink
                gi.next_canvas_state_on_blink = nil
            }
        } else if gi.current_animation.finished {
            gi.current_animation = nil
        }
    }

    if gi.mode == .Pause {
        rl.DrawTexture(gi.assets.textures[.Pause], 0, 0, rl.WHITE)
    }
}