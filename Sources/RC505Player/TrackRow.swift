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
            Spacer()
            Text(track.audioURL.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button {
                renameText = track.displayName(using: namesStore)
                isRenaming = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Rename this track")
            Button {
                playback.toggleMute(track)
            } label: {
                Text("Mute")
            }
            .buttonStyle(.borderedProminent)
            .tint(playback.isMuted(track) ? .gray : .blue)
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
