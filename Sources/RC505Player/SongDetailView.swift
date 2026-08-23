import SwiftUI

struct SongDetailView: View {
    let song: Song
    @ObservedObject var playback: PlaybackController

    private var isPlayingThisSong: Bool { playback.playingSongID == song.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(song.displayName)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button {
                    if isPlayingThisSong {
                        playback.stop()
                    } else {
                        playback.play(song: song)
                    }
                } label: {
                    Label(isPlayingThisSong ? "Stop" : "Play", systemImage: isPlayingThisSong ? "stop.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Text("\(song.tracks.count) track\(song.tracks.count == 1 ? "" : "s") · loops continuously until stopped")
                .foregroundStyle(.secondary)

            Divider()

            List(song.tracks) { track in
                HStack {
                    Text(track.name)
                    Spacer()
                    Text(track.audioURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Button {
                        playback.toggleMute(track)
                    } label: {
                        Image(systemName: playback.isMuted(track) ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundStyle(playback.isMuted(track) ? .red : .primary)
                    }
                    .buttonStyle(.borderless)
                    .help(playback.isMuted(track) ? "Unmute this track" : "Mute this track")
                }
                .opacity(playback.isMuted(track) ? 0.5 : 1.0)
            }
        }
        .padding()
        .id(song.id)
    }
}
