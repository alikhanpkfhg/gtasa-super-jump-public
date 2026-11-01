# gtasa.super_jump — GTA San Andreas (Android) CLEO super jump

A CLEO Android script that launches CJ upward when you press the in-game **jump
button**. Ships as a `.csi` file, so it appears in the CLEO script menu and only
runs when *you* launch it.

* Target: **GTA San Andreas Android + CLEO Android 2.0.x** (SA v1.00–v2.00)
* Format: `.csi` (menu-invoked) — the CLEO Android runtime treats `.csa` as
  auto-start and `.csi` as manual-start
* Not for PC and not for the Definitive Edition: `.csi` is the Android SCM layout,
  a PC `.cs` will not load on a phone and vice versa

## Install

1. Copy `dist` decoded artifact to your device as
   `/sdcard/cleo/sa/gtasa.super_jump.csi`
   (CLEO Android 2.0.x loads scripts from `%sdcard%/cleo/<game>`).
2. In game, open the CLEO menu: **slide from the top of the screen to the bottom
   through the centre**.
3. Pick `gtasa.super_jump` — the script starts.
4. Press the on-screen **jump** button. Each new press gives one boosted jump;
   holding it will not repeat.

Decode the shipping artifact from this repo:

```bash
bash dist/decode.sh          # writes gtasa.super_jump.csi + prints its SHA-256
# expected: af56c16335373710e22b11ede25c839ccf50e8db83c72a2c774d32a1107606fb (351 bytes)
```

## Build it yourself

`build.sh` needs a Sanny Builder 4.2.0 under Wine with a display (Xvfb works) and
a staging `WINEPREFIX`:

```bash
WINEPREFIX=/path/to/prefix DISPLAY=:99 bash build.sh
```

The important flag is the edit mode: `--game sa_mobile` (Android). Compiling in
the PC `sa` mode produces something Android cannot load.

## What the trigger actually reads

The script reads the **game's jump action bit**, opcode
`00E1: player 0 pressed_key 14`, where `14 = SQUARE` — the SA control map defines
that as **"Jump / Zoom In"** on foot (official Sanny Builder docs, SA Button IDs
table). On Android the on-screen jump button feeds that same action, which is why
this is the real control and not a screen area. See
[docs/ANDROID_NOTES.md](docs/ANDROID_NOTES.md) for the full evidence trail,
including why the nine CLEO touch regions cannot be used for this, and what is
still untested on hardware.

## Files

| Path | What |
|---|---|
| `src/gtasa.super_jump.txt` | source (Sanny Builder 4, `{$CLEO .csi}`) |
| `build.sh` | reproducible build (`sa_mobile` mode, extra info stripped) |
| `dist/gtasa.super_jump.csi.b64` | compiled artifact, base64 (351 bytes) |
| `dist/decode.sh` | restores the `.csi` and prints its hash |
| `docs/ANDROID_NOTES.md` | research, touch-detection behaviour, compatibility, test plan |

## Status

Compiled and verified here: clean compiler log, custom-marker check on the
bytecode (`00E1`, `0DE0`, `05BC`, `083C`, `01F5`, `004E` all present), and a
`--decompile` round-trip back to readable source. **Not** tested in-game: no
Android device or GTA SA Android install was available, so no claim is made about
runtime behaviour. See the test plan in the notes.
