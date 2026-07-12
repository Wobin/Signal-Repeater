# Signal Repeater

A Darktide mod that makes sure you actually **hear** the telegraph.

The game already tells you a Poxburster is ticking, a Trapper is lining up, or a Hound is about to
pounce. The problem is Wwise: in a loud fight, its mixer ducks and buries those cues under gunfire
and horde noise, exactly when you need them most.

Signal Repeater catches each cue as the game fires it and replays the game's **own sound** through
[SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/864), which runs on its own audio
runtime *outside* Wwise, so it cannot be ducked. The copy is positioned in 3D at the enemy that made
it, so it still tells you where the threat is.

Client-side only. Nothing is sent to the host; it changes only what you hear.

## Cues

49 cues across 13 enemies. The disablers come first, because they are the ones that kill you.

| Enemy | Cues |
|---|---|
| **Trapper** | net-gun wind-up, aim broken off, reload, stalking you, footsteps, laugh |
| **Chaos Hound** | **pounce**, bark, growl, footsteps |
| **Mutant** | charge growl, charging breath, charging rattle, footsteps |
| **Poxburster** | ticking, footsteps |
| **Flamer** | fuel tank, taking aim, proximity warning, flame stream, footsteps (Dreg and Scab) |
| Bomber | footsteps |
| Sniper | aim beam, footsteps |
| Plasma Gunner | charge-up (both layers: the charge tone *and* its overlay) |
| Daemonhost | alert scream |
| **Reaper** | callouts (spots you / opening fire), readying gun, heavy stubber, melee, footsteps |
| **Crusher** | callouts (spots you / charging you), overhead smash, hammer swing, melee, footsteps |
| **Bulwark** | readying up, overhead smash, shield swing, melee, footsteps |
| **Mauler** | overhead smash, chainaxe swing, melee, footsteps |

The voice callouts replay **the exact line the game chose**, not a random one: the mod reads the
line's key out of the dialogue system as it fires.

Cue selection is not guesswork. Darktide's breed data marks certain sounds `use_proximity_culling =
false`, which is the game itself saying *this must always be heard*. Those are the cues here.

## Footsteps tell you where it is

A telegraph tells you a Trapper exists. Its **footsteps** tell you where it is walking, which is the
information the mix is really stealing from you.

The game picks footstep audio through a Wwise switch on the **surface material** under the enemy, and
Signal Repeater mirrors that switch: it reads the same material the game just used and plays from the
matching set, so a Trapper crossing from concrete onto metal grating sounds like it. It also honours
the surfaces the game deliberately leaves **silent** (snow, warp shields) rather than inventing a
footstep the game never plays.

Timing is mirrored, not modelled: footsteps are fired from the animation, so the replay is driven by
the game's own event and is always in step with the gait.

## Faithful, not approximate

The audio is extracted from the game's own soundbanks, and so is its *behaviour*. The Poxburster's
tick cadence follows the curve the bank actually specifies (0.03s at contact, rising to 1.5s at 50m),
keyed on the distance to the burster's **target**, which may be a team-mate rather than you. Up close,
where the ticks fuse into one tone, playback hands off to a single pre-rendered loop rather than
firing a decode eleven times a second.

Where the bank data turned out not to match what the game actually sounds like, it was dropped rather
than shipped for the sake of looking thorough.

## Options

Each enemy has its own group, and every cue has two toggles: **repeat the cue**, and **silence the
game's own version** (so ours replaces it rather than doubling it). Switches at the top tick or untick
everything at once.

- **Volume** — 100 means as loud as the game's own version of that sound
- **Independent volume** — the cues ignore the game's SFX/Music/Dialogue sliders entirely, so you can
  duck the combat mix right down and still hear every telegraph. Master still applies, so muting the
  game still mutes.
- **Audible range** for the replayed cues
- **Sound test** — loops a bark circling you, so you can set the volume without a fight
- **Debug** — prints each cue to chat as it fires

## Requires

- [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8)
- [SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/864)

## Credits

Sound assets are extracted from Warhammer 40,000: Darktide and belong to Fatshark.
