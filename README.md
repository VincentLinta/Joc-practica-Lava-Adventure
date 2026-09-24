# Lava Adventure

## Description

Lava Adventure is a 2D action-platformer built with Godot Engine 4.6.2. The player progresses through 10 levels of increasing difficulty, dealing with environmental hazards (lava, traps, water) and active enemies, before facing a two-phase final boss encounter. The project combines core platforming mechanics (movement, jumping, melee attacks) with supporting systems for UI/UX, save/load progress, and audio, and is validated through an automated test suite built with GUT (Godot Unit Test).

## Key Features

- 10 levels with a progressive difficulty curve, from tutorial-style introductory levels to a water-physics level and a lava-themed level.
- Core platformer mechanics: running, jumping, and melee combat.
- Active enemies (e.g. `ShooterEnemy`, `ElectricEnemy`) integrated into later levels.
- A two-phase final boss fight on Level 10: a miniboss (`TurretGuardian`) followed by the final boss (`BossFinal` / Blood Demon).
- Score tracking, high scores per level, and level unlocking logic.
- Persistent save/load system for progress and audio settings.
- Background music and sound effects with per-category volume control.
- Automated unit and integration testing with GUT.

## Controls

| Action | Key(s) |
|---|---|
| Move left | A / Left Arrow |
| Move right | D / Right Arrow |
| Jump | Space / W / Up Arrow |
| Attack | Left Mouse Button / J |
| Shield Throw | E / R |

## Technologies Used

- **Godot Engine 4.6.2**
- **GDScript**
- **GUT (Godot Unit Test)** for automated testing
- **Git** for version control

## System Requirements

- Godot Engine 4.x (the project was developed and verified in Godot 4.6.2).
- A desktop OS compatible with Godot 4.x (development and the final build were carried out on Windows).
- Exact hardware requirements (CPU/GPU/RAM) have not been benchmarked and are not stated here to avoid overclaiming.

## Installation

1. Clone or download this repository.
2. Open **Godot Engine 4.6.2**.
3. Import the project using the `project.godot` file.
4. Wait for Godot to finish importing and processing resources before running the project.

## Running the Project

**From the editor:**
1. Open the project in Godot.
2. Use **Run Project** to start from the main scene, or run an individual scene to test it in isolation.

**Final build:**
A final build for Windows was generated and tested across all 10 levels directly from the exported build (not only from the editor), including verification of the in-build settings window (resolution, fullscreen/windowed/borderless).

## Project Structure

```text
res://
├── addons/
│   └── gut/                     # GUT (Godot Unit Test) addon
├── assets/                      # Sprites, images and other visual resources
├── teste/
│   └── unit/
│       └── test_game_state.gd   # Automated test suite
├── *.tscn                       # Scenes (levels, menus, UI)
├── *.gd                         # GDScript source files
├── *.mp3                        # Music and sound effects
├── .gutconfig.json              # GUT test runner configuration
├── project.godot                # Godot project configuration
└── README.md                    # This file
```

### Level scenes

```text
res://Level1.tscn
res://Level2.tscn
res://Level3.tscn
res://Level4.tscn
res://Level5.tscn
res://Level6.tscn
res://Level7.tscn
res://Level8.tscn
res://Level9.tscn
res://Level10.tscn
```

The existence and successful loading of all 10 level scenes are covered by the automated test suite.

## Software Architecture

The project's core is built on Autoload (singleton) modules, keeping global state, persistence, and gameplay systems separated:

- **GameState** — global game state: current level, score, per-level high scores, level-unlock rules, and level completion logic.
- **SaveManager** — persists progress and settings to `user://save.cfg` via a save/load system.
- **MusicManager** — manages background music and transitions between tracks.
- **SFXManager** — manages sound effects and UI sounds.
- **Player** — player character: health, damage handling, death, and the special mechanics used during the final boss encounter.
- **TurretGuardian** — the Level 10 miniboss, with its own health, attack, and death-sequence logic; transitions into the final boss encounter.
- **BossFinal** — the final boss (Blood Demon): activation, movement, attack patterns, HP/death handling, and triggering of the final portal.
- **FinalPortal** — manages the portal that becomes available after the final boss is defeated, and the level-completion flow.

## Main Scripts and Components

| Component | Responsibility | Relation to other systems |
|---|---|---|
| `GameState` | Global game state: score, high scores, unlocked levels, current level, level completion rules | Reads/writes progress through `SaveManager` |
| `SaveManager` | Persists progress and audio settings to `user://save.cfg` | Used by `GameState` for load/save operations |
| `MusicManager` | Background music playback and track switching | Triggered by level/scene transitions and boss-fight state changes |
| `SFXManager` | Sound effects and UI sounds | Used across gameplay and UI scenes |
| `Player` | Player movement, health, damage, death, and boss-fight-specific mechanics | Interacts with enemies, hazards, `TurretGuardian`, and `BossFinal` |
| `TurretGuardian` | Miniboss logic (health, attack, death sequence) | Transitions the encounter into `BossFinal` on Level 10 |
| `BossFinal` | Final boss logic (movement, attacks, HP, death, portal activation) | Activates `FinalPortal` on death |
| `FinalPortal` | End-of-level portal and completion flow | Triggered exclusively by `BossFinal`'s death on Level 10 |

