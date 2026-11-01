# gtasa.super_jump — GTA San Andreas (Android) CLEO super jump

Launches CJ upward when you touch the in-game jump button area. Ships as a
`.csi`, so it appears in the CLEO script menu and only runs when you launch it.

**v2 — the trigger was changed.** v1 listened to `00E1` (the pad "jump button"
bit). On Android that bit is not fed by the on-screen touch HUD on every build,
which is why the jump button did nothing. v2 triggers on `0DE0`, the touch API
that CLEO Android implements itself, and keeps `00E1` as an extra trigger.

* Target: GTA SA Android + CLEO Android 2.0.x (SA v1.00–v2.00)
* Format: `.csi` (menu-invoked). PC `.cs`, Definitive Edition and CLEO Redux are
  not supported.

## Files

| Path | What |
|---|---|
| `dist/gtasa.super_jump.csi` | **the mod** — 478 bytes, sha256 `d475ce24…5d1491` |
| `dist/gtasa.super_jump_test.csi` | diagnostic — tap the **centre** of the screen and CJ jumps (194 bytes) |
| `src/gtasa.super_jump.txt` | source (Sanny Builder 4, `{$CLEO .csi}`) |
| `src/gtasa.super_jump_test.txt` | diagnostic source |
| `build.sh` | reproducible build (edit mode `sa_mobile`) |
| `docs/ANDROID_NOTES.md` | why regions are used, opcode evidence, test plan |

## Install

Copy the file to the CLEO scripts folder for SA on the device — one of:

```
/sdcard/cleo/sa/gtasa.super_jump.csi
/sdcard/Android/data/com.rockstargames.gtasa/files/cleo/gtasa.super_jump.csi
```

(the second is used when the game has storage access configured that way; if one
does not show up in the menu, try the other).

Then:

1. Open the CLEO menu in game: **slide from the top of the screen to the bottom
   through the centre**.
2. Launch `gtasa.super_jump`.
3. Touch the **bottom-right area** of the screen (where the jump button is) →
   CJ launches upward. A new touch is required for each jump; holding does not
   repeat.
4. Leave about 0.3 s between jumps — that is the built-in cooldown.

## If it still does nothing, test in this order

1. **Is the script loaded at all?** Launch `gtasa.super_jump_test` and tap the
   **centre** of the screen. If CJ jumps, CLEO + `.csi` loading works and only
   the region needs changing. If nothing happens, the problem is installation
   (wrong folder, CLEO missing, script never launched), not this mod.
2. **Wrong region?** The screen is a 3×3 grid: `1 2 3 / 4 5 6 / 7 8 9`. The mod
   uses **9** (bottom-right) and **8** (right-centre). If your HUD puts jump
   elsewhere, edit `22@` in `src/gtasa.super_jump.txt` and rebuild.
3. **Only regions, no buttons.** CLEO Android exposes nine screen cells, not
   individual buttons, so anything you touch in the bottom-right cell triggers a
   jump. Set `23@ = 0` to drop region 8 if it is too eager.

## How the jump is applied

Three mechanisms fire together on each trigger, so the effect survives a build
where one of them is overridden:

1. `05BC` — the game's own jump task
2. `083C` — raw upward velocity, 18.0 m/s (`21@`; vanilla jump is ~7)
3. `00A0`/`00A1` — coordinates read and lifted 1.5 m, a hard guarantee that
   something visible happens

## Verified / not verified

Verified here: compiles with Sanny Builder 4.2.0 in `sa_mobile` mode with a clean
compiler log, and `--decompile` round-trips back to readable source containing
`get_touch_point_state`, `task_jump`, `set_char_velocity`,
`get_char_coordinates` and `set_char_coordinates`.

Not verified: on-device behaviour. No Android device or GTA SA Android install is
available here, so the region choice and the launch strength are untested — use
the diagnostic script and the region table above to tune it.

## Build

```bash
WINEPREFIX=/path/to/prefix DISPLAY=:99 bash build.sh
```

Edit mode `sa_mobile` is the essential flag: a PC `sa` build produces a `.cs`
that Android cannot load.
