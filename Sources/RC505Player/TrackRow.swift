import SwiftUI

struct TrackRow: View {
    let track: Track
    @ObservedObject var playback: PlaybackController
    @ObservedObject var namesStore: NamesStore

    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        HStack {
            Text(track.displayName(using: namesStore))
            Button {
                renameText = track.displayName(using: namesStore)
                isRenaming = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Rename this track")
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
        .contextMenu {
            Button("Rename…") {
                renameText = track.displayName(using: namesStore)
                isRenaming = true
            }
        }
        .alert("Rename Track", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Save") { namesStore.setName(renameText, for: track.key) }
            Button("Cancel", role: .cancel) {}
        }
    }
}
