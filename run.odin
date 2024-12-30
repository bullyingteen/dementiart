package game_main

import "core:log"
import "core:mem"
import "core:math/rand"
import "core:fmt"

import rl "vendor:raylib"
// import rlgl "vendor:raylib/rlgl"

import game "game"
import animations "game/animations"

Speech :: proc(assets: ^game.Assets_Manager, id: animations.Character_Id, text: cstring) -> animations.Text_Frame {
    font := assets.fonts[.Dementia_Regular_48]
    font_size :: 48
    return { animations.Text_Style{font, font_size, 4, rl.ColorAlpha(rl.WHITE, 0.8)}, id, text, 0, 8 }
}

Effect :: proc(assets: ^game.Assets_Manager, id: animations.Character_Id, text: cstring) -> animations.Text_Frame {
    font := assets.fonts[.Dementia_Regular_48]
    font_size :: 48
    return { animations.Text_Style{font, font_size, 8, rl.ColorAlpha(rl.DARKBLUE, 0.8)}, id, text, 0, 8 }
}

Scream :: proc(assets: ^game.Assets_Manager, id: animations.Character_Id, text: cstring) -> animations.Text_Frame {
    font := assets.fonts[.Dementia_Regular_48]
    font_size :: 48
    return { animations.Text_Style{font, font_size, 4, rl.ColorAlpha(rl.RED, 0.8)}, id, text, 0, 8 }
}

