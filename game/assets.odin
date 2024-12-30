package game

import "core:log"
import rl "vendor:raylib"

Image_Id :: enum {
    Background,
    Canvas,
    Journal,
    Eraser,
    Pencil,
    Family,
    FamilyWithVedal,
    Pause,
    
    Vedal,
    Anny,
    Neurosama,
    Evil,
    EvilKnife,
    EvilKnifeStabbed,
}

Sound_Id :: enum {
    Pencil,
    Eraser,
    Indie,
    Distructor,
}

Font_Id :: enum {
    Dementia_Regular_16,
    Dementia_Regular_24,
    Dementia_Regular_32,
    Dementia_Regular_48,
    VT323_Regular_24,
    VT323_Regular_32,
}

Assets_Manager :: struct {
    images: [Image_Id]rl.Image,
    textures: [Image_Id]rl.Texture,
    waves: [Sound_Id]rl.Wave,
    sounds: [Sound_Id]rl.Sound,
    fonts: [Font_Id]rl.Font,
}

// todo: shaders
// blur_shader := rl.LoadShader(nil, "shaders/blur.fs")
// defer rl.UnloadShader(blur_shader)
// assert(rl.IsShaderValid(blur_shader))

// render_w_loc := rl.GetShaderLocation(blur_shader, "renderWidth")
// render_w_val := f32(window_size.x)
// rl.SetShaderValue(blur_shader, rl.ShaderLocationIndex(render_w_loc), &render_w_val, .FLOAT)

load_assets :: proc() -> (am: Assets_Manager) {
    
    In_Memory_Image :: struct {
        file: cstring,
        data: []u8
    }
    
    // note: baking images in the executable data
    in_memory_images :: [Image_Id]In_Memory_Image{
        .Background = { "../assets/background.png", #load("../assets/background.png") },
        .Canvas = { "../assets/canvas.jpg", #load("../assets/canvas.jpg") },
        .Journal = { "../assets/journal.png", #load("../assets/journal.png") },
        .Eraser = { "../assets/eraser.png", #load("../assets/eraser.png") },
        .Pencil = { "../assets/pencil.png", #load("../assets/pencil.png") },
        .Family = { "../assets/family.png", #load("../assets/family.png") },
        .FamilyWithVedal = { "../assets/family_w_vedal.png", #load("../assets/family_w_vedal_2.png") },
        .Pause = { "../assets/pause.png", #load("../assets/pause.png") },
        .Vedal = { "../assets/vedal.png", #load("../assets/vedal.png") },
        .Anny = { "../assets/anny.png", #load("../assets/anny.png") },
        .Neurosama = { "../assets/neurosama.png", #load("../assets/neurosama.png") },
        .Evil = { "../assets/evil.png", #load("../assets/evil.png") },
        .EvilKnife = { "../assets/evil_knife.png", #load("../assets/evil_knife.png") },
        .EvilKnifeStabbed = { "../assets/evil_knife_stab.png", #load("../assets/evil_knife_stab.png") },
    }

    In_Memory_Wave :: struct {
        file: cstring,
        data: []u8
    }

    // note: baking sounds in the executable data
    in_memory_waves :: [Sound_Id]In_Memory_Wave {
        .Pencil = { "../assets/pencil_sfx.mp3", #load("../assets/pencil_sfx.mp3") },
        .Eraser = { "../assets/eraser_sfx.mp3", #load("../assets/eraser_sfx.mp3") },
        .Indie = { "../assets/indie.mp3", #load("../assets/indie.mp3") },
        .Distructor = { "../assets/distructor.mp3", #load("../assets/distructor.mp3") },
    }

    In_Memory_Font :: struct {
        file: cstring,
        data: []u8,
        font_size: int
    }

    dementiart :: #load("../assets/Dementiart-Regular.ttf")
    vt323 :: #load("../assets/VT323-Regular.ttf")
    in_memory_fonts :: [Font_Id]In_Memory_Font {
        .Dementia_Regular_16 = { "../assets/Dementiart-Regular.ttf", dementiart, 16 },
        .Dementia_Regular_24 = { "../assets/Dementiart-Regular.ttf", dementiart, 24 },
        .Dementia_Regular_32 = { "../assets/Dementiart-Regular.ttf", dementiart, 32 },
        .Dementia_Regular_48 = { "../assets/Dementiart-Regular.ttf", dementiart, 48 },
        .VT323_Regular_24 = { "../assets/VT323-Regular.ttf", vt323, 24 },
        .VT323_Regular_32 = { "../assets/VT323-Regular.ttf", vt323, 32 }
    }

    file_ext :: proc(file: cstring) -> cstring {
        length := len(file)
        position := max(length - 4, 0)
        return rl.TextSubtext(file, cast(i32)position, 4)
    }

    for in_memory_image, id in in_memory_images {
        ext := file_ext(in_memory_image.file)
        am.images[id] = rl.LoadImageFromMemory(ext, raw_data(in_memory_image.data), cast(i32)len(in_memory_image.data))
        assert(rl.IsImageValid(am.images[id]))
        log.infof("Loaded Image[%v] from memory: %s (%i bytes)", id, ext, len(in_memory_image.data))

        am.textures[id] = rl.LoadTextureFromImage(am.images[id])
        assert(rl.IsTextureValid(am.textures[id]))
    }

    for in_memory_wave, id in in_memory_waves {
        ext := file_ext(in_memory_wave.file)
        am.waves[id] = rl.LoadWaveFromMemory(ext, raw_data(in_memory_wave.data), cast(i32)len(in_memory_wave.data))
        assert(rl.IsWaveValid(am.waves[id]))
        log.infof("Loaded Wave[%v] from memory: %s (%i bytes)", id, ext, len(in_memory_wave.data))

        am.sounds[id] = rl.LoadSoundFromWave(am.waves[id])
        assert(rl.IsSoundValid(am.sounds[id]))
    }

    for in_memory_font, id in in_memory_fonts {
        ext := file_ext(in_memory_font.file)
        am.fonts[id] = rl.LoadFontFromMemory(ext, raw_data(in_memory_font.data), cast(i32)len(in_memory_font.data), cast(i32)in_memory_font.font_size, nil, 0)
        assert(rl.IsFontValid(am.fonts[id]))
        log.infof("Loaded Font[%v] from memory: %s (%i bytes)", id, ext, len(in_memory_font.data))
    }

    return
}

unload_assets :: proc(am: ^Assets_Manager) {
    for id in Image_Id {
        rl.UnloadTexture(am.textures[id])
        rl.UnloadImage(am.images[id])
    }

    for id in Sound_Id {
        rl.UnloadSound(am.sounds[id])
        rl.UnloadWave(am.waves[id])
    }

    for id in Font_Id {
        rl.UnloadFont(am.fonts[id])
    }
}

