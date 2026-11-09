# gtasa.robber — GTA San Andreas (Android) robbery mod

Aim a gun at a pedestrian and press the trigger: he throws his hands up, you take
his cash, and he runs away.

* Target: GTA SA Android + CLEO Android 2.0.x
* Format: `.csi` (menu-invoked)

## Files

| Path | What |
|---|---|
| `dist/gtasa.robber.csi` | **the mod** — 585 bytes, sha256 `0d1d121b…68375b96` |
| `dist/gtasa.robber_test.csi` | proof-of-life test — +$1000 on launch, then +$100 every 5 s (30 bytes) |
| `src/gtasa.robber.txt` | source |
| `src/gtasa.robber_test.txt` | test source |

## Install

Copy to the CLEO scripts folder for SA on the device (try the first, then the
second if it does not appear in the menu):

```
/sdcard/cleo/sa/gtasa.robber.csi
/sdcard/Android/data/com.rockstargames.gtasa/files/cleo/gtasa.robber.csi
```

Open the CLEO menu (slide top→bottom through the screen centre), launch
`gtasa.robber`.

## How to tell it is working

The script adds **$1** to your money the moment it starts. Watch the HUD when you
launch it:

* money goes up by 1 → the script is running;
* nothing happens → **no custom script is loading on your install**. Run
  `gtasa.robber_test.csi` next: it adds $1000 and then $100 every 5 seconds. If
  that also does nothing, the problem is the CLEO installation or the folder, not
  the mod.

## Using it

1. Take out a gun (any weapon that lets you aim).
2. Aim at a pedestrian so the crosshair is on him.
3. Press the trigger — the jump/sprint buttons, a tap in the bottom-right area of
   the screen, or the centre-right cell also count.
4. He puts his hands up for 4 s, you gain $50–$250, and he flees.

One robbery per press: hold the button and nothing repeats; press again for the
next target. There is a ~0.75 s cooldown between robberies.

## How the target is chosen

`0457 player 0 aiming_at_actor` — the game itself reports which ped CJ is aiming
at, so the mod robs exactly the person under the crosshair. No screen regions and
no ped-searching opcodes are involved in picking the victim; regions and buttons
are only used to decide *when* to rob.

Then: `0209` rolls the payout, `0109` adds it to the player, `05C4` hands up,
`05DB` flee from the player.

## Config (edit the source, then rebuild)

| Variable | Meaning | Default |
|---|---|---|
| `20@` / `26@` / `27@` | key triggers (14 Square, 16 Cross, 17 Circle) | 14, 16, 17 |
| `22@` / `23@` / `28@` | touch regions 9 / 8 / 5 (set 0 to disable) | 9, 8, 5 |
| `21@` | payout | 150 |
| `25@` | cooldown frames | 45 |

## Verified / not verified

Verified here: compiles with Sanny Builder 4.2.0 in `sa_mobile` mode with a clean
compiler log; bytecode contains `0457`, `0209`, `0109`, `05C4`, `05DB`, `01F5`,
`0DE0`; `--decompile` round-trips to
`is_player_targetting_char 6@ aiming_at_actor 0`, `random_int_in_ranges 5@ = …`,
`add_score 0 money += 5@`, `task_hands_up …`, `task_flee_char …`.

Not verified: on-device behaviour (no Android device or SA Android install here).
The two things most likely to need adjusting on a real phone are the trigger
regions (`22@`/`23@`/`28@`) and the payout.

## If nothing happens at all

In order of likelihood:

1. **The `.csi` is not being loaded** — wrong folder or CLEO not installed for
   your SA version. The proof-of-life $1 and `gtasa.robber_test.csi` settle this.
2. **Never launched** — a `.csi` only starts when picked in the CLEO menu
   (unlike `.csa`, which auto-starts).
3. **Trigger mismatch** — your HUD may not put the jump button in the
   bottom-right cell. Set `28@ = 5` only (centre tap) while testing, or use the
   key triggers.
