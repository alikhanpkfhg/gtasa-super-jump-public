# gtasa.robber — GTA San Andreas (Android) robbery mod

Aim a gun at a pedestrian for a moment: he throws his hands up, you take his cash
( $50–$250 ), and he runs away. **No button to press** — the mod reacts to your
crosshair.

* Target: GTA SA Android + CLEO Android 2.0.x
* Format: `.csi` (menu-invoked)

## Files

| Path | What |
|---|---|
| `dist/gtasa.robber.csi` | **v3, the mod** — 202 bytes, sha256 `82aaf773…2359322069` |
| `dist/gtasa.robber_test.csi` | standalone load test — +$1000 on launch, +$100 every 5 s |
| `src/gtasa.robber.txt` | source |
| `src/gtasa.robber_test.txt` | test source |

## Install

Copy to the CLEO scripts folder for SA on the device (try the first, then the
second):

```
/sdcard/cleo/sa/gtasa.robber.csi
/sdcard/Android/data/com.rockstargames.gtasa/files/cleo/gtasa.robber.csi
```

Open the CLEO menu (slide top→bottom through the screen centre), launch
`gtasa.robber`.

## What v3 fixed

The v2 build added $1 and then did nothing on a real phone. That "+$1 then
silence" is the signature of the script dying right after start-up, and the
prime suspect was the touch opcode `0DE0` — not every CLEO Android build
implements it, and calling a missing opcode kills the thread instantly.

v3 removes `0DE0` completely. It uses only core SA opcodes and needs no input
detection at all: the trigger is `0457 player 0 aiming_at_actor`.

## Self-check built in

| What you see | What it means |
|---|---|
| money +$1 at launch | the script loaded |
| money +$1 every ~5 s | the main loop is running |
| +$50–$250 while aiming at a ped | a robbery happened |
| nothing at all | the `.csi` is not loading (folder/CLEO install), not this mod |

## Using it

1. Take out a gun.
2. Aim (hold aim) so the crosshair sits on a pedestrian.
3. Money is added, he puts his hands up for 4 s, then flees.
4. ~10 s cooldown before the next robbery.

## Config (edit the source, then rebuild)

| Line | Meaning | Default |
|---|---|---|
| `0019: 3@ > 19` | heartbeat interval in 250 ms ticks (20 = 5 s) | 20 |
| `0209: 5@ = random_int_in_ranges 50 250` | payout range | 50–250 |
| `0006: 4@ = 40` | cooldown in ticks after a robbery (40 = 10 s) | 40 |

## Verified / not verified

Verified here: compiles with Sanny Builder 4.2.0 in `sa_mobile` mode, clean
compiler log; bytecode contains `0457`, `0209`, `0109`, `05C4`, `05DB`, `01F5`
and contains **no** `0DE0`; `--decompile` round-trips to
`is_player_targetting_char 6@ aiming_at_actor 0`, `random_int_in_ranges 5@ = …`,
`add_score 0 money += 5@`, `task_hands_up …`, `task_flee_char …`.

Not verified: on-device behaviour beyond the +$1 you already observed. The open
question is whether `0457` reports the aimed actor on your build; the heartbeat
tells you immediately if the loop is alive, and if the money no longer ticks +$1
then the loop died and we have a different problem to chase.
