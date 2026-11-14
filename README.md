# Monty Workout

A minimal macOS app for the 6-day routine — weights, yoga, treadmill and guided
breathing / meditation (60 min/day).
Native SwiftUI. Timer-driven sessions with follow-along video + audio, and
day-by-day tracking.

## Run it

```bash
cd "MontyWorkout"
swift run
```

## Build a double-clickable app

```bash
cd "MontyWorkout"
./build-app.sh
open MontyWorkout.app          # or: cp -r MontyWorkout.app /Applications/
```

Requires the Xcode command-line tools (`xcode-select --install`) — no full
Xcode needed. Targets macOS 14+.

## What it does

- **Today** — the workout for the current weekday, the full step list, and a
  one-tap **Begin workout**. Sunday is a rest day (with a "train anyway" pick).
- **Session** — one exercise at a time:
  - A short **looping movement animation** as the follow-along — just the rep,
    no intro/outro, and it stops the instant the exercise changes.
  - Nothing counts until you press **Start**. Rep sets wait for **Complete
    set**; timed holds count down and auto-advance.
  - **Rest is counted automatically** between sets and exercises (with its own
    countdown, spoken cue, and ticks). Skip it if you want — only real rest
    time is logged.
  - A synthesized voice announces the set/reps and the countdown; it stays
    quiet while the video is talking.
  - Live totals: work time, rest time, total, sets done. End early any time —
    it's saved as a partial session.
- **History** — a calendar grid of the last 10 weeks (done / partial / missed /
  rest), current & best streak, total workouts and time, and a recent-sessions
  list. Stored locally at
  `~/Library/Application Support/MontyWorkout/history.json`.
- **How-to guides** — every exercise has a "Kaise karna hai" panel: an animated
  stick figure (drawn in code, `Model/StickFigure.swift`) plus each step as
  Hinglish text with its own little figure. Poses live in `Model/Guides.swift`.
- **Guided blocks** — breathing (ujjayi, box, 4-7-8, nadi shodhana) runs a
  paced orb with a spoken count; body scans, vinyasa, backbends and warrior
  flows narrate at timed moments. Chained meditation steps start on their own.
- **Schedule** — all six days, expandable, each startable on its own.
- **Settings** — voice picker, video-sound toggle, coaching-cue and tick
  toggles, reveal/reset history.

## Media & audio

- **Kettlebell / bodyweight moves** map to a folder id from the public-domain
  [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (`media:` in
  `Schedule.swift`) — two position photos cross-faded into a short loop.
- **Yoga poses** use freely-licensed Wikimedia Commons imagery (`images:` in
  `Schedule.swift`): the illustrated "Nina-Mel" asana set for a consistent
  look, a few photos, and an animated Surya Namaskar GIF for the sun
  salutations / vinyasa. One URL that ends `.gif` animates; a single still gets
  a slow breathing zoom.
- Anything still unmatched falls back to a labelled animated placeholder —
  nothing appears broken.
- **Spoken cues** rotate. Every exercise has a pool of lines in
  `Engine/Cues.swift` — a mix of straight coaching, hype, and dry humour — and
  a persisted per-movement index advances each time you do it, so the guidance
  is different session to session. The "go", rest, set-done and finish lines
  rotate too.
- Voice is `AVSpeechSynthesizer` with the most natural installed English voice
  (novelty voices filtered out). For a far more human voice, download an
  **Enhanced** or **Premium** voice in *System Settings ▸ Accessibility ▸
  Spoken Content ▸ System Voice ▸ Manage Voices* — picked up automatically.
  Countdown ticks and a rest-over chime use system sounds.

## Layout

```
Sources/MontyWorkout/
  MontyWorkoutApp.swift      app entry + Dock/activation
  Theme.swift                palette, helpers
  Model/Schedule.swift       the 6-day routine as data (+ video ids)
  Engine/
    WorkoutSession.swift     the session state machine + timers
    Announcer.swift          speech + sound cues
    Cues.swift               rotating spoken-line pools per movement
    HistoryStore.swift       JSON persistence, streaks, calendar status
  Views/
    RootView, TodayView, SessionView, HistoryView, ScheduleView, SettingsView
    Components/  GifView (looping animation + placeholder), Bits (ring, buttons, tiles)
```
