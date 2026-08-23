import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    @ObservedObject var namesStore: NamesStore

    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        HStack {
            Text(song.displayName(using: namesStore))
            Spacer()
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.tint)
            }
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
