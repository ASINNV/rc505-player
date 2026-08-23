# rc505-player

A small macOS app for listening to Boss RC-505 mkII track exports without digging
through folders. Point it at the big export folder and it groups the
`001_1`, `001_2`, `002_1`, … subfolders into songs, then plays every track of a
song simultaneously, looped, with per-track mute.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15 or later

## Running it

This is a Swift Package, not a hand-built `.xcodeproj`, so there's nothing to
generate:

1. Open `Package.swift` in Xcode (`File > Open…`, pick this folder — Xcode
   opens Swift Packages directly as a project).
2. Select the **RC505Player** scheme in the toolbar.
3. Press **Run** (⌘R). A window opens.

Alternatively, from Terminal with the Xcode command line tools installed:

```sh
swift run
```

## Using it

1. Click **Choose Export Folder…** and select the top-level folder that
   contains all your song/track subfolders (the one with `001_1`, `001_2`,
   `001_3`… inside it). The app remembers this folder on next launch.
2. Songs appear in the sidebar, grouped and numbered automatically from the
   folder names.
3. Select a song, hit **Play** — every track for that song plays together on
   a continuous loop until you hit **Stop**.
4. Click the speaker icon next to any track to mute/unmute it. Muting doesn't
   stop or restart playback, so the remaining tracks stay in sync.

## How it works / limitations

- Folder names are parsed as `<song>_<track>` (e.g. `001_1` → song 001,
  track 1). Folders that don't match this pattern are ignored.
- Each track folder's first audio file (`.wav`, `.aif`/`.aiff`, or `.mp3`) is
  used.
- Tracks are decoded into memory once and played with `AVAudioEngine`, with
  all tracks in a song scheduled to start at the same host time so they
  begin in sync, then each loops its own buffer independently.
- If the tracks within a song are not exactly the same length, independent
  looping means they can drift apart from each other over a long listening
  session — this matches how the RC-505 itself only guarantees same-length
  loops within a synced song, so this shouldn't come up in practice.
