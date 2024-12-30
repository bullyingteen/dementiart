package game_animations

import "core:log"
import rl "vendor:raylib"

Text_Style :: struct {
    font: rl.Font,
    font_size: f32,
    font_spacing: f32,
    color: rl.Color,
}

Text_Frame :: struct {
    using style: Text_Style,
    character: Character_Id,
    data: cstring,
    offset: int,
    timeout: int
}

Text_Animation :: struct {
    avatar: ^rl.Texture,
    keyframes: []Text_Frame,
    speed: int,
    current: int,
    waiting_for_input: bool,
    finished: bool,
    paused: bool,
    clock: int
}

update_text_animation :: proc(anim: ^Text_Animation) -> (^Text_Frame, cstring) {
    assert(anim != nil)

    if anim.finished do return &anim.keyframes[anim.current], anim.keyframes[anim.current].data

    if anim.waiting_for_input {
        if rl.IsKeyPressed(.SPACE) {
            anim.waiting_for_input = false
            if (anim.current+1) < len(anim.keyframes) {
                anim.current += 1
                anim.clock = 0
                kf := &anim.keyframes[anim.current]
                return kf, rl.TextSubtext(kf.data, 0, cast(i32)kf.offset)
            } else {
                anim.finished = true
                return &anim.keyframes[anim.current], anim.keyframes[anim.current].data
            }
        }
        kf := &anim.keyframes[anim.current]
        return kf, kf.data
    }
    
    anim.clock += 1
    frame := anim.clock / anim.speed

    if frame > (len(anim.keyframes[anim.current].data) + anim.keyframes[anim.current].timeout) {
        anim.waiting_for_input = true
        return &anim.keyframes[anim.current], anim.keyframes[anim.current].data
    }
    else if frame > len(anim.keyframes[anim.current].data) {
        return &anim.keyframes[anim.current], anim.keyframes[anim.current].data
    }
    else {
        kf := &anim.keyframes[anim.current]
        subtext := rl.TextSubtext(kf.data, 0, cast(i32)(kf.offset + frame))
        return kf, subtext
    }
}

render_text_animation :: proc(avatar: ^rl.Texture, rect: rl.Rectangle, kf: ^Text_Frame, text: cstring) {
    max_message_length :: 85
    assert( (len(Characters[kf.character].name) + len(kf.data)) < max_message_length )

    // draw avatar
    if avatar != nil do rl.DrawTexture(avatar^, 20, rl.GetRenderHeight() - avatar.height - i32(rect.height), rl.WHITE)

    rect_offset_x :: 0.275
    rect_offset_y :: 0.275

    rl.DrawRectangleRec(rect, rl.BLACK)
    rl.DrawRectangleLinesEx(rect, 5, rl.GRAY)
    
    pos := rl.Vector2{rect.x + rect.height*rect_offset_x, rect.y + rect.height*rect_offset_y}

    rl.DrawTextEx(kf.font, Characters[kf.character].name, pos, kf.font_size, 2, Characters[kf.character].color)
    pos.x += rl.MeasureTextEx(kf.font, Characters[kf.character].name, kf.font_size, 2).x + 2*kf.font_spacing

    rl.DrawTextEx(kf.font, text, pos, kf.font_size, kf.font_spacing, kf.color)
    pos.x += rl.MeasureTextEx(kf.font, text, kf.font_size, kf.font_spacing).x + 2*kf.font_spacing

    //////////////////

    caret_duration :: 30
    Caret :: struct {
        frame: int,
        toggle: bool
    }
    @static caret := Caret{0, true}
    
    update_caret :: proc() {
        caret.frame += 1
        if caret.frame > caret_duration {
            caret.toggle = !caret.toggle
            caret.frame = 0
        }
    }
    
    update_caret()
    if caret.toggle {
        rl.DrawTextEx(kf.font, "/", pos, kf.font_size, kf.font_spacing, rl.ColorAlpha(rl.WHITE, 0.7))
    }
}
