package game_animations

import rl "vendor:raylib"

Game_Time :: struct {
    style: Text_Style,
    year: int,
    month: int,
    day: int,
    hours: int,
    minutes: int,
    seconds: f32
}

update_game_time_animation :: proc(gt: ^Game_Time, dt: f32) {
    gt.seconds += dt

    for gt.seconds >= 60 {
        gt.seconds -= 60
        gt.minutes += 1
    }

    for gt.minutes >= 60 {
        gt.minutes -= 60
        gt.hours += 1
    }

    for gt.hours >= 24 {
        gt.hours -= 24
        gt.day += 1
    }

    for gt.day >= 31 {
        gt.day -= 31
        gt.month += 1
    }

    for gt.month >= 12 {
        gt.month -= 12
        gt.year += 1
    }
}

import "core:fmt"
import "core:strings"

render_game_time_animation :: proc(gt: Game_Time) {
    colon_duration :: 60
    Colon :: struct {
        frame: int,
        toggle: bool,
    }
    @static colon := Colon{0, true}
    
    colon.frame += 1
    if colon.frame > colon_duration {
        colon.frame = 0
        colon.toggle = !colon.toggle
    }

    clock_: [32]u8
    time_str_ := fmt.bprintf(clock_[:], colon.toggle ? "%02i:%02i.%02i\x00" : "%02i %02i %02i\x00", gt.hours, gt.minutes, int(gt.seconds))
    
    time_box := rl.MeasureTextEx(gt.style.font, strings.unsafe_string_to_cstring(time_str_), gt.style.font_size, gt.style.font_spacing)
    
    rl.DrawRectangleRounded({10, 10, f32(time_box.x + 32), f32(time_box.y + 16)}, 4, 0, rl.ColorAlpha(rl.DARKBLUE, 0.8))
    rl.DrawTextEx(gt.style.font, strings.unsafe_string_to_cstring(time_str_), 
        {10 + 16, 10 + 8}, 
        gt.style.font_size, gt.style.font_spacing, gt.style.color
    )

    date_: [32]u8
    date_str_ := fmt.bprintf(date_[:], colon.toggle ? "%02i/%02i/%04i\x00" : "%02i %02i %04i\x00", gt.day, gt.month, gt.year)
    date_box := rl.MeasureTextEx(gt.style.font, strings.unsafe_string_to_cstring(date_str_), gt.style.font_size, gt.style.font_spacing)

    rl.DrawRectangleRounded({10 + time_box.x + 32 + 16, 10, date_box.x + 32, date_box.y + 16}, 4, 0, rl.ColorAlpha(rl.DARKBROWN, 0.8))
    rl.DrawTextEx(gt.style.font, strings.unsafe_string_to_cstring(date_str_), 
        {10 + time_box.x + 32 + 16 + 16, 10 + 8}, 
        gt.style.font_size, gt.style.font_spacing, gt.style.color
    )
}
