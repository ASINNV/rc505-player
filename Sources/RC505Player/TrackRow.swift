import SwiftUI

struct TrackRow: View {
    let track: Track
    @ObservedObject var playback: PlaybackController
    @ObservedObject var namesStore: NamesStore

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isHovering = false

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text(track.displayName(using: namesStore))

                Button {
                    renameText = track.displayName(using: namesStore)
                    isRenaming = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename this track")
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    withAnimation(.easeInOut(duration: 0.15)) { isHovering = true }
                } else {
                    isHovering = false
                }
            }

            Spacer()
            Text(track.audioURL.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button {
                playback.toggleMute(track)
            } label: {
                Text("Mute")
            }
            .buttonStyle(.borderedProminent)
            .tint(playback.isMuted(track) ? .gray : .blue)
            .help(playback.isMuted(track) ? "Unmute this track" : "Mute this track")
            Button {
                playback.toggleSolo(track)
            } label: {
                Text("Solo")
            }
            .buttonStyle(.borderedProminent)
            .tint(playback.isSoloed(track) ? .orange : .gray)
            .help(playback.isSoloed(track) ? "Turn off solo" : "Solo this track (silence all others)")
        }
        .opacity(playback.isAudible(track) ? 1.0 : 0.5)
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
