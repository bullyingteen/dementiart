package game_animations

import rl "vendor:raylib"

Character_Id :: enum {
    Vedal,
    Anny,
    Neurosama,
    Evil,
    Protagonist,
    Narrator,
    Developer,
}

Character_Info :: struct {
    name: cstring,
    color: rl.Color,
}

Characters := [Character_Id]Character_Info {
    .Vedal = {"Vedal:  ", rl.GREEN},
    .Anny = {"Anny:  ", rl.PINK},
    .Neurosama = {"Neuro:  ", rl.YELLOW},
    .Evil = {"Evil:  ", rl.RED},
    .Protagonist = {"Me:  ", rl.GRAY},
    .Narrator = {"Narrator:  ", rl.DARKBLUE},
    .Developer = {"Developer:  ", rl.PURPLE}
}
