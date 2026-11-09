# What the reference mods actually do (decompiled)

Source: the folder you uploaded, `example decompile to view/`, decompiled with
Sanny Builder 4.2.0 in `sa_mobile` mode inside a Linux/Wine build sandbox.
Artifacts: `gtasa.carspawn.csi` (1,821 B), `Real_God_Mode.csi` (2,324 B),
`Free_Infernus…csa`, `enter_vehicle_as_passenger.csa`.

## 1. `get_touch_point_state` (0DE0) **works on your device**

This is the headline. `gtasa.carspawn.csi` — a mod that demonstrably runs on your
phone — is built entirely around it:

```
:CARSPWN_468
wait 0
gosub @CARSPWN_1670
get_touch_point_state 0@ = get_touch_point_state 5 mintime 0
get_touch_point_state 1@ = get_touch_point_state 4 mintime 0
get_touch_point_state 2@ = get_touch_point_state 6 mintime 0
if and
  0@ == 1
  1@ == 0
  2@ == 0
goto_if_false @CARSPWN_601
```

later in the same loop:

```
get_touch_point_state 0@ = get_touch_point_state 1 mintime 500
get_touch_point_state 1@ = get_touch_point_state 4 mintime 500
get_touch_point_state 2@ = get_touch_point_state 7 mintime 500
...
get_touch_point_state 0@ = get_touch_point_state 3 mintime 250
...
get_touch_point_state 0@ = get_touch_point_state 8 mintime 0
get_menu_button_state 0@
```

So regions 1,3,4,5,6,7,8 are all in normal use, `mintime` 0/250/500, and the loop
is `wait 0`. **The region opcode is therefore not what broke the earlier mods.**

## 2. What the working mod does differently

| Their pattern | What our failing builds did |
|---|---|
| `script_name 'CARSPWN'` at the top | no script name |
| `get_menu_button_state` to cancel/exit | never checked |
| freezes the player (`set_player_control … can_move 0`, `freeze_char_position…`) while its UI is up | acted during live gameplay |
| `get_cleo_shared_var` / mutex guard so two copies cannot run at once | no guard |
| `wait 0` loop with a `gosub` maintenance call | plain loop |

## 3. `Real_God_Mode.csi` is only a launcher

The 2.3 KB `.csi` decompiles to ~300 bytes: it just sets a mutex var
(`1380404548`) to 2 or 3 and terminates. The actual god mode lives in
`Real_God_Mode_Core.csa`. That is a common structure: tiny `.csi` menu entry →
big `.csa` worker. Two files must be installed together.

## 4. Practical conclusions for our mods

1. `0DE0` region detection is proven; keep using it if a button-style trigger is
   wanted.
2. `00E1 player pressed_key` is **not** used by any working mod here — drop it.
3. Put the money change **before** any risky task opcodes (`05C4`/`05DB`) so a
   later crash still leaves the reward visible. (Robber v3 already does this.)
4. Keep a heartbeat so a dead thread is visible on the HUD.
5. A `.csi` can be a tiny launcher for a `.csa` worker — useful if a single file
   gets too big for the mobile script limits.
