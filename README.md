# Signal Repeater

A Darktide mod that makes sure you actually **hear** the telegraph.

The game already tells you a Poxburster is ticking, a Sniper is lining up, or a Hound is about to
pounce. The problem is Wwise: in a loud fight, its mixer ducks and buries those cues under gunfire
and horde noise, exactly when you need them most.

Signal Repeater catches each cue as the game fires it and replays the game's **own sound** through
[SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/864), which runs on its own audio
runtime *outside* Wwise — so it cannot be ducked. The copy is positioned in 3D at the enemy that
made it, so it still tells you where the threat is.

## Cues

| Enemy | Cue |
|---|---|
| Sniper | aim beam |
| Plasma Gunner | charge-up |
| Mutant | charge growl |
| Chaos Hound | approach bark |
| Flamer | proximity warning |
| Trapper | net-gun wind-up |
| Poxburster | ticking |
| Daemonhost | alert scream |

Each enemy has its own group in the mod options, with two toggles: **repeat the cue**, and
**silence the game's own version** (so ours replaces it rather than doubling it).

## Faithful, not approximate

The audio is extracted from the game's own soundbanks, and so is its *behaviour*. The Poxburster in
particular reproduces what the bank actually specifies:

- **Cadence** — its tick delay follows the game's own curve (0.03s at contact, rising to 1.5s at
  50m), keyed on the distance to the burster's **target**, which may be a team-mate, not you.
- **Pitch** — the game detunes the tick by distance (brighter as it closes). So do we.
- **Layers** — the game crossfades a near tick and a duller far tick between ~10m and ~35m. So do we.
- Up close, where the ticks fuse into one tone, playback hands off to a single pre-rendered loop
  rather than firing a decode ~11 times a second.

## Requires

- [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8)
- [SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/864)

Client-side only. Nothing is sent to the host; it changes only what you hear.

## Options

- **Volume** and **audible range** for the replayed cues
- **Sound test** — loops a bark circling you, so you can set the volume without a fight
- **Debug** — prints each cue to chat as it fires

## Credits

Sound assets are extracted from Warhammer 40,000: Darktide and belong to Fatshark.
