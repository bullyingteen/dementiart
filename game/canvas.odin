package game

import rl "vendor:raylib"

Line :: struct {
    points: [dynamic]rl.Vector2,
    radius: f32,
    color: rl.Color
}

Tool :: struct {
    texture: Image_Id,
    offset: [2]i32,
    radius: f32,
    color: rl.Color,
    sound: Sound_Id,
    volume: f32
}

Tool_Type :: enum {
    Pencil,
    Eraser
}

Canvas :: struct {
    assets: ^Assets_Manager,
    render_texture: rl.RenderTexture,
    rect: rl.Rectangle,
    background_color: rl.Color,
    texture: Image_Id,
    texture_color: rl.Color,
    tools: [Tool_Type]Tool,
    tool_id: Tool_Type,
    //tool_radius: f32,
    lines: [dynamic]Line,
    cached_state: ^rl.Texture,
    extra_state: ^rl.Texture,
}

make_pencil_tool :: proc() -> Tool {
    return {
        texture = Image_Id.Pencil,
        offset = {80, 2},
        color = rl.ColorAlpha(rl.BLACK, 0.75),
        radius = 5,
        sound = Sound_Id.Pencil,
        volume = 1
    }
}

make_eraser_tool :: proc(canvas_background_color: rl.Color) -> Tool {
    return {
        texture = Image_Id.Eraser,
        offset = {200, 8},
        color = rl.ColorAlpha(canvas_background_color, 0.15),
        radius = 32,
        sound = Sound_Id.Eraser,
        volume = 4
    }
}

delete_tool :: proc(tool: ^Tool) {
}

make_canvas :: proc(am: ^Assets_Manager, rt: rl.RenderTexture, rect: rl.Rectangle) -> Canvas {
    bgcolor :: rl.Color{0xb4, 0xb4, 0xb5, 255}

    return {
        am,
        rt,
        rect,
        bgcolor,
        Image_Id.Canvas,
        rl.ColorAlpha(rl.WHITE, 0.1),
        { 
            .Pencil = make_pencil_tool(), 
            .Eraser = make_eraser_tool(bgcolor)
        },
        .Pencil,
        {},
        nil,
        nil
    }
}

delete_canvas :: proc(canvas: ^Canvas) {
    rl.UnloadRenderTexture(canvas.render_texture)
    for &tool in canvas.tools {
        delete_tool(&tool)
    }
    for line in canvas.lines {
        if len(line.points) > 0 do delete(line.points)
    }
    delete(canvas.lines)
}

set_tool :: proc(canvas: ^Canvas, tool: Tool_Type) {
    if canvas.tool_id == tool do return

    if sound_id := canvas.tools[canvas.tool_id].sound; rl.IsSoundPlaying(canvas.assets.sounds[sound_id]) {
        rl.PauseSound(canvas.assets.sounds[sound_id])
    }

    canvas.tool_id = tool

    s := canvas.assets.sounds[canvas.tools[tool].sound]
    rl.PlaySound(s)
    rl.SetSoundVolume(s, canvas.tools[canvas.tool_id].volume)
    rl.PauseSound(s)
}

// todo: respect screen resolution
is_mouse_position_inside_canvas :: proc(canvas: Canvas) -> bool {
    canvas_points :: []rl.Vector2{ 
        {1490, 60}, 
        {2445, 75}, 
        {2335, 1310}, 
        {1332, 1248}, 
    } 

    mpos := rl.GetMousePosition()
    return rl.CheckCollisionPointPoly(mpos, raw_data(canvas_points), 4)
}

