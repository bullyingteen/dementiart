package game_animations

import rl "vendor:raylib"

Curtain_Stage :: enum {
    In,
    Wait,
    Out,
    Done,
}

Curtain_Animation :: struct {
    frames_in: int,
    frames_wait: int,
    frames_out: int,
    color: rl.Color,
    stage: Curtain_Stage,
    current: int,
    paused: bool
}

update_curtain_animation :: proc(anim: ^Curtain_Animation, window_size: rl.Vector2) {
    anim.current += 1
    switch anim.stage {
        case .In:
            if anim.current >= anim.frames_in {
                rl.DrawRectangleV({0,0}, window_size, anim.color)
                anim.stage = .Wait
                anim.current = 0
                return
            }

            h := max( 0, rl.EaseSineInOut(f32(anim.current), 0, window_size.y, f32(anim.frames_in)+1) )
            rl.DrawRectangleV({0, 0}, {window_size.x, h}, anim.color)
        case .Wait:
            rl.DrawRectangleV({0,0}, window_size, anim.color)
            
            if anim.current >= anim.frames_wait {
                anim.stage = .Out
                anim.current = 0
                return
            }
        case .Out:
            if anim.current >= anim.frames_out {
                anim.stage = .Done
                anim.current = 0
                return
            }
            
            h := max( 0, f32(window_size.y)-rl.EaseSineInOut(f32(anim.current), 0, window_size.y, f32(anim.frames_out)+1) )
            rl.DrawRectangleV({0, 0}, {window_size.x, h}, anim.color)
        case .Done:
            return
    }
}

reset_curtain_animation :: proc(anim: ^Curtain_Animation) {
    anim.current = 0
    anim.stage = .In
}