This is a documentation-level overview of responsibilities; it does not reproduce the implementation.

## Gameplay and Levels

- **Level 1–2** — introductory/tutorial levels covering basic mechanics: jumping, movement, and collisions.
- **Level 3–5** — intermediate mechanics: moving platforms and traps, with a progressively increasing difficulty.
- **Level 6–7** — active enemies on platforms (`ShooterEnemy`, `ElectricEnemy`).
- **Level 8** — a water level with modified local physics (reduced horizontal speed, a stronger jump, and adjusted gravity).
- **Level 9** — a lava-themed level, the most difficult of the standard levels, with extended lethal zones.
- **Level 10** — the final level, containing the two-phase boss encounter described below and the victory screen.

## Boss Fight

**Phase 1 — TurretGuardian (miniboss):** a stationary tower-type enemy with a maximum of 550 HP, player detection, a health bar, hurt/death animations, and a death sound sequence. It attacks with the `FireOrb` projectile (35 damage), aimed at the player's position at the moment of firing (no continuous homing).

**Transition:** three seconds after the miniboss's death sequence, the player receives a set of buffs for the final encounter — health is fully restored, a shield is activated, and a damage multiplier is applied — while the music switches to the final boss theme.

**Phase 2 — Blood Demon (final boss, `BossFinal`):** 5000 HP maximum, with four distinct, non-overlapping attacks:
- **Punch** — melee attack, 75 damage, strong knockback.
- **Blood Ball** — ranged projectile, 50 damage, fired every 2 seconds; its direction is calculated once at launch (non-homing).
- **Earthquake** — area attack, 100 damage, every 10 seconds.
- **Vomit attack** — triggered at 75%, 50%, and 25% health thresholds.

On death, the boss grants a large score bonus, followed by a death sequence (dedicated animation, death sounds, and a final screen shake).

The **WinScreen** is triggered exclusively by the death of the Blood Demon — not by player death and not by the standard level portal (which is disabled for this level). It displays "YOU WIN", the subtitle "THE BLOOD DEMON IS DEFEATED" / "YOU FINISHED THE LAVA ADVENTURE", the current score and high score, with **PLAY AGAIN** (replays the level without losing saved progress) and **MAIN MENU** options.

## Save System and Progress

Progress is managed centrally through `GameState`, with persistence handled by `SaveManager`:

```text
GameState
   │
   ├── score / high score
   ├── per-level high scores
   ├── unlocked level
   │
   └── SaveManager
          │
          └── user://save.cfg
```

`SaveManager` persists the unlocked level, total score, per-level high scores, and audio volume settings to `user://save.cfg`, with safe handling of missing or corrupted save files (falling back to default values).

## Audio

- **MusicManager** handles background music and switches tracks based on game progress and key moments (e.g. the transition into the final boss fight, and from the boss theme to the victory screen).
- **SFXManager** handles sound effects, including jump, attack, impact, and enemy-death sounds, as well as UI sounds.
- Volume is adjustable per category (master, music, effects) and persisted through `SaveManager`.

## Testing

Automated testing is implemented with **GUT (Godot Unit Test)**.

Configuration file: `res://.gutconfig.json`

```json
{
  "dirs": ["res://teste"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "log_level": 1,
  "should_exit": true,
  "should_maximize": false
}
```

Test suite location: `res://teste/unit/test_game_state.gd`

### Latest recorded test results

- 24 tests executed, 24/24 passed (100% success rate)
- 356 assertions
- Total execution time: approximately 7.08 seconds

### Coverage areas

- `GameState`: level unlocking, score and bonus logic, high scores, level completion, load/reset behavior.
- Core player behavior, including damage and the buffs received before the final boss fight.
- `SaveManager`: save/load persistence and audio settings, including missing/corrupted save file cases.
- Existence and loading of all 10 level scenes, and level-to-level flow/progression.
- `BossFinal`: structure, attack behavior, and Level 10 dependencies.
- `FinalPortal` behavior.
- `TurretGuardian` and its integration into the transition to the final boss.
- Integration tests for level completion combined with save persistence.

Tests use mock objects (e.g. mock player and boss objects) instead of loading full real scenes, and automatically back up and restore the real `user://save.cfg` file so that test runs do not affect actual saved progress.

## Build

A final build for Windows was generated using Godot's export templates and tested across all 10 levels directly from the exported build.

## Project Status

The core systems are implemented: gameplay across all 10 levels, scoring and progress tracking, save/load, audio, the miniboss and final boss encounter, the end-of-level portal flow, and an automated test suite covering the systems listed above. A Windows build has been generated and tested against all levels.

## Additional Documentation

The following documents are associated with this project as part of the university practice/internship requirements, and are maintained separately from this repository:

- Practice journal and time log (jurnal de practică / pontaj).
- Automated testing results report (GUT).
- Architecture diagram of the main scripts.
- Final practice report.
- Final presentation and gameplay demo.

## License

No explicit license file is included in this project. It is developed as an academic / educational project for a university practice/internship requirement.