update_canvas :: proc(canvas: ^Canvas) {
    @static stroke := false

    stop_sound :: proc(canvas: ^Canvas) {
        s := canvas.assets.sounds[canvas.tools[canvas.tool_id].sound]
        if rl.IsSoundPlaying(s) {
            rl.PauseSound(s)
        }
    }

    if !is_mouse_position_inside_canvas(canvas^) {
        stroke = false
        stop_sound(canvas)
        return
    }

    // canvas.tool_radius += rl.GetMouseWheelMove()

    if rl.IsMouseButtonDown(.LEFT) {
        pos := rl.GetMousePosition()

        shift := rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)
        target_color: rl.Color = canvas.tool_id == .Eraser && shift ? canvas.background_color : canvas.tools[canvas.tool_id].color 

        if stroke && len(canvas.lines) > 0 && canvas.lines[len(canvas.lines)-1].color == target_color {
            line := &canvas.lines[len(canvas.lines)-1]

            if len(line.points)>0 && pos == line.points[len(line.points)-1] do return
            
            append(&line.points, pos)
        } else {
            l := Line{ {}, canvas.tools[canvas.tool_id].radius, target_color }
            append(&l.points, pos)
            append(&canvas.lines, l)
        }

        stroke = true
        s := canvas.assets.sounds[canvas.tools[canvas.tool_id].sound]
        rl.ResumeSound(s)
        if !rl.IsSoundPlaying(s) {
            rl.PlaySound(s)
        }
    } else {
        stroke = false
        stop_sound(canvas)
    }

    if rl.IsKeyPressed(.ENTER) {
        clear_canvas_state(canvas)
    }

    if rl.IsKeyPressed(.E) {
        set_tool(canvas, .Eraser)
    }

    if rl.IsKeyPressed(.B) {
        set_tool(canvas, .Pencil)
    }
}

render_canvas :: proc(canvas: Canvas, mpos: rl.Vector2, draw_tool := true) {
    rl.BeginTextureMode(canvas.render_texture)
    
    rl.ClearBackground(rl.BLANK)

    if canvas.cached_state != nil {
        rl.DrawTexture(canvas.cached_state^, 0, 0, rl.WHITE)
    }

    if canvas.extra_state != nil {
        rl.DrawTexturePro(canvas.extra_state^, 
            {0, 0, cast(f32)canvas.extra_state.width, cast(f32)canvas.extra_state.height},
            {1490, 60, 2335-1490, 1310-60},
            {0, 0},
            0,
            rl.WHITE
        )
    }

    for line in canvas.lines {
        if len(line.points) == 0 {
            continue
        }

        if len(line.points) >= 4 {
            rl.DrawSplineBezierQuadratic(raw_data(line.points), cast(i32)len(line.points), line.radius, line.color)
        } else if len(line.points) > 1 {
            for i in 1..<len(line.points) {
                rl.DrawLineBezier(line.points[i-1], line.points[i], line.radius, line.color)
            }
        } else {
            rl.DrawCircleV(line.points[0], line.radius/2, line.color)
        }
    }
    
    rl.EndTextureMode()

    // rl.DrawRectangleRec(canvas.rect, canvas.background_color)
    rl.DrawTexturePro(canvas.render_texture.texture, 
        {0, f32(canvas.render_texture.texture.height) - canvas.rect.height, canvas.rect.width, -canvas.rect.height}, 
        canvas.rect,
        {0,0},
        0,
        rl.WHITE
    )

    canvas_tex := canvas.assets.textures[canvas.texture]
    rl.DrawTexturePro(canvas_tex, 
        /*source*/{ 0, 0, f32(canvas_tex.width), f32(canvas_tex.height) }, 
        /*destination*/{0,0, f32(canvas.render_texture.texture.width), f32(canvas.render_texture.texture.height)},
        {0,0},
        0,
        canvas.texture_color
    )
    
    if draw_tool {
        tool_tex := canvas.assets.textures[ canvas.tools[canvas.tool_id].texture ]
        off := canvas.tools[canvas.tool_id].offset
    
        left_offset := i32(mpos.x) < off[0] ? f32(off[0]) - mpos.x : 0
    
        rl.DrawTexturePro(tool_tex, 
            { 0, 0, f32(tool_tex.width), f32(tool_tex.height) }, 
            { mpos.x - f32(off[0]), mpos.y - f32(off[1]), f32(tool_tex.width), f32(tool_tex.height) },
            {0,0},
            0,
            rl.WHITE
        )
    }
}
