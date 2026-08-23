import AVFoundation
import Combine

/// Loads every track of a song into its own AVAudioPlayerNode and starts them
/// all at a shared future host time so they begin in sync, each looping its
/// own buffer independently (gapless, no re-decoding on each loop).
@MainActor
final class PlaybackController: ObservableObject {
    @Published private(set) var playingSongID: Song.ID?
    @Published private var mutedTrackIDs: Set<Track.ID> = []
    @Published private var soloedTrackID: Track.ID?

    private let engine = AVAudioEngine()
    private var players: [Track.ID: AVAudioPlayerNode] = [:]

    func isMuted(_ track: Track) -> Bool {
        mutedTrackIDs.contains(track.id)
    }

    func isSoloed(_ track: Track) -> Bool {
        soloedTrackID == track.id
    }

    /// Whether this track would currently produce sound, accounting for
    /// both its own mute state and any other track being soloed.
    func isAudible(_ track: Track) -> Bool {
        effectiveVolume(for: track.id) > 0
    }

    func toggleMute(_ track: Track) {
        if mutedTrackIDs.contains(track.id) {
            mutedTrackIDs.remove(track.id)
        } else {
            mutedTrackIDs.insert(track.id)
        }
        applyVolumes()
    }

    func unmuteAll(_ tracks: [Track]) {
        for track in tracks {
            mutedTrackIDs.remove(track.id)
        }
        applyVolumes()
    }

    /// Soloing a track silences every other track (regardless of their own
    /// mute state) until solo is toggled off or moved to another track.
    func toggleSolo(_ track: Track) {
        soloedTrackID = (soloedTrackID == track.id) ? nil : track.id
        applyVolumes()
    }

    private func effectiveVolume(for trackID: Track.ID) -> Float {
        if let soloedTrackID {
            return soloedTrackID == trackID ? 1 : 0
        }
        return mutedTrackIDs.contains(trackID) ? 0 : 1
    }

    private func applyVolumes() {
        for (trackID, player) in players {
            player.volume = effectiveVolume(for: trackID)
        }
    }

    func play(song: Song) {
        stop()

        var loadedPlayers: [Track.ID: AVAudioPlayerNode] = [:]
        var loadedBuffers: [Track.ID: AVAudioPCMBuffer] = [:]

        for track in song.tracks {
            guard let file = try? AVAudioFile(forReading: track.audioURL),
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                continue
            }
            do {
                try file.read(into: buffer)
            } catch {
                continue
            }

            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)

            loadedPlayers[track.id] = player
            loadedBuffers[track.id] = buffer
        }

        guard !loadedPlayers.isEmpty else { return }

        players = loadedPlayers

        do {
            try engine.start()
        } catch {
            print("RC505Player: failed to start audio engine: \(error)")
            teardown()
            return
        }

        // Schedule every track to start at the same future host time so
        // they begin sample-aligned instead of drifting by however long
        // scheduleBuffer/play take to call per track.
        let startTime = AVAudioTime(hostTime: Self.hostTime(secondsFromNow: 0.1))

        for (trackID, player) in loadedPlayers {
            guard let buffer = loadedBuffers[trackID] else { continue }
            player.volume = effectiveVolume(for: trackID)
            player.scheduleBuffer(buffer, at: startTime, options: .loops, completionHandler: nil)
            player.play()
        }

        playingSongID = song.id
    }

    func stop() {
        teardown()
        playingSongID = nil
    }

    private func teardown() {
        for player in players.values {
            player.stop()
            engine.disconnectNodeOutput(player)
            engine.detach(player)
        }
        players.removeAll()
        if engine.isRunning {
            engine.stop()
        }
    }

    private static func hostTime(secondsFromNow seconds: Double) -> UInt64 {
        var timebaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timebaseInfo)
        let now = mach_absolute_time()
        let nanos = seconds * 1_000_000_000
        let ticks = nanos * Double(timebaseInfo.denom) / Double(timebaseInfo.numer)
        return now + UInt64(ticks)
    }
}
