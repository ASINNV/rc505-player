import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    @ObservedObject var namesStore: NamesStore

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isHovering = false

    var body: some View {
        HStack {
            Text(song.displayName(using: namesStore))

            Button {
                renameText = song.displayName(using: namesStore)
                isRenaming = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Rename this song")
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)

            Spacer()
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.tint)
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Rename…") {
                renameText = song.displayName(using: namesStore)
                isRenaming = true
            }
        }
        .alert("Rename Song", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Save") { namesStore.setName(renameText, for: song.key) }
            Button("Cancel", role: .cancel) {}
        }
    }
}
