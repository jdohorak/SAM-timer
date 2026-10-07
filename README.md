# SAM Timer – Ethos widget

A flight timer and scoring widget for vintage (old-timer) RC model contests, for FrSky Ethos radios (X20/X20S, X18/X18S, X14, Twin X Lite).

It times 4 rounds plus a fly-off and converts flight time into points. Points are capped at 10 minutes, and the lowest round is dropped from the total. The 90-second motor run gets its own warnings. Results survive a power cycle.

The widget follows the radio language: English, Czech, Slovak and Hungarian are built in, and any other language falls back to English.

---

## Installation

1. Copy the `alot` folder into the `scripts/` folder on the SD card (or the radio's internal storage):
   ```
   scripts/alot/main.lua
   scripts/alot/lang.lua
   ```
2. Restart the radio.
3. On the main screen, choose a **full-screen layout** (one widget) and select the **SAM timer** widget.
4. Long-press the widget, choose **Configure**, and set the **start/stop switch** (see [Settings](#settings)).

> The widget also works in smaller layouts, but it is easiest to read full screen.

---

## Using it at a contest

| Step | What you do | What happens |
|---|---|---|
| Launch | Start switch **ON** | Timing and the motor-run countdown start, and a short beep sounds |
| Motor run | – | Beeps every second for the last 10 s of the motor run. At 90 s you get a long tone, a vibration and a flashing "MOTOR OFF!" message |
| Flight | – | The timer keeps counting. It alerts at 10 minutes but **does not stop** |
| Landing | Start switch **OFF** | The time is recorded, the big display shows that flight's time and points, and the widget moves to the next round |

- Timings shorter than 3 seconds are ignored, because they are switch accidents.
- If the start switch is already ON when the radio powers up, timing does not start by itself. Switch it OFF first.

### Scoring

- **Points = flight time in whole seconds.** For example, 7:42 scores 462 points.
- **Over 10 minutes**, the round gets the maximum of **600 points**. The time and points turn red and a **MAX** marker appears. The display still shows the real flight time (e.g. 11:23).
- **Total:** the sum of the 4 rounds, with **the lowest-scoring round dropped**. This only happens once all 4 rounds are flown. The dropped round is greyed out and struck through. On a tie, the earlier round is dropped.
- **Fly-off:** a separate round (FO). It does not count towards the total.

### Display

```
┌───────────────────────────┬──────────────────────────┐
│        Round 2 / 4        │ Round  mm:ss         pts │
│       MOTOR  00:47        │ 1.     07:42         462 │
│                           │ 2.     03:13         193 │ ← current (framed)
│          03:13            │ 3.     --:--           - │
│          193 pts          │ 4.     --:--           - │
│  [████▌─────|──────────]  │ ─────────────────────────│
│     RUN    max 10:00      │ FO     --:--           - │
│                           │ Total                462 │
└───────────────────────────┴──────────────────────────┘
```

- **Left side:**
  - current round;
  - motor-run countdown;
  - big timer;
  - points;
  - progress bar: the orange section is the motor run, and the vertical line marks its end;
  - status (RUN / STOP).
- **Right side:** every round with its time and points, and the total at the bottom.
- In a narrow or portrait window, the two parts are stacked.

### Selecting a round and re-flying it

- **Touch:** tap a row in the table to make it the current round. This only works while the timer is stopped. The next timing overwrites that round's earlier time.
- **Widget menu** (long-press the widget, only while the timer is stopped):
  - **New contest (clear all)**
  - **Previous round**
  - **Next round**

### Saving results and resetting

- Results (round times and the current round) are **saved automatically for each model** to `scripts/alot/res_<modelname>.txt`. Everything comes back after a power cycle.
- **Only a reset clears the results:** the **New contest** menu item or the **reset switch**. The reset switch only works while the timer is stopped.
- If the radio is switched off **while timing**, the unfinished round is lost. Rounds already recorded are kept.

---

## Settings

Widget configuration panel (long-press → **Configure**):

| Setting | Default | Description |
|---|---|---|
| Start/stop switch | – | ON starts timing; OFF stops it and records the time. **Required.** |
| Reset switch | – | Switching it ON starts a new contest (clears all results). Optional. |
| Number of rounds | 4 | 1–10 |
| Fly-off round | on | Add a fly-off round after the regular rounds |
| Max time (round) | 600 s | Rounds longer than this get maximum points |
| Max time (fly-off) | 3600 s | The same for the fly-off |
| Motor run time | 90 s | 0 = off |
| Motor pre-warning | 10 s | Beeping starts this many seconds before the motor run ends. 0 = off |
| Drop lowest round | on | Leave the weakest regular round out of the total |
| Min. recorded time | 3 s | Shorter timings are ignored |
| Call out each minute | on | A callout or beep at every full minute |
| Alert at max time | on | Tone and vibration when the max time is reached |
| Colors | | Background, text, running time, max marker (red), current round, motor (orange) |

## Sound and vibration alerts

| Event | Alert |
|---|---|
| Timing starts | short high beep |
| Timing stops | lower tone |
| Before the motor run ends (pre-warning) | short beep every second |
| End of motor run | long high tone + double vibration |
| Every full minute | minute callout (if the firmware supports it), otherwise a short beep |
| Max time reached | tone + vibration |
| Reset by switch | vibration |

---

## Testing in the simulator (VS Code)

Requirement: the `bsongis.ethos` VS Code extension, set to the X20S, EU, nightly26 simulator.

1. In the status bar, click `X20S_EU` and choose **Deploy ALOT**. This copies the `.lua` files from `my-scripts/alot/` into the simulator's `scripts/alot/` folder.
2. Choose **Start SIM**, then **Open Display**.
3. For a quick test, set these in the widget settings:
   - Max time = 10 s;
   - Motor run time = 15 s.
4. Flip the switch in the **Open Controls** panel and check the following:
   - motor pre-warning and flashing "MOTOR OFF!";
   - red MAX marker;
   - after 4 rounds, the lowest round is struck through;
   - results come back after restarting the simulator.
5. Lua errors are written to `simulators/ethos.log`.

## Known limitations

- Spoken minute callouts only work if the firmware provides the `UNIT_MINUTE` unit. Otherwise you get a beep.
- An unfinished round (radio switched off while timing) is not saved.

## Files

| File | Contents |
|---|---|
| `main.lua` | The widget |
| `lang.lua` | UI strings (English, Czech, Slovak, Hungarian) – add a new language here |
| `README.md` | This document |
| `res_<modelname>.txt` | Results file, created automatically on the radio |

The developer specification is in `D:\FRSKY\AI\ALOT\claude.md`.