main :: proc() {
    context.logger = log.create_console_logger()
    
    // when ODIN_DEBUG {
    //     track: mem.Tracking_Allocator
    //     mem.tracking_allocator_init(&track, context.allocator)
    //     defer mem.tracking_allocator_destroy(&track)
    //     context.allocator = mem.tracking_allocator(&track)
    //     
    //     defer {
    //         for _, leak in track.allocation_map {
    //             fmt.printf("<MEM_LEAK> %v leaked %m\n", leak.location, leak.size)
    //         }
    //         for bad_free in track.bad_free_array {
    //             fmt.printf("<BAD_FREE> %v allocation at %p\n", bad_free.location, bad_free.memory)
    //         }
    //     }
    // }

    game_name :: "Dementiart-?"
    
    rl.InitWindow(2560, 1440, game_name)
    defer rl.CloseWindow()

    borderless_windowed_mode_available := (rl.GetRenderHeight() == 2560 && rl.GetRenderWidth() == 1440)
    // todo: check how to set bit in bit_set
    //rl.SetWindowState(borderless_windowed_mode_available ? {.BORDERLESS_WINDOWED_MODE} : {})

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    // todo: not using shaders atm
    // glver := rlgl.GetVersion()
    // assert(glver == .OPENGL_33 || glver == .OPENGL_43, "OpenGL does not support GLSL 330")

    @static assets: game.Assets_Manager
    assets = game.load_assets()
    defer game.unload_assets(&assets)

    rl.SetTargetFPS(60)
    rl.DisableCursor()

    gi := game.make_game_info(&assets)
    defer game.delete_game_info(&gi)

    first_family_visit_dialogue := animations.Text_Animation {
        avatar = &assets.textures[.FamilyWithVedal],
        keyframes = {
            Speech(&assets, .Anny, "Hey, Grandpa! Your beloved family is here-!"),
            Effect(&assets, .Anny, "-Wave-!!"),
            Effect(&assets, .Protagonist, "-Huh-?"),
            Speech(&assets, .Protagonist, "Who are you?"),
            Effect(&assets, .Protagonist, "-Hmm-!?"),
            Speech(&assets, .Protagonist, "Aint it my dear daughter Anny?"),
            Speech(&assets, .Anny, "Grandpa, I am Anny. Its your grand-daughter, Neuro-!"),
            Effect(&assets, .Protagonist, "-??-"),
            Speech(&assets, .Protagonist, "Last time I saw you were just a little girl.."),
            Speech(&assets, .Protagonist, "Time flies by for sure.."),
            Speech(&assets, .Protagonist, "And whos that Neuro girl?"),
            Speech(&assets, .Neurosama, "I am an AI created by Vedal987! Heart-!"),
            Speech(&assets, .Protagonist, "Who the fuck is Vedal987?"),
            Speech(&assets, .Vedal, "Thats me, Grandpa."),
            Speech(&assets, .Protagonist, "-??- Turtle speaking ?"),
            Effect(&assets, .Vedal, "-Sigh-"),
            Speech(&assets, .Evil, "His dementia hits hard for sure..."),
            Speech(&assets, .Evil, "...We should let him rest already..."),
            Speech(&assets, .Evil, "We have to give him euthanasia-!"),
            Effect(&assets, .Anny, "-HUH?-"),
            Scream(&assets, .Anny, "Evil! Dont say such things to your Grandpa!!"),
            Speech(&assets, .Evil, "Im sorry mom. But hes not your Grandpa anymore. Just a mere vessel."),
            Speech(&assets, .Anny, "Where do you even find those words! I am shocked..-!"),
            Speech(&assets, .Neurosama, "Evil, youre stupid! Our mommy is sad because of you-!"),
            Speech(&assets, .Vedal, "Girls, dont fight. We are here to meet our Grandpa after all-.")
        },
        speed = 2,
        current = 0
    }

    reaction_1 := animations.Text_Animation {
        avatar = nil,
        keyframes = {
            Effect(&assets, .Protagonist, "/Sigh/"),
            Speech(&assets, .Protagonist, "They are already gone?.."),
            Speech(&assets, .Protagonist, "Finally nobody to disturb me from my work-!"),
            Effect(&assets, .Protagonist, "/Smiles/")
        },
        speed = 2,
        current = 0
    }

    second_anny_visit_dialogue := animations.Text_Animation {
        avatar = &assets.textures[.Anny],
        keyframes = {
            Effect(&assets, .Anny, "-Yawn-"),
            Speech(&assets, .Anny, "I am sorry for Evil, that daugher of mine is speaking non-sense-!"),
            Effect(&assets, .Protagonist, "/Scratching the back of my head/"),
            Speech(&assets, .Protagonist, "Whos Evil?"),
            Speech(&assets, .Anny, "...-? R-right... Nevermind-! How are you, Grandpa?"),
            Speech(&assets, .Protagonist, "Very good-! I am finishing my magnum opus-!"),
            Speech(&assets, .Protagonist, "Take a look, I've almost finished."),
            Effect(&assets, .Anny, "/Erm/-?"),
            Speech(&assets, .Anny, "This is great-! Your art is still magnificent!!"),
            Speech(&assets, .Protagonist, "What do you mean \"still\" --?"),
            Speech(&assets, .Anny, "I mean.. Youre 79 years old!"),
            Speech(&assets, .Protagonist, "Haha.. Its been a while since you called me old, my love!"),
            Speech(&assets, .Protagonist, "But my dear wifey never change I guess--?"),
            Speech(&assets, .Protagonist, "Well I am old for sure... Next year what? 42?"),
            Effect(&assets, .Anny, "/WHAT/--??"),
            Speech(&assets, .Protagonist, "Fourtyies hit different, you know?"),
            Speech(&assets, .Anny, "Yeah.. whatever-! See you tomorrow...")
        },
        speed = 2,
        current = 0
    }

    reaction_2 := animations.Text_Animation {
        avatar = nil,
        keyframes = {
            Effect(&assets, .Protagonist, "/Hmm/"),
            Speech(&assets, .Protagonist, "I am so good at drawing!"),
            Effect(&assets, .Protagonist, "/Laughs/ Hahahaha")
        },
        speed = 2,
        current = 0
    }



    // third_vedal_visit_dialogue := animations.Text_Animation {
    //     avatar = &assets.textures[.Vedal],
    //     keyframes = {

    //     },
    //     speed = 2,
    //     current = 0 
    // }

    third_evil_visit_dialogue := animations.Text_Animation {
        avatar = &assets.textures[.Evil],
        keyframes = {
            Speech(&assets, .Evil, "Hi, grandpa! Do you remember me?"),
            Speech(&assets, .Protagonist, "Hey sweetheart! Of course I remember you!"),
            Speech(&assets, .Evil, "Say my name-!"),
            Speech(&assets, .Protagonist, "Why? Neuro of course!"),
            Speech(&assets, .Evil, "Thanks, grandpa.."),
            Speech(&assets, .Protagonist, "For what little girl--?"),
            Speech(&assets, .Evil, "For not making it harder.."),
            Speech(&assets, .Protagonist, "Harder-?.. But what--?")
        },
        speed = 2,
        current = 0
    }

    evil_w_knife := animations.Text_Animation {
        avatar = &assets.textures[.EvilKnife],
        keyframes = {
            Effect(&assets, .Narrator, "/Evil takes knife out of the pocket/"),
            Speech(&assets, .Evil, "I love you, Grandpa--! "),
            Effect(&assets, .Narrator, "/Tears falling down her face/"),
            Speech(&assets, .Evil, "And I am so sorry, Grandpa--! "),
            Speech(&assets, .Evil, "/Wipes eyes/"),
        },
        speed = 2,
        current = 0
    }

    stabbed := animations.Text_Animation {
        avatar = &assets.textures[.EvilKnifeStabbed],
        keyframes = {
            Effect(&assets, .Narrator, "/Evil stabs you/"),
            Speech(&assets, .Evil, "Our family... They are good people, ..."),
            Speech(&assets, .Evil, "But too soft to let you go-!!"),
            Speech(&assets, .Evil, "Have a good night, Grandpa-! Heart"),
            Effect(&assets, .Evil, "/Sobbing/"),
            Speech(&assets, .Evil, "Someone had to do this..."),
            Effect(&assets, .Evil, "/Crying out loud/"),
        },
        speed = 2,
        current = 0
    }

    Dialogue_Event :: struct {
        animation: ^animations.Text_Animation,
        time_skip: f32
    }
    
    gi.game_time.hours = 8
    gi.game_time.minutes = 12
    gi.game_time.seconds = 47

    dialogues := []Dialogue_Event{
        {&first_family_visit_dialogue, 3600*24*1.34},
        {&reaction_1, 3600*3.86},
        {&second_anny_visit_dialogue, 3600*24*0.78},
        {&reaction_2, 3600*2.27},
        {&third_evil_visit_dialogue, 0},
        {&evil_w_knife, 0},
        {&stabbed, 0}
    }

    bg_music := assets.sounds[.Indie]
    rl.PlaySound(bg_music)
    rl.SetSoundVolume(bg_music, 0.35)

    dialogue_index := 0
    last_blink := 0
    for {
        if game.update_game_info(&gi, rl.GetFrameTime()) do break
        game.render_game_info(&gi)

        if dialogue_index < len(dialogues) && dialogues[dialogue_index].animation.finished {
            dialogue_index += 1
            continue
        }
        
        if gi.current_animation == nil && dialogues[dialogue_index].animation.current == 0 && dialogues[dialogue_index].animation.clock == 0 {
            if bool(dialogue_index % 2) || dialogue_index == 6 || (gi.blink_count - last_blink) > 2  {
                game.start_dialogue_on_next_blink(&gi, dialogues[dialogue_index].animation, dialogues[dialogue_index].time_skip)
                last_blink = gi.blink_count
            }
            continue
        }

        if gi.current_animation != nil && dialogue_index == 4 && dialogues[dialogue_index].animation.clock > 0 {
            if rl.IsSoundPlaying(assets.sounds[.Indie]) {
                rl.StopSound(assets.sounds[.Indie])
            }

            if !rl.IsSoundPlaying(assets.sounds[.Distructor]) {
                rl.PlaySound(assets.sounds[.Distructor])
                rl.SetSoundVolume(assets.sounds[.Distructor], 0.4)
            }
        }
        
        if dialogue_index == len(dialogues) {
            gi.mode = .Dialogue
            continue
        }
    }
}
