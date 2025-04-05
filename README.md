# Language Arena

A multiplayer language learning game built with LÖVE and LÖVE Potion, playable on PC and Nintendo Switch.

## Description

Language Arena is a competitive multiplayer game where players learn Chinese or Japanese characters while battling it out in an arena. Players can:
- Choose between Chinese or Japanese characters
- Move around the arena using controller input
- Collect boxes containing character meanings
- Punch other players to knock them back
- Score points by collecting boxes

## Requirements

### For PC (LÖVE):
- [LÖVE 12.0](https://love2d.org/) or later
- A game controller (Xbox, PlayStation, or Switch Pro Controller recommended)

### For Nintendo Switch (LÖVE Potion):
- [LÖVE Potion](https://lovebrew.org/)
- A Nintendo Switch with homebrew access
- A game controller (Switch Pro Controller recommended)

## Installation

### PC Version:
1. Download and install LÖVE 12.0 from [love2d.org](https://love2d.org/)
2. Clone this repository
3. Run the game by dragging the project folder onto the LÖVE executable

### Nintendo Switch Version:
1. Install LÖVE Potion following the instructions at [lovebrew.org](https://lovebrew.org/)
2. Build the game using the LÖVE Potion bundler
3. Install the resulting NRO file on your Switch

## Nintendo Switch Installation

Once the files are done extracting, transfer the executable (3dsx, nro, wuhb) binary to your microSD card:

```
sdmc:/switch/lovepotion/lovepotion.nro
```

It is likely that the parent directory does not exist yet, so the folder will need to be created.

Now create a folder called `game` inside of the `lovepotion` directory. Inside of this will be your source files for what LÖVE Potion will be running. Inside of `game` should be a file named `main.lua`. The content of this file is the main entry point, and for this tutorial will be a basic "Hello World".

After all files have been created, simply launch LÖVE Potion from the Homebrew Menu (3DS, Switch) or Home Menu (Wii U) and it will run your game.

### Switch-Specific Notes

- The game is configured to run at 1280x720 resolution on the Switch
- Source Han Sans font is not used on the Switch platform to prevent crashes
- Controller support is optimized for the Switch's gamepad
- Error logging is available to help diagnose any issues

## Controls

- **Left Analog Stick**: Move character (works with both Joy-Cons and Pro Controller)
- **A Button**: Jump
- **B Button**: Fast fall
- **X Button**: Punch
- **Start Button**: Quit game
- **A Button (Menu)**: Select Chinese
- **B Button (Menu)**: Select Japanese

### Controller Support
- Nintendo Switch Pro Controller
- Joy-Cons (attached or detached)
- Xbox Controller
- PlayStation Controller

Note: When using Joy-Cons, the left Joy-Con's analog stick controls movement. The game automatically detects whether you're using Joy-Cons or a Pro Controller and adjusts the controls accordingly.

## Game Features

- Multiplayer support for up to 4 players
- Dynamic character spawning
- Physics-based movement and combat
- Score tracking
- Colorful arena environment
- Character display billboard

## Development

This game is built using:
- LÖVE 12.0
- LÖVE Potion for Nintendo Switch support
- Lua programming language

### Project Structure
- `main.lua`: Entry point
- `game.lua`: Main game logic
- `player.lua`: Player mechanics
- `characters.lua`: Character data

## License

This project is open source and available under the MIT License.

## Credits

Created by [Your Name]

## Support

For issues and feature requests, please open an issue on the GitHub repository. 