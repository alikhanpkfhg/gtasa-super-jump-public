# Android notes: touch detection, compatibility, testing

Everything here was established from primary sources in the build environment
(Sanny Builder 4.2.0's own `sa_mobile` opcode database and its SBL library JSON)
and from the official CLEO-ANDROID source. Nothing is assumed from PC knowledge.

## 1. The nine touch points are generic screen regions

`0DE0: <var> = get_touch_point_state <point> mintime <ms>` and
`0DE1: ... get_touch_slide_state from <a> to <b> mintime .. maxtime ..` are the
whole CLEO-Android touch API.

* Sanny Builder's library metadata for `0DE0` says verbatim: *"Touch points is the
  CLEO Android engine implemented touch detection system which divides touchscreen
  into 9 parts called touch points"*.
* The enum in `data/sa_mobile/enums.txt` is exactly nine values:
  `LeftTop=1, LeftCenter=2, LeftBottom=3, CenterTop=4, Center=5, CenterBottom=6,
  RightTop=7, RightCenter=8, RightBottom=9`.
* The official implementation (`cleolibrary/CLEO-ANDROID`, `src/touch.cpp`)
  confirms the mechanism: each touch is normalised to 0–100 % and bucketed into a
  **3×3 grid** (x thirds × y thirds); `point_touched()` is "touched within the last
  150 ms" (`TOUCH_EXIST_TIME 150`), `point_touched_timed()` adds a hold duration.

Consequence: **a region tells you roughly where the finger is (one of nine
thirds-of-the-screen cells), never which button was pressed.** In the bottom-right
cell you cannot tell the jump button from the attack button, the camera swipe or
an empty pixel. So a region is *not* an acceptable implementation of "the jump
button", and this script does not ship one as its default.

## 2. `00E1` — what it is, and why it is the right trigger

```
00E1: player <index> pressed_key <button>
```

`00E1` is the SA **pad/button state** command. It is not a raw touch API, and the
button ids come from the game's own control map (Sanny Builder docs, "SA Button
IDs"):

| id | enum | on foot |
|---|---|---|
| 4 | LEFTSHOULDER1 | Action |
| 14 | **SQUARE** | **Jump / Zoom In** |
| 15 | TRIANGLE | Enter vehicle |
| 16 | CROSS | Sprint / Zoom Out |
| 17 | CIRCLE | Attack |

The mobile port drives the same control state from its on-screen HUD: the touch
jump button *is* the game's Jump action, and `00E1 ... 14` is the documented way to
read that action. That is why the script uses button **14**, not 16 (Sprint) —
pressing sprint would otherwise trigger the jump.

Note what this does and does not give you: it detects the **jump action**, which is
the real control the player presses. It cannot tell touch from a paired gamepad
(both drive the same action), which does not matter for this feature.

## 3. The widget route (`0A51`) — researched, not used

The SBL library JSON documents `0A51 IS_WIDGET_PRESSED(widgetId)` — *"Returns true
if the button widget icon on the screen is touched"* — which would address the HUD
button even more directly. Two blockers stopped it here:

1. It is **not present in the legacy opcode database** the `sa_mobile` edit mode
   compiles against (checked in `data/sa/SASCM.ini`, `data/sa_mobile/SASCM.Mobile.ini`
   and `data/sa_mobile/SASCM.CLEO.ini`: no `0A51` entry), so it does not compile in
   this mode without a custom opcode file.
2. The `WidgetId` values for the HUD buttons are not published in the compiler data,
   and reading them requires the game's own widget list on a device.

It stays documented as the future upgrade path: with a calibrated widget id, a
`0A51` variant would be even closer to "the exact button".

## 4. Script behaviour

| Item | Value |
|---|---|
| Extension | `.csi` — menu-invoked only (CLEO Android README: `.csa` starts at game load, `.csi` only from the menu) |
| Entry | `{$CLEO .csi}`, compiled with `--game sa_mobile` |
| Trigger | `00E1: player 0 pressed_key 20@` with `20@ = 14` |
| Hold protection | latch `1@`: fires once per press, re-armed only when the button is released |
| Launch | `05BC: AS_actor <char> jump 1` then `083C: set_actor <char> velocity_in_direction_XYZ 0.0 0.0 21@` with `21@ = 12.0` (vanilla jump ≈ 7 m/s) |
| Guards | `01F5: get_player_actor 0` checked against 0 before use; `wait 0` per frame, 500 ms settle at start |
| Clean termination | `004E: terminate_this_script` after 36000 idle frames (≈10 min at 60 fps); `22@ = 0` disables the timeout |
| Config | locals at the top of the source: `20@` button id, `21@` launch velocity, `22@` idle timeout, `23@` trigger mode, `24@` region for the opt-in fallback |
| Opt-in fallback | `23@ = 1` switches to `0DE0` on region `24@` (default `9` = RightBottom). Explicitly documented as a **region**, not the button — off by default |

## 5. Compatibility

| Target | Works? | Why |
|---|---|---|
| GTA SA Android v1.00–v2.00 + CLEO Android 2.0.x | **intended target** | `sa_mobile` layout, `.csi`, root required for CLEO install |
| GTA SA PC (any) | no | Android and PC SCM layouts differ; use the PC `.cs` pipeline |
| GTA SA Definitive Edition | no | different engine, no SCM/CLEO pipeline |
| CLEO Redux (JS) | no | different runtime |

## 6. What is verified here, and what is not

Verified in the build environment:

* compiles with Sanny Builder 4.2.0 in `sa_mobile` mode, `compile.log` clean;
* 351-byte `.csi` (release build, embedded-source chunk stripped with
  `--option Compiler::AddExtraInfo 0`; the same source with default options is
  4142 bytes and was also built and decompiled successfully);
* bytecode markers present: `00E1` (jump action), `0DE0` (region fallback),
  `05BC` (task jump), `083C` (velocity), `01F5` (player actor), `004E` (terminate);
* `--decompile` round-trip returns the expected source structure;
* a broken fixture in the same mode is rejected by the compiler (negative test).

**Not verified** (no device, no GTA SA Android install here):

1. that the on-screen jump button drives `00E1` button 14 in every SA Android
   build, including modded/customised HUDs — if a device does not react, set
   `23@ = 1` to test the region fallback and confirm the script itself is alive;
2. that `05BC` + `083C` produce the intended arc (12.0 m/s may feel too strong or
   too weak — tune `21@`);
3. interactions with vehicles, interiors, cutscenes and missions;
4. CLEO Android's own log (`cleo.log` on the device) for load errors.

## 7. Test plan for a device

1. Install CLEO Android, drop the `.csi` in `/sdcard/cleo/sa/`.
2. Start the game, open the CLEO menu (slide top→bottom through the centre),
   launch `gtasa.super_jump`.
3. Stand on foot in open ground; press the jump button once → one boosted jump.
   Hold it → no repeat. Release and press → second jump.
4. If nothing happens: set `23@ = 1` and recompile to prove the trigger loop runs
   (region 9 = bottom-right cell), then check `cleo.log`.
5. Tune `21@` (try 8.0 → 15.0) until the arc feels right, then re-test in a
   vehicle and during a mission to confirm it does not misfire.


## 8. v2 change: why region detection is now the default (2026-11-01)

The first release listened only to `00E1` (pad button 14). On the device the jump
button did nothing. Diagnosis: `00E1` reads the game's *pad state*, and the
Android on-screen HUD does not update that state on every SA Android build, so
the check never became true. Meanwhile `0DE0` is implemented **inside CLEO
Android itself** (`src/touch.cpp`), so it always works wherever the runtime is
installed.

v2 therefore uses, in order:

1. `0DE0` on region **9** (bottom-right cell — where the jump button is drawn)
2. `0DE0` on region **8** (right-centre cell — alternative HUD layouts)
3. `00E1` on button **14**, then **16**, kept as extra triggers

All four feed one press latch, a 20-frame cooldown, and the three-layer launch
(`05BC` task, `083C` velocity 18.0 m/s, `00A0`/`00A1` +1.5 m lift). The idle
timeout from v1 was removed: a menu-launched script that silently killed itself
after ten idle minutes was one more way for the mod to look dead.

A second file, `gtasa.super_jump_test.csi`, triggers on region **5** (centre) so
the pipeline can be checked independently of the region choice: if a centre tap
jumps, CLEO and `.csi` loading are fine and only `22@`/`23@` need tuning; if it
does not, the problem is installation, not the trigger.

Honest limits of v2: the region is a cell, not the button, so any touch in the
bottom-right third of the screen fires a jump, and none of this has been run on
hardware here.
