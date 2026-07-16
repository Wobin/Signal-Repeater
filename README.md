# Signal Repeater

Signal Repeater re-plays special and elite enemy telegraph cues so that they remain audible during
combat.

Darktide's Wwise mixer applies ducking and attenuation under load, which can suppress enemy telegraph
audio at the moments it is most relevant. Signal Repeater intercepts each cue as the game triggers it
and replays the game's own extracted audio through
[SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/929), which operates on a separate
runtime outside Wwise and is therefore unaffected by the mixer. The replayed cue is positioned in 3D
at the emitting enemy.

The mod is client-side only. No data is transmitted to the host and no game state is modified.

## Cues

50 cues across 13 enemies.

| Enemy | Cues |
|---|---|
| Trapper | net-gun wind-up, aim interrupted, reload, proximity warning, footsteps, laugh |
| Chaos Hound | pounce, bark, growl, footsteps |
| Mutant | charge growl, charging breath, charging rattle, footsteps |
| Poxburster | ticking, footsteps |
| Flamer | fuel tank, taking aim, proximity warning, flame stream, footsteps (Dreg and Scab) |
| Bomber | grenade-throw callout, footsteps |
| Sniper | aim beam, footsteps |
| Plasma Gunner | charge-up (charge tone and overlay) |
| Daemonhost | alert scream |
| Reaper | callouts (alerted, opening fire), readying gun, heavy stubber, melee, footsteps |
| Crusher | callouts (alerted, assault), overhead smash, hammer swing, melee, footsteps |
| Bulwark | readying, overhead smash, shield swing, melee, footsteps |
| Mauler | overhead smash, chainaxe swing, melee, footsteps |

Voice callouts replay the specific line selected by the game. The mod reads the dialogue key from the
dialogue system at the point of playback rather than selecting a line at random.

Cue selection is derived from the game's own breed data. Sounds marked `use_proximity_culling = false`
are exempted by Fatshark from distance culling; those sounds form the basis of this cue set.

## Footsteps

Footstep audio conveys enemy position and movement, which telegraph cues alone do not.

Darktide selects footstep audio through a Wwise switch keyed on the surface material beneath the
enemy. Signal Repeater mirrors this switch: it reads the material the game resolved for that footstep
and plays from the corresponding sample set, so surface changes are reflected in the replayed audio.
Surfaces for which the game defines no footstep audio are left silent rather than substituted.

Footstep timing is not modelled. Footsteps are triggered from the animation, so the replay is driven
by the game's own event and remains synchronised with the gait.

## Distance and occlusion

Darktide conveys distance to a sound almost entirely through progressive low-pass filtering rather
than volume attenuation. Its attenuation curves hold volume nearly flat (0 dB at the listener to
-1 dB at 60 m) while ramping the low-pass from 0 to 45 over the same span. Signal Repeater reads each
cue's own attenuation curve from the soundbank and reproduces both the radius and the filter, so a
distant enemy is dull rather than merely quieter.

Cues are also occluded by level geometry. Five rays are cast from the listener to a fan around the
emitter using the game's line-of-sight collision filter; the blocked fraction adds further low-pass
attenuation and reduces volume, so an enemy behind a wall is muffled rather than heard through it.
This is an approximation: the game's own occlusion uses authored portal volumes and obstructor units,
which are not exposed to mods.

## Poxburster cadence

The Poxburster tick is an internal Wwise loop with no per-tick event, so its cadence is reconstructed
from the soundbank. The tick interval follows the curve defined in the bank (0.03s at contact, rising
to 1.5s at 50m) and is keyed on the distance between the Poxburster and its current target, which may
be a team-mate rather than the local player. At close range, where individual ticks converge into a
continuous tone, playback switches to a single pre-rendered loop.

## Options

Cues are grouped by enemy. Each cue has two settings: whether it is repeated, and whether the game's
own version is silenced (replacement rather than reinforcement). Bulk toggles are provided.

Each enemy group additionally carries two settings of its own.

| Per-enemy setting | Description |
|---|---|
| Volume | Scales every cue from that enemy. 100 leaves them at the overall Volume below; use it to balance one enemy against another |
| Skip cues aimed at a team-mate | When that enemy is targeting a team-mate rather than the local player, its cues are not replayed at all. The enemy's target is read from the game, and the check is made before any audio work is done. Poxbursters default to off, since a Poxburster endangers everyone nearby |

The mod-wide settings are as follows.

| Setting | Description |
|---|---|
| Volume | 100 is slightly louder than the game's own version of the sound, so the replay stands out; higher and lower values scale from there |
| Independent volume | Replayed cues ignore the SFX, Music and Dialogue sliders. The Master slider still applies |
| Audible range | Scales every cue's range as a percentage of the range the game itself uses (100 = the same) |
| Sound test | Loops a sample orbiting the player for volume calibration |
| Debug | Prints each cue to chat as it fires |

## Requirements

- [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8)
- [SimpleAudio](https://www.nexusmods.com/warhammer40kdarktide/mods/929)

## Credits

Sound assets are extracted from Warhammer 40,000: Darktide and remain the property of Fatshark.
