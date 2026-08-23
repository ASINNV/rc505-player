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
5. **Rename** a song or track by right-clicking it (or Control-click) and
   choosing **Rename…**. Custom names are saved and survive relaunching the
   app or re-choosing the same export folder — they're matched back up by
   song/track number, not by the folder's original name.
6. **Export** a song's tracks into one folder by clicking **Export…** in the
   song's toolbar and picking a destination. This copies all of that song's
   track files into a single new folder there (named after the song), using
   your custom track names as filenames when set, and reveals it in Finder
   when done — handy for grabbing a song's stems without digging through the
   original `001_1`, `001_2`… folders.

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
- Custom names are stored in the app's `UserDefaults`, keyed by song/track
  number — they're per-Mac, not stored inside the export folder itself, so
  they won't follow the folder if you copy it to another machine.

## Packaging a DMG to install on your other Macs

Running via Xcode (above) is the easiest way to develop and use the app on
this Mac, but it doesn't produce something you can just copy to another
machine. To build a real, standalone `RC505Player.app` and wrap it in a DMG:

```sh
./Scripts/build-dmg.sh
```

This builds a release binary (universal, so it runs on both Apple Silicon and
Intel Macs), assembles it into `build/RC505Player.app`, ad-hoc code-signs it,
and creates `build/RC505Player.dmg`. Share that DMG file (AirDrop, USB drive,
etc.) with your other Macs — open it and drag `RC505Player.app` into
`Applications`.

**About Gatekeeper:** this DMG isn't signed with a paid Apple Developer ID or
notarized, so the first time you open the app on each Mac, macOS will warn
that it's from an unidentified developer. Right-click (or Control-click) the
app and choose **Open**, then confirm in the dialog that appears — you only
need to do this once per Mac. (If macOS blocks it outright with no Open
option, go to **System Settings → Privacy & Security** and click **Open
Anyway** next to the RC505Player message.)
